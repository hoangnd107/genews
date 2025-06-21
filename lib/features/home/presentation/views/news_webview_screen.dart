import 'package:flutter/material.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';

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
  bool _isBookmarked = false; // Thêm biến trạng thái
  final BookmarksService _bookmarksService = BookmarksService(); // Khởi tạo service

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked(); // Kiểm tra trạng thái bookmark khi khởi tạo
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

  // Hàm kiểm tra xem tin tức đã được bookmark chưa
  void _checkIfBookmarked() async {
    final isSaved = await _bookmarksService.isArticleSaved(
        (widget.newsData.articleId ?? "") as Result);
    if (mounted) { // Kiểm tra widget còn mounted không trước khi gọi setState
      setState(() {
        _isBookmarked = isSaved;
      });
    }
  }

  void _toggleBookmark() async {
    bool successfullyToggled;
    String message;

    if (_isBookmarked) {
      // Nếu đã bookmark, thì thực hiện hủy bookmark
      successfullyToggled =
      await _bookmarksService.removeArticle((widget.newsData.articleId ?? "") as Result);
      message = successfullyToggled ? 'Đã bỏ lưu tin tức' : 'Lỗi khi bỏ lưu';
    } else {
      // Nếu chưa bookmark, thì thực hiện lưu
      successfullyToggled =
      await _bookmarksService.saveArticle(widget.newsData);
      message = successfullyToggled
          ? 'Đã lưu tin tức'
          : 'Tin tức này đã được lưu trước đó hoặc có lỗi';
    }

    if (successfullyToggled) {
      setState(() {
        _isBookmarked = !_isBookmarked; // Cập nhật trạng thái
      });
    }

    if (mounted) { // Kiểm tra widget còn mounted không
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết tin tức"),
        actions: [
          IconButton(
            // Sử dụng _isBookmarked để chọn icon và tooltip
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () {
              _toggleBookmark(); // Gọi hàm toggle bookmark
            },
            tooltip: _isBookmarked ? 'Bỏ lưu tin tức' : 'Lưu tin tức',
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NewsAnalysisScreen(newsData: widget.newsData),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        tooltip: 'Tóm tắt tin tức',
        child: const Icon(Icons.summarize),
      ),
    );
  }
}