// import 'package:flutter/material.dart';
// import 'package:genews/features/news/data/models/news_data_model.dart';
// import 'package:genews/features/analysis/views/news_summary_screen.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:genews/shared/services/bookmarks_service.dart';
// import 'package:genews/shared/utils/share_utils.dart';

// class NewsWebViewScreen extends StatefulWidget {
//   final String url;
//   final String title;
//   final Result newsData;

//   const NewsWebViewScreen({
//     super.key,
//     required this.url,
//     required this.title,
//     required this.newsData,
//   });

//   @override
//   State<NewsWebViewScreen> createState() => _NewsWebViewScreenState();
// }

// class _NewsWebViewScreenState extends State<NewsWebViewScreen> {
//   late final WebViewController _controller;
//   bool isLoading = true;
//   bool _isBookmarked = false;
//   final BookmarksService _bookmarksService = BookmarksService();

//   // Danh sách các domain quảng cáo phổ biến
//   static const List<String> _adBlockList = [
//     'doubleclick.net',
//     'googleadservices.com',
//     'googlesyndication.com',
//     'google-analytics.com',
//     'googletagmanager.com',
//     'facebook.com/tr',
//     'facebook.net',
//     'amazon-adsystem.com',
//     'adsystem.com',
//     'ads.yahoo.com',
//     'bing.com/search',
//     'outbrain.com',
//     'taboola.com',
//     'addthis.com',
//     'sharethis.com',
//     'scorecardresearch.com',
//     'quantserve.com',
//     'hotjar.com',
//     'mouseflow.com',
//     'crazyegg.com',
//     'adsystem',
//     'adnxs.com',
//     'adsystem.com',
//     'pubmatic.com',
//     'rubiconproject.com',
//     'openx.net',
//     'adsystem.net',
//     'advertising.com',
//     'ads.twitter.com',
//     'analytics.twitter.com',
//     'ads.linkedin.com',
//     'ads.pinterest.com',
//     'ads.tiktok.com',
//     'adform.net',
//     'adsrvr.org',
//     'amazon-advertising.com',
//     'criteo.com',
//     'adsystem.com',
//     'turn.com',
//     'rlcdn.com',
//     'serving-sys.com',
//     'moatads.com',
//     'adsystem.com',
//     'adroll.com',
//     'adsystem.com',
//     'casalemedia.com',
//     'contextweb.com',
//     'exponential.com',
//     'indexww.com',
//     'sharethrough.com',
//     'sovrn.com',
//     'spotxchange.com',
//     'springserve.com',
//     'teads.tv',
//     'tidaltv.com',
//     'undertone.com',
//     'yieldmo.com',
//     'ads.google.com',
//     'www.googletagservices.com',
//     'pagead2.googlesyndication.com',
//     'tpc.googlesyndication.com',
//     'googleads.g.doubleclick.net',
//     'static.doubleclick.net',
//     'stats.g.doubleclick.net',
//     'cm.g.doubleclick.net',
//     'ad.doubleclick.net',
//     'ads30.adnxs.com',
//     'ib.adnxs.com',
//     'secure.adnxs.com',
//     'nym1-ib.adnxs.com',
//     'prg-ib.adnxs.com',
//     'sin1-ib.adnxs.com',
//     'lax1-ib.adnxs.com',
//     'ams1-ib.adnxs.com',
//   ];

//   // JavaScript để ẩn quảng cáo
//   static const String _adBlockingScript = '''
//     (function() {
//       // Ẩn các element có class hoặc id liên quan đến quảng cáo
//       const adSelectors = [
//         '[id*="ad"]', '[class*="ad"]', '[id*="banner"]', '[class*="banner"]',
//         '[id*="popup"]', '[class*="popup"]', '[id*="sponsor"]', '[class*="sponsor"]',
//         '.advertisement', '.ads', '.adsbygoogle', '.ad-container', '.ad-banner',
//         '.banner-ad', '.google-ad', '.fb-ad', '.twitter-ad', '.linkedin-ad',
//         '.promo', '.promotional', '.marketing', '.commercial',
//         'iframe[src*="ads"]', 'iframe[src*="doubleclick"]', 'iframe[src*="google"]',
//         'div[data-ad]', 'div[data-ads]', 'section[data-ad]',
//         '.outbrain', '.taboola', '.content-ads', '.sidebar-ads',
//         '.header-ads', '.footer-ads', '.inline-ads', '.video-ads',
//         '.native-ads', '.display-ads', '.banner-ads', '.popup-ads',
//         '.interstitial', '.overlay-ad', '.floating-ad', '.sticky-ad'
//       ];
      
