import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genews/features/news/data/models/news_data_model.dart';
import 'package:genews/features/analysis/views/news_summary_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:genews/shared/services/bookmarks_service.dart';
import 'package:genews/shared/utils/share_utils.dart';

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

class _NewsWebViewScreenState extends State<NewsWebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool isSaved = false;
  int _blockedAdsCount = 0;

  // Danh sách các domain quảng cáo phổ biến
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

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
    _setupWebViewController();
  }

  void _checkBookmarkStatus() async {
    final bookmarksService = BookmarksService();
    final saved = await bookmarksService.isArticleSaved(widget.newsData);
    setState(() {
      isSaved = saved;
    });
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
                _injectAdBlockCSS();
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('Web Resource Error: ${error.description}');
              },
              onNavigationRequest: (NavigationRequest request) {
                // Chặn các URL quảng cáo
                if (_isAdUrl(request.url)) {
                  setState(() {
                    _blockedAdsCount++;
                  });
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  bool _isAdUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    return _adBlockList.any((adDomain) => host.contains(adDomain));
  }

  void _injectAdBlockCSS() {
    const adBlockCSS = '''
      // Ẩn các element quảng cáo phổ biến
      var adSelectors = [
        '[id*="ad"]', '[class*="ad"]', '[id*="banner"]', '[class*="banner"]',
        '[id*="sponsor"]', '[class*="sponsor"]', '[id*="popup"]', '[class*="popup"]',
        'iframe[src*="doubleclick"]', 'iframe[src*="googlesyndication"]',
        'iframe[src*="googleadservices"]', '.advertisement', '.ads', '.banner',
        '.sponsor', '.popup', '.advert', '#ads', '#advertisement', '#banner',
        'div[id*="google_ads"]', 'div[class*="google-ad"]'
      ];
      
      adSelectors.forEach(function(selector) {
        var elements = document.querySelectorAll(selector);
        elements.forEach(function(element) {
          element.style.display = 'none !important';
        });
      });
      
      // Ẩn các script quảng cáo
      var scripts = document.querySelectorAll('script');
      scripts.forEach(function(script) {
        if (script.src && script.src.includes('googlesyndication')) {
          script.remove();
        }
      });
    ''';

    _controller.runJavaScript(adBlockCSS);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_blockedAdsCount > 0)
              Text(
                '🛡️ Đã chặn $_blockedAdsCount quảng cáo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () {
              setState(() {
                _blockedAdsCount = 0;
                isLoading = true;
              });
              _controller.reload();
            },
            tooltip: 'Tải lại',
          ),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.orange : Colors.black87,
            ),
            onPressed: _toggleSaved,
            tooltip: isSaved ? 'Bỏ lưu' : 'Lưu',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.black87),
            onPressed: () {
              shareNewsLink(
                context: context,
                url: widget.url,
                title: widget.title,
              );
            },
            tooltip: 'Chia sẻ',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) {
              switch (value) {
                case 'copy_link':
                  _copyLink();
                  break;
                case 'font_size':
                  _showFontSizeDialog();
                  break;
                case 'reload':
                  setState(() {
                    _blockedAdsCount = 0;
                    isLoading = true;
                  });
                  _controller.reload();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'copy_link',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 12),
                        Text('Sao chép liên kết'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'font_size',
                    child: Row(
                      children: [
                        Icon(Icons.text_fields, size: 20),
                        SizedBox(width: 12),
                        Text('Cỡ chữ'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reload',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 12),
                        Text('Tải lại & chặn quảng cáo'),
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
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải nội dung...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🛡️ Đang chặn quảng cáo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NewsAnalysisScreen(newsData: widget.newsData),
            ),
          );
        },
        tooltip: 'Tóm tắt AI',
        icon: const Icon(Icons.bolt, color: Colors.white),
        label: const Text(
          'Tóm tắt AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
