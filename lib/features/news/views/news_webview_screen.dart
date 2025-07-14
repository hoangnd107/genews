import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/summary/views/news_summary_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/shared/utils/share_utils.dart';
import 'package:genews/shared/utils/webview_utils.dart';
import 'package:genews/shared/widgets/custom_bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:genews/features/main/providers/main_screen_provider.dart';

class NewsWebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Result newsData;

  const NewsWebViewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.newsData,
  });

  @override
  State<NewsWebViewScreen> createState() => _NewsWebViewScreenState();
}

class _NewsWebViewScreenState extends State<NewsWebViewScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool isLoading = true;
  bool isSaved = false;
  // ignore: unused_field
  int _blockedAdsCount = 0;
  bool _isAdBlockingEnabled = false;

  Timer? _loadingTimer;
  bool _hasError = false;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _setupWebViewController();
  }

  void _checkBookmarkStatus() async {
    final bookmarksService = BookmarksService();
    final saved = await bookmarksService.isArticleSaved(widget.newsData);
    if (mounted) {
      setState(() {
        isSaved = saved;
      });
    }
  }

  void _setupWebViewController() {
    _controller = WebViewUtils.createOptimizedController(
      url: widget.url,
      enableAdBlock: _isAdBlockingEnabled,
      onLoadingChanged: (bool loading) {
        _loadingTimer?.cancel();
        if (mounted) {
          setState(() {
            isLoading = loading;
            if (loading) {
              _hasError = false;
              _errorMessage = null;
            }
          });
        }
      },
      onNavigationRequest: (NavigationRequest request) {
        if (_isAdBlockingEnabled && WebViewUtils.isAdUrl(request.url)) {
          if (mounted) {
            setState(() {
              _blockedAdsCount++;
            });
          }
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onError: (WebResourceError error) {
        debugPrint('Web Resource Error: ${error.description}');
        if (error.errorType == WebResourceErrorType.hostLookup ||
            error.errorType == WebResourceErrorType.connect ||
            error.errorType == WebResourceErrorType.timeout) {
          if (mounted && isLoading) {
            setState(() {
              isLoading = false;
              _hasError = true;
              _errorMessage =
                  'Không thể kết nối đến trang web. Vui lòng kiểm tra kết nối mạng.';
            });
          }
        }
      },
    );

    _loadPageWithTimeout();
  }

  void _loadPageWithTimeout() async {
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
          _hasError = true;
          _errorMessage = 'Trang web tải quá lâu. Vui lòng thử lại.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Trang web tải quá lâu. Vui lòng thử lại.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _reloadPage(),
            ),
          ),
        );
      }
    });

    try {
      await _controller.loadRequest(Uri.parse(widget.url));
    } catch (e) {
      debugPrint('Error loading page: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _hasError = true;
          _errorMessage =
              'Không thể tải trang. Vui lòng kiểm tra kết nối mạng.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Không thể tải trang. Vui lòng kiểm tra kết nối mạng.',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _reloadPage(),
            ),
          ),
        );
      }
    }
  }

  void _reloadPage() {
    setState(() {
      isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });
    _loadingTimer?.cancel();
    _setupWebViewController();
  }

  void _toggleSaved() async {
    final bookmarksService = BookmarksService();
    setState(() {
      isSaved = !isSaved;
    });

    if (isSaved) {
      await bookmarksService.saveArticle(widget.newsData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Đã lưu bài viết'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      await bookmarksService.removeArticle(widget.newsData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark_border, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Đã bỏ lưu bài viết'),
            ],
          ),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: widget.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đã sao chép liên kết'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Điều chỉnh cỡ chữ'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.text_decrease),
                  title: const Text('Nhỏ'),
                  onTap: () {
                    _controller.runJavaScript(
                      WebViewUtils.getFontSizeScript(14),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Trung bình'),
                  onTap: () {
                    _controller.runJavaScript(
                      WebViewUtils.getFontSizeScript(16),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_increase),
                  title: const Text('Lớn'),
                  onTap: () {
                    _controller.runJavaScript(
                      WebViewUtils.getFontSizeScript(18),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_increase),
                  title: const Text('Rất lớn'),
                  onTap: () {
                    _controller.runJavaScript(
                      WebViewUtils.getFontSizeScript(20),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }

  void _toggleAdBlocking() {
    setState(() {
      _isAdBlockingEnabled = !_isAdBlockingEnabled;
      _blockedAdsCount = 0;
      isLoading = true;
    });

    _controller.reload();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAdBlockingEnabled
              ? 'Đã bật chặn quảng cáo. Trang sẽ được tải lại.'
              : 'Đã tắt chặn quảng cáo. Trang sẽ được tải lại.',
        ),
        backgroundColor: _isAdBlockingEnabled ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex =
        Provider.of<MainScreenProvider>(context).getCurrentIndex();

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: selectedIndex),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDarkMode
                        ? [
                          Color(0xFF232526), // dark gray
                          Color(0xFF414345), // slightly lighter gray
                          Color(0xFF5B86E5), // blue
                          Color(0xFF232526), // dark gray again for depth
                        ]
                        : [
                          Color(0xFF36D1C4), // teal
                          Color(0xFF5B86E5), // blue
                          Color(0xFF6A82FB), // light blue
                          Color(0xFF8F6ED5), // purple
                        ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        shadowColor: Colors.transparent, // Remove shadow
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        title: const Text(
          "Điểm tin",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'bookmark':
                  _toggleSaved();
                  break;
                case 'share':
                  shareNewsLink(
                    context: context,
                    url: widget.url,
                    title: widget.title,
                  );
                  break;
                case 'copy_link':
                  _copyLink();
                  break;
                case 'font_size':
                  _showFontSizeDialog();
                  break;
                case 'reload':
                  _reloadPage();
                  break;
                case 'toggle_adblock':
                  _toggleAdBlocking();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              isSaved
                                  ? Colors.orange
                                  : (isDarkMode
                                      ? Colors.white70
                                      : Colors.orange.shade300),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(isSaved ? 'Bỏ lưu' : 'Lưu tin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.ios_share,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 12),
                        const Text('Chia sẻ'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'copy_link',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20, color: Colors.green),
                        const SizedBox(width: 12),
                        const Text('Sao chép liên kết'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          size: 20,
                          color: Colors.purpleAccent,
                        ),
                        const SizedBox(width: 12),
                        const Text('Cỡ chữ'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reload',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        const Text('Tải lại trang'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'toggle_adblock',
                    child: Row(
                      children: [
                        Icon(
                          _isAdBlockingEnabled
                              ? Icons.shield
                              : Icons.shield_outlined,
                          color:
                              _isAdBlockingEnabled
                                  ? Colors.green
                                  : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAdBlockingEnabled
                              ? 'Tắt chặn quảng cáo'
                              : 'Bật chặn quảng cáo',
                          style: TextStyle(
                            color:
                                _isAdBlockingEnabled
                                    ? Colors.green
                                    : Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!_hasError)
            WebViewWidget(controller: _controller)
          else
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage ?? 'Đã xảy ra lỗi khi tải trang',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _reloadPage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          if (isLoading)
            Container(
              color: (isDarkMode ? Colors.black : Colors.white).withOpacity(
                0.9,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[300],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.blue[300]! : Colors.blue[600]!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đang tải nội dung...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vui lòng chờ trong giây lát',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    if (_isAdBlockingEnabled) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield,
                              color: Colors.green[600],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Chặn quảng cáo: Đang hoạt động',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 8),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => NewsSummaryScreen(newsData: widget.newsData),
              ),
            );
          },
          tooltip: 'Tóm tắt',
          icon: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrangeAccent, Colors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.bolt, color: Colors.white, size: 28),
          ),
          label: Text(
            'Tóm tắt',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.orange.shade900,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
