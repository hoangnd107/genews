import threading
import logging
import time
import schedule
import os
from datetime import datetime
from flask import Flask
import argparse

# Import the refactored fetcher classes
from api_fetcher import APIFetcher
from rss_fetcher import RSSFetcher
from selenium_fetcher import SeleniumFetcher

app = Flask(__name__)


@app.route("/")
def health():
    """Health check endpoint for Cloud Run."""
    return "OK", 200


def setup_logging():
    """Setup global logging configuration."""
    # Remove all handlers associated with the root logger object.
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - [MAIN] - %(message)s",
        handlers=[logging.StreamHandler()],
    )


def safe_run(fetcher_instance, name):
    """
    Safely run a fetcher's main method with error handling and logging.
    :param fetcher_instance: An instance of a fetcher class (e.g., RSSFetcher()).
    :param name: The name of the fetcher for logging purposes.
    """
    try:
        start_time = datetime.now()
        logging.info(f"--- Starting fetch process for: {name} ---")
        fetcher_instance.run()
        duration = datetime.now() - start_time
        logging.info(f"--- Completed fetch process for: {name} in {duration} ---")
    except Exception as e:
        logging.error(f"--- Critical error in {name}: {e} ---", exc_info=True)


def run_all_fetchers_sequential():
    """Run all fetchers sequentially: RSS -> API -> Selenium."""
    logging.info("=" * 60)
    logging.info("🚀 STARTING SCHEDULED FETCH PROCESS (SEQUENTIAL)")
    logging.info("=" * 60)
    start_time = datetime.now()

    # Instantiate fetchers and run them
    # The order is preserved here
    fetchers_to_run = [
        (RSSFetcher(), "VnExpress RSS Fetcher"),
        (APIFetcher(), "NewsData.io API Fetcher"),
        (SeleniumFetcher(), "DanTri Selenium Fetcher"),
    ]

    for instance, name in fetchers_to_run:
        safe_run(instance, name)

    total_duration = datetime.now() - start_time
    logging.info("🏁 ALL FETCHERS COMPLETED!")
    logging.info(f"⏱️  Total execution time: {total_duration}")
    logging.info("=" * 60)


def run_scheduler():
    """Run the scheduler continuously"""
    setup_logging()

    # Schedule to run every hour
    schedule.every().hour.do(run_all_fetchers_sequential)

    logging.info("🕐 Starting news fetcher scheduler on Cloud Run...")
    logging.info("📅 Scheduled to run every 1 hour")

    # Run once immediately
    run_all_fetchers_sequential()

    # Keep the scheduler running
    while True:
        try:
            schedule.run_pending()
            time.sleep(60)
        except Exception as e:
            logging.error(f"❌ Scheduler error: {e}", exc_info=True)
            time.sleep(60)


def main(schedule=False):
    """Main function"""
    if schedule:
        # Start Flask health check server in background
        import threading

        flask_thread = threading.Thread(
            target=lambda: app.run(
                host="0.0.0.0", port=int(os.environ.get("PORT", 8080))
            )
        )
        flask_thread.daemon = True
        flask_thread.start()

        # Run scheduler
        run_scheduler()
    else:
        setup_logging()
        run_all_fetchers_sequential()


if __name__ == "__main__":
    import threading

    # Chạy Flask server ở background
    flask_thread = threading.Thread(target=lambda: app.run(host="0.0.0.0", port=8080))
    flask_thread.daemon = True
    flask_thread.start()

    parser = argparse.ArgumentParser(description="News Fetcher Scheduler")
    parser.add_argument(
        "--schedule", action="store_true", help="Run in schedule mode for Cloud Run"
    )
    args = parser.parse_args()
    main(schedule=args.schedule)
