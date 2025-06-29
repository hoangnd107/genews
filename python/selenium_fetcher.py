import os
import sys
import time
import logging
import traceback
from datetime import datetime
from typing import List, Dict, Any, Optional

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from webdriver_manager.chrome import ChromeDriverManager

from base_fetcher import BaseFetcher


class SeleniumFetcher(BaseFetcher):
    """
    Fetches news from Dantri.com.vn using Selenium and saves to Firestore.
    Inherits common functionality from BaseFetcher.
    """

    BASE_URL = "https://dantri.com.vn"
    SOURCE_CONFIG = {
        "source_id": "dantri",
        "source_name": "Dân Trí",
        "source_url": "https://dantri.com.vn",
        "source_icon": "https://dantri.com.vn/favicon.ico",
        "language": "vi",
        "country": ["VN"],
        "creator": ["Dân Trí"],
    }

    CATEGORIES = {
        "kinh-doanh": "business",
        "xa-hoi": "society",
        "the-gioi": "world",
        "giai-tri": "entertainment",
        "the-thao": "sports",
        "suc-khoe": "health",
        "cong-nghe": "technology",
        "giao-duc": "education",
        "du-lich": "tourism",
        "tin-moi-nhat": "top",
        "o-to-xe-may": "auto",
        "viec-lam": "job",
        "bat-dong-san": "real-estate",
        "phap-luat": "law",
        "doi-song": "lifestyle",
        "khoa-hoc": "science",
    }

    def __init__(self):
        """Initializes the Selenium fetcher."""
        super().__init__(source_id=self.SOURCE_CONFIG["source_id"])
        self.driver = None
        self.wait = None

    def _init_selenium(self):
        """Initializes the Selenium WebDriver with Chrome options."""
        if self.driver:
            logging.info("Selenium WebDriver is already initialized.")
            return

        logging.info("Initializing Selenium WebDriver with optimized options...")
        chrome_options = Options()
        chrome_options.add_argument("--headless=new")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--log-level=3")
        chrome_options.add_experimental_option("excludeSwitches", ["enable-logging"])
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--blink-settings=imagesEnabled=false")
        chrome_options.add_argument(
            "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36"
        )

        try:
            chrome_driver_path = os.getenv("CHROME_DRIVER_PATH")
            if chrome_driver_path and os.path.exists(chrome_driver_path):
                logging.info(f"Using ChromeDriver from path: {chrome_driver_path}")
                service = Service(executable_path=chrome_driver_path)
            else:
                logging.info("ChromeDriver path not found, using ChromeDriverManager.")
                service = Service(ChromeDriverManager().install())

            self.driver = webdriver.Chrome(service=service, options=chrome_options)
            self.wait = WebDriverWait(self.driver, 10)
            logging.info("Selenium WebDriver initialized successfully.")
        except Exception as e:
            logging.error(f"Error initializing Selenium: {e}", exc_info=True)
            raise

    def _close_selenium(self):
        """Closes the Selenium WebDriver if it's running."""
        if self.driver:
            self.driver.quit()
            self.driver = None
            self.wait = None
            logging.info("Selenium WebDriver closed.")

    def _extract_full_url(self, relative_url: str) -> str:
        """Convert relative URL to full URL."""
        if relative_url.startswith("http"):
            return relative_url
        elif relative_url.startswith("//"):
            return f"https:{relative_url}"
        elif relative_url.startswith("/"):
            return f"{self.BASE_URL}{relative_url}"
        else:
            return f"{self.BASE_URL}/{relative_url}"

    def _create_article_dict(
        self,
        title: str,
        link: str,
        description: str,
        image_url: Optional[str],
        category_name: str,
    ) -> Dict[str, Any]:
        """Creates a standardized article dictionary."""
        now = datetime.now().isoformat()
        full_link = self._extract_full_url(link)

        return {
            "article_id": self._generate_article_id(full_link),
            "title": title.strip(),
            "link": full_link,
            "creator": self.SOURCE_CONFIG["creator"],
            "video_url": None,
            "description": (
                description.strip() if description else title.strip() or "No description available."
            ),
            "content": (
                description.strip() if description else title.strip() or "No description available."
            ),
            "pubDate": now,
            "image_url": self._extract_full_url(image_url) if image_url else None,
            "source_id": self.SOURCE_CONFIG["source_id"],
            "source_name": self.SOURCE_CONFIG["source_name"],
            "source_url": self.SOURCE_CONFIG["source_url"],
            "source_icon": self.SOURCE_CONFIG["source_icon"],
            "language": self.SOURCE_CONFIG["language"],
            "country": self.SOURCE_CONFIG["country"],
            "category": [category_name],
            "ai_tag": "SELENIUM_SCRAPED",
            "created_at": now,
            "updated_at": now,
        }

    def fetch_category_articles(
        self, category_slug: str, category_name: str
    ) -> List[Dict[str, Any]]:
        """Fetches articles from a specific category page."""
        category_url = f"{self.BASE_URL}/{category_slug}.htm"
        logging.info(f"Fetching articles from: {category_url}")

        try:
            self.driver.get(category_url)
            time.sleep(3)

            article_elements = self.driver.find_elements(
                By.CSS_SELECTOR, "article.article-item"
            )

            if not article_elements:
                logging.warning(
                    f"No article items found for category '{category_name}' at {category_url}"
                )
                return []

            logging.info(
                f"Found {len(article_elements)} potential articles in '{category_name}'"
            )
            articles = []

            for element in article_elements:
                try:
                    title_element = element.find_element(
                        By.CSS_SELECTOR, ".article-title a"
                    )
                    title = title_element.text.strip()
                    link = title_element.get_attribute("href")

                    description = ""
                    try:
                        desc_element = element.find_element(
                            By.CSS_SELECTOR, ".article-excerpt"
                        )
                        description = desc_element.text.strip()
                    except:
                        pass

                    image_url = None
                    try:
                        thumb_element = element.find_element(
                            By.CSS_SELECTOR, ".article-thumb img"
                        )
                        image_url = thumb_element.get_attribute(
                            "data-src"
                        ) or thumb_element.get_attribute("src")
                    except:
                        pass

                    if title and link:
                        article = self._create_article_dict(
                            title, link, description, image_url, category_name
                        )
                        articles.append(article)

                except Exception as e:
                    logging.warning(
                        f"Could not extract data from an article element: {e}"
                    )
                    continue

            logging.info(
                f"Successfully extracted {len(articles)} articles from '{category_name}'"
            )
            return articles

        except Exception as e:
            logging.error(
                f"Error fetching category page '{category_name}': {e}", exc_info=True
            )
            return []

    def fetch_all(self) -> bool:
        """Fetches news for all categories defined in the configuration."""
        try:
            self._init_selenium()
            total_saved = 0
            total_skipped = 0
            successful_categories = []
            failed_categories = []

            for i, (slug, name) in enumerate(self.CATEGORIES.items(), 1):
                logging.info(
                    f"--- Processing category {i}/{len(self.CATEGORIES)}: {name} ---"
                )
                articles = self.fetch_category_articles(slug, name)
                if articles:
                    saved, skipped = self.save_articles_to_firestore(articles, name)
                    if saved > 0:
                        successful_categories.append(name)
                    total_saved += saved
                    total_skipped += skipped
                else:
                    failed_categories.append(name)

                if i < len(self.CATEGORIES):
                    logging.info("Waiting 5 seconds before next category...")
                    time.sleep(5)
        except Exception as e:
            logging.critical(
                f"A critical error occurred in fetch_all: {e}", exc_info=True
            )
            self.update_summary_document(0, 0, [], "selenium_scrape", status="failed")
            return False
        finally:
            self._close_selenium()

        self.update_summary_document(
            total_saved=total_saved,
            total_skipped=total_skipped,
            categories_processed=successful_categories,
            fetch_type="selenium_scrape",
        )

        logging.info(f"Total new articles saved: {total_saved}")
        logging.info(f"Total existing articles skipped: {total_skipped}")
        if successful_categories:
            logging.info(
                f"✅ Successful categories: {', '.join(successful_categories)}"
            )
        if failed_categories:
            logging.warning(
                f"❌ Failed/Empty categories: {', '.join(failed_categories)}"
            )

        return total_saved > 0

    def scrape_full_article_content(self, url: str) -> str:
        """Scrape full article content from a given URL."""
        try:
            self.driver.get(url)
            time.sleep(3)

            content_selectors = [
                ".singular-content",
                ".article-content",
                "div.e-magazine__body",
            ]

            for selector in content_selectors:
                try:
                    content_element = self.driver.find_element(
                        By.CSS_SELECTOR, selector
                    )
                    if content_element:
                        for unwanted_selector in [".ads", "script", "style"]:
                            try:
                                for el in content_element.find_elements(
                                    By.CSS_SELECTOR, unwanted_selector
                                ):
                                    self.driver.execute_script(
                                        "arguments[0].remove()", el
                                    )
                            except:
                                pass
                        return content_element.text.strip()
                except:
                    continue

            return "Content not found with available selectors."

        except Exception as e:
            logging.error(f"Error scraping content from {url}: {e}")
            return "Content scraping failed."

    def scrape_content_for_existing_articles(self, limit: int = 10):
        """Finds articles missing full content and scrapes it."""
        logging.info(f"🔍 Starting to scrape full content for up to {limit} articles.")
        
        try:
            self._init_selenium()
            docs = (
                self.db.collection(self.articles_collection)
                .where("content", "==", "CONTENT_TO_BE_SCRAPED")
                .where("source_id", "==", self.source_id)
                .limit(limit)
                .stream()
            )

            updated_count = 0
            for doc in docs:
                article = doc.to_dict()
                url = article.get("link")
                if not url:
                    continue

                logging.info(f"Scraping: {article.get('title', doc.id)[:60]}...")
                full_content = self.scrape_full_article_content(url)

                if full_content and "Content scraping failed" not in full_content:
                    doc.reference.update(
                        {
                            "content": full_content,
                            "updated_at": datetime.now().isoformat(),
                        }
                    )
                    updated_count += 1
                    time.sleep(3)

            logging.info(f"✅ Updated content for {updated_count} articles.")

        except Exception as e:
            logging.error(
                "An error occurred during content scraping batch.", exc_info=True
            )
        finally:
            self._close_selenium()


def main():
    """Main function to run the fetcher."""
    fetcher = SeleniumFetcher()
    fetcher.run()


if __name__ == "__main__":
    main()