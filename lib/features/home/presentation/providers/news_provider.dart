import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/repository/news_api_repository.dart';

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

  Future<void> generateAnalysis(String content) async {
    if (content.isEmpty) return;
    newsAnalysisState = ViewState.busy;
    _updateUI();

    try {
      final newsResult = await _newsRepo.generateNewsAiAnalysis(content);

      analysis = newsResult;
      socialMediaPost = "";
      generatedVideoScript = "";
      newsAnalysisState = ViewState.success;
      _updateUI();
    } catch (e) {
      newsAnalysisState = ViewState.error;
      _updateUI();
      log(e.toString());
    }
  }

  void _updateUI() {
    Future.delayed(const Duration(seconds: 1), () {
      notifyListeners();
    });
  }
}