//       function removeAds() {
//         adSelectors.forEach(selector => {
//           try {
//             const elements = document.querySelectorAll(selector);
//             elements.forEach(el => {
//               if (el && el.parentNode) {
//                 el.style.display = 'none';
//                 el.style.visibility = 'hidden';
//                 el.style.opacity = '0';
//                 el.style.height = '0px';
//                 el.style.width = '0px';
//                 el.remove();
//               }
//             });
//           } catch(e) {
//             console.log('Error removing ads:', e);
//           }
//         });
        
//         // Xóa các script tag có chứa quảng cáo
//         const scripts = document.querySelectorAll('script');
//         scripts.forEach(script => {
//           const src = script.src || '';
//           const content = script.innerHTML || '';
//           if (src.includes('ads') || src.includes('doubleclick') || 
//               content.includes('adsystem') || content.includes('googletag')) {
//             script.remove();
//           }
//         });
//       }
      
//       // Chạy ngay lập tức
//       removeAds();
      
//       // Chạy khi DOM ready
//       if (document.readyState === 'loading') {
//         document.addEventListener('DOMContentLoaded', removeAds);
//       }
      
//       // Chạy sau khi trang load xong
//       window.addEventListener('load', removeAds);
      
//       // Theo dõi thay đổi DOM và xóa quảng cáo mới
//       const observer = new MutationObserver(function(mutations) {
//         let shouldRemoveAds = false;
//         mutations.forEach(function(mutation) {
//           if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
//             shouldRemoveAds = true;
//           }
//         });
//         if (shouldRemoveAds) {
//           setTimeout(removeAds, 100);
//         }
//       });
      
//       observer.observe(document.body, {
//         childList: true,
//         subtree: true
//       });
//     })();
//   ''';

//   @override
//   void initState() {
//     super.initState();
//     _checkIfBookmarked();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               isLoading = true;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               isLoading = false;
//             });
//             _injectAdBlockingScript();
//           },
//           onWebResourceError: (WebResourceError error) {
//             debugPrint('Lỗi: ${error.description}');
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             final uri = Uri.parse(request.url);
//             final domain = uri.host.toLowerCase();
            
//             for (String blockedDomain in _adBlockList) {
//               if (domain.contains(blockedDomain.toLowerCase())) {
//                 debugPrint('🚫 Blocked ad domain: $domain');
//                 return NavigationDecision.prevent;
//               }
//             }
            
//             final url = request.url.toLowerCase();
//             final adKeywords = [
//               '/ads/', '/ad/', '/banner/', '/popup/', '/sponsor/',
//               'advertisement', 'adsystem', 'adservice', 'adserver',
//               'doubleclick', 'googlesyndication', 'googleadservices',
//               'outbrain', 'taboola', 'addthis', 'sharethis'
//             ];
            
//             for (String keyword in adKeywords) {
//               if (url.contains(keyword)) {
//                 debugPrint('🚫 Blocked ad URL: ${request.url}');
//                 return NavigationDecision.prevent;
//               }
//             }
            
//             return NavigationDecision.navigate;
//           },
//         ),
//       )
//       ..loadRequest(Uri.parse(widget.url));
//   }

//   void _injectAdBlockingScript() async {
//     try {
//       await _controller.runJavaScript(_adBlockingScript);
//       debugPrint('✅ Ad blocking script injected successfully');
      
//       await Future.delayed(const Duration(seconds: 2));
//       await _controller.runJavaScript(_adBlockingScript);
      
//       await Future.delayed(const Duration(seconds: 3));
//       await _controller.runJavaScript(_adBlockingScript);
//     } catch (e) {
//       debugPrint('❌ Error injecting ad blocking script: $e');
//     }
//   }

