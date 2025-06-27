import feedparser
import requests
import hashlib
import json
import logging
import os
import re
import sys
import time
import traceback
import argparse
from bs4 import BeautifulSoup
from datetime import datetime
from dotenv import load_dotenv
from urllib.parse import urljoin, urlparse
from typing import List, Dict, Any, Optional, Tuple

import firebase_admin
from firebase_admin import credentials, firestore

# --- Configuration ---
# Centralized configuration for easier management
VNEXPRESS_CONFIG = {
    "source_id": "vnexpress",
    "source_name": "VnExpress",
    "base_rss_url": "https://vnexpress.net/rss",
    "base_url": "https://vnexpress.net",
    "favicon": "https://vnexpress.net/favicon.ico",
    "language": "vi",
    "country": ["VN"],
    "creator": ["VnExpress"],
    "content_selectors": [
        ".fck_detail",
        ".content_detail",
        ".Normal",
        "article .content",
        ".article-content",
    ],
    "categories": {
        "trang-chu": "Trang chủ",
        "the-gioi": "Thế giới",
        "thoi-su": "Thời sự",
        "kinh-doanh": "Kinh doanh",
        "startup": "Startup",
        "giai-tri": "Giải trí",
        "the-thao": "Thể thao",
        "phap-luat": "Pháp luật",
        "giao-duc": "Giáo dục",
        "tin-moi-nhat": "Tin mới nhất",
        "tin-noi-bat": "Tin nổi bật",
        "suc-khoe": "Sức khỏe",
        "doi-song": "Đời sống",
        "du-lich": "Du lịch",
        "so-hoa": "Khoa học công nghệ",
        "oto-xe-may": "Xe",
        "y-kien": "Ý kiến",
        "tam-su": "Tâm sự",
        "cuoi": "Cười",
        "tin-xem-nhieu": "Tin xem nhiều",
    },
}


