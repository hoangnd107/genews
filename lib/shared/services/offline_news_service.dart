import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';

class OfflineNewsService {
  static const String _newsKey = 'cached_news_articles';
  static const String _aiSummariesKey = 'cached_ai_summaries';
  static const String _lastFetchTimeKey = 'last_fetch_time';

  static OfflineNewsService? _instance;
  static OfflineNewsService get instance =>
      _instance ??= OfflineNewsService._();
  OfflineNewsService._();

  Future<void> cacheArticles(List<Result> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final filteredArticles = _prioritizeCompleteArticles(articles);

      final articlesJson =
          filteredArticles.map((article) => article.toJson()).toList();
      await prefs.setString(_newsKey, jsonEncode(articlesJson));
      await prefs.setInt(
        _lastFetchTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      log("Cached ${filteredArticles.length} articles offline");
    } catch (e) {
      log("Error caching articles: $e");
    }
  }

  // Get cached articles
  Future<List<Result>> getCachedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final articlesJsonString = prefs.getString(_newsKey);

      if (articlesJsonString == null) {
        log("No cached articles found");
        return [];
      }

      final articlesJson = jsonDecode(articlesJsonString) as List;
      final articles =
          articlesJson.map((json) => Result.fromJson(json)).toList();

      log("Retrieved ${articles.length} cached articles");
      return articles;
    } catch (e) {
      log("Error retrieving cached articles: $e");
      return [];
    }
  }

  Future<void> cacheAiSummary(String articleId, String summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSummaries = prefs.getString(_aiSummariesKey) ?? '{}';
      final summariesMap =
          jsonDecode(existingSummaries) as Map<String, dynamic>;

      summariesMap[articleId] = {
        'summary': summary,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_aiSummariesKey, jsonEncode(summariesMap));
      log("Cached AI summary for article: $articleId");
    } catch (e) {
      log("Error caching AI summary: $e");
    }
  }

  Future<String?> getCachedAiSummary(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final summariesJsonString = prefs.getString(_aiSummariesKey);

      if (summariesJsonString == null) return null;

      final summariesMap =
          jsonDecode(summariesJsonString) as Map<String, dynamic>;
      final summaryData = summariesMap[articleId] as Map<String, dynamic>?;

      if (summaryData != null) {
        log("Retrieved cached AI summary for article: $articleId");
        return summaryData['summary'] as String;
      }

      return null;
    } catch (e) {
      log("Error retrieving cached AI summary: $e");
      return null;
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      return !connectivityResults.contains(ConnectivityResult.none);
    } catch (e) {
      log("Error checking connectivity: $e");
      return false;
    }
  }

  Future<bool> isCachedDataFresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getInt(_lastFetchTimeKey);

      if (lastFetchTime == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final oneHourInMs = 60 * 60 * 1000;

      return (now - lastFetchTime) < oneHourInMs;
    } catch (e) {
      log("Error checking cached data freshness: $e");
      return false;
    }
  }

  List<Result> _prioritizeCompleteArticles(List<Result> articles) {
    final completeArticles = <Result>[];
    final incompleteArticles = <Result>[];

    for (final article in articles) {
      final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
      final hasTitle = article.title != null && article.title!.isNotEmpty;
      final hasDescription =
          article.description != null && article.description!.isNotEmpty;

      if (hasImage && hasTitle && hasDescription) {
        completeArticles.add(article);
      } else {
        incompleteArticles.add(article);
      }
    }

    completeArticles.sort((a, b) {
      final dateA = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    incompleteArticles.sort((a, b) {
      final dateA = a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    final result = <Result>[];
    result.addAll(completeArticles);
    result.addAll(incompleteArticles);

    return result.take(500).toList();
  }

  Future<List<Result>> getArticlesByCategory(String category) async {
    try {
      final cachedArticles = await getCachedArticles();

      if (cachedArticles.isEmpty) {
        log("No cached articles to filter by category");
        return [];
      }

      final filteredArticles =
          cachedArticles.where((article) {
            final categories = article.category ?? [];

            return categories.any((cat) {
              final cleanCat = _cleanCategoryString(cat);
              final cleanTargetCategory = _cleanCategoryString(category);

              return cleanCat.toLowerCase() ==
                      cleanTargetCategory.toLowerCase() ||
                  cleanCat.toLowerCase() == category.toLowerCase();
            });
          }).toList();

      log(
        "Found ${filteredArticles.length} cached articles for category: $category",
      );
      return filteredArticles;
    } catch (e) {
      log("Error filtering cached articles by category: $e");
      return [];
    }
  }

  Future<List<Result>> searchCachedArticles(String query) async {
    try {
      final cachedArticles = await getCachedArticles();

      if (cachedArticles.isEmpty) {
        log("No cached articles to search");
        return [];
      }

      final filteredArticles =
          cachedArticles.where((article) {
            final title = article.title?.toLowerCase() ?? "";
            final description = article.description?.toLowerCase() ?? "";
            final sourceName = article.sourceName?.toLowerCase() ?? "";
            final lowerQuery = query.toLowerCase();

            return title.contains(lowerQuery) ||
                description.contains(lowerQuery) ||
                sourceName.contains(lowerQuery);
          }).toList();

      log(
        "Found ${filteredArticles.length} cached articles matching query: $query",
      );
      return filteredArticles;
    } catch (e) {
      log("Error searching cached articles: $e");
      return [];
    }
  }

  String _cleanCategoryString(String category) {
    return category
        .replaceAll(
          RegExp(r'[\[\]"",\.]'),
          '',
        )
        .trim();
  }

  Future<List<String>> getAvailableCategories() async {
    try {
      final cachedArticles = await getCachedArticles();
      final categorySet = <String>{};

      for (final article in cachedArticles) {
        final categories = article.category ?? [];
        for (final cat in categories) {
          final cleanCat = _cleanCategoryString(cat);
          if (cleanCat.isNotEmpty) {
            categorySet.add(cleanCat);
          }
        }
      }

      final sortedCategories = categorySet.toList()..sort();
      log("Found ${sortedCategories.length} unique categories");
      return sortedCategories;
    } catch (e) {
      log("Error getting available categories: $e");
      return [];
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_newsKey);
      await prefs.remove(_aiSummariesKey);
      await prefs.remove(_lastFetchTimeKey);
      log("Cleared offline cache");
    } catch (e) {
      log("Error clearing cache: $e");
    }
  }

  Future<void> addArticlesToCache(List<Result> newArticles) async {
    try {
      final existingArticles = await getCachedArticles();
      final combinedArticles = [...existingArticles, ...newArticles];
      final uniqueArticles = <String, Result>{};
      for (var article in combinedArticles) {
        final key = article.articleId ?? article.link ?? article.title ?? '';
        if (key.isNotEmpty) {
          uniqueArticles[key] = article;
        }
      }

      await cacheArticles(uniqueArticles.values.toList());

      log(
        "Added ${newArticles.length} new articles to cache, total: ${uniqueArticles.length}",
      );
    } catch (e) {
      log("Error adding articles to cache: $e");
    }
  }
}
