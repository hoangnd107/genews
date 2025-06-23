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

  final ai.GenerativeModel _model = ai.GenerativeModel(
    model: "gemini-2.5-pro-preview-06-05",
    apiKey: apiKeyGemini,
  );
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

  @override
  Future<String> generateNewsAiAnalysis(String content) async {
    final prompt = """
Phân tích và tóm tắt tin tức sau theo định dạng yêu cầu, chỉ trả về nội dung tóm tắt, không thêm bất kỳ lời giới thiệu hay kết thúc nào:

"$content"

Định dạng trả về:

1. TÓM TẮT CHÍNH
- Sự kiện/vấn đề chính trong 2-3 câu
- Điểm nhấn quan trọng nhất

2. CÁC ĐIỂM NỔI BẬT
- 3-4 thông tin quan trọng
- Số liệu, dữ liệu cụ thể (nếu có)
- Tác động đến cộng đồng/xã hội

3. BỐI CẢNH & Ý NGHĨA
- Nguyên nhân dẫn đến sự kiện
- Ảnh hưởng tiềm tàng
- Liên quan đến xu hướng lớn

4. KẾT LUẬN
- Đánh giá tổng quan
- Hướng phát triển có thể

Yêu cầu:
- Chỉ trả về nội dung tóm tắt theo định dạng trên
- Ngôn ngữ Tiếng Việt tự nhiên, dễ hiểu
- Không sử dụng ký tự đặc biệt như **, ##, ***
- Sử dụng số thứ tự và dấu gạch ngang để phân chia
- Tối đa 300 từ
- Giọng văn khách quan, chuyên nghiệp
- KHÔNG thêm lời mở đầu hay kết thúc""";

    return await _generateContent(prompt);
  }
}
