import feedparser
import requests
import logging
import time
import argparse
from bs4 import BeautifulSoup
from datetime import datetime
from typing import List, Dict, Any, Optional

from base_fetcher import BaseFetcher

VNEXPRESS_CONFIG = {
    "source_id": "vnexpress",
    "source_name": "VnExpress",
    "base_rss_url": "https://vnexpress.net/rss",
    "base_url": "https://vnexpress.net",
    "favicon": "https://vnexpress.net/favicon.ico",
    "language": "vi",
    "country": ["VN"],
    "creator": ["VnExpress"],
    "content_selectors": [
        ".fck_detail",
        ".content_detail",
        ".Normal",
        "article .content",
        ".article-content",
    ],
    "categories": {
        "trang-chu": "top",
        "the-gioi": "world",
        "thoi-su": "politics",
        "kinh-doanh": "business",
        "startup": "startup",
        "giai-tri": "entertainment",
        "the-thao": "sports",
        "phap-luat": "law",
        "giao-duc": "education",
        "tin-moi-nhat": "top",
        "tin-noi-bat": "top",
        "suc-khoe": "health",
        "doi-song": "lifestyle",
        "du-lich": "tourism",
        "so-hoa": "technology",
        "oto-xe-may": "auto",
        "y-kien": "opinion",
        "tam-su": "confession",
        "cuoi": "funny",
        "tin-xem-nhieu": "most-viewed",
    },
}


