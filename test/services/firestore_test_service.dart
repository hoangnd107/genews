import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:genews/app/config/constants.dart';

class FirestoreTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test method to check Firestore connection and data availability
  static Future<Map<String, dynamic>> testFirestoreConnection() async {
    try {
      log("🔥 Testing Firestore connection...");

      // Test 1: Check if articles collection exists and has data
      final articlesSnapshot =
          await _firestore.collection(articlesCollectionName).limit(1).get();

      final bool hasArticles = articlesSnapshot.docs.isNotEmpty;
      final int articlesCount =
          hasArticles ? await _getCollectionCount(articlesCollectionName) : 0;

      // Test 2: Check if news_data collection exists
      final newsSnapshot =
          await _firestore.collection(newsCollectionName).limit(1).get();

      final bool hasNewsData = newsSnapshot.docs.isNotEmpty;

      // Test 3: Get sample article data
      Map<String, dynamic>? sampleArticle;
      if (hasArticles) {
        sampleArticle = articlesSnapshot.docs.first.data();
        // Remove sensitive data for logging
        sampleArticle.removeWhere((key, value) => key == 'content');
      }

      // Test 4: Check available sources
      List<String> availableSources = [];
      if (hasArticles) {
        final sourcesQuery =
            await _firestore.collection(articlesCollectionName).limit(20).get();

        final sourceSet = <String>{};
        for (var doc in sourcesQuery.docs) {
          final data = doc.data();
          if (data['source_name'] != null) {
            sourceSet.add(data['source_name'].toString());
          }
        }
        availableSources = sourceSet.toList();
      }

      // Test 5: Check available categories
      List<String> availableCategories = [];
      if (hasArticles) {
        final categoriesQuery =
            await _firestore.collection(articlesCollectionName).limit(50).get();

        final categorySet = <String>{};
        for (var doc in categoriesQuery.docs) {
          final data = doc.data();
          if (data['category'] != null && data['category'] is List) {
            final categories = data['category'] as List;
            for (var cat in categories) {
              categorySet.add(cat.toString());
            }
          }
        }
        availableCategories = categorySet.toList();
      }

      final result = {
        'connectionSuccessful': true,
        'hasArticles': hasArticles,
        'articlesCount': articlesCount,
        'hasNewsData': hasNewsData,
        'availableSources': availableSources,
        'availableCategories': availableCategories,
        'sampleArticle': sampleArticle,
        'timestamp': DateTime.now().toIso8601String(),
      };

      log("✅ Firestore test completed successfully");
      log("📊 Articles found: $articlesCount");
      log("🏷️ Available categories: ${availableCategories.length}");
      log("📰 Available sources: ${availableSources.length}");

      return result;
    } catch (e, stackTrace) {
      log("❌ Firestore test failed: $e");
      log("Stack trace: $stackTrace");

      return {
        'connectionSuccessful': false,
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get approximate count of documents in a collection
  static Future<int> _getCollectionCount(String collectionName) async {
    try {
      final snapshot = await _firestore.collection(collectionName).get();
      return snapshot.docs.length;
    } catch (e) {
      log("Error getting collection count: $e");
      return 0;
    }
  }

  /// Test method to get recent articles with detailed logging
  static Future<List<Map<String, dynamic>>> getRecentArticles({
    int limit = 5,
  }) async {
    try {
      log("📰 Fetching $limit recent articles for testing...");

      final querySnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .orderBy('pubDate', descending: true)
              .limit(limit)
              .get();

      final articles =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title']?.toString() ?? 'No title',
              'source_name':
                  data['source_name']?.toString() ?? 'Unknown source',
              'category': data['category']?.toString() ?? 'No category',
              'pubDate': data['pubDate']?.toString() ?? 'No date',
              'hasImage':
                  data['image_url'] != null &&
                  data['image_url'].toString().isNotEmpty,
              'hasDescription':
                  data['description'] != null &&
                  data['description'].toString().isNotEmpty,
            };
          }).toList();

      log("✅ Successfully fetched ${articles.length} recent articles");
      for (var article in articles) {
        log("  📄 ${article['title']} - ${article['source_name']}");
      }

      return articles;
    } catch (e, stackTrace) {
      log("❌ Error fetching recent articles: $e");
      log("Stack trace: $stackTrace");
      return [];
    }
  }

  /// Test method to search articles with query
  static Future<List<Map<String, dynamic>>> testSearchArticles(
    String query,
  ) async {
    try {
      log("🔍 Testing search for: '$query'");

      final querySnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .orderBy('pubDate', descending: true)
              .limit(100)
              .get();

      final allArticles =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'title': data['title']?.toString() ?? '',
              'description': data['description']?.toString() ?? '',
              'source_name': data['source_name']?.toString() ?? '',
              'category': data['category']?.toString() ?? '',
            };
          }).toList();

      // Filter articles based on search query
      final filteredArticles =
          allArticles.where((article) {
            final title = (article['title'] ?? '').toString().toLowerCase();
            final description =
                (article['description'] ?? '').toString().toLowerCase();
            final sourceName =
                (article['source_name'] ?? '').toString().toLowerCase();
            final lowerQuery = query.toLowerCase();

            return title.contains(lowerQuery) ||
                description.contains(lowerQuery) ||
                sourceName.contains(lowerQuery);
          }).toList();

      log(
        "✅ Search completed: ${filteredArticles.length} results found for '$query'",
      );
      return filteredArticles.take(10).toList(); // Return top 10 results
    } catch (e, stackTrace) {
      log("❌ Error testing search: $e");
      log("Stack trace: $stackTrace");
      return [];
    }
  }

  /// Method to check data freshness
  static Future<Map<String, dynamic>> checkDataFreshness() async {
    try {
      log("⏰ Checking data freshness...");

      // Get the most recent article
      final recentSnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .orderBy('pubDate', descending: true)
              .limit(1)
              .get();

      if (recentSnapshot.docs.isEmpty) {
        return {'hasData': false, 'message': 'No articles found in collection'};
      }

      final recentDoc = recentSnapshot.docs.first;
      final data = recentDoc.data();

      DateTime? recentDate;
      if (data['pubDate'] != null) {
        if (data['pubDate'] is Timestamp) {
          recentDate = (data['pubDate'] as Timestamp).toDate();
        } else if (data['pubDate'] is String) {
          try {
            recentDate = DateTime.parse(data['pubDate']);
          } catch (e) {
            log("Error parsing date: ${data['pubDate']}");
          }
        }
      }

      if (recentDate == null) {
        return {
          'hasData': true,
          'freshness': 'unknown',
          'message': 'Cannot determine article date',
        };
      }

      final now = DateTime.now();
      final difference = now.difference(recentDate);

      String freshnessStatus;
      if (difference.inHours < 1) {
        freshnessStatus = 'very_fresh';
      } else if (difference.inHours < 6) {
        freshnessStatus = 'fresh';
      } else if (difference.inDays < 1) {
        freshnessStatus = 'recent';
      } else if (difference.inDays < 7) {
        freshnessStatus = 'week_old';
      } else {
        freshnessStatus = 'old';
      }

      log("📅 Most recent article: ${difference.inHours} hours ago");
      log("🆕 Data freshness: $freshnessStatus");

      return {
        'hasData': true,
        'mostRecentDate': recentDate.toIso8601String(),
        'hoursAgo': difference.inHours,
        'daysAgo': difference.inDays,
        'freshness': freshnessStatus,
        'title': data['title']?.toString() ?? 'No title',
        'source': data['source_name']?.toString() ?? 'Unknown source',
      };
    } catch (e) {
      log("❌ Error checking data freshness: $e");
      return {'hasData': false, 'error': e.toString()};
    }
  }
}
