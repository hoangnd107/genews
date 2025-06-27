# 🚀 GeNews Migration: API → Firestore

## Tổng quan

Ứng dụng GeNews đã được chuyển đổi thành công từ việc sử dụng API newsdata.io sang lấy dữ liệu trực tiếp từ Firestore collection `articles`. Việc chuyển đổi này mang lại nhiều lợi ích:

- ⚡ Tốc độ truy xuất nhanh hơn
- 💰 Tiết kiệm chi phí API calls
- 🔄 Dữ liệu được cập nhật tự động bởi Python scripts
- 🔍 Khả năng tìm kiếm mạnh mẽ hơn
- 📊 Tốt hơn cho việc phân tích và thống kê

## Những thay đổi chính

### 1. Repository Layer

- ✅ **Mới**: `FirestoreNewsRepositoryImpl` - Lấy dữ liệu từ Firestore
- ⚠️ **Cũ**: `NewsApiRepositoryImpl` - Lấy dữ liệu từ API (không sử dụng nữa)

### 2. NewsProvider Updates

```dart
// Thêm methods mới
Future<void> fetchTrendingNews()      // Lấy tin nổi bật
Future<void> fetchNewsByCategory()    // Lấy tin theo category
Future<void> searchArticles()         // Tìm kiếm với Firestore
```

### 3. UI Components Updates

- **HomeScreen**: Sử dụng `fetchTrendingNews()` thay vì `fetchNews()`
- **DiscoverScreen**: Cập nhật để dùng Firestore data
- **CategoryNewsScreen**: Sử dụng `fetchNewsByCategory()` thay vì filter local
- **Search**: Tích hợp Firestore search queries

### 4. Constants Updates

```dart
// DEPRECATED - không sử dụng nữa
// String newsUrl = "https://newsdata.io/api/1/latest?apikey=$newsApiKey&language=vi";

// SỬ DỤNG CÁC COLLECTION FIRESTORE
const articlesCollectionName = 'articles';
```

## Cấu trúc dữ liệu Firestore

### Collection: `articles`

```json
{
  "title": "Tiêu đề bài viết",
  "title_lower": "tiêu đề bài viết",  // Để search
  "description": "Mô tả bài viết",
  "content": "Nội dung đầy đủ",
  "link": "https://...",
  "image_url": "https://...",
  "source_name": "Tên nguồn",
  "source_url": "https://...",
  "category": "technology",
  "pubDate": Timestamp,
  "country": "vi",
  "language": "vietnamese"
}
```

## Python Scripts Integration

Dữ liệu được fetch tự động bởi các Python scripts trong thư mục `python/`:

- `api_fetcher.py` - Lấy dữ liệu từ newsdata.io API
- `rss_fetcher.py` - Lấy dữ liệu từ RSS feeds
- `selenium_fetcher.py` - Crawl dữ liệu từ websites
- `main.py` - Script chính để chạy tất cả fetchers

## Testing Migration

### 1. Sử dụng Test Service

```dart
import 'package:genews/shared/services/migration_test_service.dart';

// Test migration programmatically
final results = await MigrationTestService.testMigration();
print(results);

// Check data freshness
final freshness = await MigrationTestService.checkDataFreshness();
```

### 2. Sử dụng Debug Widget

```dart
import 'package:genews/shared/widgets/migration_test_widget.dart';

// Thêm vào debug menu hoặc development screen
const MigrationTestWidget()
```

### 3. Console Testing

Mở debug console và chạy:

```dart
MigrationTestService.printMigrationSummary();
```

## Performance Optimizations

### 1. Firestore Indexes

Đã tạo các composite indexes cần thiết:

- `title_lower` (for search)
- `category` + `pubDate` (for category filtering)
- `pubDate` (for trending sort)

### 2. Caching

- Analysis results được cache để tránh duplicate AI calls
- Local search results được cache khi filter categories

### 3. Query Limits

- Trending news: Limit 50 articles
- Category news: Limit 100 articles
- Search results: Limit 50 articles

## Monitoring & Maintenance

### 1. Firestore Usage

- Monitor read/write operations trong Firebase Console
- Set up alerts cho usage limits
- Optimize queries nếu cần thiết

### 2. Data Quality

- Python scripts chạy định kỳ để cập nhật dữ liệu
- Monitor data freshness với `checkDataFreshness()`
- Clean up old articles nếu cần

### 3. Error Handling

- Fallback mechanisms trong trường hợp Firestore unavailable
- Retry logic cho failed operations
- User-friendly error messages

## Rollback Plan (Nếu cần)

Nếu cần rollback về API cũ:

1. Uncomment `newsUrl` trong `constants.dart`
2. Thay đổi repository trong `NewsProvider`:

   ```dart
   // Thay vì
   final FirestoreNewsRepositoryImpl _newsRepo = FirestoreNewsRepositoryImpl();

   // Sử dụng
   final NewsApiRepositoryImpl _newsRepo = NewsApiRepositoryImpl();
   ```

3. Revert các method calls về `fetchNews()` thay vì `fetchTrendingNews()`

## Next Steps

1. ✅ **Hoàn thành**: Core migration
2. 🔄 **Đang làm**: Monitoring và optimization
3. 📋 **Kế hoạch**:
   - Thêm pagination cho large datasets
   - Implement offline caching
   - Add real-time updates với Firestore listeners
   - Optimize image loading và caching

## Support

Nếu gặp vấn đề với migration:

1. Chạy `MigrationTestService.testMigration()` để diagnose
2. Check Firebase Console cho Firestore status
3. Verify Python scripts đang chạy và cập nhật dữ liệu
4. Check app logs cho các error messages

---

**🎉 Migration hoàn thành thành công! Ứng dụng giờ đã sử dụng Firestore làm data source chính.**
