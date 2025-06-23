import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/views/news_webview_screen.dart'
    as webview; // Thêm import này
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/widgets/category_bar.dart';
import 'package:genews/features/shared/widgets/search_bar_widget.dart';
import 'package:carousel_slider/carousel_slider.dart'; // Thêm import này
import 'package:cached_network_image/cached_network_image.dart'; // Thêm import này

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
  int _currentCarouselIndex = 0; // Thêm biến này

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
    List<Result> categoryFiltered =
        selectedCategory == null
            ? allNews
            : allNews.where((article) {
              String articleCategory =
                  (article.category ?? '').toString().toLowerCase();
              return articleCategory.contains(selectedCategory!.toLowerCase());
            }).toList();

    // Then filter by search query
    if (_searchQuery.isEmpty) {
      return categoryFiltered;
    }

    final query = _searchQuery.toLowerCase();
    return categoryFiltered.where((article) {
      final titleMatch = article.title?.toLowerCase().contains(query) ?? false;
      final descMatch =
          article.description?.toLowerCase().contains(query) ?? false;
      final sourceMatch =
          article.sourceName?.toLowerCase().contains(query) ?? false;

      return titleMatch || descMatch || sourceMatch;
    }).toList();
  }

  // Thêm function mở NewsWebViewScreen
  void _openNewsWebView(Result article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => webview.NewsWebViewScreen(
              url: article.link ?? "",
              title: article.title ?? "",
              newsData: article,
            ),
      ),
    );
  }

  // Thêm function mở NewsAnalysisScreen
  void _openNewsAnalysis(Result article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsAnalysisScreen(newsData: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/icon/icon.png', height: 24, width: 24),
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

          if (allArticles.isEmpty ||
              newsState.newsViewState == ViewState.error) {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredArticles = _getFilteredNews(allArticles);

          return Column(
            children: [
              // Search bar cố định ở trên
              if (_isSearchActive)
                NewsSearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                  hintText: 'Tìm kiếm ...',
                ),

              // Phần scrollable bao gồm Carousel, Category và News List
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Carousel Section
                    if (allArticles.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildCarouselSection(allArticles),
                      ),

                    // Category Bar với title
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            child: Text(
                              'Chuyên mục',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CategoryBar(
                            selectedCategory: selectedCategory,
                            onCategorySelected: _onCategorySelected,
                          ),
                          const SizedBox(
                            height: 10,
                          ), // Thêm khoảng cách dưới category
                        ],
                      ),
                    ),

                    // News List
                    filteredArticles.isEmpty
                        ? SliverToBoxAdapter(
                          child: Container(
                            height: 200,
                            child: Center(
                              child: Text(
                                _isSearchActive && _searchQuery.isNotEmpty
                                    ? "Không tìm thấy tin tức phù hợp với tìm kiếm"
                                    : "Không tìm thấy tin tức cho chuyên mục này",
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        )
                        : SliverPadding(
                          padding: const EdgeInsets.all(10),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final data = filteredArticles[index];
                              final articleId =
                                  data.articleId ?? data.link ?? '';
                              final isSaved = _savedStates[articleId] ?? false;

                              return GestureDetector(
                                onTap: () => _openNewsWebView(data),
                                child: NewsCard(
                                  newsData: data,
                                  onViewAnalysis: () => _openNewsAnalysis(data),
                                  onSave: () => _toggleSave(data),
                                  isSaved: isSaved,
                                ),
                              );
                            }, childCount: filteredArticles.length),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Cập nhật Widget cho Carousel Section (bỏ padding để tránh duplicate)
  Widget _buildCarouselSection(List<Result> allArticles) {
    final carouselArticles =
        allArticles.take(10).toList(); // Lấy 10 tin đầu tiên

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Tin nổi bật',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          _buildCarouselSlider(carouselArticles),
          const SizedBox(height: 10), // Thêm spacing dưới carousel
        ],
      ),
    );
  }

  // Thêm Widget cho Carousel Slider
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
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.3, // Tăng độ phóng to của item ở giữa
            viewportFraction: 0.8, // Giảm để hiển thị phần của item bên cạnh
            enableInfiniteScroll: true,
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
          children:
              articles.asMap().entries.map((entry) {
                return Container(
                  width:
                      _currentCarouselIndex == entry.key
                          ? 24.0
                          : 8.0, // Thay đổi width cho indicator active
                  height: 6.0, // Giảm height để tạo hình chữ nhật
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.0), // Bo góc
                    color:
                        _currentCarouselIndex == entry.key
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Thêm Widget cho Carousel Item với hiệu ứng scale
  Widget _buildCarouselItem(Result article) {
    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ), // Tăng margin để tạo khoảng cách
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
                errorWidget:
                    (context, error, stackTrace) => Container(
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
                        Expanded(
                          child: Text(
                            article.sourceName ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
}
