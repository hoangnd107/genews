import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:genews/core/constants.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/shared/services/offline_news_service.dart';
import 'package:offline_first_support/offline_first.dart';

abstract class FirestoreNewsRepository {
  Future<NewsDataModel> fetchTrendingNews();
  Future<List<Result>> getArticlesByCategory(String category);
  Future<List<Result>> searchArticles(String query);
  Future<String> generateNewsAiAnalysis(String content, {String? articleId});
}

class FirestoreNewsRepositoryImpl implements FirestoreNewsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _offlineFirst = OfflineFirst();

  final ai.GenerativeModel _model = ai.GenerativeModel(
    model: "gemini-2.5-pro",
    apiKey: apiKeyGemini,
  );

  @override
  Future<NewsDataModel> fetchTrendingNews() async {
    try {
      log(
        "🔥 Fetching 500 news from Firestore collection: $articlesCollectionName",
      );

      // Check if offline and has cached data
      final hasInternet =
          await OfflineNewsService.instance.hasInternetConnection();
      final isCachedFresh =
          await OfflineNewsService.instance.isCachedDataFresh();

      if (!hasInternet && isCachedFresh) {
        log("📱 Using cached data (offline mode)");
        final cachedArticles =
            await OfflineNewsService.instance.getCachedArticles();
        return NewsDataModel(
          status: "success",
          totalResults: cachedArticles.length,
          results: cachedArticles,
          nextPage: null,
        );
      }

      // Fetch from Firestore - increase limit to 500
      final querySnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .limit(500) // Increased from 100 to 500
              .get();

      if (querySnapshot.docs.isEmpty) {
        log("⚠️ No articles found in Firestore collection");

        // Try to return cached data even if not fresh
        final cachedArticles =
            await OfflineNewsService.instance.getCachedArticles();
        if (cachedArticles.isNotEmpty) {
          log("📱 Using cached data as fallback");
          return NewsDataModel(
            status: "success",
            totalResults: cachedArticles.length,
            results: cachedArticles,
            nextPage: null,
          );
        }

        return NewsDataModel(
          status: "error",
          totalResults: 0,
          results: [],
          nextPage: null,
        );
      }

      log("✅ Found ${querySnapshot.docs.length} articles from Firestore");

      // Convert Firestore documents to Result objects using helper method
      final List<Result> articles =
          querySnapshot.docs.map((doc) => _mapDocumentToResult(doc)).toList();

      // Cache articles for offline use
      await OfflineNewsService.instance.cacheArticles(articles);

      // Create NewsDataModel compatible with existing code
      final newsDataModel = NewsDataModel(
        status: "success",
        totalResults: articles.length,
        results: articles,
        nextPage: null,
      );

      log(
        "🎉 Successfully converted ${articles.length} Firestore articles to NewsDataModel",
      );
      return newsDataModel;
    } catch (e, stackTrace) {
      log("❌ Error fetching news from Firestore: $e");
      log("Stack trace: $stackTrace");

      // Return cached data as fallback
      final cachedArticles =
          await OfflineNewsService.instance.getCachedArticles();
      if (cachedArticles.isNotEmpty) {
        log("📱 Using cached data due to error");
        return NewsDataModel(
          status: "success",
          totalResults: cachedArticles.length,
          results: cachedArticles,
          nextPage: null,
        );
      }

      throw Exception("❌ Lỗi khi lấy tin tức từ Firestore: $e");
    }
  }

  @override
  Future<String> generateNewsAiAnalysis(
    String content, {
    String? articleId,
  }) async {
    // Check for cached AI summary first
    if (articleId != null) {
      final cachedSummary = await OfflineNewsService.instance
          .getCachedAiSummary(articleId);
      if (cachedSummary != null) {
        log("✅ Using cached AI summary for article: $articleId");
        return cachedSummary;
      }
    }

    // Check internet connection before generating new summary
    final hasInternet =
        await OfflineNewsService.instance.hasInternetConnection();
    if (!hasInternet) {
      throw Exception("Cần kết nối internet để tạo tóm tắt mới");
    }

    final prompt = """
Phân tích và tóm tắt tin tức sau theo định dạng yêu cầu, chỉ trả về nội dung tóm tắt, không thêm bất kỳ lời giới thiệu hay kết thúc nào:

Nội dung tin tức:
$content

Định dạng tóm tắt yêu cầu:

1. Điểm chính
- Thông tin quan trọng nhất
- Các sự kiện chính diễn ra
- Tác động hoặc ảnh hưởng

2. Chi tiết bổ sung
- Nguyên nhân dẫn đến sự việc
- Các bên liên quan
- Bối cảnh và thông tin nền

3. Tầm quan trọng
- Ý nghĩa của sự việc
- Ảnh hưởng đến cộng đồng/xã hội
- Hướng phát triển có thể

Yêu cầu:
- Chỉ trả về nội dung tóm tắt theo định dạng trên
- Ngôn ngữ Tiếng Việt tự nhiên, dễ hiểu
- Không sử dụng ký tự đặc biệt như **, ##, ***
- Sử dụng số thứ tự và dấu gạch ngang để phân chia
- Tối đa 300 từ
- Giọng văn khách quan, chuyên nghiệp
- KHÔNG thêm lời mở đầu hay kết thúc""";

    final summary = await _generateContent(prompt);

    // Cache the generated summary
    if (articleId != null && summary.isNotEmpty) {
      await OfflineNewsService.instance.cacheAiSummary(articleId, summary);
    }

    return summary;
  }

  Future<String> _generateContent(String prompt) async {
    final result = await _offlineFirst.fetchData(
      urlPath: prompt,
      fetchPolicy: OfflineFirstFetchPolicy.networkOnly,
    );

    if (result.data != null) {
      return result.data;
    }

    final response = await _model.generateContent([ai.Content.text(prompt)]);

    if (response.text == null) {
      throw Exception("❌ Lỗi");
    }
    _offlineFirst.saveData(key: prompt, content: response.text!);
    return response.text!;
  }

  // Helper methods to convert Firestore data to proper types

  List<String> _convertToStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }

  int? _parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  Content _mapContent(String? value) {
    if (value == null || value.isEmpty)
      return Content.ONLY_AVAILABLE_IN_PAID_PLANS;

    // Map content values từ Firestore
    switch (value.toLowerCase()) {
      case 'content_to_be_scraped':
        return Content.ONLY_AVAILABLE_IN_PAID_PLANS;
      default:
        return Content.ONLY_AVAILABLE_IN_PAID_PLANS;
    }
  }

  PubDateTz _mapPubDateTz(String? value) {
    if (value == null) return PubDateTz.UTC;

    switch (value.toLowerCase()) {
      case 'utc+07:00':
      case 'utc+7':
        return PubDateTz.UTC;
      default:
        return PubDateTz.UTC;
    }
  }

  AiTag _mapAiTag(String? value) {
    if (value == null || value.isEmpty) {
      return AiTag.ONLY_AVAILABLE_IN_PROFESSIONAL_AND_CORPORATE_PLANS;
    }

    switch (value.toLowerCase()) {
      case 'rss_parsed':
      case 'selenium_scraped':
      case 'not_analyzed':
        return AiTag.ONLY_AVAILABLE_IN_PROFESSIONAL_AND_CORPORATE_PLANS;
      case 'neutral':
        return AiTag.ONLY_AVAILABLE_IN_PROFESSIONAL_AND_CORPORATE_PLANS;
      default:
        return AiTag.ONLY_AVAILABLE_IN_PROFESSIONAL_AND_CORPORATE_PLANS;
    }
  }

  Ai _mapAi(String? value) {
    if (value == null || value.isEmpty) {
      return Ai.ONLY_AVAILABLE_IN_CORPORATE_PLANS;
    }
    return Ai.ONLY_AVAILABLE_IN_CORPORATE_PLANS;
  }

  // Helper method to map Firestore document to Result object
  Result _mapDocumentToResult(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    DateTime? pubDate;
    if (data['pubDate'] != null) {
      if (data['pubDate'] is Timestamp) {
        pubDate = (data['pubDate'] as Timestamp).toDate();
      } else if (data['pubDate'] is String) {
        try {
          pubDate = DateTime.parse(data['pubDate']);
        } catch (e) {
          pubDate = DateTime.now();
        }
      }
    } else {
      pubDate = DateTime.now();
    }

    return Result(
      articleId: doc.id,
      title: data['title']?.toString() ?? "Không có tiêu đề",
      link: data['link']?.toString() ?? "",
      keywords: _convertToStringList(data['keywords']),
      creator: _convertToStringList(data['creator']),
      videoUrl: data['video_url'],
      description: data['description']?.toString() ?? "Không có mô tả",
      content: _mapContent(data['content']?.toString()),
      pubDate: pubDate,
      pubDateTz: _mapPubDateTz(data['pubDateTZ']?.toString()),
      imageUrl: data['image_url']?.toString(),
      sourceId: data['source_id']?.toString() ?? "unknown",
      sourcePriority: _parseToInt(data['source_priority']) ?? 1,
      sourceName: data['source_name']?.toString() ?? "Nguồn không xác định",
      sourceUrl: data['source_url']?.toString(),
      sourceIcon: data['source_icon']?.toString(),
      language: data['language']?.toString() ?? "vi",
      country: _convertToStringList(data['country']),
      category: _convertToStringList(data['category']),
      aiTag: _mapAiTag(data['ai_tag']?.toString()),
      sentiment: _mapAiTag(data['sentiment']?.toString()),
      sentimentStats: _mapAiTag(data['sentiment_stats']?.toString()),
      aiRegion: _mapAi(data['ai_region']?.toString()),
      aiOrg: _mapAi(data['ai_org']?.toString()),
      duplicate: data['duplicate'] as bool? ?? false,
    );
  }

  // Method to get articles by category
  // Method to get articles by category - enhanced with Firestore fallback
  @override
  Future<List<Result>> getArticlesByCategory(String category) async {
    try {
      log("🔍 Getting articles for category: $category");

      // First try to get from cached data
      final cachedArticles = await OfflineNewsService.instance
          .getArticlesByCategory(category);

      if (cachedArticles.isNotEmpty) {
        log(
          "✅ Found ${cachedArticles.length} articles for category '$category' in cache",
        );
        return cachedArticles;
      }

      log(
        "⚠️ No articles found for category '$category' in cache, querying Firestore...",
      );

      // If no cached articles for this category, query from Firestore
      final querySnapshot =
          await _firestore
              .collection(articlesCollectionName)
              .where('category', isEqualTo: category)
              .limit(50) // Limit to 50 articles per category
              .get();

      if (querySnapshot.docs.isEmpty) {
        log("⚠️ No articles found for category '$category' in Firestore");
        return [];
      }

      log(
        "✅ Found ${querySnapshot.docs.length} articles for category '$category' from Firestore",
      );

      // Convert Firestore documents to Result objects
      final List<Result> articles =
          querySnapshot.docs.map((doc) => _mapDocumentToResult(doc)).toList();

      // Add these articles to existing cache
      await OfflineNewsService.instance.addArticlesToCache(articles);

      return articles;
    } catch (e) {
      log("❌ Error getting articles by category: $e");
      return [];
    }
  }

  // Method to search articles - now uses cached data
  @override
  Future<List<Result>> searchArticles(String query) async {
    try {
      log("🔍 Searching cached articles with query: $query");

      // Use cached articles for better performance and offline support
      return await OfflineNewsService.instance.searchCachedArticles(query);
    } catch (e) {
      log("❌ Error searching cached articles: $e");
      return [];
    }
  }
}
