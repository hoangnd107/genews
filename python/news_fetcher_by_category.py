from newsdataapi import NewsDataApiClient
import json
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys
from dotenv import load_dotenv
import time
import traceback
import csv


class NewsFetcherByCategory:
    def __init__(self):
        # Load environment variables from .env file in project root
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        load_dotenv(env_path)

        # Get configuration from environment variables
        self.api_key = os.getenv("NEWS_API_KEY")
        self.news_collection = os.getenv("NEWS_COLLECTION", "news_data")
        self.articles_collection = os.getenv("ARTICLES_COLLECTION", "articles")

        # CSV configuration
        self.csv_output_dir = os.getenv(
            "CSV_OUTPUT_DIR",
            os.path.join(os.path.dirname(__file__), "..", "csv_output"),
        )
        self.save_to_csv = os.getenv("SAVE_TO_CSV", "true").lower() == "true"

        # Create CSV output directory if it doesn't exist
        if self.save_to_csv:
            os.makedirs(self.csv_output_dir, exist_ok=True)

        # Validate required environment variables
        if not self.api_key:
            raise ValueError("NEWS_API_KEY environment variable is required")

        # Initialize NewsData API client
        self.api_client = NewsDataApiClient(apikey=self.api_key)

        # Categories to fetch
        self.categories = [
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

        # Initialize Firebase
        service_account_path = os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")
        if not service_account_path:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_PATH environment variable is required"
            )

        # Convert relative path to absolute path
        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(
                os.path.dirname(__file__), "..", service_account_path
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
        """Process articles (same as original news_fetcher.py)"""
        processed_articles = []

        for article in articles:
            processed_article = {
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
                    "sentiment", "ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS"
                ),
                "sentiment_stats": article.get(
                    "sentiment_stats",
                    "ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS",
                ),
                "ai_region": article.get(
                    "ai_region", "ONLY AVAILABLE IN CORPORATE PLANS"
                ),
                "ai_org": article.get("ai_org", "ONLY AVAILABLE IN CORPORATE PLANS"),
                "duplicate": article.get("duplicate", False),
                "created_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
            }
            processed_articles.append(processed_article)

        return processed_articles

    def save_articles_to_firestore(self, articles, category):
        """Save articles to Firestore (same collection as original)"""
        try:
            if not articles:
                print(f"   ⚠️  No articles to save for category '{category}'")
                return 0

            print(
                f"   💾 Saving {len(articles)} articles from category '{category}'..."
            )

            # Save articles in batch (Firestore batch limit is 500)
            batch_size = 500
            articles_saved = 0
            articles_skipped = 0

            for i in range(0, len(articles), batch_size):
                batch = self.db.batch()
                batch_articles = articles[i : i + batch_size]
                batch_has_items = False

                for article in batch_articles:
                    if article.get("article_id"):
                        article_ref = self.db.collection(
                            self.articles_collection
                        ).document(article["article_id"])

                        # Check if article already exists
                        existing_doc = article_ref.get()
                        if existing_doc.exists:
                            # Article already exists, skip it
                            articles_skipped += 1
                            continue

                        # Article doesn't exist, add to batch
                        batch.set(article_ref, article)
                        articles_saved += 1
                        batch_has_items = True

                # Only commit if there are documents to save
                if batch_has_items:
                    batch.commit()

                if len(articles) > batch_size:
                    print(
                        f"   📦 Processed batch {(i//batch_size)+1} for category '{category}'"
                    )

            print(
                f"   ✅ Category '{category}': Saved {articles_saved} new articles, skipped {articles_skipped} existing"
            )
            return articles_saved

        except Exception as e:
            print(f"   ❌ Error saving category '{category}' to Firestore: {e}")
            return 0

    def save_articles_to_csv(self, articles, category):
        """Save articles to CSV file"""
        try:
            if not articles or not self.save_to_csv:
                return 0

            # Create filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"news_{category}_{timestamp}.csv"
            filepath = os.path.join(self.csv_output_dir, filename)

            print(f"   📄 Saving {len(articles)} articles to CSV: {filename}")

            # Define CSV headers
            headers = [
                "article_id",
                "title",
                "link",
                "description",
                "content",
                "pubDate",
                "pubDateTZ",
                "image_url",
                "source_id",
                "source_name",
                "source_url",
                "language",
                "category",
                "keywords",
                "creator",
                "country",
                "source_priority",
                "source_icon",
                "video_url",
                "ai_tag",
                "sentiment",
                "duplicate",
                "created_at",
                "updated_at",
            ]

            with open(filepath, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=headers)
                writer.writeheader()

                for article in articles:
                    # Prepare row data
                    row = {}
                    for header in headers:
                        value = article.get(header, "")

                        # Convert lists to comma-separated strings
                        if isinstance(value, list):
                            value = ", ".join(str(item) for item in value)

                        row[header] = value

                    writer.writerow(row)

            print(f"   ✅ CSV saved: {filepath}")
            return len(articles)

        except Exception as e:
            print(f"   ❌ Error saving CSV for category '{category}': {e}")
            return 0

    def save_summary_to_csv(
        self, total_articles, successful_categories, failed_categories, duration
    ):
        """Save summary report to CSV"""
        try:
            if not self.save_to_csv:
                return

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"news_summary_{timestamp}.csv"
            filepath = os.path.join(self.csv_output_dir, filename)

            print(f"📊 Saving summary report to CSV: {filename}")

            headers = ["category", "status", "timestamp", "total_duration"]

            with open(filepath, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=headers)
                writer.writeheader()

                # Write successful categories
                for category in successful_categories:
                    writer.writerow(
                        {
                            "category": category,
                            "status": "success",
                            "timestamp": datetime.now().isoformat(),
                            "total_duration": str(duration),
                        }
                    )

                # Write failed categories
                for category in failed_categories:
                    writer.writerow(
                        {
                            "category": category,
                            "status": "failed",
                            "timestamp": datetime.now().isoformat(),
                            "total_duration": str(duration),
                        }
                    )

                # Write summary row
                writer.writerow(
                    {
                        "category": "SUMMARY",
                        "status": f"{len(successful_categories)} success, {len(failed_categories)} failed",
                        "timestamp": datetime.now().isoformat(),
                        "total_duration": str(duration),
                    }
                )

            print(f"✅ Summary CSV saved: {filepath}")

        except Exception as e:
            print(f"❌ Error saving summary CSV: {e}")

    def fetch_category_news(self, category):
        """Fetch and save news for a specific category"""
        print(f"\n🏷️  PROCESSING CATEGORY: '{category.upper()}'")

        try:
            # Fetch news for this category
            print(f"   📡 Fetching articles for category '{category}'...")
            response = self.api_client.news_api(language="en", category=category)

            if not response or response.get("status") != "success":
                print(f"   ❌ Failed to fetch category '{category}': {response}")
                return 0

            # Get results
            results = response.get("results", [])

            if not results:
                print(f"   📭 No articles found for category '{category}'")
                return 0

            print(f"   ✅ Fetched {len(results)} articles for category '{category}'")

            # Process articles
            print(f"   🔄 Processing {len(results)} articles...")
            processed_articles = self.process_articles(results)

            # Save to Firestore
            articles_saved = self.save_articles_to_firestore(
                processed_articles, category
            )

            # Save to CSV
            if self.save_to_csv:
                self.save_articles_to_csv(processed_articles, category)

            print(
                f"   🎉 Category '{category}' completed: {articles_saved} new articles saved!"
            )

            return articles_saved

        except Exception as e:
            print(f"   💥 Error processing category '{category}': {e}")
            traceback.print_exc()
            return 0

    def update_summary_document(
        self, total_articles, categories_processed, total_skipped
    ):
        """Update summary document (similar to original)"""
        try:
            # Save the summary with timestamp
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

            print(
                f"📊 Updated summary document: {total_articles} new articles, {total_skipped} skipped from {len(categories_processed)} categories"
            )
            return True

        except Exception as e:
            print(f"❌ Error updating summary document: {e}")
            return False

    def fetch_all_categories(self):
        """Fetch news for all categories"""
        print("=" * 70)
        print("🚀 STARTING CATEGORY-BASED NEWS FETCH PROCESS")
        print("Using official NewsData API client library")
        print("Will fetch and save each category immediately")
        if self.save_to_csv:
            print(f"📄 CSV files will be saved to: {self.csv_output_dir}")
        print("=" * 70)

        start_time = datetime.now()
        total_articles_saved = 0
        total_articles_skipped = 0
        successful_categories = []
        failed_categories = []

        for i, category in enumerate(self.categories, 1):
            print(f"\n📋 Processing category {i}/{len(self.categories)}")

            # Store initial count
            initial_saved = total_articles_saved

            articles_saved = self.fetch_category_news(category)

            if articles_saved > 0:
                successful_categories.append(category)
                total_articles_saved += articles_saved
            else:
                failed_categories.append(category)

            # Add delay between categories to respect rate limits
            if i < len(self.categories):
                print(f"   ⏳ Waiting 3 seconds before next category...")
                time.sleep(3)

        end_time = datetime.now()
        duration = end_time - start_time

        # Update summary
        self.update_summary_document(
            total_articles_saved, successful_categories, total_articles_skipped
        )

        # Save summary to CSV
        if self.save_to_csv:
            self.save_summary_to_csv(
                total_articles_saved, successful_categories, failed_categories, duration
            )

        print(f"\n🏁 PROCESS COMPLETED!")
        print("=" * 70)
        print(f"⏱️  Total time: {duration}")
        print(
            f"🏷️  Categories processed: {len(successful_categories)}/{len(self.categories)}"
        )
        print(f"📰 Total new articles saved: {total_articles_saved}")
        print(f"🔄 Total existing articles skipped: {total_articles_skipped}")
        print(f"💾 All articles saved to same collection: {self.articles_collection}")
        if self.save_to_csv:
            print(f"📄 CSV files saved to: {self.csv_output_dir}")

        if successful_categories:
            print(f"✅ Successful categories: {', '.join(successful_categories)}")
        if failed_categories:
            print(f"❌ Failed categories: {', '.join(failed_categories)}")

        return total_articles_saved > 0


def main():
    try:
        fetcher = NewsFetcherByCategory()
        success = fetcher.fetch_all_categories()

        print("\n" + "=" * 70)
        if success:
            print("🎉 SUCCESS! All categories fetched and saved!")
            print("Your Flutter app can now access all articles from one collection!")
        else:
            print("💥 PROCESS FAILED! Check the errors above.")
        print("=" * 70)

    except Exception as e:
        print(f"💥 Critical Error: {e}")
        traceback.print_exc()


if __name__ == "__main__":
    main()
