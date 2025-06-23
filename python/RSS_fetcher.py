import feedparser
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys
from dotenv import load_dotenv
import time
import traceback
import re
from urllib.parse import urljoin, urlparse
import hashlib

class VnExpressRSSFetcher:
    def __init__(self):
        # Load environment variables from .env file in project root
        env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
        load_dotenv(env_path)
        
        # Get configuration from environment variables
        self.news_collection = os.getenv('NEWS_COLLECTION', 'news_data')
        self.articles_collection = os.getenv('ARTICLES_COLLECTION', 'articles')
        
        # VnExpress RSS configuration
        self.base_rss_url = "https://vnexpress.net/rss"
        self.categories = {
            'trang-chu': 'Trang chủ',
            'the-gioi': 'Thế giới', 
            'thoi-su': 'Thời sự',
            'kinh-doanh': 'Kinh doanh',
            'startup': 'Startup',
            'giai-tri': 'Giải trí',
            'the-thao': 'Thể thao',
            'phap-luat': 'Pháp luật',
            'giao-duc': 'Giáo dục',
            'tin-moi-nhat': 'Tin mới nhất',
            'tin-noi-bat': 'Tin nổi bật',
            'suc-khoe': 'Sức khỏe',
            'doi-song': 'Đời sống',
            'du-lich': 'Du lịch',
            'so-hoa': 'Khoa học công nghệ',
            'oto-xe-may': 'Xe',
            'y-kien': 'Ý kiến',
            'tam-su': 'Tâm sự',
            'cuoi': 'Cười',
            'tin-xem-nhieu': 'Tin xem nhiều'
        }
        
        # Initialize Firebase
        service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
        if not service_account_path:
            raise ValueError("FIREBASE_SERVICE_ACCOUNT_PATH environment variable is required")
        
        # Convert relative path to absolute path
        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(os.path.dirname(__file__), '..', service_account_path)
        
        if not os.path.exists(service_account_path):
            raise FileNotFoundError(f"Service account file not found: {service_account_path}")
        
        if not firebase_admin._apps:
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()
        
        # Session for HTTP requests
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        })
    
    def generate_article_id(self, link):
        """Generate a unique article ID from the link"""
        return hashlib.md5(link.encode()).hexdigest()
    
    def extract_image_from_description(self, description):
        """Extract image URL from the description CDATA"""
        try:
            soup = BeautifulSoup(description, 'html.parser')
            img_tag = soup.find('img')
            if img_tag and img_tag.get('src'):
                return img_tag['src']
        except Exception as e:
            print(f"   ⚠️  Error extracting image: {e}")
        return None
    
    def extract_description_text(self, description):
        """Extract clean text from the description CDATA"""
        try:
            soup = BeautifulSoup(description, 'html.parser')
            # Remove image tag and get text
            for img in soup.find_all('img'):
                img.decompose()
            for br in soup.find_all('br'):
                br.replace_with(' ')
            text = soup.get_text().strip()
            return text if text else None
        except Exception as e:
            print(f"   ⚠️  Error extracting description: {e}")
        return description
    
    def scrape_full_article_content(self, url):
        """Scrape full article content from the article page"""
        try:
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Find article content (VnExpress specific selectors)
            content_selectors = [
                '.fck_detail',
                '.content_detail',
                '.Normal',
                'article .content',
                '.article-content'
            ]
            
            content = None
            for selector in content_selectors:
                content_div = soup.select_one(selector)
                if content_div:
                    # Remove ads and unwanted elements
                    for unwanted in content_div.find_all(['script', 'style', '.ads', '.advertisement']):
                        unwanted.decompose()
                    
                    content = content_div.get_text().strip()
                    break
            
            return content if content else "Content not available"
            
        except Exception as e:
            print(f"   ⚠️  Error scraping content from {url}: {e}")
            return "Content not available"
    
    def extract_keywords_from_content(self, title, description):
        """Extract basic keywords from title and description"""
        try:
            text = f"{title} {description}".lower()
            # Simple keyword extraction - you can enhance this
            common_words = ['và', 'của', 'cho', 'với', 'từ', 'trong', 'về', 'là', 'có', 'được', 'tại', 'theo', 'để', 'này', 'đã', 'sẽ', 'một', 'những', 'các', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by']
            words = re.findall(r'\b\w+\b', text)
            keywords = [word for word in words if len(word) > 3 and word not in common_words]
            return list(set(keywords))[:10]  # Return top 10 unique keywords
        except:
            return []
    
    def parse_rss_date(self, date_string):
        """Parse RSS date string to ISO format"""
        try:
            # VnExpress uses format like "Sun, 22 Jun 2025 22:07:14 +0700"
            dt = datetime.strptime(date_string, "%a, %d %b %Y %H:%M:%S %z")
            return dt.isoformat()
        except Exception as e:
            print(f"   ⚠️  Error parsing date {date_string}: {e}")
            return datetime.now().isoformat()
    
    def fetch_rss_category(self, category_slug, category_name):
        """Fetch articles from a specific RSS category"""
        try:
            if category_slug == 'trang-chu':
                rss_url = f"{self.base_rss_url}.rss"
            else:
                rss_url = f"{self.base_rss_url}/{category_slug}.rss"
            
            print(f"   📡 Fetching RSS: {rss_url}")
            
            # Parse RSS feed
            feed = feedparser.parse(rss_url)
            
            if not feed.entries:
                print(f"   📭 No entries found in {category_name}")
                return []
            
            print(f"   ✅ Found {len(feed.entries)} articles in {category_name}")
            
            articles = []
            for entry in feed.entries:
                try:
                    # Generate unique article ID
                    article_id = self.generate_article_id(entry.link)
                    
                    # Extract image from description
                    image_url = self.extract_image_from_description(entry.get('description', ''))
                    
                    # Clean description text
                    description = self.extract_description_text(entry.get('description', ''))
                    
                    # Extract keywords
                    keywords = self.extract_keywords_from_content(entry.title, description)
                    
                    # Parse publication date
                    pub_date = self.parse_rss_date(entry.get('published', ''))
                    
                    # Create article in the same format as news_fetcher.py
                    article = {
                        'article_id': article_id,
                        'title': entry.title,
                        'link': entry.link,
                        'keywords': keywords,
                        'creator': ['VnExpress'],
                        'video_url': None,
                        'description': description,
                        'content': 'CONTENT_TO_BE_SCRAPED',  # Will be scraped separately if needed
                        'pubDate': pub_date,
                        'pubDateTZ': 'Asia/Ho_Chi_Minh',
                        'image_url': image_url,
                        'source_id': 'vnexpress',
                        'source_priority': 1,
                        'source_name': 'VnExpress',
                        'source_url': 'https://vnexpress.net',
                        'source_icon': 'https://vnexpress.net/favicon.ico',
                        'language': 'vi',
                        'country': ['VN'],
                        'category': [category_name],
                        'ai_tag': 'RSS_PARSED',
                        'sentiment': 'NEUTRAL',
                        'sentiment_stats': 'NOT_ANALYZED',
                        'ai_region': 'VIETNAM',
                        'ai_org': 'VNEXPRESS',
                        'duplicate': False,
                        'created_at': datetime.now().isoformat(),
                        'updated_at': datetime.now().isoformat(),
                        'rss_category': category_slug,
                        'rss_category_name': category_name
                    }
                    
                    articles.append(article)
                    
                except Exception as e:
                    print(f"   ⚠️  Error processing article in {category_name}: {e}")
                    continue
            
            return articles
            
        except Exception as e:
            print(f"   ❌ Error fetching RSS for {category_name}: {e}")
            return []
    
    def save_articles_to_firestore(self, articles, category_name):
        """Save articles to Firestore"""
        try:
            if not articles:
                print(f"   ⚠️  No articles to save for {category_name}")
                return 0, 0
            
            print(f"   💾 Saving {len(articles)} articles from {category_name}...")
            
            articles_saved = 0
            articles_skipped = 0
            
            # Save articles in batch (Firestore batch limit is 500)
            batch_size = 500
            
            for i in range(0, len(articles), batch_size):
                batch = self.db.batch()
                batch_articles = articles[i:i + batch_size]
                batch_has_items = False
                
                for article in batch_articles:
                    article_ref = self.db.collection(self.articles_collection).document(article['article_id'])
                    
                    # Check if article already exists
                    existing_doc = article_ref.get()
                    if existing_doc.exists:
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
                    print(f"   📦 Processed batch {(i//batch_size)+1} for {category_name}")
            
            print(f"   ✅ {category_name}: Saved {articles_saved} new articles, skipped {articles_skipped} existing")
            return articles_saved, articles_skipped
            
        except Exception as e:
            print(f"   ❌ Error saving {category_name} to Firestore: {e}")
            return 0, 0
    
    def fetch_all_categories(self):
        """Fetch news from all RSS categories"""
        print("="*70)
        print("🚀 STARTING VNEXPRESS RSS FETCH PROCESS")
        print("Fetching from all RSS categories")
        print("="*70)
        
        start_time = datetime.now()
        total_articles_saved = 0
        total_articles_skipped = 0
        all_articles_sample = []
        categories_processed = 0
        
        for category_slug, category_name in self.categories.items():
            categories_processed += 1
            print(f"\n📂 Processing category {categories_processed}/{len(self.categories)}: {category_name}")
            
            try:
                # Fetch articles from this category
                articles = self.fetch_rss_category(category_slug, category_name)
                
                if articles:
                    # Save articles to Firestore
                    saved, skipped = self.save_articles_to_firestore(articles, category_name)
                    total_articles_saved += saved
                    total_articles_skipped += skipped
                    
                    # Keep sample for main document (first 50 articles)
                    for article in articles[:min(50 - len(all_articles_sample), len(articles))]:
                        if len(all_articles_sample) < 50:
                            all_articles_sample.append(article)
                
                # Add delay between categories to be respectful
                time.sleep(1)
                
            except Exception as e:
                print(f"   💥 Error processing category {category_name}: {e}")
                traceback.print_exc()
                continue
        
        # Update main document with summary
        self.update_main_document(total_articles_saved, categories_processed, all_articles_sample)
        
        end_time = datetime.now()
        duration = end_time - start_time
        
        print(f"\n🏁 PROCESS COMPLETED!")
        print(f"⏱️  Total time: {duration}")
        print(f"📂 Categories processed: {categories_processed}")
        print(f"📰 Total new articles saved: {total_articles_saved}")
        print(f"🔄 Total existing articles skipped: {total_articles_skipped}")
        print(f"💾 Articles saved to Firestore collection: {self.articles_collection}")
        
        return total_articles_saved > 0
    
    def update_main_document(self, total_articles, categories_processed, all_articles_sample=None):
        """Update the main document with current statistics"""
        try:
            # Create summary data
            summary_data = {
                'status': 'success',
                'totalResults': total_articles,
                'totalCategories': categories_processed,
                'source': 'vnexpress_rss',
                'results': all_articles_sample or []
            }
            
            # Save the summary with timestamp
            doc_ref = self.db.collection(self.news_collection).document('vnexpress_latest')
            doc_ref.set({
                'data': summary_data,
                'last_updated': datetime.now(),
                'fetch_timestamp': datetime.now().isoformat(),
                'total_articles_saved': total_articles,
                'categories_processed': categories_processed,
                'source': 'vnexpress_rss'
            })
            
            print(f"📊 Updated main document: {total_articles} articles from {categories_processed} categories")
            return True
            
        except Exception as e:
            print(f"❌ Error updating main document: {e}")
            return False
    
    def scrape_content_for_existing_articles(self, limit=10):
        """Scrape full content for articles that need it"""
        print(f"\n🔍 SCRAPING FULL CONTENT FOR ARTICLES...")
        
        try:
            # Query articles that need content scraping
            articles_ref = self.db.collection(self.articles_collection)
            query = articles_ref.where('content', '==', 'CONTENT_TO_BE_SCRAPED').limit(limit)
            docs = query.stream()
            
            updated_count = 0
            for doc in docs:
                try:
                    article_data = doc.to_dict()
                    article_url = article_data.get('link')
                    
                    if article_url:
                        print(f"   🔍 Scraping content for: {article_data.get('title', 'Unknown')[:50]}...")
                        
                        # Scrape full content
                        full_content = self.scrape_full_article_content(article_url)
                        
                        # Update the article with full content
                        doc.reference.update({
                            'content': full_content,
                            'updated_at': datetime.now().isoformat()
                        })
                        
                        updated_count += 1
                        time.sleep(2)  # Be respectful to the server
                
                except Exception as e:
                    print(f"   ⚠️  Error scraping content: {e}")
                    continue
            
            print(f"   ✅ Updated content for {updated_count} articles")
            return updated_count
            
        except Exception as e:
            print(f"   ❌ Error in content scraping: {e}")
            return 0

def main():
    try:
        fetcher = VnExpressRSSFetcher()
        
        # Fetch all RSS categories
        success = fetcher.fetch_all_categories()
        
        # Optionally scrape full content for some articles
        print(f"\n{'='*50}")
        scrape_content = input("Do you want to scrape full content for some articles? (y/n): ").lower().strip()
        if scrape_content == 'y':
            limit = int(input("How many articles to scrape content for? (default 10): ") or 10)
            fetcher.scrape_content_for_existing_articles(limit)
        
        print("\n" + "="*70)
        if success:
            print("🎉 SUCCESS! VnExpress RSS news fetched and saved!")
            print("Your Flutter app now has access to Vietnamese news articles!")
        else:
            print("💥 PROCESS FAILED! Check the errors above.")
        print("="*70)
        
    except Exception as e:
        print(f"💥 Critical Error: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    main()