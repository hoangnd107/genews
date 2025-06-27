import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/data/repository/firestore_news_repository.dart';
import 'package:genews/shared/services/category_mapping_service.dart';

class NewsProvider extends ChangeNotifier {
  final FirestoreNewsRepositoryImpl _newsRepo = FirestoreNewsRepositoryImpl();

  NewsDataModel _allNews = NewsDataModel();
  NewsDataModel get allNews => _allNews;

  ViewState newsViewState = ViewState.idle;
  ViewState newsAnalysisState = ViewState.idle;
  ViewState newsContentState = ViewState.idle;

  String message = "";

  String analysis = "";
  String socialMediaPost = "";
  String generatedVideoScript = "";

  // Thêm Map để cache analysis
  final Map<String, String> _analysisCache = {};

  // Thêm method để get cache key
  String _getAnalysisCacheKey(String content) {
    // Sử dụng hash của content làm key để tránh key quá dài
    return content.hashCode.toString();
  }

  Future<void> fetchNews() async {
    newsViewState = ViewState.busy;
    _updateUI();

    try {
      final newsResult = await _newsRepo.fetchTrendingNews();

      _allNews = newsResult;
      newsViewState = ViewState.success;
      _updateUI();
    } catch (e, s) {
      newsViewState = ViewState.error;
      _updateUI();
      log("$e ::: stack trace $s");
    }
  }

  // Alias for fetchNews for clearer semantics
  Future<void> fetchTrendingNews() async {
    return fetchNews();
  }

  // Cập nhật generateAnalysis method
  generateAnalysis(String content) async {
    try {
      final cacheKey = _getAnalysisCacheKey(content);

      // Kiểm tra cache trước
      if (_analysisCache.containsKey(cacheKey)) {
        analysis = _analysisCache[cacheKey]!;
        newsAnalysisState = ViewState.success;
        notifyListeners();
        return;
      }

      newsAnalysisState = ViewState.busy;
      notifyListeners();

      final result = await _newsRepo.generateNewsAiAnalysis(content);

      // Lưu vào cache
      _analysisCache[cacheKey] = result;
      analysis = result;
      newsAnalysisState = ViewState.success;
    } catch (e) {
      analysis = "";
      newsAnalysisState = ViewState.error;
    }
    notifyListeners();
  }

  // Thêm method để regenerate analysis (bypass cache)
  regenerateAnalysis(String content) async {
    try {
      final cacheKey = _getAnalysisCacheKey(content);

      newsAnalysisState = ViewState.busy;
      notifyListeners();

      final result = await _newsRepo.generateNewsAiAnalysis(content);

      // Cập nhật cache với kết quả mới
      _analysisCache[cacheKey] = result;
      analysis = result;
      newsAnalysisState = ViewState.success;
    } catch (e) {
      analysis = "";
      newsAnalysisState = ViewState.error;
    }
    notifyListeners();
  }

  // Method để clear cache nếu cần
  void clearAnalysisCache() {
    _analysisCache.clear();
  }

  Future<void> fetchNewsByCategory(String category) async {
    newsViewState = ViewState.busy;
    _updateUI();

    try {
      // Convert display category to query key (English or Vietnamese)
      final queryCategory = CategoryMappingService.getCategoryKey(category);
      final articles = await _newsRepo.getArticlesByCategory(queryCategory);

      // Convert articles to NewsDataModel format
      _allNews = NewsDataModel(
        status: "success",
        totalResults: articles.length,
        results: articles,
        nextPage: null,
      );

      newsViewState = ViewState.success;
      _updateUI();
    } catch (e, s) {
      newsViewState = ViewState.error;
      _updateUI();
      log("Error fetching news by category: $e ::: stack trace $s");
    }
  }

  Future<void> searchArticles(String query) async {
    newsViewState = ViewState.busy;
    _updateUI();

    try {
      final articles = await _newsRepo.searchArticles(query);

      // Convert articles to NewsDataModel format
      _allNews = NewsDataModel(
        status: "success",
        totalResults: articles.length,
        results: articles,
        nextPage: null,
      );

      newsViewState = ViewState.success;
      _updateUI();
    } catch (e, s) {
      newsViewState = ViewState.error;
      _updateUI();
      log("Error searching articles: $e ::: stack trace $s");
    }
  }

  // Thêm method để truy cập repository methods
  FirestoreNewsRepositoryImpl get firestoreRepo => _newsRepo;

  void _updateUI() {
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
