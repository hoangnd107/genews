import 'package:flutter/material.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarksService _bookmarksService = BookmarksService();
  late Future<List<Result>> _savedArticlesFuture;

  @override
  void initState() {
    super.initState();
    _loadSavedArticles();
  }

  void _loadSavedArticles() {
    _savedArticlesFuture = _bookmarksService.getSavedArticles();
  }

  void _navigateToSummary(Result article) {
    // Navigate to summary screen
  }

  void _removeBookmark(Result article) async {
    await _bookmarksService.removeArticle(article);
    setState(() {
      _loadSavedArticles();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa khỏi danh sách lưu')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin đã lưu'),
      ),
      body: FutureBuilder<List<Result>>(
        future: _savedArticlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Chưa có tin tức nào được lưu'),
            );
          }

          final savedArticles = snapshot.data!;
          return ListView.builder(
            itemCount: savedArticles.length,
            itemBuilder: (context, index) {
              final article = savedArticles[index];
              return NewsCard(
                newsData: article,
                onViewAnalysis: () => _navigateToSummary(article),
                onSave: () => _removeBookmark(article),
                isSaved: true,
              );
            },
          );
        },
      ),
    );
  }
}