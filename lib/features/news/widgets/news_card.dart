import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/views/news_webview_screen.dart';
import 'package:genews/shared/services/offline_news_service.dart';
import 'package:genews/shared/utils/share_utils.dart';

class NewsCard extends StatelessWidget {
  final Result newsData;
  final VoidCallback onViewAnalysis;
  final VoidCallback onSave;
  final bool isSaved;

  const NewsCard({
    super.key,
    required this.newsData,
    required this.onViewAnalysis,
    required this.onSave,
    this.isSaved = false,
  });

  String _translateCategory(dynamic category) {
    if (category == null) return "";
    if (category is List && category.isNotEmpty) {
      for (var cat in category) {
        if (_isVietnamese(cat.toString())) return cat.toString();
      }
      return _categoryMapToVietnamese(category.first.toString());
    }
    if (category is String) {
      if (_isVietnamese(category)) return category;
      return _categoryMapToVietnamese(category);
    }
    return "";
  }

  String _categoryMapToVietnamese(String category) {
    final Map<String, String> categoryTranslations = {
      'business': 'Kinh doanh',
      'education': 'Giáo dục',
      'entertainment': 'Giải trí',
      'environment': 'Môi trường',
      'food': 'Ẩm thực',
      'health': 'Sức khỏe',
      'lifestyle': 'Đời sống',
      'politics': 'Chính trị',
      'science': 'Khoa học',
      'sports': 'Thể thao',
      'technology': 'Công nghệ',
      'top': 'Nổi bật',
      'tourism': 'Du lịch',
      'world': 'Thế giới',
      'other': 'Khác',
    };
    final clean =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    if (categoryTranslations.containsKey(clean))
      return categoryTranslations[clean]!;
    for (var entry in categoryTranslations.entries) {
      if (clean.contains(entry.key)) return entry.value;
    }
    return category;
  }

  // Helper method to check if text contains Vietnamese characters
  bool _isVietnamese(String text) {
    // Check for Vietnamese-specific characters
    final vietnameseRegex = RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
    );
    return vietnameseRegex.hasMatch(text);
  }

  String _formatPubDate(BuildContext context, DateTime? pubDateTime) {
    if (pubDateTime == null) {
      return "Không rõ ngày";
    }
    try {
      final formatter = DateFormat("EEEE, dd MMMM, yyyy", 'vi_VN');
      return formatter.format(pubDateTime);
    } catch (e) {
      debugPrint("Lỗi format ngày tháng: $e.");
      return DateFormat('dd/MM/yyyy').format(pubDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openNewsWebView(context, newsData),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: newsData.imageUrl ?? "",
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorWidget:
                    (context, error, stackTrace) =>
                        Container(height: 180, color: Colors.grey[300]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source và Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: CachedNetworkImageProvider(
                              newsData.sourceIcon ?? "",
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            newsData.sourceName ?? "",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      if (newsData.category != null)
                        Text(
                          _translateCategory(newsData.category),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // News Title
                  Text(
                    newsData.title ?? "Không có tiêu đề",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    newsData.description ?? "",
                    style: TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),

                  // PubDate và Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // PubDate thay thế category
                      Expanded(
                        child: Text(
                          _formatPubDate(context, newsData.pubDate),
                          style: TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: onViewAnalysis,
                            icon: const Icon(Icons.bolt, color: Colors.orange),
                            tooltip: 'Tóm tắt',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: onSave,
                            icon: Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_border,
                            ),
                            tooltip: isSaved ? 'Bỏ lưu' : 'Lưu',
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () {
                              shareNewsLink(
                                context: context,
                                url: newsData.link ?? newsData.sourceUrl,
                                title: newsData.title,
                              );
                            },
                            icon: const Icon(Icons.ios_share),
                            tooltip: 'Chia sẻ',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openNewsWebView(BuildContext context, Result newsData) async {
  final url = newsData.link ?? newsData.sourceUrl ?? "";
  if (url.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không có liên kết để mở.')));
    return;
  }

  // Check internet connection before opening webview
  final offlineService = OfflineNewsService.instance;
  final hasInternet = await offlineService.hasInternetConnection();

  if (!hasInternet) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cần kết nối internet để xem nội dung chi tiết'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (context) => NewsWebViewScreen(
            url: url,
            title: newsData.title ?? "Tin tức",
            newsData: newsData,
          ),
    ),
  );
}
