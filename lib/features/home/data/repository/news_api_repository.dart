import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:news_bite_ai/core/constants.dart';
import 'package:news_bite_ai/features/home/data/models/news_data_model.dart';
import 'package:offline_first_support/offline_first.dart';

abstract class NewsApiRepository {
  Future<NewsDataModel> fetchTrendingNews();
  Future<String> generateNewsAiAnalysis(String content);
  Future<String> generateNewsAiSocialContents(String content);
  Future<String> generateNewsAiVideoScript(String content);
  Future<void> generateNewsAiVideo(String videoScript);
}

class NewsApiRepositoryImpl implements NewsApiRepository {
  final _offlineFirst = OfflineFirst();

  final ai.GenerativeModel _model = ai.GenerativeModel(model: "gemini-2.5-pro-preview-06-05", apiKey: apiKeyGemini);
  @override
  Future<NewsDataModel> fetchTrendingNews() async {
    final result = await _offlineFirst.fetchData(
      urlPath: newsUrl,
      fetchPolicy: OfflineFirstFetchPolicy.networkOnly,
      debugMode: kDebugMode,
    );

    if (result.status) {
      return NewsDataModel.fromJson(json.decode(result.data));
    } else {
      throw Exception("❌ Lỗi: ${result.message}");
    }
  }

  Future<String> _generateContent(String prompt) async {
    final result = await _offlineFirst.fetchData(urlPath: prompt, fetchPolicy: OfflineFirstFetchPolicy.networkOnly);

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

  @override
  Future<String> generateNewsAiAnalysis(String content) async {
    final prompt = """
      Tạo một bản tóm tắt ngắn, phân loại và những hiểu biết chính cho tin tức xu hướng này: $content
      Vui lòng trả về kết quả mà không cần định dạng **
    """;
    return await _generateContent(prompt);
  }

  @override
  Future<String> generateNewsAiSocialContents(String content) async {
    final prompt = "Generate a short social media post for this news: $content";
    return await _generateContent(prompt);
  }

  @override
  Future<void> generateNewsAiVideo(String videoScript) async {
    // TODO: implement generateNewsAiVideo
    throw UnimplementedError();
  }

  @override
  Future<String> generateNewsAiVideoScript(String content) async {
    final prompt = "Generate a short video script for this news: $content";
    return await _generateContent(prompt);
  }
}
