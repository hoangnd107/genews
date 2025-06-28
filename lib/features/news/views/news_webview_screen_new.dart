import 'package:flutter/material.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/shared/utils/share_utils.dart';

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
    _controller =
        WebViewController()
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
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaved,
            tooltip: isSaved ? 'Bỏ lưu' : 'Lưu',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              shareNewsLink(
                context: context,
                url: widget.url, // URL hiện tại của WebView
                title: widget.title,
              );
            },
            tooltip: 'Chia sẻ',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NewsAnalysisScreen(newsData: widget.newsData),
            ),
          );
        },
        tooltip: 'Tóm tắt',
        child: const Icon(Icons.bolt, color: Colors.orange),
      ),
    );
  }
}
