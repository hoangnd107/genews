import 'package:flutter/material.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:genews/features/news/widgets/news_card.dart';
import 'package:genews/features/news/widgets/category_bar.dart';
import 'package:genews/app/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/shared/utils/share_utils.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  final BookmarksService _bookmarksService = BookmarksService();
  List<Result> _bookmarkedArticles = [];
  bool _isLoading = true;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? selectedCategory;
  List<String> _availableCategories = [];
  bool _isListView = true; // Toggle between list and grid view
  late AnimationController _animationController;

  // Category colors map
  static final Map<String, List<Color>> _categoryColors = {
    'business': [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    'crime': [Color(0xFFD32F2F), Color(0xFFEF5350)],
    'domestic': [Color(0xFF1976D2), Color(0xFF2196F3)],
    'education': [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
    'entertainment': [Color(0xFFE91E63), Color(0xFFF06292)],
    'environment': [Color(0xFF388E3C), Color(0xFF66BB6A)],
    'food': [Color(0xFFFF5722), Color(0xFFFF7043)],
    'health': [Color(0xFF00ACC1), Color(0xFF26C6DA)],
    'lifestyle': [Color(0xFFAB47BC), Color(0xFFBA68C8)],
    'politics': [Color(0xFF5D4037), Color(0xFF8D6E63)],
    'science': [Color(0xFF303F9F), Color(0xFF3F51B5)],
    'sports': [Color(0xFFFF6F00), Color(0xFFFF9800)],
    'technology': [Color(0xFF455A64), Color(0xFF607D8B)],
    'top': [Color(0xFFFFD600), Color(0xFFFFEB3B)],
    'tourism': [Color(0xFF0097A7), Color(0xFF00BCD4)],
    'world': [Color(0xFF512DA8), Color(0xFF673AB7)],
    'other': [Color(0xFF616161), Color(0xFF757575)],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadBookmarks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookmarks = await _bookmarksService.getSavedArticles();

      // Extract unique categories from bookmarked articles
      final categorySet = <String>{};
      for (var article in bookmarks) {
        if (article.category != null &&
            article.category.toString().isNotEmpty) {
          categorySet.add(article.category.toString());
        }
      }

      setState(() {
        _bookmarkedArticles = bookmarks;
        _availableCategories = categorySet.toList()..sort();
        _isLoading = false;
        selectedCategory = null;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _bookmarkedArticles = [];
        _availableCategories = [];
        _isLoading = false;
      });
    }
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
  void _removeBookmark(Result article) async {
    await _bookmarksService.removeArticle(article);
    _loadBookmarks();

    // Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa khỏi danh sách lưu'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              await _bookmarksService.saveArticle(article);
              _loadBookmarks();
            },
          ),
        ),
      );
    }
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

  List<Result> _getFilteredBookmarks() {
    List<Result> categoryFiltered =
        selectedCategory == null
            ? _bookmarkedArticles
            : _bookmarkedArticles.where((article) {
              String articleCategory =
                  (article.category ?? '').toString().toLowerCase();
              return articleCategory.contains(selectedCategory!.toLowerCase());
            }).toList();

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

  List<Color> _getCategoryColors(String category) {
    String cleanCategory =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();

    if (_categoryColors.containsKey(cleanCategory)) {
      return _categoryColors[cleanCategory]!;
    }

    for (var entry in _categoryColors.entries) {
      if (cleanCategory.contains(entry.key)) {
        return entry.value;
      }
    }

    return [
      AppColors.primaryColor.withOpacity(0.8),
      AppColors.primaryColor.withOpacity(0.6),
    ];
  }

  // Thêm method để dịch category sang tiếng Việt
  String _translateCategory(dynamic category) {
    if (category == null) return "";
    if (category is List && category.isNotEmpty) {
      for (var cat in category) {
        if (_isVietnamese(cat.toString())) return cat.toString();
      }
      return _categoryMapToVietnamese(category.first.toString());
    }
    if (category is String) {
      if (_isVietnamese(category)) return category;
      return _categoryMapToVietnamese(category);
    }
    return "";
  }

  String _categoryMapToVietnamese(String category) {
    final Map<String, String> categoryTranslations = {
      'business': 'Kinh doanh',
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
    final clean =
        category.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
    if (categoryTranslations.containsKey(clean))
      return categoryTranslations[clean]!;
    for (var entry in categoryTranslations.entries) {
      if (clean.contains(entry.key)) return entry.value;
    }
    return category;
  }

  // Chuẩn hóa category: Ưu tiên tiếng Việt, nếu không có thì dịch từ tiếng Anh
  String normalizeCategory(dynamic category) {
    if (category == null) return 'Khác';
    if (category is List && category.isNotEmpty) {
      for (var cat in category) {
        if (_isVietnamese(cat.toString())) return cat.toString();
      }
      return _translateCategory(category.first.toString());
    }
    if (category is String) {
      if (_isVietnamese(category)) return category;
      return _translateCategory(category);
    }
    return 'Khác';
  }

  bool _isVietnamese(String text) {
    final vietnameseRegex = RegExp(
      r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]',
    );
    return vietnameseRegex.hasMatch(text);
  }

  // Thay thế method _buildSliverAppBar và search bar section
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            _isSearchActive ? Icons.search_off : Icons.search,
            color: Colors.white,
          ),
          onPressed: _toggleSearch,
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
                  Icon(Icons.bookmark, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Tin đã lưu',
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.9),
                const Color(0xFF6A4C93),
                const Color(0xFF9B59B6),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Thêm 'Tất cả' vào đầu danh sách category
    final Set<String> categories = {};
    for (var article in _bookmarkedArticles) {
      final cat = normalizeCategory(article.category);
      if (cat.isNotEmpty && cat != 'Khác') categories.add(cat);
    }
    final List<String> displayCategories = ['Tất cả', ...categories.toList()];

    return Scaffold(
      body: SafeArea(
        child: Container(
          color:
              isDarkMode
                  ? Colors.grey[900]
                  : Colors.white, // Thêm màu nền container chính
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(),

              // Search Bar
              if (_isSearchActive)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    color:
                        isDarkMode
                            ? Colors.grey[900]
                            : Colors.white, // Màu nền search container
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100], // Màu nền search field
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color:
                              isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
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
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlignVertical:
                            TextAlignVertical.center, // Fix text alignment
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm trong tin đã lưu...',
                          hintStyle: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0, // Fix vertical padding
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                            size: 20,
                          ),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      size: 20,
                                      color:
                                          isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                  : null,
                          isDense: true, // Reduce default padding
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                ),

              // Category Bar
              if (displayCategories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    color:
                        isDarkMode
                            ? Colors.grey[900]
                            : Colors.white, // Màu nền category bar
                    child: CategoryBar(
                      availableCategories: displayCategories,
                      selectedCategory: selectedCategory ?? 'Tất cả',
                      onCategorySelected: (cat) {
                        if (cat == 'Tất cả') {
                          setState(() => selectedCategory = null);
                        } else {
                          setState(() => selectedCategory = cat);
                        }
                      },
                    ),
                  ),
                ),

              // Statistics Section
              if (!_isLoading && _bookmarkedArticles.isNotEmpty)
                SliverToBoxAdapter(child: _buildStatisticsSection()),

              // Content
              _isLoading
                  ? SliverToBoxAdapter(
                    child: Container(
                      height: 300,
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  )
                  : _buildBookmarksContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    final filteredBookmarks = _getFilteredBookmarks();
    final categoryStats = <String, int>{};

    for (var article in _bookmarkedArticles) {
      final category = article.category?.toString() ?? 'other';
      categoryStats[category] = (categoryStats[category] ?? 0) + 1;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.grey[850]
                : Colors.white, // Chỉnh màu nền theo dark mode
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(
                      0.1,
                    ), // Chỉnh shadow theo dark mode
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? Colors.white
                          : Colors.black87, // Chỉnh màu text theo dark mode
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedCategory != null || _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Hiển thị ${filteredBookmarks.length} / ${_bookmarkedArticles.length} bài viết',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  categoryStats.entries.take(3).map((entry) {
                    final colors = _getCategoryColors(entry.key);
                    final translatedCategory = _translateCategory(entry.key);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$translatedCategory: ${entry.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  // Cập nhật _buildBookmarksContent để phù hợp với logic mới
  Widget _buildBookmarksContent() {
    final filteredBookmarks = _getFilteredBookmarks();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (filteredBookmarks.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 400,
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty || selectedCategory != null
                      ? Icons.search_off
                      : Icons.bookmark_border,
                  size: 80,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  _searchQuery.isNotEmpty
                      ? "Không tìm thấy tin phù hợp"
                      : selectedCategory != null
                      ? "Không có tin trong chuyên mục này"
                      : "Chưa có tin tức nào được lưu",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? "Thử tìm kiếm với từ khóa khác"
                      : selectedCategory != null
                      ? "Chọn chuyên mục khác hoặc bỏ chọn"
                      : "Bắt đầu lưu tin tức yêu thích để đọc sau",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_bookmarkedArticles.isEmpty &&
                    _searchQuery.isEmpty &&
                    selectedCategory == null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.explore),
                    label: const Text("Khám phá tin tức"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // ĐẢO NGƯỢC LOGIC để giống HomeScreen
    return _isListView
        ? _buildBookmarksListView(filteredBookmarks) // Danh sách dạng dòng
        : _buildBookmarksGridView(filteredBookmarks); // Lưới (NewsCard)
  }

  // CẬP NHẬT _buildListView thành _buildBookmarksGridView (sử dụng NewsCard)
  Widget _buildBookmarksGridView(List<Result> articles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / articles.length) * 0.5,
                      ((index + 1) / articles.length) * 0.5 + 0.5,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: NewsCard(
                  newsData: article,
                  onViewAnalysis: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => NewsAnalysisScreen(newsData: article),
                      ),
                    );
                  },
                  onSave: () => _removeBookmark(article),
                  isSaved: true,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // THÊM _buildBookmarksListView mới (dạng dòng ngang tương tự HomeScreen)
  Widget _buildBookmarksListView(List<Result> articles) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.separated(
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
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      (index / articles.length) * 0.5,
                      ((index + 1) / articles.length) * 0.5 + 0.5,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                ),
                child: _buildListRowItem(article, true), // isSaved = true
              );
            },
          ),
        ),
      ),
    );
  }

  // THÊM method _buildListRowItem tương tự HomeScreen
  Widget _buildListRowItem(Result article, bool isSaved) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsAnalysisScreen(newsData: article),
          ),
        );
      },
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
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
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
                          _translateCategory(
                            article.category?.toString() ?? '',
                          ),
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
                  itemBuilder:
                      (BuildContext context) => [
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
                          value: 'remove',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bookmark_remove,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bỏ lưu',
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
                        _shareArticle(article);
                        break;
                      case 'analysis':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    NewsAnalysisScreen(newsData: article),
                          ),
                        );
                        break;
                      case 'remove':
                        _removeBookmark(article);
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

  // THÊM method chia sẻ
  void _shareArticle(Result article) {
    shareNewsLink(context: context, url: article.link, title: article.title);
  }

  // THÊM method format time
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
}
