import 'package:flutter/material.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:genews/features/news/widgets/news_card.dart';
import 'package:genews/features/news/widgets/category_bar.dart';
import 'package:genews/app/themes/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/shared/utils/share_utils.dart';
import 'package:genews/shared/services/category_mapping_service.dart';
import 'package:genews/shared/widgets/paginated_list_view.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';
import 'package:provider/provider.dart';

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
  bool _isListView = true;
  late AnimationController _animationController;
  int? _previousTabIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Lắng nghe thay đổi tab để tải lại bookmark khi màn hình này được kích hoạt
    final mainScreenProvider = Provider.of<MainScreenProvider>(context);
    final currentIndex = mainScreenProvider.currentIndex;

    // Index của BookmarksScreen là 2
    if (currentIndex == 2 && _previousTabIndex != 2) {
      _loadBookmarks();
    }
    _previousTabIndex = currentIndex;
  }

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
        final cat = CategoryMappingService.toVietnamese(article.category);
        if (cat.isNotEmpty && cat != 'Khác') categorySet.add(cat);
      }

      setState(() {
        _bookmarkedArticles = bookmarks;
        _isLoading = false;
        if (mounted) {
          selectedCategory = null;
        }
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _bookmarkedArticles = [];
        _isLoading = false;
      });
    }
  }

  void _removeBookmark(Result article) async {
    // Lưu lại tin vừa xóa để có thể hoàn tác
    final removedArticle = article;
    // Xóa tin khỏi SharedPreferences
    await _bookmarksService.removeArticle(removedArticle);

    // Cập nhật UI ngay lập tức
    setState(() {
      _bookmarkedArticles.removeWhere(
        (a) =>
            a.articleId == removedArticle.articleId ||
            a.link == removedArticle.link,
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xóa khỏi danh sách lưu'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () async {
              // Lưu lại tin đã xóa
              await _bookmarksService.saveArticle(removedArticle);
              // Tải lại danh sách để cập nhật UI
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
              final cat = CategoryMappingService.toVietnamese(article.category);
              return cat == selectedCategory;
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
      final categoryMatch = CategoryMappingService.toVietnamese(
        article.category,
      ).toLowerCase().contains(query);
      return titleMatch || descMatch || sourceMatch || categoryMatch;
    }).toList();
  }

  // THÊM: Hàm lấy màu sắc cho category từ DiscoverScreen
  List<Color> _getCategoryColors(String category) {
    final vietnameseCategory = CategoryMappingService.toVietnamese(category);
    return CategoryMappingService.getCategoryColors(vietnameseCategory);
  }

  // THÊM: Hàm lấy icon cho category từ DiscoverScreen
  IconData _getCategoryIcon(String? category) {
    final vietnameseCategory = CategoryMappingService.toVietnamese(category);
    return CategoryMappingService.getCategoryIcon(vietnameseCategory);
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
    final Set<String> categories = {};
    for (var article in _bookmarkedArticles) {
      final cat = CategoryMappingService.toVietnamese(article.category);
      if (cat.isNotEmpty && cat != 'Khác') categories.add(cat);
    }
    final List<String> displayCategories = ['Tất cả', ...categories.toList()];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBookmarks,
          child: Container(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
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
                if (displayCategories.length >
                    1) // Chỉ hiển thị nếu có category
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
                          setState(() {
                            selectedCategory = cat == 'Tất cả' ? null : cat;
                          });
                        },
                        getCategoryIcon:
                            (cat) =>
                                cat == 'Tất cả'
                                    ? Icons.list
                                    : _getCategoryIcon(cat),
                        getCategoryColors:
                            (cat) => [
                              Colors.blue,
                              Colors.blue.withOpacity(0.7),
                            ],
                      ),
                    ),
                  ),
                if (!_isLoading && _bookmarkedArticles.isNotEmpty)
                  SliverToBoxAdapter(child: _buildStatisticsSection()),
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
      ),
    );
  }

  // Sửa lỗi: lấy đúng key tiếng Anh cho màu sắc thống kê
  Widget _buildStatisticsSection() {
    final filteredBookmarks = _getFilteredBookmarks();
    final categoryStats = <String, int>{};

    for (var article in _bookmarkedArticles) {
      // Dùng toEnglish để lấy key tiếng Anh cho việc đếm thống kê
      final categoryEn = CategoryMappingService.toEnglish(
        article.category?.toString() ?? 'other',
      );
      categoryStats[categoryEn] = (categoryStats[categoryEn] ?? 0) + 1;
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  color: isDarkMode ? Colors.white : Colors.black87,
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
                  categoryStats.entries.take(10).map((entry) {
                    final colors = _getCategoryColors(entry.key);
                    final translatedCategory =
                        CategoryMappingService.toVietnamese(entry.key);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
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

  // SỬA ĐỔI: Thay thế _buildBookmarksContent bằng PaginatedListView
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
                    onPressed:
                        () => Provider.of<MainScreenProvider>(
                          context,
                          listen: false,
                        ).setCurrentIndex(1),
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

    // SỬA LỖI: Chỉ hiển thị pagination nếu có tin tức
    return SliverToBoxAdapter(
      child:
          filteredBookmarks.isNotEmpty
              ? Container(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 600,
                  child: PaginatedListView<Result>(
                    items: filteredBookmarks,
                    itemsPerPage: 5,
                    emptyMessage: 'Không có tin tức nào được lưu',
                    itemBuilder: (context, article, index) {
                      return _isListView
                          ? _buildListRowItem(article, true)
                          : _buildGridItem(article, true);
                    },
                  ),
                ),
              )
              : const SizedBox.shrink(), // Không hiển thị gì nếu không có tin
    );
  }

  // THÊM: _buildGridItem để dùng trong PaginatedListView
  Widget _buildGridItem(Result article, bool isSaved) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NewsCard(
        newsData: article,
        isSaved: isSaved,
        onSave: () => _removeBookmark(article),
        onViewAnalysis: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewsAnalysisScreen(newsData: article),
            ),
          );
        },
      ),
    );
  }

  // SỬA LỖI: Thêm hàm _buildListRowItem bị thiếu
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
                          CategoryMappingService.toVietnamese(article.category),
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

  void _shareArticle(Result article) {
    shareNewsLink(context: context, url: article.link, title: article.title);
  }

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
