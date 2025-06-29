import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/shared/utils/share_utils.dart';
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

// SỬA ĐỔI: Thêm AutomaticKeepAliveClientMixin để giữ trạng thái WebView
class _NewsWebViewScreenState extends State<NewsWebViewScreen>
    with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool isLoading = true;
  bool isSaved = false;
  // ignore: unused_field
  int _blockedAdsCount = 0;
  bool _isAdBlockingEnabled = false;

  // SỬA ĐỔI: Ghi đè wantKeepAlive để giữ state
  @override
  bool get wantKeepAlive => true;

  // SỬA ĐỔI: Cập nhật danh sách domain chặn quảng cáo
  static const List<String> _adBlockList = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'googletagmanager.com',
    'facebook.com/tr',
    'facebook.net',
    'amazon-adsystem.com',
    'adsystem.com',
    'ads.yahoo.com',
    'bing.com/search',
    'outbrain.com',
    'taboola.com',
    'addthis.com',
    'sharethis.com',
    'scorecardresearch.com',
    'quantserve.com',
    'hotjar.com',
    'mouseflow.com',
    'crazyegg.com',
    'adnxs.com',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'advertising.com',
    'ads.twitter.com',
    'analytics.twitter.com',
    'ads.linkedin.com',
    'ads.pinterest.com',
    'ads.tiktok.com',
    'adform.net',
    'adsrvr.org',
    'amazon-advertising.com',
    'criteo.com',
    'turn.com',
    'rlcdn.com',
    'serving-sys.com',
    'moatads.com',
    'adroll.com',
    'casalemedia.com',
    'contextweb.com',
    'exponential.com',
    'indexww.com',
    'sharethrough.com',
    'sovrn.com',
    'spotxchange.com',
    'springserve.com',
    'teads.tv',
    'tidaltv.com',
    'undertone.com',
    'yieldmo.com',
    'ads.google.com',
    'www.googletagservices.com',
    'pagead2.googlesyndication.com',
    'tpc.googlesyndication.com',
    'googleads.g.doubleclick.net',
    'static.doubleclick.net',
    'stats.g.doubleclick.net',
    'cm.g.doubleclick.net',
    'ad.doubleclick.net',
  ];

  // SỬA ĐỔI: Cập nhật script chặn quảng cáo
  static const String _adBlockingScript = '''
    (function() {
      const adSelectors = [
        '[id*="ad"]', '[class*="ad"]', '[id*="banner"]', '[class*="banner"]',
        '[id*="sponsor"]', '[class*="sponsor"]', '[id*="popup"]', '[class*="popup"]',
        'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
        'iframe[src*="googleadservices"]', '.advertisement', '.ads', '.banner',
        '.sponsor', '.popup', '.advert', '#ads', '#advertisement', '#banner',
        'div[id*="google_ads"]', 'div[class*="google-ad"]'
      ];
      
      let removedCount = 0;
      function removeAds() {
        adSelectors.forEach(selector => {
          try {
            document.querySelectorAll(selector).forEach(el => {
              if (el && el.parentNode) {
                el.style.display = 'none !important';
                el.remove();
                removedCount++;
              }
            });
          } catch (e) {}
        });
        
        document.querySelectorAll('script').forEach(script => {
          if (script.src && script.src.includes('googlesyndication')) {
            script.remove();
            removedCount++;
          }
        });
      }
      
      removeAds();
      const observer = new MutationObserver(removeAds);
      observer.observe(document.body, { childList: true, subtree: true });
      console.log('Ad blocker executed. Removed ' + removedCount + ' elements.');
    })();
  ''';

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
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                setState(() {
                  isLoading = true;
                });
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                });
                // SỬA ĐỔI: Chỉ chạy script khi tính năng được bật
                if (_isAdBlockingEnabled) {
                  _injectAdBlockingScript();
                }
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('Web Resource Error: ${error.description}');
              },
              onNavigationRequest: (NavigationRequest request) {
                // SỬA ĐỔI: Chỉ chặn URL khi tính năng được bật
                if (_isAdBlockingEnabled && _isAdUrl(request.url)) {
                  if (mounted) {
                    setState(() {
                      _blockedAdsCount++;
                    });
                  }
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  // SỬA ĐỔI: Sử dụng danh sách domain mới
  bool _isAdUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return _adBlockList.any((adDomain) => uri.host.contains(adDomain));
  }

  // SỬA ĐỔI: Sử dụng script mới
  void _injectAdBlockingScript() {
    _controller.runJavaScript(_adBlockingScript);
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
                      'document.body.style.fontSize = "14px"',
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Trung bình'),
                  onTap: () {
                    _controller.runJavaScript(
                      'document.body.style.fontSize = "16px"',
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_increase),
                  title: const Text('Lớn'),
                  onTap: () {
                    _controller.runJavaScript(
                      'document.body.style.fontSize = "18px"',
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_increase),
                  title: const Text('Rất lớn'),
                  onTap: () {
                    _controller.runJavaScript(
                      'document.body.style.fontSize = "20px"',
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

  // SỬA ĐỔI: Hàm bật/tắt chặn quảng cáo
  void _toggleAdBlocking() {
    setState(() {
      _isAdBlockingEnabled = !_isAdBlockingEnabled;
      _blockedAdsCount = 0; // Reset bộ đếm
      isLoading = true; // Hiển thị loading khi reload
    });

    // Tải lại trang để áp dụng thay đổi
    _controller.reload();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAdBlockingEnabled
              ? '✅ Đã bật chặn quảng cáo. Trang sẽ được tải lại.'
              : '❌ Đã tắt chặn quảng cáo. Trang sẽ được tải lại.',
        ),
        backgroundColor: _isAdBlockingEnabled ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SỬA ĐỔI: Gọi super.build(context) để giữ state
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex =
        Provider.of<MainScreenProvider>(context).getCurrentIndex();

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(selectedIndex: selectedIndex),
      appBar: AppBar(
        elevation: 0, // Remove default shadow for a cleaner gradient
        backgroundColor: Colors.transparent, // Make AppBar transparent
        flexibleSpace: Container(
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
        shadowColor: Colors.transparent, // Remove shadow
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        title: const Text(
          "Điểm tin",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          // SỬA ĐỔI: Gom các nút vào PopupMenuButton, sắp xếp lại và chỉnh màu sắc
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
                  _controller.reload();
                  break;
                case 'toggle_adblock':
                  _toggleAdBlocking();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  // Item lưu tin
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
                  // Item chia sẻ
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
                  // Item sao chép link
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
                  // Item cỡ chữ
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
                  // Item tải lại
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
                  // Item bật/tắt chặn quảng cáo (đặt cuối, nổi bật)
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
          WebViewWidget(controller: _controller),
          if (isLoading)
            Container(
              color: (isDarkMode ? Colors.black : Colors.white).withOpacity(
                0.8,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Đang tải nội dung...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isAdBlockingEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🛡️ Chặn quảng cáo: Đang bật',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
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
                    (context) => NewsAnalysisScreen(newsData: widget.newsData),
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
