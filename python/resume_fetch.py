import firebase_admin
from firebase_admin import credentials, firestore
from newsdataapi import NewsDataApiClient
import os
from dotenv import load_dotenv

def check_last_saved_article():
    """Check what was the last article saved to determine resume point"""
    # Load environment variables
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    load_dotenv(env_path)
    
    # Initialize Firebase
    if not firebase_admin._apps:
        service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(os.path.dirname(__file__), '..', service_account_path)
        
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    try:
        # Get main document to see progress
        doc = db.collection('news_data').document('latest').get()
        
        if doc.exists:
            data = doc.to_dict()
            total_articles = data.get('total_articles_saved', 0)
            total_pages = data.get('total_pages_processed', 0)
            
            print(f"📊 Current status:")
            print(f"   Articles saved: {total_articles}")
            print(f"   Pages processed: {total_pages}")
            
            # Check some recent articles
            articles_ref = db.collection('articles')
            recent_articles = list(articles_ref.order_by('created_at', direction=firestore.Query.DESCENDING).limit(5).stream())
            
            print(f"\n📰 Last 5 articles saved:")
            for i, article_doc in enumerate(recent_articles):
                article = article_doc.to_dict()
                print(f"   {i+1}. {article.get('title', 'No title')[:50]}...")
                print(f"      Created: {article.get('created_at')}")
            
            return total_articles, total_pages
        else:
            print("📭 No previous data found. Starting fresh.")
            return 0, 0
            
    except Exception as e:
        print(f"❌ Error checking progress: {e}")
        return 0, 0

if __name__ == "__main__":
    check_last_saved_article()