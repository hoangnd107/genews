import os
import sys
import logging
import hashlib
from datetime import datetime
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Tuple

from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore


class BaseFetcher(ABC):
    """
    An abstract base class for news fetchers.
    Handles common functionalities like logging, configuration,
    Firebase initialization, and saving data to Firestore.
    """

    def __init__(self, source_id: str):
        """
        Initializes the base fetcher.
        :param source_id: A unique identifier for the news source (e.g., 'vnexpress', 'dantri').
        """
        self.source_id = source_id
        self.db = None
        self.articles_collection = "articles"
        self.summary_collection = "news_data"
        self._setup_logging()
        self._load_config()
        self._init_firebase()

    def _setup_logging(self):
        """Configures a standardized logger."""
        # Remove existing handlers to avoid duplicate logs
        for handler in logging.root.handlers[:]:
            logging.root.removeHandler(handler)

        logging.basicConfig(
            level=logging.INFO,
            format=f"%(asctime)s - %(levelname)s - [{self.source_id.upper()}] - %(message)s",
            stream=sys.stdout,
        )

    def _load_config(self):
        """Loads configuration from the .env file."""
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        load_dotenv(env_path)
        self.articles_collection = os.getenv("ARTICLES_COLLECTION", "articles")
        self.summary_collection = os.getenv("NEWS_COLLECTION", "news_data")
        logging.info("Configuration loaded.")

    def _init_firebase(self):
        """
        Initializes the Firebase Admin SDK if not already initialized.
        Ensures that the service account path is correctly resolved.
        """
        if firebase_admin._apps:
            self.db = firestore.client()
            logging.info("Firebase already initialized. Using existing app.")
            return

        service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        if not service_account_path:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_PATH environment variable is required."
            )

        # Resolve path relative to the script's directory if it's not absolute
        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(
                os.path.dirname(__file__), service_account_path
            )

        if not os.path.exists(service_account_path):
            raise FileNotFoundError(
                f"Service account file not found at resolved path: {service_account_path}"
            )

        try:
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
            self.db = firestore.client()
            logging.info("Firebase initialized successfully.")
        except Exception as e:
            logging.error(f"Failed to initialize Firebase: {e}", exc_info=True)
            raise

    def _generate_article_id(self, link: str) -> str:
        """Generates a unique article ID from its link using MD5 hash."""
        if not link:
            raise ValueError("Link cannot be empty for generating an article ID.")
        return hashlib.md5(link.encode("utf-8")).hexdigest()

    def save_articles_to_firestore(
        self, articles: List[Dict[str, Any]], category_name: str
    ) -> Tuple[int, int]:
        """
        Saves a list of articles to Firestore in batches, skipping duplicates.
        This version is optimized to reduce read operations.
        Returns a tuple of (saved_count, skipped_count).
        """
        if not articles:
            logging.info(f"No articles to save for category '{category_name}'.")
            return 0, 0

        saved_count = 0
        skipped_count = 0
        batch_size = 500  # Firestore batch write limit

        for i in range(0, len(articles), batch_size):
            batch = self.db.batch()
            batch_articles = articles[i : i + batch_size]
            writes_in_batch = 0

            article_ids = [
                article["article_id"]
                for article in batch_articles
                if "article_id" in article
            ]
            if not article_ids:
                continue

            docs_ref = [
                self.db.collection(self.articles_collection).document(id)
                for id in article_ids
            ]
            existing_docs = self.db.get_all(docs_ref)
            existing_ids = {doc.id for doc in existing_docs if doc.exists}

            for article in batch_articles:
                article_id = article.get("article_id")
                if not article_id:
                    logging.warning(
                        f"Skipping article with no ID: {article.get('title', 'N/A')}"
                    )
                    continue

                if article_id not in existing_ids:
                    doc_ref = self.db.collection(self.articles_collection).document(
                        article_id
                    )
                    batch.set(doc_ref, article)
                    writes_in_batch += 1
                else:
                    skipped_count += 1

            if writes_in_batch > 0:
                try:
                    batch.commit()
                    logging.info(
                        f"Committed batch of {writes_in_batch} new articles for '{category_name}'."
                    )
                    saved_count += writes_in_batch
                except Exception as e:
                    logging.error(
                        f"Error committing batch for '{category_name}': {e}",
                        exc_info=True,
                    )

        logging.info(
            f"Category '{category_name}': Saved {saved_count} new, skipped {skipped_count} existing articles."
        )
        return saved_count, skipped_count

    def update_summary_document(
        self,
        total_saved: int,
        total_skipped: int,
        categories_processed: List[str],
        fetch_type: str,
        status: str = "success",
    ):
        """
        Updates a summary document in Firestore with the results of the fetch process.
        """
        summary_doc_id = f"summary_{self.source_id}"
        logging.info(f"Updating summary document: {summary_doc_id}")
        try:
            doc_ref = self.db.collection(self.summary_collection).document(
                summary_doc_id
            )
            doc_ref.set(
                {
                    "status": status,
                    "total_articles_saved": total_saved,
                    "total_articles_skipped": total_skipped,
                    "categories_processed": categories_processed,
                    "last_updated": datetime.now(),
                    "fetch_timestamp": datetime.now().isoformat(),
                    "fetch_type": fetch_type,
                    "source": self.source_id,
                }
            )
            logging.info(
                f"Summary updated: {total_saved} new, {total_skipped} skipped from {len(categories_processed)} categories."
            )
        except Exception as e:
            logging.error(f"Error updating summary document: {e}", exc_info=True)

    @abstractmethod
    def fetch_all(self) -> bool:
        """
        The main method to be implemented by subclasses to fetch all news.
        It should orchestrate the entire fetching process for the source.
        Should return True if new articles were saved, False otherwise.
        """
        pass

    def run(self):
        """
        Executes the fetcher's main logic and handles overall logging.
        """
        logging.info("=" * 60)
        logging.info(f"🚀 STARTING {self.source_id.upper()} FETCH PROCESS")
        logging.info("=" * 60)
        start_time = datetime.now()

        try:
            success = self.fetch_all()
            if success:
                logging.info(
                    f"🎉 SUCCESS! {self.source_id.upper()} news fetched and saved!"
                )
            else:
                logging.warning(
                    f"PROCESS FINISHED, but no new articles were saved for {self.source_id.upper()}."
                )
        except Exception as e:
            logging.critical(
                f"A critical error occurred during the fetch process: {e}",
                exc_info=True,
            )
        finally:
            duration = datetime.now() - start_time
            logging.info("🏁 PROCESS COMPLETED!")
            logging.info(f"⏱️  Total execution time: {duration}")
            logging.info("=" * 60)
