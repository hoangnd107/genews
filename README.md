<div align="center" style="display: flex; align-items: center; justify-content: center; gap: 20px;">
   <img src="assets/icon/icon.png" alt="GeNews Logo" width="70" height="70">
   <h1 style="margin: 0;">GeNews - AI-Powered News Aggregator</h1>
</div>

## 🌟 Overview

**GeNews** is a cross-platform news aggregator and summarizer built with Flutter, powered by Google Gemini AI. The app fetches news from multiple sources, stores and syncs data in Firestore, and provides real-time updates, advanced search, bookmarking, sharing, and enhanced in-app reading with intelligent ad-blocking technology.

## 🏗️ System Architecture

![System Architecture](assets/system.png)

### Main Components

- **Data Processing (Python Backend):**
  - Automated news collection from RSS, web scraping (Selenium), and official APIs
  - Preprocessing and normalization, storing articles in Firestore via scripts in [`python/`](python/)
- **Cloud Infrastructure (Firebase/Google Cloud):**
  - **Firestore Database:** Stores articles, bookmarks, and user data
  - **Realtime Sync:** Instant data updates across all devices
  - **Google Gemini AI:** Generates news summaries and content analysis (called directly from the Flutter app)
- **Flutter Application (Client):**
  - **Cross-platform UI:** Android, iOS, Web, Windows, macOS, Linux
  - **State Management:** Provider pattern for efficient state management
  - **Advanced Search:** Full-text search, filter by category/source
  - **Smart Bookmarking:** Save, manage, search saved articles with real-time sync
  - **Sharing:** Native and web sharing support across platforms
  - **Enhanced WebView:** In-app reading with intelligent ad-blocking and font size controls
  - **UI Customization:** Dark/Light mode, adjustable font size, optimized reading experience

## 🚀 Key Features

### 🤖 AI-Powered Features

- **Smart Summarization:** Automatic article summarization using Gemini AI, with intelligent caching for performance
- **Content Analysis:** AI-powered news analysis and key insights extraction

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

- **Flutter 3.x** (Dart): Cross-platform UI framework with modern architecture
- **Firebase Firestore:** NoSQL database for real-time data storage and sync
- **Google Gemini AI:** Advanced AI for summarization and content analysis
- **Python (Selenium, RSS Parser):** Backend data collection and processing pipeline
- **Provider:** Efficient state management with reactive programming
- **WebView Flutter:** Enhanced in-app browser with ad-blocking capabilities
- **Cached Network Image:** Optimized image loading with smart caching
- **Share Plus:** Native and web sharing integration
- **Shared Preferences:** Local data persistence and user settings
- **Custom UI Components:** Reusable widgets with modern design principles

## 📁 Project Structure

```
genews/
├── lib/                           # Flutter/Dart source code
│   ├── app/                      # Application configuration
│   │   ├── config/              # Constants, enums, Firebase options
│   │   ├── themes/              # UI themes, colors, styling
│   │   ├── routes/              # Navigation routes (reserved)
│   │   └── app.dart             # Main application widget
│   ├── features/                # Feature-based modules
│   │   ├── analysis/            # News analysis and AI summaries
│   │   │   ├── data/           # Models and repositories
│   │   │   ├── providers/      # State management
│   │   │   └── views/          # UI screens
│   │   ├── bookmarks/           # Bookmark management
│   │   │   ├── data/           # Bookmark data models
│   │   │   ├── providers/      # Bookmark state management
│   │   │   └── views/          # Bookmark screens
│   │   ├── main/                # Main screen and navigation
│   │   │   ├── data/           # Main app data
│   │   │   ├── providers/      # Navigation state
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
│   ├── api_fetcher.py          # API-based news collection
│   ├── rss_fetcher.py          # RSS feed processing
│   ├── selenium_fetcher.py     # Web scraping with Selenium
│   ├── main.py                 # Main processing pipeline
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

## ✨ Key Improvements & Features

### 🔒 Enhanced Ad-Blocking

- **Smart Detection:** Advanced pattern matching for ad networks
- **Real-time Counter:** Live tracking of blocked advertisements
- **Performance Optimized:** Minimal impact on page loading speed
- **Comprehensive Coverage:** Blocks major ad networks and tracking scripts

### 🎨 Improved User Experience

- **Modern AppBar:** Clean design with real-time status indicators
- **Enhanced Loading:** Beautiful loading states with progress indicators
- **Smart Bookmarking:** Real-time bookmark status with visual feedback
- **Font Controls:** Easy text size adjustment for better readability
- **Quick Actions:** Copy link, share, and reload with enhanced filtering

### 🏗️ Clean Architecture

- **Feature-based Organization:** Modular structure for easy maintenance
- **Separation of Concerns:** Clear distinction between production and test code
- **Barrel Exports:** Clean import structure with organized exports
- **Consistent Patterns:** Standardized structure across all features

## 🔧 Setup & Configuration

### Prerequisites

- **Flutter SDK:** Version 3.x or later
- **Firebase Project:** Firestore database enabled
- **Google AI Studio:** Gemini API key
- **Python 3.8+:** For backend data processing

### Firebase Setup

1. Create a new Firebase project
2. Enable Firestore Database
3. Set up security rules for articles collection
4. Download and configure `google-services.json` (Android) / `GoogleService-Info.plist` (iOS)

### Gemini AI Configuration

1. Obtain API key from Google AI Studio
2. Configure in application settings
3. Set up appropriate usage limits and quotas

### Python Backend

```bash
cd python/
pip install -r requirements.txt
python main.py  # Run data collection pipeline
```

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

## 🚀 Future Enhancements

- **Offline Mode:** Complete offline reading support
- **Push Notifications:** Real-time news alerts
- **User Profiles:** Personalized news preferences
- **Social Features:** Share and discuss articles
- **Analytics:** Advanced usage analytics and insights
- **Multi-language:** Extended language support

## 👥 Author

- **Hoang Nguyen Duy** - Full-stack Developer & AI Enthusiast

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📞 Support

If you have any questions or need support, please:

- Open an issue on GitHub
- Contact the development team
- Check the documentation in the `docs/` folder

---

**Built with ❤️ using Flutter & AI Technologies**
