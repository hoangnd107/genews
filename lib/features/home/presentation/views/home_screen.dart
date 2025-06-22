import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  
  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  _fetchNews() {
    context.read<NewsProvider>().fetchNews();
  }

  Future<void> _loadSavedStates(List<Result> articles) async {
    for (var article in articles) {
      final articleId = article.articleId ?? article.link ?? '';
      if (articleId.isNotEmpty) {
        final isSaved = await _bookmarksService.isArticleSaved(article);
        if (mounted) {
          setState(() {
            _savedStates[articleId] = isSaved;
          });
        }
      }
    }
  }

  void _toggleSave(Result article) async {
    final articleId = article.articleId ?? article.link ?? '';
    final isSaved = await _bookmarksService.toggleSave(article);
    
    setState(() {
      _savedStates[articleId] = isSaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/icon/icon.png',
              height: 24,
              width: 24,
            ),
            SizedBox(width: 8),
            Text("GeNews", style: TextStyle(fontSize: 20)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Handle search functionality
              // You can show search dialog or navigate to search screen
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notification tap
              // You can navigate to a notifications screen here
            },
          ),
        ],
      ),

      body: Consumer<NewsProvider>(
        builder: (context, newsState, child) {
          if (newsState.newsViewState == ViewState.busy) {
            return Center(child: CircularProgressIndicator());
          }
          
          final articles = newsState.allNews.results ?? [];
          
          // Load saved states when we have articles
          if (articles.isNotEmpty) {
            _loadSavedStates(articles);
          }
          
          if (articles.isEmpty || newsState.newsViewState == ViewState.error) {
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
              itemCount: articles.length,
              itemBuilder: (context, index) {
                final data = articles[index];
                final articleId = data.articleId ?? data.link ?? '';
                final isSaved = _savedStates[articleId] ?? false;
                
                return NewsCard(
                  newsData: data,
                  onViewAnalysis: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NewsAnalysisScreen(newsData: data)),
                    );
                  },
                  onSave: () => _toggleSave(data),
                  isSaved: isSaved, // Pass saved state to NewsCard
                );
              },
            ),
          );
        },
      ),
    );
  }
}