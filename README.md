<div align="center" style="display: flex; align-items: center; justify-content: center; gap: 20px;">
   <img src="assets/icon/icon.png" alt="GeNews Logo" width="70" height="70">
   <h1 style="margin: 0;">GeNews - AI-Powered News Aggregator</h1>
</div>

## 🌟 Overview

**GeNews** is a cross-platform news app using Flutter and Google Gemini AI. News is fetched automatically from APIs, RSS, and web scraping by Python scripts running in Docker on Cloud Run, then synced to Firestore for real-time access on all devices.

The platform features a sophisticated three-tier architecture: automated Python-based fetchers running on Google Cloud Run collect news from APIs, RSS feeds, and web scraping; real-time data synchronization through Firebase Firestore; and a rich Flutter client application offering advanced search, smart bookmarking, intelligent ad-blocking, and AI-powered content summarization across Android, iOS, Web, Windows, macOS, and Linux platforms.

## 🏗️ System Architecture

![System Architecture](assets/system.png)

### Main Components

- **Data Processing Layer (Python Backend):**

  - **Multi-Source Fetchers:** Automated news collection from RSS feeds, web scraping (Selenium), and official APIs
  - **Data Pipeline:** Preprocessing, normalization, and deduplication of news articles
  - **Scheduled Processing:** Hourly automated fetching with error handling and retry mechanisms

- **Containerization & Deployment (Docker + Cloud Run):**

  - **Docker Image:** Containerized Python environment with all dependencies (Chrome, ChromeDriver, Python libraries)
  - **Google Cloud Run Service:** Serverless container platform running fetchers automatically 24/7
  - **Auto-scaling:** Automatic resource management and cost optimization
  - **Health Monitoring:** Built-in health checks and logging for service reliability

- **Cloud Infrastructure (Firebase/Google Cloud):**

  - **Firestore Database:** NoSQL storage for articles, bookmarks, and user data with real-time sync
  - **Cloud Run:** Serverless platform hosting the automated news fetching service
  - **Google Gemini AI:** Advanced AI for news summarization and content analysis (called directly from Flutter app)

- **Client Application (Flutter):**
  - **Cross-platform UI:** Single codebase for Android, iOS, Web, Windows, macOS, and Linux
  - **Real-time Updates:** Live data synchronization with Firestore backend
  - **State Management:** Provider pattern for efficient and reactive state management
  - **Advanced Features:** Search, bookmarking, sharing, ad-blocking, and customizable reading experience

## 🚀 Key Features

### 🤖 AI-Powered Features

- **Smart Summarization:** Automatic article summarization using Gemini AI, with intelligent caching for performance

### 🔍 Advanced Search & Discovery

- **Powerful Search:** Full-text search with real-time results, filter by category/source
- **Smart Filtering:** Support for Vietnamese and English content with intelligent categorization
- **Discovery Feed:** Personalized news recommendations based on reading habits

### 📚 Enhanced Bookmark Management

- **Smart Bookmarking:** Save, search, and filter bookmarks with real-time status indication
- **Cross-Device Sync:** Bookmarks synced across all devices via Firestore
- **Advanced Organization:** Category-based organization with search functionality

### 🌐 Superior Reading Experience

- **Intelligent Ad-Blocking:** Advanced ad-blocking technology with real-time counter
- **Font Size Controls:** Adjustable text size for optimal reading comfort
- **Performance Optimized:** Fast loading with smart resource management
- **Copy & Share:** Easy link copying and sharing functionality
- **Reload & Filter:** Smart reload with enhanced ad-blocking

### 🎨 Modern UI/UX

- **Clean Design:** Modern, intuitive interface with smooth animations
- **Dark/Light Mode:** Seamless theme switching with system preference support
- **Responsive Layout:** Optimized for all screen sizes and orientations
- **Accessibility:** Full accessibility support for inclusive user experience

### ⚡ Performance & Reliability

- **Realtime Updates:** Instant news updates via Firestore realtime sync
- **Offline Support:** Read saved articles without internet connection
- **Smart Caching:** Intelligent image and content caching for faster loading
- **Error Handling:** Robust error handling with user-friendly messages

## 🛠️ Technical Stack & Technologies

### Frontend & Client

- **Flutter 3.x** (Dart): Cross-platform UI framework with modern architecture
- **Provider:** Efficient state management with reactive programming
- **WebView Flutter:** Enhanced in-app browser with ad-blocking capabilities
- **Cached Network Image:** Optimized image loading with smart caching
- **Share Plus:** Native and web sharing integration
- **Shared Preferences:** Local data persistence and user settings

### Backend & Data Processing

- **Python:** Backend data collection and processing pipeline
- **Selenium:** Automated web scraping with Chrome headless browser
- **RSS Parser:** Feed processing and aggregation from news sources
- **NewsData API:** Official news API integration for reliable data sources
- **BeautifulSoup:** HTML parsing and content extraction

### Cloud Infrastructure & DevOps

- **Docker:** Containerization of Python fetchers with all dependencies
- **Google Cloud Run:** Serverless container platform for automated deployment
- **Firebase Firestore:** NoSQL database for real-time data storage and sync

