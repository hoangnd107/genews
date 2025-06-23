<div align="center" style="display: flex; align-items: center; justify-content: center; gap: 20px;">
   <img src="assets/icon/icon.png" alt="GeNews Logo" width="70" height="70">
   <h1 style="margin: 0;">GeNews - AI-Powered News Aggregator</h1>
</div>

## 🌟 Overview

**GeNews** is an intelligent, multi-platform news aggregator and summarizer built with Flutter and powered by Google's Gemini AI. The application provides users with AI-driven news summaries delivery across mobile platforms.

## 🏗️ System Architecture

![System Architecture](assets/system.png)

### Architecture Overview

The GeNews system follows a microservices architecture with clear separation of concerns:

#### **Data Processing Layer (Python Backend)**

- **Web Scraping**: Selenium-based automated content extraction
- **RSS Integration**: Real-time RSS feed processing
- **API Aggregation**: Integration with official news APIs
- **Data Pipeline**: Automated content processing and storage

#### **Cloud Infrastructure (Google Cloud Platform)**

- **Firestore Database**: NoSQL document storage for articles and user data
- **Real-time Synchronization**: Instant updates across all client devices
- **Scalable Storage**: Efficient handling of large-scale news data

#### **AI Processing (Google Gemini)**

- **Summary Generation**: Intelligent article summarization

#### **Client Application (Flutter)**

- **Cross-Platform UI**: Single codebase for all platforms
- **State Management**: Provider pattern for reactive UI updates
- **Real-time Updates**: Live data synchronization with backend

## 🚀 Key Features

### 🤖 AI-Powered Intelligence

- **Smart Summaries**: Transforms lengthy articles into concise, digestible content using Gemini AI

### 📱 Multi-Platform Support

- **Cross-Platform**: Native performance on iOS, Android, Web, Windows, macOS, and Linux

### 🎨 User Experience

- **Dark/Light Theme**: Automatic theme switching with system preference support
- **Customizable Font Sizes**: Accessibility-focused reading experience
- **Advanced Search**: Intelligent search with category filtering
- **Bookmark Management**: Save and organize articles for later reading
- **Social Sharing**: One-click sharing across social media platforms

### 🌐 Content Aggregation

- **Multiple Sources**: RSS feeds, web scraping, and official APIs
- **Real-time Updates**: Live news feed with refresh capabilities
- **Vietnamese Language**: Localized content and interface
- **Category Management**: Organized news by topics (Politics, Business, Sports, etc.)

## 🛠️ Tech Stack

### Frontend

- **Flutter 3.x**: Cross-platform UI framework
- **Dart**: Primary programming language
- **Provider**: State management solution
- **WebView**: In-app web content rendering
- **Cached Network Image**: Optimized image loading

### Backend & Data Processing

- **Python**: Data processing and web scraping
- **Selenium**: Automated web content extraction
- **RSS Parser**: Feed processing and aggregation
- **REST APIs**: External news source integration

### Cloud Services

- **Firebase/Firestore**: Real-time database
- **Google Gemini AI**: Content analysis and summarization
- **Google Cloud Platform**: Infrastructure and hosting

## 📁 Project Structure

```
genews/
├── lib/
│   ├── core/                    # Core utilities and constants
│   ├── features/
│   │   ├── home/               # News browsing features
│   │   │   ├── data/           # Data models and repositories
│   │   │   ├── presentation/   # UI screens and widgets
│   │   │   └── providers/      # State management
│   │   └── shared/             # Shared components
│   ├── shared/                 # Common widgets and styles
│   └── main.dart              # Application entry point
├── android/                   # Android-specific configuration
├── ios/                       # iOS-specific configuration
├── web/                       # Web deployment files
├── windows/                   # Windows desktop configuration
├── linux/                     # Linux desktop configuration
├── macos/                     # macOS configuration
├── python/                    # Backend data processing
└── assets/                    # Static resources
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Python 3.8+ (for backend processing)
- Firebase project setup
- Google Gemini API key

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/genews.git
   cd genews
   ```

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a new Firebase project
   - Enable Firestore Database
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective platform directories

4. **Set up environment variables**

   ```bash
   # Create .env file in project root
   GEMINI_API_KEY=your_gemini_api_key
   FIREBASE_PROJECT_ID=your_firebase_project_id
   ```

5. **Install Python dependencies**
   ```bash
   cd python
   pip install -r requirements.txt
   ```

### Running the Application

```bash
# Debug mode
flutter run

# Specific platform
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d macos          # macOS
flutter run -d linux          # Linux
```

<!-- #### Backend Services

```bash
cd python
python main.py
``` -->

## 🔧 Configuration

### Firebase Setup

1. Create a Firestore database
2. Configure security rules
3. Set up collections: `news`, `bookmarks`, `categories`

### API Configuration

- Configure news API endpoints in [`lib/core/constants.dart`](lib/core/constants.dart)
- Set up Gemini AI credentials
- Configure RSS feed sources

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 👥 Authors

- **Hoang Nguyen Duy**

---
