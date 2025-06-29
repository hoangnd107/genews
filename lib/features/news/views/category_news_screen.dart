import 'package:flutter/material.dart';
import 'package:genews/app/config/enums.dart';
import 'package:genews/app/themes/colors.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/news/providers/news_provider.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/shared/services/category_mapping_service.dart';
import 'package:genews/features/news/data/repository/firestore_news_repository.dart';
import 'package:genews/shared/widgets/paginated_list_view.dart';
import 'package:genews/features/news/widgets/news_card.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:genews/features/news/views/news_webview_screen.dart' as webview;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/shared/utils/share_utils.dart';

class CategoryNewsScreen extends StatefulWidget {
  final String category;
  final String categoryDisplayName;
  final List<Color> categoryColors;
  final IconData categoryIcon;

  const CategoryNewsScreen({
    super.key,
    required this.category,
    required this.categoryDisplayName,
    required this.categoryColors,
    required this.categoryIcon,
  });

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  final BookmarksService _bookmarksService = BookmarksService();
  final Map<String, bool> _savedStates = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Result> _filteredArticles = [];
  bool _isSearchActive = false;
  bool _isListView =
      true; // true = danh sách dạng dòng, false = lưới (NewsCard)

  @override
  void initState() {
    super.initState();
    _loadCategoryNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategoryNews() async {
    setState(() {
      _filteredArticles = [];
    });
    try {
      final repo = FirestoreNewsRepositoryImpl();
      // Luôn dùng key tiếng Anh chuẩn hóa từ CategoryMappingService
      final queryCategory = CategoryMappingService.toEnglish(widget.category);
      final articles = await repo.getArticlesByCategory(queryCategory);
      setState(() {
        _filteredArticles = articles;
      });
      _loadSavedStates(articles);
    } catch (e) {
      debugPrint("Error loading category news: $e");
      setState(() {
        _filteredArticles = [];
      });
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

  void _performSearch(String query) {
    if (query.isEmpty) {
      _loadCategoryNews(); // Reload category news when search is cleared
      setState(() {
        _searchQuery = '';
      });
      return;
    }

    final newsProvider = context.read<NewsProvider>();
    newsProvider.searchArticles("${widget.category} $query").then((_) {
      final searchResults = newsProvider.allNews.results ?? [];
      setState(() {
        _filteredArticles = searchResults;
        _searchQuery = query;
      });
      _loadSavedStates(searchResults);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _performSearch('');
      }
    });
  }

  void _refreshNews() {
    context.read<NewsProvider>().fetchTrendingNews().then((_) {
      _loadCategoryNews();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _performSearch(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch('');
  }

  // Thêm method share article
  void _shareArticle(Result article) {
    shareNewsLink(context: context, url: article.link, title: article.title);
  }

  // Thêm method format time
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Consumer<NewsProvider>(
            builder: (context, newsState, child) {
              return CustomScrollView(
                slivers: [
                  // Custom App Bar
                  _buildSliverAppBar(),

                  // Search Bar (if active)
                  if (_isSearchActive)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: isDarkMode ? Colors.grey[900] : Colors.white,
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
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
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText:
                                  'Tìm kiếm trong ${widget.categoryDisplayName}...',
                              hintStyle: TextStyle(
                                color:
                                    isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 0,
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
                              isDense: true,
                            ),
                            onChanged: _onSearchChanged,
                            onSubmitted: _performSearch,
                          ),
                        ),
                      ),
                    ),

                  // Content
                  _buildContent(newsState),
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
      floating: false,
      pinned: true,
      backgroundColor:
          widget.categoryColors.isNotEmpty
              ? widget.categoryColors[0]
              : Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
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
            padding: const EdgeInsets.only(left: 60),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.categoryIcon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    widget.categoryDisplayName,
                    style: const TextStyle(
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
              colors:
                  widget.categoryColors.length >= 4
                      ? widget.categoryColors
                      : [
                        widget.categoryColors.isNotEmpty
                            ? widget.categoryColors[0]
                            : Colors.blue,
                        widget.categoryColors.length > 1
                            ? widget.categoryColors[1]
                            : Colors.blue[300]!,
                      ],
              stops:
                  widget.categoryColors.length >= 4
                      ? const [0.0, 0.3, 0.7, 1.0]
                      : const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(NewsProvider newsState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (newsState.newsViewState == ViewState.busy) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_filteredArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 400,
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : widget.categoryIcon,
                  size: 60,
                  color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Không tìm thấy kết quả cho "$_searchQuery"'
                      : 'Chưa có tin tức trong chuyên mục này',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Thử tìm kiếm với từ khóa khác'
                      : 'Hãy quay lại sau để xem tin tức mới',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _refreshNews,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Tải lại"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.categoryColors.isNotEmpty
                              ? widget.categoryColors[0]
                              : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(
      child: Container(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with count and search info
              if (_searchQuery.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (widget.categoryColors.isNotEmpty
                            ? widget.categoryColors[0]
                            : Colors.blue)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (widget.categoryColors.isNotEmpty
                              ? widget.categoryColors[0]
                              : Colors.blue)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color:
                            widget.categoryColors.isNotEmpty
                                ? widget.categoryColors[0]
                                : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_filteredArticles.length} kết quả cho "$_searchQuery"',
                          style: TextStyle(
                            color:
                                widget.categoryColors.isNotEmpty
                                    ? widget.categoryColors[0]
                                    : Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Content with pagination
              _buildPaginatedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginatedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _searchQuery.isNotEmpty
              ? '${_filteredArticles.length} kết quả'
              : 'Tất cả tin tức',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Paginated list of articles
        SizedBox(
          height: 600, // Fixed height for the paginated list
          child: PaginatedListView<Result>(
            items: _filteredArticles,
            itemsPerPage: 5,
            emptyMessage:
                _searchQuery.isNotEmpty
                    ? 'Không tìm thấy kết quả nào cho "$_searchQuery"'
                    : 'Không có tin tức nào trong chuyên mục này',
            itemBuilder: (context, article, index) {
              final articleId = article.articleId ?? article.link ?? '';
              final isSaved = _savedStates[articleId] ?? false;

              return _isListView
                  ? _buildListRowItem(article, isSaved)
                  : _buildGridItem(article, isSaved);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(Result article, bool isSaved) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: NewsCard(
        newsData: article,
        isSaved: isSaved,
        onSave: () => _toggleSave(article),
        onViewAnalysis: () => _openNewsAnalysis(article),
      ),
    );
  }

  // THÊM METHOD MỚI cho list row item tương tự DiscoverScreen
  Widget _buildListRowItem(Result article, bool isSaved) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!isDarkMode)
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
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
                    article.title ?? "",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.description ?? "",
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          article.sourceName ?? "",
                          style: TextStyle(
                            color:
                                isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(article.pubDate),
                        style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[500],
                          fontSize: 11,
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
                  onSelected: (value) {
                    switch (value) {
                      case 'share':
                        _shareArticle(article);
                        break;
                      case 'summary':
                        _openNewsAnalysis(article);
                        break;
                      case 'bookmark':
                        _toggleSave(article);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(
                                Icons.ios_share,
                                size: 20,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(width: 12),
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
                        PopupMenuItem(
                          value: 'summary',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 20,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 12),
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
                        PopupMenuItem(
                          value: 'bookmark',
                          child: Row(
                            children: [
                              Icon(
                                isSaved
                                    ? Icons.bookmark_remove
                                    : Icons.bookmark_add,
                                size: 18,
                                color:
                                    isSaved
                                        ? Colors.red
                                        : AppColors.primaryColor,
                              ),
                              const SizedBox(width: 12),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
