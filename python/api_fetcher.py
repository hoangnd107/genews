import os
import sys
import time
import logging
from datetime import datetime
from typing import List, Dict, Any

from newsdataapi import NewsDataApiClient
from base_fetcher import BaseFetcher


class APIFetcher(BaseFetcher):
    """
    Fetches news by category from NewsData API and saves to Firestore.
    Inherits common functionality from BaseFetcher.
    """

    CATEGORIES = [
        "business",
        "crime",
        "domestic",
        "education",
        "entertainment",
        "environment",
        "food",
        "health",
        "lifestyle",
        "other",
        "politics",
        "science",
        "sports",
        "technology",
        "top",
        "tourism",
        "world",
    ]

    def __init__(self):
        """Initializes the API fetcher."""
        super().__init__(source_id="newsdata_api")
        self._load_api_key()
        self.api_client = NewsDataApiClient(apikey=self.api_key)

    def _load_api_key(self):
        """Loads the NewsData.io API key from environment variables."""
        self.api_key = os.getenv("NEWS_API_KEY")
        if not self.api_key:
            raise ValueError("NEWS_API_KEY environment variable is required.")
        logging.info("NewsData.io API key loaded.")

    def _process_article(self, article: Dict[str, Any]) -> Dict[str, Any]:
        """Standardizes a single article's fields."""
        now = datetime.now().isoformat()
        # The API uses 'article_id' which is a hash of the URL, which is good.
        # We can use it directly as our document ID.
        article_id = article.get("article_id")

        # If the API doesn't provide an ID, we generate one from the link.
        if not article_id:
            article_id = self._generate_article_id(article.get("link"))

        return {
            "article_id": article_id,
            "title": article.get("title"),
            "link": article.get("link"),
            "creator": article.get("creator", []),
            "video_url": article.get("video_url"),
            "description": article.get("description"),
            "content": article.get("description"),
            "pubDate": article.get("pubDate"),
            "image_url": article.get("image_url"),
            "source_id": article.get("source_id"),
            "source_priority": article.get("source_priority"),
            "language": article.get("language"),
            "country": article.get("country", []),
            "category": article.get("category", []),
            "ai_tag": "API_FETCHED",
            "created_at": now,
            "updated_at": now,
        }

    def fetch_category_news(self, category: str) -> List[Dict[str, Any]]:
        """Fetches news for a specific category from the API."""
        logging.info(f"Fetching news for category: '{category.upper()}'")
        processed_articles = []
        try:
            # Fetching from multiple English-speaking countries for broader coverage
            response = self.api_client.news_api(
                language="en", category=category
            )

            if response.get("status") != "success":
                logging.error(
                    f"Failed to fetch category '{category}'. Response: {response}"
                )
                return []

            results = response.get("results", [])
            if not results:
                logging.info(f"No articles found for category '{category}'.")
                return []

            logging.info(f"Received {len(results)} articles for '{category}'.")
            for article in results:
                processed_articles.append(self._process_article(article))

        except Exception as e:
            logging.error(
                f"An error occurred while fetching category '{category}': {e}",
                exc_info=True,
            )
        return processed_articles

    def fetch_all(self) -> bool:
        """Fetches news for all defined categories."""
        total_saved = 0
        total_skipped = 0
        successful_categories = []

        for i, category in enumerate(self.CATEGORIES, 1):
            logging.info(
                f"--- Processing category {i}/{len(self.CATEGORIES)}: {category} ---"
            )
            articles = self.fetch_category_news(category)
            if articles:
                saved, skipped = self.save_articles_to_firestore(articles, category)
                if saved > 0:
                    successful_categories.append(category)
                total_saved += saved
                total_skipped += skipped

            # Respect API rate limits if any; add a small delay
            if i < len(self.CATEGORIES):
                time.sleep(2)

        self.update_summary_document(
            total_saved=total_saved,
            total_skipped=total_skipped,
            categories_processed=successful_categories,
            fetch_type="api_category_fetch",
        )

        # Log final results
        logging.info(
            f"Total new articles saved: {total_saved} across {len(successful_categories)} categories."
        )
        logging.info(f"Total existing articles skipped: {total_skipped}.")
        if successful_categories:
            logging.info(
                f"✅ Successful categories: {', '.join(successful_categories)}"
            )

        failed_categories = set(self.CATEGORIES) - set(successful_categories)
        if failed_categories:
            logging.warning(
                f"❌ Failed/Empty categories: {', '.join(failed_categories)}"
            )

        return total_saved > 0


def main():
    """Main function to run the fetcher."""
    fetcher = APIFetcher()
    fetcher.run()


if __name__ == "__main__":
    main()
