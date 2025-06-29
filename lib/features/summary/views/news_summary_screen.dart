import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genews/app/config/enums.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/news/providers/news_provider.dart';
import 'package:genews/app/themes/colors.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:genews/shared/utils/share_utils.dart';
import 'package:genews/features/news/views/news_webview_screen.dart';
import 'package:genews/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';

class NewsSummaryScreen extends StatefulWidget {
  final Result newsData;
  const NewsSummaryScreen({super.key, required this.newsData});

  @override
  State<NewsSummaryScreen> createState() => _NewsSummaryScreenState();
}

class _NewsSummaryScreenState extends State<NewsSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchSummary();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ignore: strict_top_level_inference
  _fetchSummary() {
    context.read<NewsProvider>().generateSummary(
      widget.newsData.description ?? widget.newsData.title ?? "",
    );
  }

  // ignore: strict_top_level_inference
  _regenerateSummary() {
    context.read<NewsProvider>().regenerateAnalysis(
      widget.newsData.description ?? widget.newsData.title ?? "",
    );
  }

  void _copySummary(String analysis) {
    Clipboard.setData(ClipboardData(text: analysis));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã sao chép tóm tắt'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(String? pubDate) {
    if (pubDate == null || pubDate.isEmpty) return "Vừa xong";

    try {
      final DateTime dateTime = DateTime.parse(pubDate);
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 60) {
        return "${difference.inMinutes} phút trước";
      } else if (difference.inHours < 24) {
        return "${difference.inHours} giờ trước";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} ngày trước";
      } else {
        return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
      }
    } catch (e) {
      return "Vừa xong";
    }
  }

  void _openOriginalArticle() {
    if (widget.newsData.link != null && widget.newsData.link!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => NewsWebViewScreen(
                url: widget.newsData.link!,
                title: widget.newsData.title ?? "Bài viết",
                newsData: widget.newsData,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có liên kết bài viết gốc'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = Provider.of<MainScreenProvider>(context).getCurrentIndex();

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDarkMode),
            SliverToBoxAdapter(
              child: Consumer<NewsProvider>(
                builder: (context, newsState, child) {
                  return AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildContent(newsState, isDarkMode),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDarkMode) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primaryColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero, // Reset padding như DiscoverScreen
        title: Align(
          alignment: Alignment.centerLeft, // Căn trái như DiscoverScreen
          child: Padding(
            padding: const EdgeInsets.only(left: 60), // Để tránh back button
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.orange, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Tóm tắt tin tức",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.8),
                const Color(0xFFFF6B35),
                const Color(0xFFFF8E53),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share, color: Colors.white),
          onPressed: () {
            shareNewsLink(
              context: context,
              url: widget.newsData.link,
              title: widget.newsData.title,
            );
          },
          tooltip: 'Chia sẻ',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showMoreOptions(context),
          tooltip: 'Tùy chọn',
        ),
      ],
    );
  }

  Widget _buildContent(NewsProvider newsState, bool isDarkMode) {
    if (newsState.newsAnalysisState == ViewState.busy) {
      return _buildLoadingState(isDarkMode);
    }

    if (newsState.analysis.isEmpty ||
        newsState.newsAnalysisState == ViewState.error) {
      return _buildErrorState(isDarkMode);
    }

    return _buildSuccessState(newsState, isDarkMode);
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.psychology,
                      color: AppColors.primaryColor,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Đang tạo bản tóm tắt...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Không thể tạo tóm tắt",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Kiểm tra kết nối internet và thử lại",
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _fetchSummary,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "Thử lại",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(NewsProvider newsState, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildArticleHeader(isDarkMode),
          const SizedBox(height: 20),
          _buildSummaryCard(newsState.analysis, isDarkMode),
          const SizedBox(height: 20),
          _buildActionButtons(newsState.analysis, isDarkMode),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildArticleHeader(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Image
          if (widget.newsData.imageUrl != null &&
              widget.newsData.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: widget.newsData.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorWidget:
                    (context, error, stackTrace) => Container(
                      height: 200,
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
              ),
            ),

          // Article Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.newsData.title ?? "Không có tiêu đề",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Meta Info Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.newsData.sourceName ?? "Nguồn tin",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _formatTime(widget.newsData.pubDate?.toIso8601String()),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String analysis, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.1),
                  AppColors.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Nội dung tóm tắt",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copySummary(analysis),
                  icon: Icon(
                    Icons.copy,
                    color: AppColors.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Sao chép',
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              analysis,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String analysis, bool isDarkMode) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copySummary(analysis),
                icon: Icon(
                  Icons.copy,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
                label: Text(
                  "Sao chép",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  shareNewsLink(
                    context: context,
                    url: widget.newsData.link,
                    title: widget.newsData.title,
                  );
                },
                icon: Icon(
                  Icons.ios_share,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
                label: Text(
                  "Chia sẻ",
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Tùy chọn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // First option
                ListTile(
                  leading: Icon(Icons.refresh, color: AppColors.primaryColor),
                  title: Text(
                    'Tạo lại bản tóm tắt',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _regenerateSummary();
                  },
                ),

                // Divider - NGĂN CÁCH
                Divider(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  thickness: 1,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),

                // Second option
                ListTile(
                  leading: Icon(
                    Icons.open_in_browser,
                    color: AppColors.primaryColor,
                  ),
                  title: Text(
                    'Xem bài viết gốc',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openOriginalArticle();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
