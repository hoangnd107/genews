import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  _fetchNews() {
    context.read<NewsProvider>().fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tin tức hot"), centerTitle: false),

      body: Consumer<NewsProvider>(
        builder: (context, newsState, child) {
          if (newsState.newsViewState == ViewState.busy) {
            return Center(child: CircularProgressIndicator());
          }
          if ((newsState.allNews.results ?? []).isEmpty || newsState.newsViewState == ViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 10),
                  Text(
                    "Lỗi lấy dữ liệu.",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Kiểm tra lại kết nối và thử lại.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _fetchNews,
                    icon: Icon(Icons.refresh),
                    label: Text("Thử lại"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              itemCount: (newsState.allNews.results ?? []).length,
              itemBuilder: (context, index) {
                final data = (newsState.allNews.results ?? [])[index];
                return NewsCard(
                  newsData: data,
                  onViewAnalysis: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewsAnalysisScreen(newsData: data)),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
