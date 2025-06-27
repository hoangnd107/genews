import threading
import logging

from fetcher.api_fetcher import main as api_main
from fetcher.rss_fetcher import main as rss_main
from fetcher.selenium_fetcher import main as selenium_main


def safe_run(fetcher_func, name):
    try:
        fetcher_func()
    except Exception as e:
        logging.error(f"[{name}] Error: {e}", exc_info=True)


def main():
    threads = [
        threading.Thread(target=safe_run, args=(api_main, "API Fetcher")),
        threading.Thread(target=safe_run, args=(rss_main, "RSS Fetcher")),
        threading.Thread(target=safe_run, args=(selenium_main, "Selenium Fetcher")),
    ]
    for t in threads:
        t.start()
    for t in threads:
        t.join()


if __name__ == "__main__":
    main()
