import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/views/news_webview_screen.dart';
import 'package:genews/shared/services/offline_news_service.dart';
import 'package:genews/shared/utils/share_utils.dart';
import 'package:genews/shared/services/category_mapping_service.dart';

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

  // Hàm duy nhất để hiển thị category
  String _getCategoryDisplayName(dynamic category) {
    return CategoryMappingService.toVietnamese(category);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBackgroundColor =
        isDark
            ? Color.alphaBlend(
              theme.colorScheme.secondaryContainer.withOpacity(0.18),
              theme.colorScheme.surface,
            )
            : theme.colorScheme.surface;
    final categoryTextColor =
        isDark
            ? theme.colorScheme.primary.withOpacity(0.85)
            : theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _openNewsWebView(context, newsData),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: cardBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
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
                      SizedBox(width: 8),
                      if (newsData.category != null)
                        Text(
                          _getCategoryDisplayName(newsData.category),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: categoryTextColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // News Title
                  Text(
                    newsData.title ?? "Không có tiêu đề",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    newsData.description ?? "",
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // PubDate và Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatPubDate(context, newsData.pubDate),
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
