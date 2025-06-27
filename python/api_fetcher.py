import os
import sys
import time
import logging
import traceback
from datetime import datetime
from dotenv import load_dotenv

import firebase_admin
from firebase_admin import credentials, firestore
from newsdataapi import NewsDataApiClient


class APIFetcher:
    """Fetches news by category from NewsData API and saves to Firestore."""

    CATEGORIES = [
        "top",
        "business",
        "sports",
        "education",
        "entertainment",
        "environment",
        "food",
        "health",
        "lifestyle",
        "politics",
        "science",
        "technology",
        "tourism",
        "world",
        "other",
    ]

    def __init__(self):
        self._setup_logging()
        self._load_config()
        self._init_firebase()
        self.api_client = NewsDataApiClient(apikey=self.api_key)

    def _setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format="%(asctime)s - %(levelname)s - %(message)s",
            stream=sys.stdout,
        )

    def _load_config(self):
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        load_dotenv(env_path)
        self.api_key = os.getenv("NEWS_API_KEY")
        self.news_collection = os.getenv("NEWS_COLLECTION", "news_data")
        self.articles_collection = os.getenv("ARTICLES_COLLECTION", "articles")
        if not self.api_key:
            raise ValueError("NEWS_API_KEY environment variable is required")

    def _init_firebase(self):
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

    def process_articles(self, articles):
        """Standardize article fields."""
        now = datetime.now().isoformat()
        processed = []
        for article in articles:
            processed.append(
                {
                    "article_id": article.get("article_id"),
                    "title": article.get("title"),
                    "link": article.get("link"),
                    "keywords": article.get("keywords", []),
                    "creator": article.get("creator", []),
                    "video_url": article.get("video_url"),
                    "description": article.get("description"),
                    "content": article.get("content", "ONLY AVAILABLE IN PAID PLANS"),
                    "pubDate": article.get("pubDate"),
                    "pubDateTZ": article.get("pubDateTZ", "UTC"),
                    "image_url": article.get("image_url"),
                    "source_id": article.get("source_id"),
                    "source_priority": article.get("source_priority"),
                    "source_name": article.get("source_name"),
                    "source_url": article.get("source_url"),
                    "source_icon": article.get("source_icon"),
                    "language": article.get("language"),
                    "country": article.get("country", []),
                    "category": article.get("category", []),
                    "ai_tag": article.get(
                        "ai_tag", "ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS"
                    ),
                    "sentiment": article.get(
                        "sentiment",
                        "ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS",
                    ),
                    "sentiment_stats": article.get(
                        "sentiment_stats",
                        "ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS",
                    ),
                    "ai_region": article.get(
                        "ai_region", "ONLY AVAILABLE IN CORPORATE PLANS"
                    ),
                    "ai_org": article.get(
                        "ai_org", "ONLY AVAILABLE IN CORPORATE PLANS"
                    ),
                    "duplicate": article.get("duplicate", False),
                    "created_at": now,
                    "updated_at": now,
                }
            )
        return processed

    def save_articles_to_firestore(self, articles, category):
        """Save articles to Firestore, skipping duplicates."""
        if not articles:
            logging.warning(f"No articles to save for category '{category}'")
            return 0
        batch_size = 500
        saved, skipped = 0, 0
        for i in range(0, len(articles), batch_size):
            batch = self.db.batch()
            batch_articles = articles[i : i + batch_size]
            writes = 0
            for article in batch_articles:
                if article.get("article_id"):
                    doc_ref = self.db.collection(self.articles_collection).document(
                        article["article_id"]
                    )
                    if not doc_ref.get().exists:
                        batch.set(doc_ref, article)
                        writes += 1
                    else:
                        skipped += 1
            if writes > 0:
                batch.commit()
                logging.info(
                    f"Committed batch of {writes} new articles for '{category}'."
                )
                saved += writes
        logging.info(
            f"Category '{category}': Saved {saved} new, skipped {skipped} existing."
        )
        return saved

    def fetch_category_news(self, category):
        """Fetch and save news for a specific category."""
        logging.info(f"Processing category: '{category.upper()}'")
        try:
            response = self.api_client.news_api(language="en", category=category)
            if not response or response.get("status") != "success":
                logging.error(f"Failed to fetch category '{category}': {response}")
                return 0
            results = response.get("results", [])
            if not results:
                logging.warning(f"No articles found for category '{category}'")
                return 0
            processed = self.process_articles(results)
            saved = self.save_articles_to_firestore(processed, category)
            logging.info(
                f"Category '{category}' completed: {saved} new articles saved!"
            )
            return saved
        except Exception as e:
            logging.error(f"Error processing category '{category}': {e}", exc_info=True)
            return 0

    def update_summary_document(
        self, total_articles, categories_processed, total_skipped
    ):
        """Update summary document in Firestore."""
        try:
            doc_ref = self.db.collection(self.news_collection).document(
                "latest_categories"
            )
            doc_ref.set(
                {
                    "status": "success",
                    "total_articles_saved": total_articles,
                    "total_articles_skipped": total_skipped,
                    "categories_processed": categories_processed,
                    "last_updated": datetime.now(),
                    "fetch_timestamp": datetime.now().isoformat(),
                    "fetch_type": "by_category",
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
        logging.info("🚀 STARTING CATEGORY-BASED NEWS FETCH PROCESS")
        logging.info("=" * 60)
        start_time = datetime.now()
        total_saved = 0
        total_skipped = 0
        successful = []
        failed = []
        for i, category in enumerate(self.CATEGORIES, 1):
            logging.info(f"Processing category {i}/{len(self.CATEGORIES)}: {category}")
            saved = self.fetch_category_news(category)
            if saved > 0:
                successful.append(category)
                total_saved += saved
            else:
                failed.append(category)
            if i < len(self.CATEGORIES):
                time.sleep(3)
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


def main():
    try:
        fetcher = APIFetcher()
        success = fetcher.fetch_all_categories()
        if success:
            logging.info("🎉 SUCCESS! All categories fetched and saved!")
        else:
            logging.warning("💥 PROCESS FAILED! Check the errors above.")

    except Exception as e:
        logging.critical(f"Critical Error: {e}", exc_info=True)
        traceback.print_exc()


if __name__ == "__main__":
    main()
