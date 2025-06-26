import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/data/repository/news_api_repository.dart';

class NewsProvider extends ChangeNotifier {
  final _newsRepo = NewsApiRepositoryImpl();

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

  void _updateUI() {
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
