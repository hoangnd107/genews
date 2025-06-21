import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/data/utils/share_utils.dart';

class NewsWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Result newsData;

  const NewsWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.newsData,
  });

  @override
  State<NewsWebViewScreen> createState() => _NewsWebViewScreenState();
}

class _NewsWebViewScreenState extends State<NewsWebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Lỗi: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _toggleSaved() async {
    final bookmarksService = BookmarksService();
    setState(() {
      isSaved = !isSaved;
    });

    if (isSaved) {
      await bookmarksService.saveArticle(widget.newsData);
    } else {
      await bookmarksService.removeArticle(widget.newsData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Điểm tin"),
        actions: [
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaved,
            tooltip: isSaved ? 'Bỏ lưu' : 'Lưu',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              shareNewsLink(
                context: context,
                url: widget.url, // URL hiện tại của WebView
                title: widget.title,
              );
            },
            tooltip: 'Chia sẻ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsAnalysisScreen(newsData: widget.newsData),
            ),
          );
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text("Tóm tắt"),
        tooltip: 'Tóm tắt',
      ),
    );
  }
}

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
                errorWidget: (context, error, stackTrace) => Container(height: 180, color: Colors.grey[300]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundImage: CachedNetworkImageProvider(newsData.sourceIcon ?? ""),
                          ),
                          SizedBox(width: 8),
                          Text(
                            newsData.sourceName ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatPubDate(context, newsData.pubDate),
                        style: TextStyle(fontSize: 12),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: onViewAnalysis,
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'Tóm tắt',
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onSave,
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
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
                        icon: const Icon(Icons.share_outlined),
                        tooltip: 'Chia sẻ',
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

void _openNewsWebView(BuildContext context, Result newsData) {
  final url = newsData.link ?? newsData.sourceUrl ?? "";
  if (url.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Không có liên kết để mở.')),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NewsWebViewScreen(
        url: url,
        title: newsData.title ?? "Tin tức",
        newsData: newsData,
      ),
    ),
  );
}