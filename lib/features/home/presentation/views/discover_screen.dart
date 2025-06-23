import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  String _searchQuery = '';
  List<Result> _searchResults = [];
  bool _isSearching = false;
  int _currentCarouselIndex = 0;

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

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    final newsProvider = context.read<NewsProvider>();
    final allArticles = newsProvider.allNews.results ?? [];

    final searchResults = _getFilteredNews(allArticles, query);

    setState(() {
      _searchResults = searchResults;
      _isSearching = false;
    });

    // Load saved states for search results
    _loadSavedStates(searchResults);

    // Close keyboard after search
    FocusManager.instance.primaryFocus?.unfocus();
  }

  List<Result> _getFilteredNews(List<Result> allNews, String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allNews.where((article) {
      final titleMatch = article.title?.toLowerCase().contains(lowerQuery) ?? false;
      final descMatch = article.description?.toLowerCase().contains(lowerQuery) ?? false;
      final sourceMatch = article.sourceName?.toLowerCase().contains(lowerQuery) ?? false;
      final categoryMatch = article.category?.toString().toLowerCase().contains(lowerQuery) ?? false;

      return titleMatch || descMatch || sourceMatch || categoryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // Handle notification tap
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Consumer<NewsProvider>(
          builder: (context, newsState, child) {
            final allArticles = newsState.allNews.results ?? [];

            if (allArticles.isNotEmpty) {
              _loadSavedStates(allArticles);
            }

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm tin tức...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _searchResults = [];
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _performSearch,
                          ),
                        ],
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),

                // Content area
                Expanded(
                  child: _buildContent(newsState, allArticles),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(NewsProvider newsState, List<Result> allArticles) {
    if (newsState.newsViewState == ViewState.busy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (allArticles.isEmpty || newsState.newsViewState == ViewState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              "Lỗi lấy dữ liệu.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Kiểm tra lại kết nối và thử lại.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<NewsProvider>().fetchNews(),
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            ),
          ],
        ),
      );
    }

    // Show search results if searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show default content with carousel
    return _buildDefaultContent(allArticles);
  }

  Widget _buildDefaultContent(List<Result> allArticles) {
    // Get top articles for carousel (first 5 articles)
    final topArticles = allArticles.take(5).toList();

    // Get trending articles for list (remaining articles)
    final trendingArticles = allArticles.skip(5).take(10).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel Section
          if (topArticles.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Tin nổi bật',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildCarouselSlider(topArticles),
            const SizedBox(height: 20),
          ],

          // Trending Section
          if (trendingArticles.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Xu hướng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildTrendingList(trendingArticles),
          ],

          if (topArticles.isEmpty && trendingArticles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Nơi tìm kiếm, xem các chủ đề thịnh hành và khám phá nguồn tin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCarouselSlider(List<Result> articles) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: articles.length,
          itemBuilder: (context, index, realIndex) {
            final article = articles[index];
            return _buildCarouselItem(article);
          },
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 10),
        // Carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: articles.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentCarouselIndex == entry.key
                    ? AppColors.primaryColor
                    : Colors.grey.shade400,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Result article) {
    return GestureDetector(
      onTap: () => _openNewsWebView(article), // Thay đổi ở đây
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: article.imageUrl ?? "",
                fit: BoxFit.cover,
                errorWidget: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      // ignore: deprecated_member_use
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title ?? "Không có tiêu đề",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          article.sourceName ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          article.pubDate?.toString() ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingList(List<Result> articles) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        final articleId = article.articleId ?? article.link ?? '';
        final isSaved = _savedStates[articleId] ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: GestureDetector(
            onTap: () => _openNewsWebView(article),
            child: NewsCard(
              newsData: article,
              onViewAnalysis: () => _openNewsAnalysis(article), // Giữ nguyên cho nút phân tích
              onSave: () => _toggleSave(article),
              isSaved: isSaved,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              'Không tìm thấy kết quả cho "$_searchQuery"',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            const Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${_searchResults.length} kết quả cho "$_searchQuery"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final article = _searchResults[index];
              final articleId = article.articleId ?? article.link ?? '';
              final isSaved = _savedStates[articleId] ?? false;
              return GestureDetector(
                onTap: () => _openNewsWebView(article),
                child: NewsCard(
                  newsData: article,
                  onViewAnalysis: () => _openNewsAnalysis(article), // Giữ nguyên cho nút phân tích
                  onSave: () => _toggleSave(article),
                  isSaved: isSaved,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Thêm function mới để mở NewsWebViewScreen
  void _openNewsWebView(Result article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsWebViewScreen(
          url: article.link ?? "",
          title: article.title ?? "",
          newsData: article,
        ),
      ),
    );
  }

  // Giữ nguyên function này cho nút phân tích
  void _openNewsAnalysis(Result article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsAnalysisScreen(newsData: article),
      ),
    );
  }
}