//   void _checkIfBookmarked() async {
//     try {
//       final isSaved = await _bookmarksService.isArticleSaved(widget.newsData);
//       if (mounted) {
//         setState(() {
//           _isBookmarked = isSaved;
//         });
//       }
//     } catch (e) {
//       debugPrint('Lỗi khi kiểm tra bookmark: $e');
//       if (mounted) {
//         setState(() {
//           _isBookmarked = false;
//         });
//       }
//     }
//   }

//   void _toggleBookmark() async {
//     try {
//       bool newBookmarkState;
//       String message;

//       if (_isBookmarked) {
//         final success = await _bookmarksService.removeArticle(widget.newsData);
//         newBookmarkState = !success;
//         message = success ? 'Đã bỏ lưu tin tức' : 'Lỗi khi bỏ lưu tin tức';
//       } else {
//         final success = await _bookmarksService.saveArticle(widget.newsData);
//         newBookmarkState = success;
//         message = success ? 'Đã lưu tin tức' : 'Lỗi khi lưu tin tức';
//       }

//       if (mounted) {
//         setState(() {
//           _isBookmarked = newBookmarkState;
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(
//                   _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(message),
//               ],
//             ),
//             backgroundColor: _isBookmarked ? Colors.green : Colors.orange,
//             duration: const Duration(seconds: 2),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint('Lỗi khi toggle bookmark: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     }
//   }

//   void _shareNews() {
//     shareNewsLink(
//       context: context,
//       url: widget.url,
//       title: widget.title,
//     );
//   }

//   void _showNotifications() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.notifications, color: Colors.white, size: 20),
//             SizedBox(width: 8),
//             Text('Chức năng thông báo đang được phát triển'),
//           ],
//         ),
//         duration: Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _reloadAndBlockAds() {
//     _controller.reload();
//     Future.delayed(const Duration(seconds: 1), () {
//       _injectAdBlockingScript();
//     });
    
//     // Hiển thị thông báo đang tải lại
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.refresh, color: Colors.white, size: 20),
//             SizedBox(width: 8),
//             Text('Đang tải lại và chặn quảng cáo...'),
//           ],
//         ),
//         duration: Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _blockAdsManually() {
//     _injectAdBlockingScript();
    
