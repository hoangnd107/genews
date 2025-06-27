import os
import sys
import time
import logging
import traceback
import hashlib
from datetime import datetime
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

import firebase_admin
from firebase_admin import credentials, firestore

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager


class SeleniumFetcher:
    """Fetches news from Dantri.com.vn using Selenium and saves to Firestore."""

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
        "kinh-doanh": "Kinh doanh",
        "xa-hoi": "Xã hội",
        "the-gioi": "Thế giới",
        "giai-tri": "Giải trí",
        "the-thao": "Thể thao",
        "suc-khoe": "Sức khỏe",
        "cong-nghe": "Công nghệ",
        "giao-duc": "Giáo dục",
        "phap-luat": "Pháp luật",
        "viec-lam": "Việc làm",
        "tin-moi-nhat": "Tin mới nhất",
    }

    def __init__(self):
        self._setup_logging()
        self._load_config()
        self._init_firebase()
        self._init_selenium()

    def _setup_logging(self):
        """Configure logging format and level."""
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            stream=sys.stdout,
        )

    def _load_config(self):
        """Load configuration from .env file."""
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        load_dotenv(env_path)
        self.articles_collection = os.getenv("ARTICLES_COLLECTION", "articles")
        self.news_collection = os.getenv("NEWS_COLLECTION", "news_data")

    def _init_firebase(self):
        """Initialize Firebase Admin SDK."""
        service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        if not service_account_path:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_PATH environment variable is required"
            )

        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(
                os.path.dirname(__file__), service_account_path
            )

        if not os.path.exists(service_account_path):
            raise FileNotFoundError(
                f"Service account file not found: {service_account_path}"
            )

        if not firebase_admin._apps:
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)

        self.db = firestore.client()
        logging.info("Firebase initialized successfully.")

    def _init_selenium(self):
        """Initialize Selenium WebDriver with Chrome options."""
        chrome_options = Options()
        chrome_options.add_argument("--headless")  # Run in background
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-software-rasterizer")
        chrome_options.add_argument("--disable-background-timer-throttling")
        chrome_options.add_argument("--disable-backgrounding-occluded-windows")
        chrome_options.add_argument("--disable-renderer-backgrounding")
        chrome_options.add_argument("--disable-features=TranslateUI")
        chrome_options.add_argument("--disable-ipc-flooding-protection")
        chrome_options.add_argument("--disable-webgl")
        chrome_options.add_argument("--disable-webgl2")
        chrome_options.add_argument("--disable-3d-apis")
        chrome_options.add_argument("--disable-accelerated-2d-canvas")
        chrome_options.add_argument("--disable-accelerated-jpeg-decoding")
        chrome_options.add_argument("--disable-accelerated-mjpeg-decode")
        chrome_options.add_argument("--disable-accelerated-video-decode")
        chrome_options.add_argument("--disable-accelerated-video-encode")
        chrome_options.add_argument("--disable-background-media-processing")
        chrome_options.add_argument("--disable-background-timer-throttling")
        chrome_options.add_argument("--disable-features=VizDisplayCompositor")
        chrome_options.add_argument("--use-gl=swiftshader")
        chrome_options.add_argument("--enable-unsafe-swiftshader")
        chrome_options.add_argument("--window-size=1920,1080")
        chrome_options.add_argument(
            "--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        )

        try:
            service = Service(ChromeDriverManager().install())
            self.driver = webdriver.Chrome(service=service, options=chrome_options)
            self.wait = WebDriverWait(self.driver, 10)
            logging.info("Selenium WebDriver initialized successfully.")
        except Exception as e:
            logging.error(f"Error initializing Selenium: {e}")
            raise

    def _generate_article_id(self, link: str) -> str:
        """Generate unique article ID from link using MD5 hash."""
        return hashlib.md5(link.encode()).hexdigest()

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
        category_slug: str,
        category_name: str,
    ) -> Dict[str, Any]:
        """Create standardized article dictionary."""
        now = datetime.now().isoformat()

        return {
            "article_id": self._generate_article_id(link),
            "title": title.strip(),
            "link": self._extract_full_url(link),
            "keywords": [],
            "creator": self.SOURCE_CONFIG["creator"],
            "video_url": None,
            "description": (
                description.strip() if description else "No description available."
            ),
            "content": "CONTENT_TO_BE_SCRAPED",
            "pubDate": now,  # Use current time as we can't get exact publish date from listing
            "pubDateTZ": "UTC+07:00",
            "image_url": self._extract_full_url(image_url) if image_url else None,
            "source_id": self.SOURCE_CONFIG["source_id"],
            "source_priority": 1,
            "source_name": self.SOURCE_CONFIG["source_name"],
            "source_url": self.SOURCE_CONFIG["source_url"],
            "source_icon": self.SOURCE_CONFIG["source_icon"],
            "language": self.SOURCE_CONFIG["language"],
            "country": self.SOURCE_CONFIG["country"],
            "category": [category_name],
            "ai_tag": "SELENIUM_SCRAPED",
            "sentiment": "NEUTRAL",
            "sentiment_stats": "NOT_ANALYZED",
            "ai_region": "NOT_ANALYZED",
            "ai_org": "NOT_ANALYZED",
            "duplicate": False,
            "created_at": now,
            "updated_at": now,
            "category_slug": category_slug,
        }

    def fetch_category_articles(
        self, category_slug: str, category_name: str
    ) -> List[Dict[str, Any]]:
        """Fetch articles from a specific category page."""
        category_url = f"{self.BASE_URL}/{category_slug}.htm"
        logging.info(f"Fetching articles from: {category_url}")

        try:
            self.driver.get(category_url)
            time.sleep(3)  # Wait for page to load

            # Find all article items
            article_elements = self.driver.find_elements(By.CLASS_NAME, "article-item")

            if not article_elements:
                logging.warning(
                    f"No article items found for category '{category_name}'"
                )
                return []

            logging.info(f"Found {len(article_elements)} articles in '{category_name}'")
            articles = []

            for element in article_elements:
                try:
                    # Extract title and link
                    title_element = element.find_element(
                        By.CSS_SELECTOR, ".article-title a"
                    )
                    title = title_element.text.strip()
                    link = title_element.get_attribute("href")

                    # Extract description
                    description = ""
                    try:
                        desc_element = element.find_element(
                            By.CLASS_NAME, "article-excerpt"
                        )
                        description = desc_element.text.strip()
                    except:
                        pass  # Description is optional

                    # Extract image URL
                    image_url = None
                    try:
                        thumb_element = element.find_element(
                            By.CSS_SELECTOR, ".article-thumb a img"
                        )
                        image_url = thumb_element.get_attribute("src")
                        if not image_url:
                            image_url = thumb_element.get_attribute(
                                "data-src"
                            )  # Lazy loading
                    except:
                        pass  # Image is optional

                    if title and link:
                        article = self._create_article_dict(
                            title,
                            link,
                            description,
                            image_url,
                            category_slug,
                            category_name,
                        )
                        articles.append(article)

                except Exception as e:
                    logging.warning(f"Error extracting article data: {e}")
                    continue

            logging.info(
                f"Successfully extracted {len(articles)} articles from '{category_name}'"
            )
            return articles

        except Exception as e:
            logging.error(f"Error fetching category '{category_name}': {e}")
            return []

    def save_articles_to_firestore(
        self, articles: List[Dict[str, Any]], category_name: str
    ) -> int:
        """Save articles to Firestore, skipping duplicates."""
        if not articles:
            logging.warning(f"No articles to save for category '{category_name}'")
            return 0

        batch_size = 500
        saved = 0
        skipped = 0

        for i in range(0, len(articles), batch_size):
            batch = self.db.batch()
            batch_articles = articles[i : i + batch_size]
            writes = 0

            for article in batch_articles:
                if article.get("article_id"):
                    doc_ref = self.db.collection(self.articles_collection).document(
                        article["article_id"]
                    )
                    # Check if article already exists
                    if not doc_ref.get().exists:
                        batch.set(doc_ref, article)
                        writes += 1
                    else:
                        skipped += 1

            if writes > 0:
                batch.commit()
                logging.info(
                    f"Committed batch of {writes} new articles for '{category_name}'."
                )
                saved += writes

        logging.info(
            f"Category '{category_name}': Saved {saved} new, skipped {skipped} existing."
        )
        return saved

    def fetch_category_news(self, category_slug: str, category_name: str) -> int:
        """Fetch and save news for a specific category."""
        logging.info(f"Processing category: '{category_name.upper()}'")

        try:
            articles = self.fetch_category_articles(category_slug, category_name)
            if not articles:
                logging.warning(f"No articles found for category '{category_name}'")
                return 0

            saved = self.save_articles_to_firestore(articles, category_name)
            logging.info(
                f"Category '{category_name}' completed: {saved} new articles saved!"
            )
            return saved

        except Exception as e:
            logging.error(
                f"Error processing category '{category_name}': {e}", exc_info=True
            )
            return 0

    def update_summary_document(
        self, total_articles: int, categories_processed: List[str], total_skipped: int
    ):
        """Update summary document in Firestore."""
        try:
            doc_ref = self.db.collection(self.news_collection).document(
                "latest_selenium"
            )
            doc_ref.set(
                {
                    "status": "success",
                    "total_articles_saved": total_articles,
                    "total_articles_skipped": total_skipped,
                    "categories_processed": categories_processed,
                    "last_updated": datetime.now(),
                    "fetch_timestamp": datetime.now().isoformat(),
                    "fetch_type": "selenium_scraping",
                    "source": "dantri.com.vn",
                }
            )
            logging.info(
                f"Updated summary: {total_articles} new, {total_skipped} skipped from {len(categories_processed)} categories"
            )
            return True
        except Exception as e:
            logging.error(f"Error updating summary document: {e}", exc_info=True)
            return False

    def fetch_all_categories(self):
        """Fetch news for all categories."""
        logging.info("=" * 60)
        logging.info("🚀 STARTING DANTRI SELENIUM FETCH PROCESS")
        logging.info("=" * 60)

        start_time = datetime.now()
        total_saved = 0
        total_skipped = 0
        successful = []
        failed = []

        try:
            for i, (category_slug, category_name) in enumerate(
                self.CATEGORIES.items(), 1
            ):
                logging.info(
                    f"Processing category {i}/{len(self.CATEGORIES)}: {category_name}"
                )

                saved = self.fetch_category_news(category_slug, category_name)

                if saved > 0:
                    successful.append(category_name)
                    total_saved += saved
                else:
                    failed.append(category_name)

                # Add delay between categories to be respectful
                if i < len(self.CATEGORIES):
                    logging.info("Waiting 5 seconds before next category...")
                    time.sleep(5)

        finally:
            # Always close the driver
            if hasattr(self, "driver"):
                self.driver.quit()
                logging.info("Selenium WebDriver closed.")

        duration = datetime.now() - start_time
        self.update_summary_document(total_saved, successful, total_skipped)

        logging.info("🏁 PROCESS COMPLETED!")
        logging.info(f"⏱️  Total time: {duration}")
        logging.info(
            f"🏷️  Categories processed: {len(successful)}/{len(self.CATEGORIES)}"
        )
        logging.info(f"📰 Total new articles saved: {total_saved}")
        logging.info(f"🔄 Total existing articles skipped: {total_skipped}")
        logging.info(f"💾 All articles saved to collection: {self.articles_collection}")

        if successful:
            logging.info(f"✅ Successful categories: {', '.join(successful)}")
        if failed:
            logging.info(f"❌ Failed categories: {', '.join(failed)}")

        return total_saved > 0

    def scrape_full_article_content(self, url: str) -> str:
        """Scrape full article content from a given URL."""
        try:
            self.driver.get(url)
            time.sleep(3)

            # Common selectors for Dantri article content
            content_selectors = [
                ".singular-content",
                ".article-content",
                ".detail-content",
                ".news-content",
                "[data-field='body']",
            ]

            for selector in content_selectors:
                try:
                    content_element = self.driver.find_element(
                        By.CSS_SELECTOR, selector
                    )
                    if content_element:
                        return content_element.text.strip()
                except:
                    continue

            return "Content not found with available selectors."

        except Exception as e:
            logging.error(f"Error scraping content from {url}: {e}")
            return "Content scraping failed."

    def scrape_content_for_existing_articles(self, limit: int = 10):
        """Find articles missing full content and scrape it."""
        logging.info(f"🔍 Starting to scrape full content for up to {limit} articles.")

        try:
            # Reinitialize driver for content scraping
            self._init_selenium()

            docs = (
                self.db.collection(self.articles_collection)
                .where("content", "==", "CONTENT_TO_BE_SCRAPED")
                .where("source_id", "==", "dantri")
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

                doc.reference.update(
                    {"content": full_content, "updated_at": datetime.now().isoformat()}
                )
                updated_count += 1
                time.sleep(3)  # Be respectful

            logging.info(f"✅ Updated content for {updated_count} articles.")

        except Exception as e:
            logging.error(
                "An error occurred during content scraping batch.", exc_info=True
            )
        finally:
            if hasattr(self, "driver"):
                self.driver.quit()


def main():
    """Main function to run the fetcher."""
    try:
        fetcher = SeleniumFetcher()
        success = fetcher.fetch_all_categories()

        if success:
            logging.info("🎉 SUCCESS! Dantri news fetched and saved!")
        else:
            logging.warning("💥 PROCESS FAILED! Check the errors above.")

        # Optionally scrape content for some articles
        # fetcher.scrape_content_for_existing_articles(limit=5)

    except Exception as e:
        logging.critical(f"Critical Error: {e}", exc_info=True)
        traceback.print_exc()


if __name__ == "__main__":
    main()
