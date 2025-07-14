import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:genews/app/config/enums.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/data/repository/firestore_news_repository.dart';

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

  final Map<String, String> _analysisCache = {};

  String _getAnalysisCacheKey(String content) {
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

  Future<void> fetchTrendingNews() async {
    return fetchNews();
  }

  generateSummary(String content) async {
    try {
      final cacheKey = _getAnalysisCacheKey(content);

      if (_analysisCache.containsKey(cacheKey)) {
        analysis = _analysisCache[cacheKey]!;
        newsAnalysisState = ViewState.success;
        notifyListeners();
        return;
      }

      newsAnalysisState = ViewState.busy;
      notifyListeners();

      final result = await _newsRepo.generateNewsAiAnalysis(content);

      _analysisCache[cacheKey] = result;
      analysis = result;
      newsAnalysisState = ViewState.success;
    } catch (e) {
      analysis = "";
      newsAnalysisState = ViewState.error;
    }
    notifyListeners();
  }

  regenerateAnalysis(String content) async {
    try {
      final cacheKey = _getAnalysisCacheKey(content);

      newsAnalysisState = ViewState.busy;
      notifyListeners();

      final result = await _newsRepo.generateNewsAiAnalysis(content);

      _analysisCache[cacheKey] = result;
      analysis = result;
      newsAnalysisState = ViewState.success;
    } catch (e) {
      analysis = "";
      newsAnalysisState = ViewState.error;
    }
    notifyListeners();
  }

  void clearAnalysisCache() {
    _analysisCache.clear();
  }

  Future<void> fetchNewsByCategory(String category) async {
    newsViewState = ViewState.busy;
    _updateUI();

    try {
      final queryCategory = category;
      final articles = await _newsRepo.getArticlesByCategory(queryCategory);

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

  FirestoreNewsRepositoryImpl get firestoreRepo => _newsRepo;

  void _updateUI() {
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