class RSSFetcher(BaseFetcher):

    def __init__(self):
        super().__init__(source_id=VNEXPRESS_CONFIG["source_id"])
        self.config = VNEXPRESS_CONFIG
        self._init_session()

    def _init_session(self):
        self.session = requests.Session()
        self.session.headers.update(
            {
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
            }
        )
        logging.info("Requests session initialized.")

    def _extract_image_from_description(self, description: str) -> Optional[str]:
        try:
            soup = BeautifulSoup(description, "html.parser")
            img_tag = soup.find("img")
            return img_tag["src"] if img_tag and img_tag.get("src") else None
        except Exception:
            return None

    def _extract_description_text(self, description: str) -> str:
        try:
            soup = BeautifulSoup(description, "html.parser")
            for tag in soup.find_all(["img", "br"]):
                tag.decompose()
            return (
                soup.get_text(separator=" ", strip=True) or "No description available."
            )
        except Exception as e:
            logging.warning(f"Could not extract clean description text: {e}")
            return description

    def _parse_rss_date(self, date_string: str) -> str:
        try:
            # Format: "Sun, 22 Jun 2025 22:07:14 +0700"
            dt = datetime.strptime(date_string, "%a, %d %b %Y %H:%M:%S %z")
            return dt.isoformat()
        except (ValueError, TypeError):
            logging.warning(
                f"Could not parse date '{date_string}', using current time."
            )
            return datetime.now().isoformat()

    def _parse_rss_entry(
        self, entry: Dict[str, Any], category_name: str
    ) -> Optional[Dict[str, Any]]:
        link = entry.get("link")
        if not link:
            logging.warning(f"Skipping entry with no link: {entry.get('title')}")
            return None

        title = entry.get("title", "No Title")
        description_html = entry.get("description", "")
        description_text = self._extract_description_text(description_html)
        now = datetime.now().isoformat()

        return {
            "article_id": self._generate_article_id(link),
            "title": title,
            "link": link,
            "creator": self.config["creator"],
            "video_url": None,
            "description": description_text,
            "content": description_text,
            "pubDate": self._parse_rss_date(entry.get("published")),
            "image_url": self._extract_image_from_description(description_html),
            "source_id": self.config["source_id"],
            "source_name": self.config["source_name"],
            "source_url": self.config["base_url"],
            "source_icon": self.config["favicon"],
            "language": self.config["language"],
            "country": self.config["country"],
            "category": [category_name],
            "ai_tag": "RSS_PARSED",
            "created_at": now,
            "updated_at": now,
        }

    def fetch_rss_category(
        self, category_slug: str, category_name: str
    ) -> List[Dict[str, Any]]:
        rss_url = f"{self.config['base_rss_url']}/{category_slug}.rss"
        if category_slug == "trang-chu":
            rss_url = f"{self.config['base_url']}/rss/tin-moi-nhat.rss"

        logging.info(f"Fetching RSS from: {rss_url}")
        feed = feedparser.parse(rss_url)

        if feed.bozo:
            logging.warning(
                f"Feed for '{category_name}' is ill-formed. Reason: {feed.bozo_exception}"
            )

        if not feed.entries:
            logging.info(f"No entries found in '{category_name}' feed.")
            return []

        logging.info(f"Found {len(feed.entries)} articles in '{category_name}'.")

        articles = []
        for entry in feed.entries:
            try:
                parsed_article = self._parse_rss_entry(entry, category_name)
                if parsed_article:
                    articles.append(parsed_article)
            except Exception as e:
                logging.error(
                    f"Error processing an article in '{category_name}': {e}",
                    exc_info=True,
                )
        return articles

    def fetch_all(self) -> bool:
        total_saved = 0
        total_skipped = 0
        successful_categories = []

        categories = self.config["categories"]
        for i, (slug, name) in enumerate(categories.items(), 1):
            logging.info(f"--- Processing category {i}/{len(categories)}: {name} ---")
            try:
                articles = self.fetch_rss_category(slug, name)
                if articles:
                    saved, skipped = self.save_articles_to_firestore(articles, name)
                    if saved > 0:
                        successful_categories.append(name)
                    total_saved += saved
                    total_skipped += skipped
                time.sleep(1)
            except Exception as e:
                logging.error(
                    f"Failed to process category '{name}': {e}", exc_info=True
                )

        self.update_summary_document(
            total_saved=total_saved,
            total_skipped=total_skipped,
            categories_processed=successful_categories,
            fetch_type="rss_feed",
        )
        return total_saved > 0

    def scrape_full_article_content(self, url: str) -> str:
        try:
            response = self.session.get(url, timeout=15)
            response.raise_for_status()
            soup = BeautifulSoup(response.content, "html.parser")

            for selector in self.config["content_selectors"]:
                content_div = soup.select_one(selector)
                if content_div:
                    for unwanted in content_div.find_all(
                        ["script", "style", ".ads", "figure"]
                    ):
                        unwanted.decompose()
                    return content_div.get_text(separator="\n", strip=True)

            return "Content not found with available selectors."
        except requests.exceptions.RequestException as e:
            logging.error(f"HTTP error scraping {url}: {e}")
            return "Content scraping failed due to network error."
        except Exception as e:
            logging.error(f"Error scraping content from {url}: {e}")
            return "Content scraping failed."

    def scrape_content_for_existing_articles(self, limit: int = 10):
        logging.info(f"Starting to scrape full content for up to {limit} articles.")
        try:
            docs = (
                self.db.collection(self.articles_collection)
                .where("content", "==", "CONTENT_TO_BE_SCRAPED")
                .where("source_id", "==", self.source_id)
                .limit(limit)
                .stream()
            )

            updated_count = 0
            for doc in docs:
                article = doc.to_dict()
                url = article.get("link")
                if not url:
                    continue

                logging.info(f"Scraping: {article.get('title', doc.id)[:60]}...")
                full_content = self.scrape_full_article_content(url)

                if full_content and "Content scraping failed" not in full_content:
                    doc.reference.update(
                        {
                            "content": full_content,
                            "updated_at": datetime.now().isoformat(),
                        }
                    )
                    updated_count += 1
                    time.sleep(2)  # Be respectful

            logging.info(f"Updated content for {updated_count} articles.")
        except Exception as e:
            logging.error(
                "An error occurred during content scraping batch.", exc_info=True
            )


def main():
    parser = argparse.ArgumentParser(description="Fetch news from VnExpress RSS feeds.")
    parser.add_argument(
        "--scrape-content",
        nargs="?",
        const=10,
        type=int,
        metavar="LIMIT",
        help="Optionally scrape full content for articles. Provide a limit (default: 10).",
    )

    args = parser.parse_args()

    fetcher = RSSFetcher()
    fetcher.run()

    if args.scrape_content is not None:
        fetcher.scrape_content_for_existing_articles(limit=args.scrape_content)


if __name__ == "__main__":
    main()