class RSSFetcher:
    """
    Fetches, parses, and stores articles from VnExpress RSS feeds into Firestore.
    """

    def __init__(self):
        """Initializes the fetcher, configuration, and services."""
        self._setup_logging()
        self._load_config()
        self._init_firebase()
        self._init_session()

    def _setup_logging(self):
        """Configures the logging format and level."""
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            stream=sys.stdout,
        )

    def _load_config(self):
        """Loads configuration from .env and the config dictionary."""
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        load_dotenv(env_path)

        self.articles_collection = os.getenv("ARTICLES_COLLECTION", "articles")
        self.summary_collection = os.getenv("NEWS_COLLECTION", "news_data")
        self.config = VNEXPRESS_CONFIG

    def _init_firebase(self):
        """Initializes the Firebase Admin SDK."""
        service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        if not service_account_path:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH is not set in .env file")

        abs_path = service_account_path
        if not os.path.isabs(abs_path):
            abs_path = os.path.join(os.path.dirname(__file__), abs_path)

        if not os.path.exists(abs_path):
            raise FileNotFoundError(f"Service account file not found: {abs_path}")

        if not firebase_admin._apps:
            cred = credentials.Certificate(abs_path)
            firebase_admin.initialize_app(cred)
        self.db = firestore.client()
        logging.info("Firebase initialized successfully.")

    def _init_session(self):
        """Initializes a requests session with a user-agent."""
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
            }
        )
        logging.info("Requests session initialized.")

    def _generate_article_id(self, link: str) -> str:
        """Generates a unique article ID from the link using MD5 hash."""
        return hashlib.md5(link.encode()).hexdigest()

    def _extract_image_from_description(self, description: str) -> Optional[str]:
        """Extracts the first image URL from the description's HTML."""
        try:
            soup = BeautifulSoup(description, "html.parser")
            img_tag = soup.find("img")
            return img_tag["src"] if img_tag and img_tag.get("src") else None
        except Exception as e:
            logging.warning(f"Could not extract image from description: {e}")
            return None

    def _extract_description_text(self, description: str) -> str:
        """Extracts and cleans the text from the description's HTML."""
        try:
            soup = BeautifulSoup(description, "html.parser")
            for tag in soup.find_all(["img", "br"]):
                tag.decompose()
            return (
                soup.get_text(separator=" ", strip=True) or "No description available."
            )
        except Exception as e:
            logging.warning(f"Could not extract clean description text: {e}")
            return description

    def _parse_rss_date(self, date_string: str) -> str:
        """Parses RSS date string to ISO 8601 format."""
        try:
            # Format: "Sun, 22 Jun 2025 22:07:14 +0700"
            dt = datetime.strptime(date_string, "%a, %d %b %Y %H:%M:%S %z")
            return dt.isoformat()
        except (ValueError, TypeError):
            logging.warning(
                f"Could not parse date '{date_string}', using current time."
            )
            return datetime.now().isoformat()

    def _parse_rss_entry(
        self, entry: Dict[str, Any], category_slug: str, category_name: str
    ) -> Dict[str, Any]:
        """Parses a single feedparser entry into a structured article dictionary."""
        link = entry.get("link")
        title = entry.get("title", "No Title")
        description_html = entry.get("description", "")

        description_text = self._extract_description_text(description_html)

        return {
            "article_id": self._generate_article_id(link),
            "title": title,
            "link": link,
            "keywords": [],  # Keywords can be generated later if needed
            "creator": self.config["creator"],
            "video_url": None,
            "description": description_text,
            "content": "CONTENT_TO_BE_SCRAPED",
            "pubDate": self._parse_rss_date(entry.get("published")),
            "image_url": self._extract_image_from_description(description_html),
            "source_id": self.config["source_id"],
            "source_name": self.config["source_name"],
            "source_url": self.config["base_url"],
            "source_icon": self.config["favicon"],
            "language": self.config["language"],
            "country": self.config["country"],
            "category": [category_name],
            "ai_tag": "RSS_PARSED",
            "sentiment": "NEUTRAL",
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "rss_category_slug": category_slug,
        }

    def fetch_rss_category(
        self, category_slug: str, category_name: str
    ) -> List[Dict[str, Any]]:
        """Fetches and parses all articles from a specific RSS category."""
        rss_url = f"{self.config['base_rss_url']}/{category_slug}.rss"
        if category_slug == "trang-chu":
            rss_url = f"{self.config['base_rss_url']}.rss"

        logging.info(f"Fetching RSS from: {rss_url}")
        feed = feedparser.parse(rss_url)

        if feed.bozo:
            logging.warning(
                f"Feed for '{category_name}' is ill-formed. Bozo reason: {feed.bozo_exception}"
            )

        if not feed.entries:
            logging.info(f"No entries found in '{category_name}' feed.")
            return []

        logging.info(f"Found {len(feed.entries)} articles in '{category_name}'.")

        articles = []
        for entry in feed.entries:
            try:
                if "link" in entry and "title" in entry:
                    articles.append(
                        self._parse_rss_entry(entry, category_slug, category_name)
                    )
            except Exception as e:
                logging.error(f"Error processing an article in '{category_name}': {e}")
        return articles

    def save_articles_to_firestore(
        self, articles: List[Dict[str, Any]], category_name: str
    ) -> Tuple[int, int]:
        """Saves a list of articles to Firestore, skipping duplicates."""
        if not articles:
            return 0, 0

        logging.info(
            f"Saving {len(articles)} articles from '{category_name}' to Firestore..."
        )
        total_articles_saved = 0
        total_articles_skipped = 0

        for i in range(0, len(articles), 500):  # Firestore batch limit is 500
            batch = self.db.batch()
            batch_articles = articles[i : i + 500]

            writes_in_this_batch = 0
            for article in batch_articles:
                article_ref = self.db.collection(self.articles_collection).document(
                    article["article_id"]
                )
                # This check is inefficient but preserves original behavior minus the bug.
                # It performs one read operation per article.
                if not article_ref.get().exists:
                    batch.set(article_ref, article)
                    writes_in_this_batch += 1
                else:
                    total_articles_skipped += 1

            # Only commit if there are actual writes in this specific batch
            if writes_in_this_batch > 0:
                batch.commit()
                logging.info(
                    f"Committed a batch of {writes_in_this_batch} new articles for '{category_name}'."
                )
                total_articles_saved += writes_in_this_batch

        logging.info(
            f"'{category_name}': Saved {total_articles_saved} new, skipped {total_articles_skipped} existing."
        )
        return total_articles_saved, total_articles_skipped

    def fetch_all_categories(self) -> bool:
        """Iterates through all categories, fetches, and saves articles."""
        logging.info("🚀 STARTING VNEXPRESS RSS FETCH PROCESS")
        start_time = time.time()
        total_saved = 0
        total_skipped = 0

        categories = self.config["categories"]
        for i, (slug, name) in enumerate(categories.items(), 1):
            logging.info(f"--- Processing category {i}/{len(categories)}: {name} ---")
            try:
                articles = self.fetch_rss_category(slug, name)
                if articles:
                    saved, skipped = self.save_articles_to_firestore(articles, name)
                    total_saved += saved
                    total_skipped += skipped
                time.sleep(1)  # Be respectful to the server
            except Exception as e:
                logging.error(
                    f"Failed to process category '{name}': {e}", exc_info=True
                )

        duration = time.time() - start_time
        logging.info("🏁 PROCESS COMPLETED!")
        logging.info(f"⏱️  Total time: {duration:.2f} seconds")
        logging.info(f"📰 Total new articles saved: {total_saved}")
        logging.info(f"🔄 Total existing articles skipped: {total_skipped}")
        return total_saved > 0

    def scrape_full_article_content(self, url: str) -> str:
        """Scrapes the full article content from a given URL."""
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, "html.parser")

            for selector in self.config["content_selectors"]:
                content_div = soup.select_one(selector)
                if content_div:
                    for unwanted in content_div.find_all(["script", "style", ".ads"]):
                        unwanted.decompose()
                    return content_div.get_text(separator="\n", strip=True)

            return "Content not found with available selectors."
        except requests.exceptions.RequestException as e:
            logging.error(f"HTTP error scraping {url}: {e}")
            return "Content scraping failed due to network error."
        except Exception as e:
            logging.error(f"Error scraping content from {url}: {e}")
            return "Content scraping failed."

    def scrape_content_for_existing_articles(self, limit: int = 10):
        """Finds articles missing full content and scrapes it."""
        logging.info(f"🔍 Starting to scrape full content for up to {limit} articles.")
        try:
            docs = (
                self.db.collection(self.articles_collection)
                .where("content", "==", "CONTENT_TO_BE_SCRAPED")
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
                time.sleep(2)  # Be respectful

            logging.info(f"✅ Updated content for {updated_count} articles.")
        except Exception as e:
            logging.error(
                "An error occurred during content scraping batch.", exc_info=True
            )


def main():
    """Main function to run the fetcher script with command-line arguments."""
    parser = argparse.ArgumentParser(description="Fetch news from VnExpress RSS feeds.")
    parser.add_argument(
        "--scrape-content",
        nargs="?",
        const=10,
        type=int,
        metavar="LIMIT",
        help="Optionally scrape full content for articles. Provide a limit (default: 10).",
    )

    args = parser.parse_args()

    try:
        fetcher = RSSFetcher()
        success = fetcher.fetch_all_categories()

        if success:
            logging.info("🎉 SUCCESS! VnExpress RSS news fetched and saved.")
        else:
            logging.warning("PROCESS FINISHED, but no new articles were saved.")

        if args.scrape_content is not None:
            fetcher.scrape_content_for_existing_articles(limit=args.scrape_content)

    except Exception as e:
        logging.critical(f"A critical error occurred: {e}", exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
