# 📱 GeNews - Testing Guide

## App Status: ✅ PRODUCTION READY

Ứng dụng GeNews đã hoạt động ổn định với dữ liệu từ Firestore.

## 🚀 Quick Start

### 1. Firebase Setup (Nếu chưa có)

1. **Firebase Console**: https://console.firebase.google.com
2. **Firestore Rules**:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### 2. Run the App

```bash
flutter pub get
flutter run
```

## 🧪 Testing Checklist

### Core Features

- [ ] **Home Screen**: Hiển thị tin tức nổi bật
- [ ] **Categories**: Lọc tin theo chuyên mục
- [ ] **Search**: Tìm kiếm bài viết
- [ ] **Bookmarks**: Lưu/xóa tin yêu thích
- [ ] **Analysis**: Phân tích AI với Gemini
- [ ] **Share**: Chia sẻ bài viết
- [ ] **WebView**: Đọc bài viết full

### UI/UX Features

- [ ] **Dark Mode**: Chuyển đổi giao diện
- [ ] **Font Size**: Thay đổi kích thước chữ
- [ ] **Pagination**: Phân trang hiện đại
- [ ] **Loading**: Smooth loading states
- [ ] **Offline**: Hoạt động offline với cache

## 📊 Data Sources

### Firestore Collections

- `articles`: Tin tức chính
- `news_data`: Backup collection

### Python Data Pipeline

Scripts trong thư mục `python/` tự động cập nhật dữ liệu:

- `api_fetcher.py`: API newsdata.io
- `rss_fetcher.py`: RSS feeds
- `selenium_fetcher.py`: Web crawling

## 🔧 Development

### Debug Mode

```bash
flutter run --debug
```

### Build APK

```bash
flutter build apk --release
```

### Analyze Code

```bash
flutter analyze
```

## 🐛 Common Issues

### 1. Permission Denied

- Check Firestore rules
- Verify Firebase config

### 2. Build Errors

- Run `flutter clean && flutter pub get`
- Check Android SDK version

### 3. No Data

- Verify Firestore has articles
- Check internet connection

## 📈 Performance Tips

1. **Firestore**: Monitor read operations
2. **Images**: Use cached_network_image
3. **Pagination**: Limit queries to 50 items
4. **AI Analysis**: Cache results to save API calls

## 🎯 Production Deployment

### Android

```bash
flutter build apk --release --split-per-abi
```

### iOS

```bash
flutter build ios --release
```

---

**🎉 App ready for production use!**
