import threading
import logging
import time
import schedule
from datetime import datetime
from flask import Flask

from api_fetcher import APIFetcher
from rss_fetcher import RSSFetcher
from selenium_fetcher import SeleniumFetcher

app = Flask(__name__)


@app.route("/")
def health():
    return "OK", 200


def setup_logging():
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - [MAIN] - %(message)s",
        handlers=[logging.StreamHandler()],
    )


def safe_run(fetcher_instance, name):
    try:
        start_time = datetime.now()
        logging.info(f"--- Starting fetch process for: {name} ---")
        fetcher_instance.run()
        duration = datetime.now() - start_time
        logging.info(f"--- Completed fetch process for: {name} in {duration} ---")
    except Exception as e:
        logging.error(f"--- Critical error in {name}: {e} ---", exc_info=True)


def run_all_fetchers_sequential():
    logging.info("=" * 60)
    logging.info("STARTING SCHEDULED FETCH PROCESS (SEQUENTIAL)")
    logging.info("=" * 60)
    start_time = datetime.now()

    fetchers_to_run = [
        (RSSFetcher(), "VnExpress RSS Fetcher"),
        (APIFetcher(), "NewsData.io API Fetcher"),
        (SeleniumFetcher(), "DanTri Selenium Fetcher"),
    ]

    for instance, name in fetchers_to_run:
        safe_run(instance, name)

    total_duration = datetime.now() - start_time
    logging.info("ALL FETCHERS COMPLETED!")
    logging.info(f"Total execution time: {total_duration}")
    logging.info("=" * 60)


def run_scheduler():
    setup_logging()

    schedule.every(6).hours.do(run_all_fetchers_sequential)

    logging.info("Starting news fetcher scheduler...")
    logging.info("Scheduled to run every 6 hours.")

    run_all_fetchers_sequential()

    while True:
        try:
            schedule.run_pending()
            time.sleep(60)
        except Exception as e:
            logging.error(f"Scheduler error: {e}", exc_info=True)
            time.sleep(60)


def main():
    setup_logging()
    logging.info("Initializing application...")

    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()

    logging.info("Application setup complete. Ready to serve requests.")


main()

# Test local execution
# if __name__ == "__main__":
#     main()
#     app.run(host="0.0.0.0", port=5000, debug=True)
