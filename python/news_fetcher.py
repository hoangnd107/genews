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


class NewsFetcher:
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

        # CSV writer for incremental saving
        self.csv_file = None
        self.csv_writer = None
        self.csv_filepath = None

    def process_page_articles(self, articles):
        """Process articles from a single page"""
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

    def initialize_csv_file(self):
        """Initialize CSV file for incremental writing"""
        try:
            if not self.save_to_csv:
                return

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"news_incremental_{timestamp}.csv"
            self.csv_filepath = os.path.join(self.csv_output_dir, filename)

            print(f"📄 Initializing CSV file: {filename}")

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
                "page_number",
            ]

            self.csv_file = open(self.csv_filepath, "w", newline="", encoding="utf-8")
            self.csv_writer = csv.DictWriter(self.csv_file, fieldnames=headers)
            self.csv_writer.writeheader()

            print(f"✅ CSV file initialized: {self.csv_filepath}")

        except Exception as e:
            print(f"❌ Error initializing CSV file: {e}")

    def save_page_to_csv(self, page_articles, page_number):
        """Save page articles to CSV file"""
        try:
            if not self.save_to_csv or not self.csv_writer:
                return 0

            articles_written = 0

            for article in page_articles:
                # Prepare row data
                row = {}
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

                for header in headers:
                    value = article.get(header, "")

                    # Convert lists to comma-separated strings
                    if isinstance(value, list):
                        value = ", ".join(str(item) for item in value)

                    row[header] = value

                # Add page number
                row["page_number"] = page_number

                self.csv_writer.writerow(row)
                articles_written += 1

            # Flush to ensure data is written
            self.csv_file.flush()

            print(
                f"   📄 Saved {articles_written} articles to CSV from page {page_number}"
            )
            return articles_written

        except Exception as e:
            print(f"   ❌ Error saving page {page_number} to CSV: {e}")
            return 0

    def close_csv_file(self):
        """Close CSV file"""
        try:
            if self.csv_file:
                self.csv_file.close()
                print(f"📄 CSV file closed: {self.csv_filepath}")

        except Exception as e:
            print(f"❌ Error closing CSV file: {e}")

    def save_summary_to_csv(self, total_articles, total_pages, duration):
        """Save summary report to CSV"""
        try:
            if not self.save_to_csv:
                return

            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"news_incremental_summary_{timestamp}.csv"
            filepath = os.path.join(self.csv_output_dir, filename)

            print(f"📊 Saving summary report to CSV: {filename}")

            headers = ["metric", "value", "timestamp", "duration"]

            with open(filepath, "w", newline="", encoding="utf-8") as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=headers)
                writer.writeheader()

                # Write summary metrics
                summary_data = [
                    {
                        "metric": "total_articles_saved",
                        "value": total_articles,
                        "timestamp": datetime.now().isoformat(),
                        "duration": str(duration),
                    },
                    {
                        "metric": "total_pages_processed",
                        "value": total_pages,
                        "timestamp": datetime.now().isoformat(),
                        "duration": str(duration),
                    },
                    {
                        "metric": "fetch_type",
                        "value": "incremental",
                        "timestamp": datetime.now().isoformat(),
                        "duration": str(duration),
                    },
                    {
                        "metric": "avg_articles_per_page",
                        "value": (
                            round(total_articles / total_pages, 2)
                            if total_pages > 0
                            else 0
                        ),
                        "timestamp": datetime.now().isoformat(),
                        "duration": str(duration),
                    },
                ]

                for row in summary_data:
                    writer.writerow(row)

            print(f"✅ Summary CSV saved: {filepath}")

        except Exception as e:
            print(f"❌ Error saving summary CSV: {e}")

    def save_page_to_firestore(self, page_articles, page_number):
        """Save a single page of articles to Firestore immediately"""
        try:
            if not page_articles:
                print(f"   ⚠️  No articles to save for page {page_number}")
                return True

            print(
                f"   💾 Saving {len(page_articles)} articles from page {page_number}..."
            )

            # Save articles in batch (Firestore batch limit is 500)
            batch_size = 500
            articles_saved = 0
            articles_skipped = 0

            for i in range(0, len(page_articles), batch_size):
                batch = self.db.batch()
                batch_articles = page_articles[i : i + batch_size]
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

                if len(page_articles) > batch_size:
                    print(
                        f"   📦 Processed batch {(i//batch_size)+1} from page {page_number}"
                    )

            # Save to CSV
            if self.save_to_csv:
                self.save_page_to_csv(page_articles, page_number)

            print(
                f"   ✅ Page {page_number}: Saved {articles_saved} new articles, skipped {articles_skipped} existing"
            )
            return True

        except Exception as e:
            print(f"   ❌ Error saving page {page_number} to Firestore: {e}")
            return False

    def update_main_document(
        self, total_articles, total_pages, all_articles_sample=None
    ):
        """Update the main document with current statistics"""
        try:
            # Create summary data
            summary_data = {
                "status": "success",
                "totalResults": total_articles,
                "totalPages": total_pages,
                "results": all_articles_sample
                or [],  # Store sample or all if small dataset
            }

            # Save the summary with timestamp
            doc_ref = self.db.collection(self.news_collection).document("latest")
            doc_ref.set(
                {
                    "data": summary_data,
                    "last_updated": datetime.now(),
                    "fetch_timestamp": datetime.now().isoformat(),
                    "total_articles_saved": total_articles,
                    "total_pages_processed": total_pages,
                }
            )

            print(
                f"📊 Updated main document: {total_articles} articles, {total_pages} pages"
            )
            return True

        except Exception as e:
            print(f"❌ Error updating main document: {e}")
            return False

    def fetch_and_save_all_news_incremental(self):
        """Fetch and save news page by page incrementally"""
        print("=" * 70)
        print("🚀 STARTING INCREMENTAL NEWS FETCH PROCESS")
        print("Using official NewsData API client library")
        print("Will fetch and save each page immediately")
        if self.save_to_csv:
            print(f"📄 CSV files will be saved to: {self.csv_output_dir}")
        print("=" * 70)

        # Initialize CSV file for incremental writing
        if self.save_to_csv:
            self.initialize_csv_file()

        start_time = datetime.now()
        page = None
        page_count = 0
        total_articles_saved = 0
        total_articles_skipped = 0
        all_articles_sample = []  # Keep sample for main document

        try:
            while True:
                page_count += 1
                print(f"\n📄 Processing page {page_count}...")

                try:
                    # Fetch current page
                    params = {"language": "vi"}
                    if page is not None:
                        params["page"] = page

                    print(f"   📡 Fetching page {page_count} from API...")
                    response = self.api_client.news_api(**params)

                    if not response or response.get("status") != "success":
                        print(f"   ❌ Failed to fetch page {page_count}: {response}")
                        break

                    # Get results from this page
                    results = response.get("results", [])
                    if not results:
                        print(f"   📭 No more results on page {page_count}. Stopping.")
                        break

                    print(
                        f"   ✅ Fetched {len(results)} articles from page {page_count}"
                    )

                    # Process articles from this page
                    print(f"   🔄 Processing {len(results)} articles...")
                    processed_articles = self.process_page_articles(results)

                    # Save this page immediately to Firestore and CSV
                    save_success = self.save_page_to_firestore(
                        processed_articles, page_count
                    )

                    if save_success:
                        # Count only new articles for sample
                        new_articles_count = 0
                        for article in processed_articles:
                            if article.get("article_id"):
                                article_ref = self.db.collection(
                                    self.articles_collection
                                ).document(article["article_id"])
                                if not article_ref.get().exists:
                                    new_articles_count += 1

                                    # Keep sample for main document (first 50 articles)
                                    if len(all_articles_sample) < 50:
                                        all_articles_sample.append(article)

                        total_articles_saved += new_articles_count
                        total_articles_skipped += (
                            len(processed_articles) - new_articles_count
                        )

                        print(
                            f"   🎉 Page {page_count} completed! Running total: {total_articles_saved} new, {total_articles_skipped} skipped"
                        )

                        # Update main document with current progress
                        self.update_main_document(
                            total_articles_saved, page_count, all_articles_sample
                        )
                    else:
                        print(f"   💥 Failed to save page {page_count}")

                    # Check for next page
                    next_page = response.get("nextPage")
                    if next_page:
                        page = next_page
                        print(f"   ➡️  Next page token: {next_page}")
                    else:
                        print(f"   🏁 No more pages available. Completed fetching.")
                        break

                    # Add delay to respect rate limits
                    print(f"   ⏳ Waiting 2 seconds before next page...")
                    time.sleep(2)

                    # Safety check to avoid infinite loop
                    if page_count >= 1000:
                        print(
                            f"   ⚠️  Reached maximum page limit ({page_count}). Stopping for safety."
                        )
                        break

                except Exception as e:
                    print(f"   💥 Error processing page {page_count}: {e}")
                    traceback.print_exc()
                    break

        finally:
            # Close CSV file
            if self.save_to_csv:
                self.close_csv_file()

        # Final update of main document
        print(f"\n📊 Final update of main document...")
        self.update_main_document(total_articles_saved, page_count, all_articles_sample)

        end_time = datetime.now()
        duration = end_time - start_time

        # Save summary to CSV
        if self.save_to_csv:
            self.save_summary_to_csv(total_articles_saved, page_count, duration)

        print(f"\n🏁 PROCESS COMPLETED!")
        print("=" * 70)
        print(f"⏱️  Total time: {duration}")
        print(f"📄 Pages processed: {page_count}")
        print(f"📰 Total new articles saved: {total_articles_saved}")
        print(f"🔄 Total existing articles skipped: {total_articles_skipped}")
        print(f"💾 Articles saved incrementally to Firestore")
        print(f"📊 Main document updated with summary")
        if self.save_to_csv:
            print(f"📄 CSV files saved to: {self.csv_output_dir}")

        return total_articles_saved > 0


def main():
    try:
        fetcher = NewsFetcher()
        success = fetcher.fetch_and_save_all_news_incremental()

        print("\n" + "=" * 70)
        if success:
            print("🎉 SUCCESS! All news fetched and saved incrementally!")
            print("Your Flutter app now has access to all news articles!")
        else:
            print("💥 PROCESS FAILED! Check the errors above.")
        print("=" * 70)

    except Exception as e:
        print(f"💥 Critical Error: {e}")
        traceback.print_exc()


if __name__ == "__main__":
    main()
