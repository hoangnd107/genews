import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genews/core/constants.dart';

/// Service để test và debug việc chuyển đổi từ API sang Firestore
class MigrationTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test connection và kiểm tra dữ liệu có sẵn trong Firestore
  static Future<Map<String, dynamic>> testMigration() async {
    try {
      debugPrint('🔄 Testing Firestore migration...');

      // 1. Test kết nối Firestore
      final connection = await _testFirestoreConnection();

      // 2. Test count articles
      final articleCount = await _getArticleCount();

      // 3. Test trending news
      final trendingArticles = await _getTrendingNews(limit: 5);

      // 4. Test search functionality
      final searchResults = await _testSearch('công nghệ', limit: 3);

      // 5. Test categories
      final categories = await _getAvailableCategories();

      // 6. Test category filter
      final categoryArticles = await _getCategoryNews('technology', limit: 3);

      return {
        'success': true,
        'connection': connection,
        'total_articles': articleCount,
        'trending_sample': trendingArticles.length,
        'search_results': searchResults.length,
        'categories': categories,
        'category_sample': categoryArticles.length,
        'message': 'Migration test completed successfully!',
      };
    } catch (e) {
      debugPrint('❌ Migration test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Migration test failed - check Firebase configuration',
      };
    }
  }

  /// Test kết nối Firestore
  static Future<bool> _testFirestoreConnection() async {
    try {
      await _firestore
          .collection(articlesCollectionName)
          .limit(1)
          .get(const GetOptions(source: Source.server));
      debugPrint('✅ Firestore connection successful');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore connection failed: $e');
      return false;
    }
  }

  /// Lấy tổng số bài viết
  static Future<int> _getArticleCount() async {
    final snapshot =
        await _firestore.collection(articlesCollectionName).count().get();
    final count = snapshot.count ?? 0;
    debugPrint('📊 Total articles in Firestore: $count');
    return count;
  }

  /// Lấy trending news (mới nhất)
  static Future<List<Map<String, dynamic>>> _getTrendingNews({
    int limit = 10,
  }) async {
    final snapshot =
        await _firestore
            .collection(articlesCollectionName)
            .orderBy('pubDate', descending: true)
            .limit(limit)
            .get();

    debugPrint('📈 Retrieved ${snapshot.docs.length} trending articles');
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Test search functionality
  static Future<List<Map<String, dynamic>>> _testSearch(
    String query, {
    int limit = 10,
  }) async {
    final lowerQuery = query.toLowerCase();

    final snapshot =
        await _firestore
            .collection(articlesCollectionName)
            .where('title_lower', isGreaterThanOrEqualTo: lowerQuery)
            .where('title_lower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
            .limit(limit)
            .get();

    debugPrint(
      '🔍 Search for "$query" returned ${snapshot.docs.length} results',
    );
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Lấy danh sách categories có sẵn
  static Future<List<String>> _getAvailableCategories() async {
    final snapshot = await _firestore.collection(articlesCollectionName).get();

    final categories = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category']?.toString();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }

    final sortedCategories = categories.toList()..sort();
    debugPrint('📂 Available categories: ${sortedCategories.join(', ')}');
    return sortedCategories;
  }

  /// Lấy tin tức theo category
  static Future<List<Map<String, dynamic>>> _getCategoryNews(
    String category, {
    int limit = 10,
  }) async {
    final snapshot =
        await _firestore
            .collection(articlesCollectionName)
            .where('category', isEqualTo: category)
            .orderBy('pubDate', descending: true)
            .limit(limit)
            .get();

    debugPrint('📂 Category "$category" has ${snapshot.docs.length} articles');
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  /// Check data freshness (bài viết trong 24h gần đây)
  static Future<Map<String, dynamic>> checkDataFreshness() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final snapshot =
          await _firestore
              .collection(articlesCollectionName)
              .where('pubDate', isGreaterThan: Timestamp.fromDate(yesterday))
              .get();

      final recentCount = snapshot.docs.length;
      debugPrint('🕒 Articles from last 24h: $recentCount');

      return {
        'recent_articles': recentCount,
        'check_time': now.toIso8601String(),
        'is_fresh': recentCount > 0,
      };
    } catch (e) {
      debugPrint('❌ Data freshness check failed: $e');
      return {'error': e.toString(), 'is_fresh': false};
    }
  }

  /// Print migration summary
  static void printMigrationSummary() {
    debugPrint('''
    
🚀 GENEWS MIGRATION SUMMARY
============================
✅ Switched from newsdata.io API to Firestore
✅ Updated NewsProvider to use FirestoreNewsRepositoryImpl  
✅ Updated HomeScreen to use fetchTrendingNews()
✅ Updated DiscoverScreen to use fetchTrendingNews()
✅ Updated CategoryNewsScreen to use fetchNewsByCategory()
✅ Enhanced search with Firestore queries
✅ Added AI analysis caching
✅ Maintained all existing features:
   - Category filtering
   - Search functionality  
   - Bookmarks
   - AI analysis
   - Share features
   - WebView

📱 PYTHON SCRIPTS INTEGRATION
============================
✅ Python scripts fetch data to Firestore 'articles' collection
✅ Real-time data updates from multiple sources
✅ Better data structure and search capabilities

🎯 NEXT STEPS
=============  
- Run migration test: MigrationTestService.testMigration()
- Monitor Firestore usage and optimize queries if needed
- Consider adding pagination for large result sets
- Set up Firestore indexes for better performance

''');
  }
}
