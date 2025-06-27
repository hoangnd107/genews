import threading
import logging
import time
import schedule
import os
from datetime import datetime
from flask import Flask
import argparse

from api_fetcher import main as api_main
from rss_fetcher import main as rss_main
from selenium_fetcher import main as selenium_main

app = Flask(__name__)


@app.route("/")
def health():
    return "OK", 200


def setup_logging():
    """Setup logging configuration"""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[logging.StreamHandler()],  # Only console for Cloud Run
    )


def safe_run(fetcher_func, name):
    """Safely run a fetcher function with error handling"""
    try:
        start_time = datetime.now()
        logging.info(f"[{name}] Starting fetch process...")
        fetcher_func()
        duration = datetime.now() - start_time
        logging.info(f"[{name}] Completed successfully in {duration}")
    except Exception as e:
        logging.error(f"[{name}] Error: {e}", exc_info=True)


def run_all_fetchers():
    """Run all fetchers concurrently"""
    logging.info("=" * 60)
    logging.info("🚀 STARTING SCHEDULED FETCH PROCESS")
    logging.info("=" * 60)

    start_time = datetime.now()

    threads = [
        threading.Thread(target=safe_run, args=(api_main, "API Fetcher")),
        threading.Thread(target=safe_run, args=(rss_main, "RSS Fetcher")),
        threading.Thread(target=safe_run, args=(selenium_main, "Selenium Fetcher")),
    ]

    for t in threads:
        t.start()

    for t in threads:
        t.join()

    total_duration = datetime.now() - start_time
    logging.info("🏁 ALL FETCHERS COMPLETED!")
    logging.info(f"⏱️  Total execution time: {total_duration}")
    logging.info("=" * 60)


def run_scheduler():
    """Run the scheduler continuously"""
    setup_logging()

    # Schedule to run every hour
    schedule.every().hour.do(run_all_fetchers)

    logging.info("🕐 Starting news fetcher scheduler on Cloud Run...")
    logging.info("📅 Scheduled to run every 1 hour")

    # Run once immediately
    run_all_fetchers()

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
        run_all_fetchers()


if __name__ == "__main__":
    import threading

    # Chạy Flask server ở background
    flask_thread = threading.Thread(target=lambda: app.run(host="0.0.0.0", port=8080))
    flask_thread.daemon = True
    flask_thread.start()
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--schedule", action="store_true", help="Run in schedule mode")
    args = parser.parse_args()
    main(schedule=args.schedule)