### AI & Intelligence

- **Google Gemini AI:** Advanced AI for summarization

## 📁 Project Structure

```
genews/
├── lib/                           # Flutter/Dart source code
│   ├── app/                      # Application configuration
│   │   ├── config/              # Constants, enums, Firebase options
│   │   ├── themes/              # UI themes, colors, styling (reserved)
│   │   └── app.dart             # Main application widget
│   ├── features/                # Feature-based modules
│   │   ├── analysis/            # News analysis and AI summaries
│   │   │   └── views/          # UI screens
│   │   ├── bookmarks/           # Bookmark management
│   │   │   └── views/          # Bookmark screens
│   │   ├── main/                # Main screen and navigation
│   │   │   └── views/          # Main screens
│   │   ├── news/                # News listing and reading
│   │   │   ├── data/           # News models and repositories
│   │   │   ├── providers/      # News state management
│   │   │   ├── views/          # News screens
│   │   │   └── widgets/        # News-specific UI components
│   │   └── settings/            # App settings and preferences
│   │       ├── providers/      # Settings state management
│   │       └── views/          # Settings screens
│   ├── shared/                  # Shared components across features
│   │   ├── services/           # Business logic and data services
│   │   ├── utils/              # Utility functions and helpers
│   │   └── widgets/            # Reusable UI components
│   ├── main.dart               # Application entry point
│   └── genews.dart             # Main library export file
├── python/                      # Backend data processing scripts
│   ├── api_fetcher.py          # API-based news collection (NewsData API)
│   ├── rss_fetcher.py          # RSS feed processing (VnExpress)
│   ├── selenium_fetcher.py     # Web scraping with Selenium (Dantri)
│   ├── main.py                 # Main processing pipeline with scheduler
│   ├── Dockerfile              # Container configuration for Cloud Run
│   ├── .dockerignore           # Docker build exclusions
│   └── requirements.txt        # Python dependencies
├── test/                        # Testing utilities (separated from production)
│   ├── screens/                # Debug and test screens
│   ├── services/               # Test services and helpers
│   ├── widgets/                # Test widgets
│   └── README.md               # Testing documentation
├── assets/                      # Static resources
│   ├── icon/                   # App icons
│   ├── splash/                 # Splash screen assets
│   └── system.png              # System architecture diagram
├── android/ ios/ web/ ...       # Platform-specific configurations
└── ...                         # Build and configuration files
```

## 🔧 Setup & Configuration

### Prerequisites

- **Flutter SDK:** Version 3.x or later
- **Firebase Project:** Firestore database enabled
- **Google AI Studio:** Gemini API key
- **Google Cloud Platform:** Account with Cloud Run
- **Python 3.8+:** For local development and testing

### Firebase Setup

1. Create a new Firebase project
2. Enable Firestore Database with appropriate security rules
3. Download and configure `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)
4. Set up collections: `articles`, `bookmarks`, `news_data`

### Cloud Infrastructure Setup

#### Google Cloud Run Deployment

1. **Enable required APIs:**

   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   ```

2. **Deploy the news fetching service:**

   ```bash
   cd python/
   gcloud run deploy genews-fetcher \
     --source . \
     --platform managed \
     --region asia-southeast1 \
     --allow-unauthenticated \
     --memory 2Gi \
     --cpu 2 \
     --timeout 3600 \
     --max-instances 1 \
     --set-env-vars DISPLAY=:99,FIREBASE_SERVICE_ACCOUNT_PATH=serviceAccountKey.json,NEWS_API_KEY=your_api_key,NEWS_COLLECTION=news_data,ARTICLES_COLLECTION=articles \
     --project your-project-id
   ```

3. **Configure environment variables:**
   - `NEWS_API_KEY`: Your NewsData API key
   - `FIREBASE_SERVICE_ACCOUNT_PATH`: Path to Firebase service account JSON
   - `NEWS_COLLECTION`: Firestore collection for news metadata
   - `ARTICLES_COLLECTION`: Firestore collection for articles

### Local Development

#### Flutter App Setup

```bash
flutter pub get
flutter run
```

#### Python Backend Testing

```bash
cd python/
pip install -r requirements.txt
python main.py  # Run once
python main.py --schedule  # Run with hourly scheduler
```

### Gemini AI Configuration

1. Obtain API key from Google AI Studio
2. Configure in Flutter app settings
3. Set up appropriate usage limits and quotas

## 🎯 Development Guidelines

### Code Organization

- Follow feature-based architecture for scalability
- Use barrel exports for clean imports
- Separate production code (`lib/`) from test code (`test/`)
- Maintain consistent naming conventions

### Best Practices

- Implement responsive design for all screen sizes
- Use Provider pattern for state management
- Optimize images and assets for performance
- Follow Material Design 3 guidelines
- Ensure accessibility compliance

### Testing

- Unit tests for business logic
- Widget tests for UI components
- Integration tests for key user flows
- Performance testing for optimization

## 👥 Author

- **Hoang Nguyen Duy** - Full-stack Developer & AI Enthusiast

---

**Built with ❤️ using Flutter & AI Technologies**
