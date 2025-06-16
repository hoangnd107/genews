import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:news_bite_ai/features/home/data/models/news_data_model.dart';
import 'package:news_bite_ai/features/home/presentation/views/news_analysis_screen.dart';
import 'package:news_bite_ai/shared/styles/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết tin tức"),
        actions: [
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
              builder: (context) => NewsAnalysisScreen(newsData: widget.newsData),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.summarize),
        tooltip: 'Tóm tắt tin tức',
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final Result newsData;
  final VoidCallback onViewAnalysis;
  const NewsCard({super.key, required this.newsData, required this.onViewAnalysis});

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
                          SizedBox(width: 10),
                          Text(
                            newsData.sourceName ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueAccent),
                          ),
                        ],
                      ),

                      Text(
                        DateFormat.MMMEd().format(newsData.pubDate ?? DateTime.now()),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // News Title
                  Text(
                    newsData.title ?? "",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    newsData.description ?? "",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // ElevatedButton.icon(
                      //   onPressed: () => _openNewsWebView(context, newsData),
                      //   label: Text("Xem online"),
                      //   icon: Icon(Icons.open_in_browser),
                      //   style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                      // ),

                      // TextButton(
                      ElevatedButton.icon(
                        onPressed: onViewAnalysis,
                        label: Text("Tóm tắt tin tức"),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
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
  if (url.isEmpty) return;

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NewsWebViewScreen(
        url: url,
        title: newsData.title ?? "News Article",
        newsData: newsData,
      ),
    ),
  );
}