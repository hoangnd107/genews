import threading
import logging
import time
import schedule
import os
from datetime import datetime
from flask import Flask

# Import the refactored fetcher classes
from api_fetcher import APIFetcher
from rss_fetcher import RSSFetcher
from selenium_fetcher import SeleniumFetcher

# Initialize Flask app
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
    """Run the scheduler continuously in a background thread."""
    setup_logging()

    # Schedule to run every 6 hours
    schedule.every(6).hours.do(run_all_fetchers_sequential)

    logging.info("🕐 Starting news fetcher scheduler...")
    logging.info("📅 Scheduled to run every 6 hours.")

    # Run once immediately at startup
    run_all_fetchers_sequential()

    # Keep the scheduler running
    while True:
        try:
            schedule.run_pending()
            time.sleep(60)  # Check every 60 seconds
        except Exception as e:
            logging.error(f"❌ Scheduler error: {e}", exc_info=True)
            time.sleep(60)


def main():
    """
    Main function to set up and start the application.
    This will start the scheduler in a background thread.
    The Flask app object 'app' will be served by Gunicorn.
    """
    setup_logging()
    logging.info("🚀 Initializing application...")

    # Start the scheduler in a background thread.
    # The thread is set as a daemon so it will be terminated when the main process exits.
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()

    logging.info("✅ Application setup complete. Ready to serve requests.")


# This block is now the single point of entry.
# When Gunicorn runs, it imports the 'app' object.
# We will start our background tasks here.
main()
