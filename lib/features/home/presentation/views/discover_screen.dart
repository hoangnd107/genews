import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:genews/core/enums.dart';
import 'package:genews/features/home/presentation/providers/news_provider.dart';
import 'package:genews/features/home/data/models/news_data_model.dart';
import 'package:genews/features/home/data/services/bookmarks_service.dart';
import 'package:genews/features/home/presentation/widgets/news_card.dart';
import 'package:genews/features/home/presentation/views/news_summary_screen.dart';
import 'package:genews/features/home/presentation/views/news_webview_screen.dart'
    as webview;
import 'package:genews/features/home/presentation/views/category_news_screen.dart';
import 'package:genews/shared/styles/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/features/home/data/utils/share_utils.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // Map dịch category giống NewsCard
  static final Map<String, String> _categoryTranslations = {
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

  // Map màu sắc cho từng category
  static final Map<String, List<Color>> _categoryColors = {
    'business': [
      Color(0xFF2E7D32),
      Color(0xFF4CAF50),
    ], // Xanh lá - kinh doanh, tăng trưởng
    'crime': [Color(0xFFD32F2F), Color(0xFFEF5350)], // Đỏ - nguy hiểm, cảnh báo
    'domestic': [
      Color(0xFF1976D2),
      Color(0xFF2196F3),
    ], // Xanh dương - ổn định, tin cậy
    'education': [
      Color(0xFF7B1FA2),
      Color(0xFF9C27B0),
    ], // Tím - trí tuệ, học vấn
    'entertainment': [
      Color(0xFFE91E63),
      Color(0xFFF06292),
    ], // Hồng - vui vẻ, giải trí
    'environment': [
      Color(0xFF388E3C),
      Color(0xFF66BB6A),
    ], // Xanh lá đậm - thiên nhiên
    'food': [Color(0xFFFF5722), Color(0xFFFF7043)], // Cam đỏ - ấm áp, thực phẩm
    'health': [
      Color(0xFF00ACC1),
      Color(0xFF26C6DA),
    ], // Xanh ngọc - sức khỏe, y tế
    'lifestyle': [
      Color(0xFFAB47BC),
      Color(0xFFBA68C8),
    ], // Tím nhạt - thời trang, phong cách
    'politics': [
      Color(0xFF5D4037),
      Color(0xFF8D6E63),
    ], // Nâu - nghiêm túc, chính trị
    'science': [
      Color(0xFF303F9F),
      Color(0xFF3F51B5),
    ], // Xanh đậm - khoa học, công nghệ
    'sports': [
      Color(0xFFFF6F00),
      Color(0xFFFF9800),
    ], // Cam - năng động, thể thao
    'technology': [
      Color(0xFF455A64),
      Color(0xFF607D8B),
    ], // Xám xanh - công nghệ, hiện đại
    'top': [Color(0xFFFFD600), Color(0xFFFFEB3B)], // Vàng - nổi bật, quan trọng
    'tourism': [
      Color(0xFF0097A7),
      Color(0xFF00BCD4),
    ], // Xanh biển - du lịch, khám phá
    'world': [
      Color(0xFF512DA8),
      Color(0xFF673AB7),
    ], // Tím đậm - quốc tế, thế giới
    'other': [Color(0xFF616161), Color(0xFF757575)], // Xám - trung tính
  };

  final TextEditingController _searchController = TextEditingController();
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  String _searchQuery = '';
  List<Result> _searchResults = [];
  bool _isSearching = false;
  bool _showAllCategories = false;
  bool _isListView = true; // Thêm biến để toggle view mode

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

    // Load saved states for search results
    _loadSavedStates(searchResults);
  }

  void _onSearchChanged(String value) {
    setState(() {}); // Để cập nhật suffixIcon

    // Thực hiện tìm kiếm real-time
    _performSearch(value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
    });
  }

  List<Result> _getFilteredNews(List<Result> allNews, String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return allNews.where((article) {
      final titleMatch =
          article.title?.toLowerCase().contains(lowerQuery) ?? false;
      final descMatch =
          article.description?.toLowerCase().contains(lowerQuery) ?? false;
      final sourceMatch =
          article.sourceName?.toLowerCase().contains(lowerQuery) ?? false;
      final categoryMatch =
          article.category?.toString().toLowerCase().contains(lowerQuery) ??
          false;

      return titleMatch || descMatch || sourceMatch || categoryMatch;
    }).toList();
  }

  // Method để lấy màu sắc cho category
  List<Color> _getCategoryColors(String category) {
    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

    // Try to find exact match first
    if (_categoryColors.containsKey(cleanCategory)) {
      return _categoryColors[cleanCategory]!;
    }

    // If no exact match, look for partial matches
    for (var entry in _categoryColors.entries) {
      if (cleanCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default colors if no match found
    return [
      AppColors.primaryColor.withOpacity(0.8),
      AppColors.primaryColor.withOpacity(0.6),
    ];
  }

  // Method để lấy icon cho từng category
  IconData _getCategoryIcon(String category) {
    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

    const categoryIcons = {
      'business': Icons.business_center,
      'crime': Icons.security,
      'domestic': Icons.home,
      'education': Icons.school,
      'entertainment': Icons.movie,
      'environment': Icons.eco,
      'food': Icons.restaurant,
      'health': Icons.local_hospital,
      'lifestyle': Icons.style,
      'politics': Icons.account_balance,
      'science': Icons.science,
      'sports': Icons.sports_soccer,
      'technology': Icons.computer,
      'top': Icons.star,
      'tourism': Icons.flight,
      'world': Icons.public,
      'other': Icons.category,
    };

    // Try to find exact match first
    if (categoryIcons.containsKey(cleanCategory)) {
      return categoryIcons[cleanCategory]!;
    }

    // If no exact match, look for partial matches
    for (var entry in categoryIcons.entries) {
      if (cleanCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    return Icons.category; // Default icon
  }

  // Method _getCategoryDisplayName để sử dụng logic dịch giống NewsCard
  String _getCategoryDisplayName(String category) {
    // Handle null case
    if (category.isEmpty) return "Khác";

    // Clean up category text and convert to lowercase for matching
    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

    // Try to find exact match first
    if (_categoryTranslations.containsKey(cleanCategory)) {
      return _categoryTranslations[cleanCategory]!;
    }

    // If no exact match, look for partial matches
    for (var entry in _categoryTranslations.entries) {
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

  void _openNewsWebView(Result article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => webview.NewsWebViewScreen(
          url: article.link ?? '',
          title: article.title ?? '',
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
                  // Custom App Bar (không có search bar)
                  _buildSliverAppBar(),

                  // Search Bar đặt riêng dưới AppBar
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Khám phá',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A90E2), Color(0xFF50C9C3), Color(0xFF96CEB4)],
              stops: [0.0, 0.5, 1.0],
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
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          textAlignVertical: TextAlignVertical.center, // Thêm dòng này để căn giữa
          decoration: InputDecoration(
            hintText: 'Tìm kiếm tin tức, chủ đề...',
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 0, // Thay đổi từ 12 thành 0
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: _clearSearch,
                  )
                : null,
            isDense: true, // Thêm dòng này để giảm padding
          ),
          onSubmitted: _performSearch,
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  Widget _buildContent(NewsProvider newsState, List<Result> allArticles) {
    if (newsState.newsViewState == ViewState.busy) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (allArticles.isEmpty || newsState.newsViewState == ViewState.error) {
      return _buildErrorState();
    }

    // Show search results if searching
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Show default discover content
    return _buildDiscoverContent(allArticles);
  }

  Widget _buildErrorState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 400,
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
              "Không thể tải nội dung",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Kiểm tra kết nối và thử lại",
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context.read<NewsProvider>().fetchNews(),
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

  Widget _buildDiscoverContent(List<Result> allArticles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Group articles by categories
    Map<String, List<Result>> categorizedNews = {};

    for (var article in allArticles) {
      String category = article.category?.toString() ?? 'other';
      if (categorizedNews[category] == null) {
        categorizedNews[category] = [];
      }
      categorizedNews[category]!.add(article);
    }

    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Trending Section
            _buildTrendingSection(allArticles.skip(1).take(4).toList()),

            const SizedBox(height: 24),

            // Categories Grid
            _buildCategoriesGrid(categorizedNews),

            const SizedBox(height: 24),

            // Recent News
            _buildRecentNews(allArticles.skip(5).take(10).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(List<Result> articles) {
    if (articles.isEmpty) return const SizedBox();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Đang thịnh hành',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return GestureDetector(
                onTap: () => _openNewsWebView(article),
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDarkMode ? Colors.grey[850] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl ?? "",
                          width: 80,
                          height: 140,
                          fit: BoxFit.cover,
                          errorWidget:
                              (context, error, stackTrace) => Container(
                                width: 80,
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                ),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title ?? "",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color:
                                      isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                article.sourceName ?? "",
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid(Map<String, List<Result>> categorizedNews) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Lấy số lượng categories hiển thị dựa trên state
    final int displayCount =
        _showAllCategories ? categorizedNews.keys.length : 4;
    final categories = categorizedNews.keys.take(displayCount).toList();

    if (categories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khám phá theo chủ đề',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final count = categorizedNews[category]?.length ?? 0;
            final categoryColors = _getCategoryColors(category);

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CategoryNewsScreen(
                          category: category,
                          categoryDisplayName: _getCategoryDisplayName(
                            category,
                          ),
                          categoryColors: _getCategoryColors(category),
                          categoryIcon: _getCategoryIcon(category),
                        ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: categoryColors,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColors[0].withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _getCategoryDisplayName(category),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count bài viết',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Thêm nút "Xem thêm" / "Ẩn"
        if (categorizedNews.keys.length > 4) ...[
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showAllCategories = !_showAllCategories;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllCategories ? 'Ẩn bớt' : 'Xem thêm',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllCategories
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.primaryColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecentNews(List<Result> articles) {
    if (articles.isEmpty) return const SizedBox();

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    'Tin tức gần đây',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${articles.length} bài viết',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Thay đổi layout dựa vào _isListView - ĐẢO NGƯỢC LOGIC
        _isListView
            ? _buildRecentNewsListView(articles) // Danh sách dạng dòng
            : _buildRecentNewsGrid(articles), // Lưới (mặc định)
      ],
    );
  }

  // Widget cho ListView (dạng dòng ngang)
  Widget _buildRecentNewsListView(List<Result> articles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: articles.length,
      separatorBuilder: (context, index) => Divider(
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

  // Widget cho GridView (dạng lưới - sử dụng NewsCard)
  Widget _buildRecentNewsGrid(List<Result> articles) {
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

  // THÊM METHOD MỚI cho list row item tương tự HomeScreen
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
                errorWidget: (context, error, stackTrace) => Container(
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

                  // Pub Date và Category
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
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                          _getCategoryDisplayName(article.category?.toString() ?? ''),
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

            // Icon menu 3 chấm
            SizedBox(
              height: 80,
              child: Center(
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    size: 20,
                  ),
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  elevation: 8,
                  offset: const Offset(-10, 0),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            Icons.ios_share,
                            size: 18,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chia sẻ',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
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
                              color: isDarkMode ? Colors.white : Colors.black87,
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
                            isSaved ? Icons.bookmark_remove : Icons.bookmark_add,
                            size: 18,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isSaved ? 'Bỏ lưu' : 'Lưu',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'share':
                        _shareArticle(article);
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

  // THÊM METHOD chia sẻ
  void _shareArticle(Result article) {
    shareNewsLink(context: context, url: article.link, title: article.title);
  }

  // THÊM METHOD format time
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

  // Cập nhật _buildSearchResults để phù hợp với logic mới
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

    return Padding(
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

          // Search results với layout tương ứng - ĐẢO NGƯỢC LOGIC
          _isListView 
              ? _buildSearchResultsListView() // Danh sách dạng dòng
              : _buildSearchResultsGrid(), // Lưới (NewsCard)
        ],
      ),
    );
  }

  // Đổi tên search results methods để phù hợp
  Widget _buildSearchResultsGrid() {
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
      separatorBuilder: (context, index) => Divider(
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
