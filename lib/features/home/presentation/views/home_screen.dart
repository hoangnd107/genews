import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/widgets/category_bar.dart';
import 'package:genews/features/shared/widgets/search_bar_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  String? selectedCategory;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initFetchNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _initFetchNews() {
    final newsProvider = context.read<NewsProvider>();
    if (newsProvider.allNews.results == null ||
        newsProvider.allNews.results!.isEmpty ||
        newsProvider.newsViewState == ViewState.error) {
      newsProvider.fetchNews();
    }
  }

  _refreshNews() {
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

  void _onCategorySelected(String category) {
    setState(() {
      if (selectedCategory == category) {
        selectedCategory = null;
      } else {
        selectedCategory = category;
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<Result> _getFilteredNews(List<Result> allNews) {
    // First filter by category
    List<Result> categoryFiltered = selectedCategory == null
      ? allNews
      : allNews.where((article) {
          String articleCategory = (article.category ?? '').toString().toLowerCase();
          return articleCategory.contains(selectedCategory!.toLowerCase());
        }).toList();

    // Then filter by search query
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    final query = _searchQuery.toLowerCase();
    return categoryFiltered.where((article) {
      final titleMatch = article.title?.toLowerCase().contains(query) ?? false;
      final descMatch = article.description?.toLowerCase().contains(query) ?? false;
      final sourceMatch = article.sourceName?.toLowerCase().contains(query) ?? false;

      return titleMatch || descMatch || sourceMatch;
    }).toList();
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
            icon: Icon(Icons.refresh),
            onPressed: _refreshNews,
            tooltip: 'Tải lại tin tức',
          ),
          IconButton(
            icon: Icon(_isSearchActive ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),

      body: Consumer<NewsProvider>(
        builder: (context, newsState, child) {
          if (newsState.newsViewState == ViewState.busy) {
            return Center(child: CircularProgressIndicator());
          }

          final allArticles = newsState.allNews.results ?? [];

          if (allArticles.isNotEmpty) {
            _loadSavedStates(allArticles);
          }

          if (allArticles.isEmpty || newsState.newsViewState == ViewState.error) {
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
                    onPressed: _refreshNews,
                    icon: Icon(Icons.refresh),
                    label: Text("Thử lại"),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
                  ),
                ],
              ),
            );
          }

          final filteredArticles = _getFilteredNews(allArticles);

          return Column(
            children: [
              if (_isSearchActive)
                NewsSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  hintText: 'Tìm kiếm ...',
                ),

              // if (!_isSearchActive)
              //   CategoryBar(
              //     selectedCategory: selectedCategory,
              //     onCategorySelected: _onCategorySelected,
              //   ),

              CategoryBar(
                selectedCategory: selectedCategory,
                onCategorySelected: _onCategorySelected,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: filteredArticles.isEmpty
                    ? Center(
                        child: Text(
                          _isSearchActive && _searchQuery.isNotEmpty
                            ? "Không tìm thấy tin tức phù hợp với tìm kiếm"
                            : "Không tìm thấy tin tức cho chuyên mục này",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredArticles.length,
                        itemBuilder: (context, index) {
                          final data = filteredArticles[index];
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
                            isSaved: isSaved,
                          );
                        },
                      ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}