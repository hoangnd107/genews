import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import 'package:genews/core/constants.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:offline_first_support/offline_first.dart';

abstract class NewsApiRepository {
  Future<NewsDataModel> fetchTrendingNews();
  Future<String> generateNewsAiAnalysis(String content);
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
      Tạo một bản tóm tắt, thể loại và những thông tin chính cho tin tức xu hướng này: $content.
      Lưu ý khi trả kết quả: Chỉ trả về nội dung, không thêm phản hồi cho yêu cầu này, không sử dụng định dạng **, cho phép dùng số và dấu "-" để phân tách các mục.
    """;
    return await _generateContent(prompt);
  }
}
