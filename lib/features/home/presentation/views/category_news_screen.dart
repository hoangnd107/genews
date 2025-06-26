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
import 'package:cached_network_image/cached_network_image.dart';

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
  bool _isListView = true; // Thêm toggle view mode

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

  void _loadCategoryNews() {
    final newsProvider = context.read<NewsProvider>();
    final allArticles = newsProvider.allNews.results ?? [];

    final categoryArticles =
        allArticles.where((article) {
          final articleCategory =
              article.category?.toString().toLowerCase() ?? '';
          return articleCategory == widget.category.toLowerCase();
        }).toList();

    setState(() {
      _filteredArticles = categoryArticles;
    });

    _loadSavedStates(categoryArticles);
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
    final newsProvider = context.read<NewsProvider>();
    final allArticles = newsProvider.allNews.results ?? [];

    final categoryArticles =
        allArticles.where((article) {
          final articleCategory =
              article.category?.toString().toLowerCase() ?? '';
          return articleCategory == widget.category.toLowerCase();
        }).toList();

    if (query.isEmpty) {
      setState(() {
        _filteredArticles = categoryArticles;
        _searchQuery = '';
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final searchResults =
        categoryArticles.where((article) {
          final titleMatch =
              article.title?.toLowerCase().contains(lowerQuery) ?? false;
          final descMatch =
              article.description?.toLowerCase().contains(lowerQuery) ?? false;
          final sourceMatch =
              article.sourceName?.toLowerCase().contains(lowerQuery) ?? false;

          return titleMatch || descMatch || sourceMatch;
        }).toList();

    setState(() {
      _filteredArticles = searchResults;
      _searchQuery = query;
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
    context.read<NewsProvider>().fetchNews().then((_) {
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Container(
          color:
              isDarkMode
                  ? Colors.grey[900]
                  : Colors.white, // Thêm màu nền container chính
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
      // expandedHeight: 180, // Giảm từ 200 xuống 180
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
        // IconButton(
        //   icon: const Icon(Icons.refresh, color: Colors.white),
        //   onPressed: _refreshNews,
        // ),
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

  // Cập nhật _buildContent để có background phù hợp
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
                      : Icons.article_outlined,
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

              // Content based on view mode
              _isListView ? _buildListView() : _buildGridView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured article (first article with special layout)
        if (_filteredArticles.isNotEmpty) ...[
          _buildFeaturedArticle(_filteredArticles.first),
          const SizedBox(height: 24),
        ],

        // Other articles
        if (_filteredArticles.length > 1) ...[
          Text(
            _searchQuery.isNotEmpty ? 'Kết quả khác' : 'Tin tức khác',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredArticles.length - 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article =
                  _filteredArticles[index + 1]; // Skip first article
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
          ),
        ],
      ],
    );
  }

  Widget _buildGridView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _searchQuery.isNotEmpty
              ? '${_filteredArticles.length} kết quả'
              : 'Tất cả tin tức',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _filteredArticles.length,
          itemBuilder: (context, index) {
            final article = _filteredArticles[index];
            final articleId = article.articleId ?? article.link ?? '';
            final isSaved = _savedStates[articleId] ?? false;

            return _buildGridItem(article, isSaved);
          },
        ),
      ],
    );
  }

  Widget _buildGridItem(Result article, bool isSaved) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl ?? "",
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget:
                      (context, error, stackTrace) => Container(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            article.sourceName ?? "",
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => _openNewsAnalysis(article),
                              child: const Icon(
                                Icons.bolt,
                                color: Colors.orange,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _toggleSave(article),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color:
                                    widget.categoryColors.isNotEmpty
                                        ? widget.categoryColors[0]
                                        : Colors.blue,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildFeaturedArticle(Result article) {
    return GestureDetector(
      onTap: () => _openNewsWebView(article),
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.categoryColors.isNotEmpty
                            ? widget.categoryColors[0]
                            : Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.categoryIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      const Text(
                        'TIN NỔI BẬT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                  mainAxisSize: MainAxisSize.min, // Thêm để tránh overflow
                  children: [
                    Text(
                      article.title ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Giảm từ 20 xuống 18
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Giảm từ 8 xuống 6
                    Text(
                      article.description ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13, // Giảm từ 14 xuống 13
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Giảm từ 8 xuống 6
                    Row(
                      children: [
                        Expanded(
                          // Wrap với Expanded
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              article.sourceName ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _openNewsAnalysis(article),
                              icon: const Icon(
                                Icons.bolt,
                                color: Colors.orange,
                                size: 20,
                              ),
                              tooltip: 'Tóm tắt',
                              constraints:
                                  const BoxConstraints(), // Giảm padding
                              padding: const EdgeInsets.all(4),
                            ),
                            IconButton(
                              onPressed: () => _toggleSave(article),
                              icon: Icon(
                                (_savedStates[article.articleId ??
                                            article.link ??
                                            ''] ??
                                        false)
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: Colors.white,
                                size: 20,
                              ),
                              tooltip: 'Lưu',
                              constraints:
                                  const BoxConstraints(), // Giảm padding
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
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
