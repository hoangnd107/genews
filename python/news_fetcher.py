from newsdataapi import NewsDataApiClient
import json
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys
from dotenv import load_dotenv
import time

class NewsFetcher:
    def __init__(self):
        # Load environment variables from .env file in project root
        env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
        load_dotenv(env_path)
        
        # Get configuration from environment variables
        self.api_key = os.getenv('NEWS_API_KEY')
        self.news_collection = os.getenv('NEWS_COLLECTION', 'news_data')
        self.articles_collection = os.getenv('ARTICLES_COLLECTION', 'articles')
        
        # Validate required environment variables
        if not self.api_key:
            raise ValueError("NEWS_API_KEY environment variable is required")
        
        # Initialize NewsData API client
        self.api_client = NewsDataApiClient(apikey=self.api_key)
        
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
    
    def process_page_articles(self, articles):
        """Process articles from a single page"""
        processed_articles = []
        
        for article in articles:
            processed_article = {
                'article_id': article.get('article_id'),
                'title': article.get('title'),
                'link': article.get('link'),
                'keywords': article.get('keywords', []),
                'creator': article.get('creator', []),
                'video_url': article.get('video_url'),
                'description': article.get('description'),
                'content': article.get('content', 'ONLY AVAILABLE IN PAID PLANS'),
                'pubDate': article.get('pubDate'),
                'pubDateTZ': article.get('pubDateTZ', 'UTC'),
                'image_url': article.get('image_url'),
                'source_id': article.get('source_id'),
                'source_priority': article.get('source_priority'),
                'source_name': article.get('source_name'),
                'source_url': article.get('source_url'),
                'source_icon': article.get('source_icon'),
                'language': article.get('language'),
                'country': article.get('country', []),
                'category': article.get('category', []),
                'ai_tag': article.get('ai_tag', 'ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS'),
                'sentiment': article.get('sentiment', 'ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS'),
                'sentiment_stats': article.get('sentiment_stats', 'ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS'),
                'ai_region': article.get('ai_region', 'ONLY AVAILABLE IN CORPORATE PLANS'),
                'ai_org': article.get('ai_org', 'ONLY AVAILABLE IN CORPORATE PLANS'),
                'duplicate': article.get('duplicate', False),
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            processed_articles.append(processed_article)
        
        return processed_articles
    
    def save_page_to_firestore(self, page_articles, page_number):
        """Save a single page of articles to Firestore immediately"""
        try:
            if not page_articles:
                print(f"   ⚠️  No articles to save for page {page_number}")
                return True
            
            print(f"   💾 Saving {len(page_articles)} articles from page {page_number}...")
            
            # Save articles in batch (Firestore batch limit is 500)
            batch_size = 500
            articles_saved = 0
            
            for i in range(0, len(page_articles), batch_size):
                batch = self.db.batch()
                batch_articles = page_articles[i:i + batch_size]
                
                for article in batch_articles:
                    if article.get('article_id'):
                        article_ref = self.db.collection(self.articles_collection).document(article['article_id'])
                        batch.set(article_ref, article)
                        articles_saved += 1
                
                # Commit the batch
                batch.commit()
                
                if len(page_articles) > batch_size:
                    print(f"   📦 Saved batch {(i//batch_size)+1} from page {page_number}")
            
            print(f"   ✅ Page {page_number}: Saved {articles_saved} articles to Firestore")
            return True
            
        except Exception as e:
            print(f"   ❌ Error saving page {page_number} to Firestore: {e}")
            return False
    
    def update_main_document(self, total_articles, total_pages, all_articles_sample=None):
        """Update the main document with current statistics"""
        try:
            # Create summary data
            summary_data = {
                'status': 'success',
                'totalResults': total_articles,
                'totalPages': total_pages,
                'results': all_articles_sample or []  # Store sample or all if small dataset
            }
            
            # Save the summary with timestamp
            doc_ref = self.db.collection(self.news_collection).document('latest')
            doc_ref.set({
                'data': summary_data,
                'last_updated': datetime.now(),
                'fetch_timestamp': datetime.now().isoformat(),
                'total_articles_saved': total_articles,
                'total_pages_processed': total_pages
            })
            
            print(f"📊 Updated main document: {total_articles} articles, {total_pages} pages")
            return True
            
        except Exception as e:
            print(f"❌ Error updating main document: {e}")
            return False
    
    def fetch_and_save_all_news_incremental(self):
        """Fetch and save news page by page incrementally"""
        print("="*70)
        print("🚀 STARTING INCREMENTAL NEWS FETCH PROCESS")
        print("Using official NewsData API client library")
        print("Will fetch and save each page immediately")
        print("="*70)
        
        start_time = datetime.now()
        page = None
        page_count = 0
        total_articles_saved = 0
        all_articles_sample = []  # Keep sample for main document
        
        while True:
            page_count += 1
            print(f"\n📄 Processing page {page_count}...")
            
            try:
                # Fetch current page
                params = {'language': 'vi'}
                if page is not None:
                    params['page'] = page
                
                print(f"   📡 Fetching page {page_count} from API...")
                response = self.api_client.news_api(**params)
                
                if not response or response.get('status') != 'success':
                    print(f"   ❌ Failed to fetch page {page_count}: {response}")
                    break
                
                # Get results from this page
                results = response.get('results', [])
                if not results:
                    print(f"   📭 No more results on page {page_count}. Stopping.")
                    break
                
                print(f"   ✅ Fetched {len(results)} articles from page {page_count}")
                
                # Process articles from this page
                print(f"   🔄 Processing {len(results)} articles...")
                processed_articles = self.process_page_articles(results)
                
                # Save this page immediately to Firestore
                save_success = self.save_page_to_firestore(processed_articles, page_count)
                
                if save_success:
                    total_articles_saved += len(processed_articles)
                    
                    # Keep sample for main document (first 50 articles)
                    if len(all_articles_sample) < 50:
                        remaining_slots = 50 - len(all_articles_sample)
                        all_articles_sample.extend(processed_articles[:remaining_slots])
                    
                    print(f"   🎉 Page {page_count} completed! Running total: {total_articles_saved} articles")
                    
                    # Update main document with current progress
                    self.update_main_document(total_articles_saved, page_count, all_articles_sample)
                else:
                    print(f"   💥 Failed to save page {page_count}")
                
                # Check for next page
                next_page = response.get('nextPage')
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
                    print(f"   ⚠️  Reached maximum page limit ({page_count}). Stopping for safety.")
                    break
                    
            except Exception as e:
                print(f"   💥 Error processing page {page_count}: {e}")
                import traceback
                traceback.print_exc()
                break
        
        # Final update of main document
        print(f"\n📊 Final update of main document...")
        self.update_main_document(total_articles_saved, page_count, all_articles_sample)
        
        end_time = datetime.now()
        duration = end_time - start_time
        
        print(f"\n🏁 PROCESS COMPLETED!")
        print(f"⏱️  Total time: {duration}")
        print(f"📄 Pages processed: {page_count}")
        print(f"📰 Total articles saved: {total_articles_saved}")
        print(f"💾 Articles saved incrementally to Firestore")
        print(f"📊 Main document updated with summary")
        
        return total_articles_saved > 0

def main():
    try:
        fetcher = NewsFetcher()
        success = fetcher.fetch_and_save_all_news_incremental()
        
        print("\n" + "="*70)
        if success:
            print("🎉 SUCCESS! All news fetched and saved incrementally!")
            print("Your Flutter app now has access to all news articles!")
        else:
            print("💥 PROCESS FAILED! Check the errors above.")
        print("="*70)
        
    except Exception as e:
        print(f"💥 Critical Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()