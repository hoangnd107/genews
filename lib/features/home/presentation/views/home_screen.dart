import 'package:flutter/material.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/views/news_webview_screen.dart'
    as webview;
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/widgets/category_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/features/home/data/utils/share_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  final TextEditingController _searchController = TextEditingController();

  String? selectedCategory;
  bool _isSearchActive = false;
  String _searchQuery = '';
  int _currentCarouselIndex = 0;
  bool _isListView = true;
  bool _isSearching = false;
  List<Result> _searchResults = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initFetchNews();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
        _searchResults = [];
      }
    });
  }

  void _performSearch([String? query]) {
    final searchQuery = query ?? _searchController.text.trim();

    if (searchQuery.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _searchQuery = searchQuery;
      _isSearching = true;
    });

    final newsProvider = context.read<NewsProvider>();
    final allArticles = newsProvider.allNews.results ?? [];

    final searchResults = _getFilteredNews(allArticles, searchQuery);

    setState(() {
      _searchResults = searchResults;
      _isSearching = false;
    });

    _loadSavedStates(searchResults);
  }

  void _onSearchChanged(String query) {
    setState(() {}); // Update suffixIcon
    _performSearch(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
    });
  }

  List<Result> _getFilteredNews(List<Result> allNews, [String? searchQuery]) {
    List<Result> filtered = List.from(allNews);

    // Apply category filter
    if (selectedCategory != null) {
      filtered =
          filtered.where((article) {
            String articleCategory =
                (article.category ?? '').toString().toLowerCase();
            return articleCategory.contains(selectedCategory!.toLowerCase());
          }).toList();
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered =
          filtered.where((article) {
            final titleMatch =
                article.title?.toLowerCase().contains(query) ?? false;
            final descMatch =
                article.description?.toLowerCase().contains(query) ?? false;
            final sourceMatch =
                article.sourceName?.toLowerCase().contains(query) ?? false;

            return titleMatch || descMatch || sourceMatch;
          }).toList();
    }

    return filtered;
  }

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
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Consumer<NewsProvider>(
            builder: (context, newsState, child) {
              final allArticles = newsState.allNews.results ?? [];

              if (allArticles.isNotEmpty) {
                _loadSavedStates(allArticles);
              }

              return CustomScrollView(
                slivers: [
                  // Modern App Bar
                  _buildSliverAppBar(),

                  // Search Bar (when active)
                  if (_isSearchActive)
                    SliverToBoxAdapter(child: _buildSearchBar()),

                  // Content
                  SliverToBoxAdapter(
                    child: _buildContent(newsState, allArticles),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshNews,
          tooltip: 'Tải lại tin tức',
        ),
        IconButton(
          icon: Icon(
            _isSearchActive ? Icons.search_off : Icons.search,
            color: Colors.white,
          ),
          onPressed: _toggleSearch,
          tooltip: 'Tìm kiếm',
        ),
        IconButton(
          icon: Icon(
            _isListView ? Icons.grid_view : Icons.view_list,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isListView = !_isListView;
            });
          },
          tooltip: _isListView ? 'Xem dạng lưới' : 'Xem dạng danh sách',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {},
          tooltip: 'Thông báo',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        height: 20,
                        width: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
                      shaderCallback:
                          (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF0096FF), // 8%
                              Color(0xFF4D49FF), // 39%
                              Color(0xFF9600FF), // 88%
                              Color(0xFFB600DF), // 27%
                              Color(0xFFF6009F), // 69%
                              Color(0xFFFF0096), // 10%
                              Color(0xFFFF4D49), // 43%
                              Color(0xFFFF8D09), // 80%
                            ],
                            stops: [
                              0.08,
                              0.27,
                              0.39,
                              0.43,
                              0.69,
                              0.80,
                              0.88,
                              1.0,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: const Text(
                        'GeNews',
                        style: TextStyle(
                          color: Colors.white, // Base color for ShaderMask
                          fontFamily: 'Inter', // Modern, professional font
                          fontWeight: FontWeight.w700, // Bold but refined
                          fontSize: 26,
                          letterSpacing: -0.5, // Tight letter spacing
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e), // Dark navy blue
                Color(0xFF16213e), // Deep blue
                Color(0xFF0f3460), // Medium blue
                Color(0xFF533483),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tin tức...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 0,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 20,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onPressed: _clearSearch,
                    )
                    : null,
            isDense: true,
          ),
          onSubmitted: _performSearch,
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildContent(NewsProvider newsState, List<Result> allArticles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (newsState.newsViewState == ViewState.busy) {
      return Container(
        height: 300,
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (allArticles.isEmpty || newsState.newsViewState == ViewState.error) {
      return _buildErrorState();
    }

    // Show search results if searching
    if (_isSearchActive && _searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show main content
    return _buildMainContent(allArticles);
  }

  Widget _buildErrorState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 400,
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Lỗi lấy dữ liệu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Kiểm tra lại kết nối và thử lại",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshNews,
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Result> allArticles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredArticles = _getFilteredNews(allArticles);

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          // Featured Carousel Section
          if (allArticles.isNotEmpty && !_isSearchActive)
            _buildCarouselSection(allArticles),

          // Category Section
          _buildCategorySection(),

          // News Content
          _buildNewsContent(filteredArticles),
        ],
      ),
    );
  }

  Widget _buildCarouselSection(List<Result> allArticles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final carouselArticles = allArticles.take(8).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tin nổi bật',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCarouselSlider(carouselArticles),
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
            return _buildCarouselItem(article, index);
          },
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.3,
            viewportFraction: 0.8,
            enableInfiniteScroll: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
          ),
        ),
        const SizedBox(height: 12),
        // Enhanced Carousel indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              articles.asMap().entries.map((entry) {
                bool isActive = _currentCarouselIndex == entry.key;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 24.0 : 8.0,
                  height: 6.0,
                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.0),
                    color:
                        isActive
                            ? AppColors.primaryColor
                            : Colors.grey.shade400,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildCarouselItem(Result article, int index) {
    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.imageUrl ?? "",
                    fit: BoxFit.cover,
                    errorWidget:
                        (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                          ),
                        ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.sourceName ?? "Nguồn tin",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.title ?? "Không có tiêu đề",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                article.pubDate?.toString() ?? "Vừa xong",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }

  Widget _buildCategorySection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.orange.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Chuyên mục',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CategoryBar(
            selectedCategory: selectedCategory,
            onCategorySelected: _onCategorySelected,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsContent(List<Result> filteredArticles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (filteredArticles.isEmpty) {
      return Container(
        height: 300,
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selectedCategory != null
                    ? Icons.category_outlined
                    : Icons.article_outlined,
                size: 60,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                selectedCategory != null
                    ? "Không tìm thấy tin tức cho chuyên mục này"
                    : "Không có tin tức nào",
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                selectedCategory != null
                    ? "Thử chọn chuyên mục khác"
                    : "Vui lòng thử lại sau",
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCategory != null
                            ? 'Tin tức ${selectedCategory}'
                            : 'Tất cả tin tức',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        '${filteredArticles.length} bài viết',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // News List/Grid - THAY ĐỔI LOGIC
            _isListView
                ? _buildNewsListView(filteredArticles) // Danh sách dạng dòng
                : _buildNewsGridView(filteredArticles), // Lưới (mặc định)
          ],
        ),
      ),
    );
  }

  Widget _buildNewsGridView(List<Result> articles) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = articles[index];
        final articleId = article.articleId ?? article.link ?? '';
        final isSaved = _savedStates[articleId] ?? false;

        return GestureDetector(
          onTap: () => _openNewsWebView(article),
          child: NewsCard(
            newsData: article,
            onViewAnalysis: () => _openNewsAnalysis(article),
            onSave: () => _toggleSave(article),
            isSaved: isSaved,
          ),
        );
      },
    );
  }

  Widget _buildNewsListView(List<Result> articles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder:
          (context, index) => Divider(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
      itemBuilder: (context, index) {
        final article = articles[index];
        final articleId = article.articleId ?? article.link ?? '';
        final isSaved = _savedStates[articleId] ?? false;

        return _buildListRowItem(article, isSaved);
      },
    );
  }

  // Thêm method để dịch category sang tiếng Việt
  String _getCategoryDisplayName(String? category) {
    if (category == null || category.isEmpty) return "Khác";

    // Map dịch category
    final Map<String, String> categoryTranslations = {
      'business': 'Kinh doanh',
      'crime': 'Tội phạm',
      'domestic': 'Trong nước',
      'education': 'Giáo dục',
      'entertainment': 'Giải trí',
      'environment': 'Môi trường',
      'food': 'Ẩm thực',
      'health': 'Sức khỏe',
      'lifestyle': 'Đời sống',
      'politics': 'Chính trị',
      'science': 'Khoa học',
      'sports': 'Thể thao',
      'technology': 'Công nghệ',
      'top': 'Nổi bật',
      'tourism': 'Du lịch',
      'world': 'Thế giới',
      'other': 'Khác',
    };

    // Clean up category text và convert to lowercase for matching
    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

    // Try to find exact match first
    if (categoryTranslations.containsKey(cleanCategory)) {
      return categoryTranslations[cleanCategory]!;
    }

    // If no exact match, look for partial matches
    for (var entry in categoryTranslations.entries) {
      if (cleanCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, capitalize first letter of each word
    return cleanCategory
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');
  }

  // Cập nhật _buildListRowItem
  Widget _buildListRowItem(Result article, bool isSaved) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bên trái
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl ?? "",
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget:
                    (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 30,
                      ),
                    ),
              ),
            ),

            const SizedBox(width: 12),

            // Nội dung chính
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    article.title ?? "Không có tiêu đề",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Pub Date và Category (thay vì Source)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatTime(article.pubDate),
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Hiển thị Category thay vì Source
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getCategoryDisplayName(article.category?.toString()),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icon menu 3 chấm - CĂN GIỮA THEO CHIỀU DỌC
            SizedBox(
              height: 80, // Cùng chiều cao với ảnh
              child: Center(
                // Căn giữa theo chiều dọc
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 8,
                  offset: const Offset(-10, 0),
                  itemBuilder:
                      (BuildContext context) => [
                        // ĐỔI "Đọc bài viết" THÀNH "Chia sẻ"
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                Icons.ios_share,
                                size: 18,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chia sẻ',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'analysis',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tóm tắt',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'bookmark',
                          child: Row(
                            children: [
                              Icon(
                                isSaved
                                    ? Icons.bookmark_remove
                                    : Icons.bookmark_add,
                                size: 18,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isSaved ? 'Bỏ lưu' : 'Lưu',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'share':
                        _shareArticle(article); // Thêm function chia sẻ
                        break;
                      case 'analysis':
                        _openNewsAnalysis(article);
                        break;
                      case 'bookmark':
                        _toggleSave(article);
                        break;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thêm method chia sẻ
  void _shareArticle(Result article) {
//     final String shareText = '''
// 📰 ${article.title ?? 'Tin tức mới'}

// 🔗 ${article.link ?? ''}

// 📱 Chia sẻ từ GeNews
// ''';

//     // Import share_plus package nếu chưa có
//     // Hoặc sử dụng platform channels để chia sẻ
//     try {
//       // Share.ios_share(shareText);

//       // Tạm thời hiển thị dialog với nội dung chia sẻ
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Chia sẻ bài viết'),
//             content: SingleChildScrollView(child: Text(shareText)),
//             actions: [
//               TextButton(
//                 child: const Text('Đóng'),
//                 onPressed: () => Navigator.of(context).pop(),
//               ),
//               TextButton(
//                 child: const Text('Sao chép'),
//                 onPressed: () {
//                   // Clipboard.setData(ClipboardData(text: shareText));
//                   Navigator.of(context).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Đã sao chép vào clipboard'),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Không thể chia sẻ bài viết'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
    shareNewsLink(context: context, url: article.link, title: article.title);
  }

  // Thêm helper method để format time nếu chưa có
  String _formatTime(DateTime? pubDate) {
    if (pubDate == null) return "Vừa xong";

    try {
      final Duration difference = DateTime.now().difference(pubDate);

      if (difference.inMinutes < 60) {
        return "${difference.inMinutes} phút trước";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} giờ trước";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} ngày trước";
      } else {
        return "${pubDate.day}/${pubDate.month}/${pubDate.year}";
      }
    } catch (e) {
      return "Vừa xong";
    }
  }

  // Cập nhật phần search results cũng theo logic mới
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_searchResults.isEmpty) {
      return Container(
        height: 300,
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy kết quả cho "$_searchQuery"',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thử tìm kiếm với từ khóa khác',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search results header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_searchResults.length} kết quả cho "$_searchQuery"',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search results content - THAY ĐỔI LOGIC
            _isListView
                ? _buildSearchResultsListView()
                : _buildSearchResultsGridView(),
          ],
        ),
      ),
    );
  }

  // Đổi tên search results methods
  Widget _buildSearchResultsGridView() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        final articleId = article.articleId ?? article.link ?? '';
        final isSaved = _savedStates[articleId] ?? false;

        return GestureDetector(
          onTap: () => _openNewsWebView(article),
          child: NewsCard(
            newsData: article,
            onViewAnalysis: () => _openNewsAnalysis(article),
            onSave: () => _toggleSave(article),
            isSaved: isSaved,
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsListView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      separatorBuilder:
          (context, index) => Divider(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            height: 1,
          ),
      itemBuilder: (context, index) {
        final article = _searchResults[index];
        final articleId = article.articleId ?? article.link ?? '';
        final isSaved = _savedStates[articleId] ?? false;

        return _buildListRowItem(article, isSaved);
      },
    );
  }
}