//     // Hiển thị thông báo
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Row(
//           children: [
//             Icon(Icons.block, color: Colors.white, size: 20),
//             SizedBox(width: 8),
//             Text('Đang chặn quảng cáo...'),
//           ],
//         ),
//         duration: Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Điểm tin"),
//         backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
//         foregroundColor: isDarkMode ? Colors.white : Colors.black87,
//         elevation: 1,
//         shadowColor: Colors.black.withOpacity(0.1),
//         actions: [
//           PopupMenuButton<String>(
//             color: isDarkMode ? Colors.grey[800] : Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             elevation: 8,
//             onSelected: (value) {
//               switch (value) {
//                 case 'refresh':
//                   _reloadAndBlockAds();
//                   break;
//                 case 'notifications':
//                   _showNotifications();
//                   break;
//                 case 'block_ads':
//                   _blockAdsManually();
//                   break;
//                 case 'share':
//                   _shareNews();
//                   break;
//                 case 'bookmark':
//                   _toggleBookmark();
//                   break;
//               }
//             },
//             itemBuilder: (context) => [
//               // Tải lại trang
//               PopupMenuItem(
//                 value: 'refresh',
//                 child: Row(
//                   children: [
//                     const Icon(Icons.refresh, size: 20),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Tải lại trang',
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Thông báo
//               PopupMenuItem(
//                 value: 'notifications',
//                 child: Row(
//                   children: [
//                     const Icon(Icons.notifications_outlined, size: 20, color: Colors.purple),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Thông báo',
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Divider
//               PopupMenuItem(
//                 enabled: false,
//                 child: Divider(
//                   color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
//                   height: 1,
//                 ),
//               ),
              
//               // Chặn quảng cáo
//               PopupMenuItem(
//                 value: 'block_ads',
//                 child: Row(
//                   children: [
//                     const Icon(Icons.block, size: 20, color: Colors.red),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Chặn quảng cáo',
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Chia sẻ
//               PopupMenuItem(
//                 value: 'share',
//                 child: Row(
//                   children: [
//                     const Icon(Icons.ios_share, size: 20, color: Colors.blue),
//                     const SizedBox(width: 12),
//                     Text(
//                       'Chia sẻ tin tức',
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Bookmark
//               PopupMenuItem(
//                 value: 'bookmark',
//                 child: Row(
//                   children: [
//                     Icon(
//                       _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
//                       size: 20,
//                       color: _isBookmarked ? Colors.orange : (isDarkMode ? Colors.white : Colors.black87),
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       _isBookmarked ? 'Bỏ lưu' : 'Lưu tin tức',
//                       style: TextStyle(
//                         color: isDarkMode ? Colors.white : Colors.black87,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               child: const Icon(Icons.more_vert),
//             ),
//           ),
          
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (isLoading)
//             Container(
//               color: isDarkMode 
//                   ? Colors.black.withOpacity(0.7)
//                   : Colors.white.withOpacity(0.7),
//               child: const Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text(
//                       'Đang tải nội dung...',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       '🚫 Đang chặn quảng cáo...',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.red,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => NewsAnalysisScreen(newsData: widget.newsData),
//             ),
//           );
//         },
//         tooltip: 'Tóm tắt',
//         backgroundColor: Colors.orange,
//         foregroundColor: Colors.white,
//         icon: const Icon(Icons.bolt),
//         label: const Text(
//           'Tóm tắt',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
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
  bool _isBookmarked = false;
  bool _isAdBlockingEnabled = false; // THÊM: Trạng thái chặn quảng cáo
  final BookmarksService _bookmarksService = BookmarksService();

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
    'adsystem',
    'adnxs.com',
    'adsystem.com',
    'pubmatic.com',
    'rubiconproject.com',
    'openx.net',
    'adsystem.net',
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
    'adsystem.com',
    'turn.com',
    'rlcdn.com',
    'serving-sys.com',
    'moatads.com',
    'adsystem.com',
    'adroll.com',
    'adsystem.com',
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
    'ads30.adnxs.com',
    'ib.adnxs.com',
    'secure.adnxs.com',
    'nym1-ib.adnxs.com',
    'prg-ib.adnxs.com',
    'sin1-ib.adnxs.com',
    'lax1-ib.adnxs.com',
    'ams1-ib.adnxs.com',
  ];

  // JavaScript để ẩn quảng cáo
  static const String _adBlockingScript = '''
    (function() {
      // Ẩn các element có class hoặc id liên quan đến quảng cáo
      const adSelectors = [
        '[id*="ad"]', '[class*="ad"]', '[id*="banner"]', '[class*="banner"]',
        '[id*="popup"]', '[class*="popup"]', '[id*="sponsor"]', '[class*="sponsor"]',
        '.advertisement', '.ads', '.adsbygoogle', '.ad-container', '.ad-banner',
        '.banner-ad', '.google-ad', '.fb-ad', '.twitter-ad', '.linkedin-ad',
        '.promo', '.promotional', '.marketing', '.commercial',
        'iframe[src*="ads"]', 'iframe[src*="doubleclick"]', 'iframe[src*="google"]',
        'div[data-ad]', 'div[data-ads]', 'section[data-ad]',
        '.outbrain', '.taboola', '.content-ads', '.sidebar-ads',
        '.header-ads', '.footer-ads', '.inline-ads', '.video-ads',
        '.native-ads', '.display-ads', '.banner-ads', '.popup-ads',
        '.interstitial', '.overlay-ad', '.floating-ad', '.sticky-ad'
      ];
      
      function removeAds() {
        let removedCount = 0;
        adSelectors.forEach(selector => {
          try {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
              if (el && el.parentNode) {
                el.style.display = 'none';
                el.style.visibility = 'hidden';
                el.style.opacity = '0';
                el.style.height = '0px';
                el.style.width = '0px';
                el.remove();
                removedCount++;
              }
            });
          } catch(e) {
            console.log('Error removing ads:', e);
          }
        });
        
        // Xóa các script tag có chứa quảng cáo
        const scripts = document.querySelectorAll('script');
        scripts.forEach(script => {
          const src = script.src || '';
          const content = script.innerHTML || '';
          if (src.includes('ads') || src.includes('doubleclick') || 
              content.includes('adsystem') || content.includes('googletag')) {
            script.remove();
            removedCount++;
          }
        });
        
        console.log('🚫 Removed ' + removedCount + ' ad elements');
        return removedCount;
      }
      
      // Chạy ngay lập tức
      const initialRemoved = removeAds();
      
      // Chạy khi DOM ready
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', removeAds);
      }
      
      // Chạy sau khi trang load xong
      window.addEventListener('load', removeAds);
      
      // Theo dõi thay đổi DOM và xóa quảng cáo mới
      const observer = new MutationObserver(function(mutations) {
        let shouldRemoveAds = false;
        mutations.forEach(function(mutation) {
          if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
            shouldRemoveAds = true;
          }
        });
        if (shouldRemoveAds) {
          setTimeout(removeAds, 100);
        }
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      return initialRemoved;
    })();
  ''';

  @override
  void initState() {
    super.initState();
    _checkIfBookmarked();
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
                // REMOVED: Không tự động chặn quảng cáo nữa
                // _injectAdBlockingScript();
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('Lỗi: ${error.description}');
              },
              // CẬP NHẬT: Chỉ chặn khi _isAdBlockingEnabled = true
              onNavigationRequest: (NavigationRequest request) {
                if (!_isAdBlockingEnabled) {
                  return NavigationDecision.navigate; // Không chặn gì cả
                }

                final uri = Uri.parse(request.url);
                final domain = uri.host.toLowerCase();

                for (String blockedDomain in _adBlockList) {
                  if (domain.contains(blockedDomain.toLowerCase())) {
                    debugPrint('🚫 Blocked ad domain: $domain');
                    return NavigationDecision.prevent;
                  }
                }

                final url = request.url.toLowerCase();
                final adKeywords = [
                  '/ads/',
                  '/ad/',
                  '/banner/',
                  '/popup/',
                  '/sponsor/',
                  'advertisement',
                  'adsystem',
                  'adservice',
                  'adserver',
                  'doubleclick',
                  'googlesyndication',
                  'googleadservices',
                  'outbrain',
                  'taboola',
                  'addthis',
                  'sharethis',
                ];

                for (String keyword in adKeywords) {
                  if (url.contains(keyword)) {
                    debugPrint('🚫 Blocked ad URL: ${request.url}');
                    return NavigationDecision.prevent;
                  }
                }

                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  // CẬP NHẬT: Method để inject script chặn quảng cáo
  void _injectAdBlockingScript() async {
    if (!_isAdBlockingEnabled) return; // Chỉ chạy khi được bật

    try {
      await _controller.runJavaScript(_adBlockingScript);
      debugPrint('✅ Ad blocking script injected successfully');

      await Future.delayed(const Duration(seconds: 2));
      if (_isAdBlockingEnabled) {
        // Check lại trước khi chạy
        await _controller.runJavaScript(_adBlockingScript);
      }

      await Future.delayed(const Duration(seconds: 3));
      if (_isAdBlockingEnabled) {
        // Check lại trước khi chạy
        await _controller.runJavaScript(_adBlockingScript);
      }
    } catch (e) {
      debugPrint('❌ Error injecting ad blocking script: $e');
    }
  }

  void _checkIfBookmarked() async {
    try {
      final isSaved = await _bookmarksService.isArticleSaved(widget.newsData);
      if (mounted) {
        setState(() {
          _isBookmarked = isSaved;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra bookmark: $e');
      if (mounted) {
        setState(() {
          _isBookmarked = false;
        });
      }
    }
  }

  void _toggleBookmark() async {
    try {
      bool newBookmarkState;
      String message;

      if (_isBookmarked) {
        final success = await _bookmarksService.removeArticle(widget.newsData);
        newBookmarkState = !success;
        message = success ? 'Đã bỏ lưu tin tức' : 'Lỗi khi bỏ lưu tin tức';
      } else {
        final success = await _bookmarksService.saveArticle(widget.newsData);
        newBookmarkState = success;
        message = success ? 'Đã lưu tin tức' : 'Lỗi khi lưu tin tức';
      }

      if (mounted) {
        setState(() {
          _isBookmarked = newBookmarkState;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(message),
              ],
            ),
            backgroundColor: _isBookmarked ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi toggle bookmark: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi xảy ra. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _shareNews() {
    shareNewsLink(context: context, url: widget.url, title: widget.title);
  }

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Chức năng thông báo đang được phát triển'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reloadAndBlockAds() {
    _controller.reload();

    // Hiển thị thông báo đang tải lại
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.refresh, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Đang tải lại trang...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // CẬP NHẬT: Toggle chặn quảng cáo
  void _toggleAdBlocking() {
    setState(() {
      _isAdBlockingEnabled = !_isAdBlockingEnabled;
    });

    if (_isAdBlockingEnabled) {
      // Bật chặn quảng cáo và chạy script ngay
      _injectAdBlockingScript();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.block, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('✅ Đã bật chặn quảng cáo'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // Tắt chặn quảng cáo và reload trang
      _controller.reload();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('❌ Đã tắt chặn quảng cáo'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openInBrowser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.open_in_browser, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Chức năng mở trình duyệt ngoài đang được phát triển'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title.isNotEmpty ? widget.title : "Điểm tin",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          // Menu tùy chọn (3 chấm)
          PopupMenuButton<String>(
            color: isDarkMode ? Colors.grey[800] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _reloadAndBlockAds();
                  break;
                case 'toggle_adblock':
                  _toggleAdBlocking();
                  break;
                case 'share':
                  _shareNews();
                  break;
                case 'bookmark':
                  _toggleBookmark();
                  break;
                case 'notifications':
                  _showNotifications();
                  break;
                case 'open_browser':
                  _openInBrowser();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  // Tải lại trang
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Tải lại trang',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  PopupMenuItem(
                    enabled: false,
                    child: Divider(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      height: 1,
                    ),
                  ),

                  // CẬP NHẬT: Toggle chặn quảng cáo
                  PopupMenuItem(
                    value: 'toggle_adblock',
                    child: Row(
                      children: [
                        Icon(
                          _isAdBlockingEnabled ? Icons.block : Icons.ads_click,
                          size: 20,
                          color:
                              _isAdBlockingEnabled ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isAdBlockingEnabled
                              ? 'Tắt chặn quảng cáo'
                              : 'Bật chặn quảng cáo',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chia sẻ
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, size: 20, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          'Chia sẻ tin tức',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bookmark
                  PopupMenuItem(
                    value: 'bookmark',
                    child: Row(
                      children: [
                        Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          size: 20,
                          color:
                              _isBookmarked
                                  ? Colors.orange
                                  : (isDarkMode
                                      ? Colors.white
                                      : Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isBookmarked ? 'Bỏ lưu' : 'Lưu tin tức',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  PopupMenuItem(
                    enabled: false,
                    child: Divider(
                      color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      height: 1,
                    ),
                  ),

                  // Thông báo
                  PopupMenuItem(
                    value: 'notifications',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thông báo',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mở trình duyệt ngoài
                  PopupMenuItem(
                    value: 'open_browser',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.open_in_browser,
                          size: 20,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Mở trình duyệt ngoài',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.more_vert),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Container(
              color:
                  isDarkMode
                      ? Colors.black.withOpacity(0.7)
                      : Colors.white.withOpacity(0.7),
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
                    const SizedBox(height: 8),
                    Text(
                      _isAdBlockingEnabled
                          ? '🚫 Chặn quảng cáo: BẬT'
                          : '✅ Chặn quảng cáo: TẮT',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isAdBlockingEnabled ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // THÊM: Indicator trạng thái chặn quảng cáo ở góc màn hình
          if (_isAdBlockingEnabled)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Chặn QC',
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
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.bolt),
        label: const Text(
          'Tóm tắt AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
