import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv
import time

def monitor_firestore_progress():
    # Load environment variables
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    load_dotenv(env_path)
    
    # Initialize Firebase if not already done
    if not firebase_admin._apps:
        service_account_path = os.getenv('FIREBASE_SERVICE_ACCOUNT_PATH')
        if not os.path.isabs(service_account_path):
            service_account_path = os.path.join(os.path.dirname(__file__), '..', service_account_path)
        
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    
    db = firestore.client()
    
    print("🔍 Monitoring Firestore progress...")
    print("Press Ctrl+C to stop monitoring")
    print("="*50)
    
    try:
        while True:
            # Check main document
            doc = db.collection('news_data').document('latest').get()
            
            if doc.exists:
                data = doc.to_dict()
                total_articles = data.get('total_articles_saved', 0)
                total_pages = data.get('total_pages_processed', 0)
                last_updated = data.get('last_updated')
                
                print(f"📊 Current Progress:")
                print(f"   Articles saved: {total_articles}")
                print(f"   Pages processed: {total_pages}")
                print(f"   Last updated: {last_updated}")
                print("-" * 30)
            else:
                print("📭 No main document found yet...")
            
            # Wait 10 seconds before next check
            time.sleep(10)
            
    except KeyboardInterrupt:
        print("\n👋 Monitoring stopped")

if __name__ == "__main__":
    monitor_firestore_progress()