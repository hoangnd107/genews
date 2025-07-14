import 'package:webview_flutter/webview_flutter.dart';

class WebViewUtils {
  static const String optimizedUserAgent =
      'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36 '
      'GeNews/1.0';

  static const String performanceOptimizationScript = '''
    (function() {
      try {
        var images = document.querySelectorAll('img:not([loading])');
        images.forEach(function(img) {
          img.setAttribute('loading', 'lazy');
          img.style.maxWidth = '100%';
          img.style.height = 'auto';
        });

        var videos = document.querySelectorAll('video');
        videos.forEach(function(video) {
          video.style.maxWidth = '100%';
          video.style.height = 'auto';
          video.preload = 'metadata';
        });

        var unnecessaryElements = document.querySelectorAll(
          '.newsletter-signup, .subscribe-popup, .cookie-banner, ' +
          '.notification-bar, .floating-social, .sticky-sidebar, ' +
          '.related-posts-sidebar, .comment-form'
        );
        unnecessaryElements.forEach(function(el) {
          el.style.display = 'none';
        });

        // 4. Tối ưu font và typography
        var style = document.createElement('style');
        style.innerHTML = \`
          * { 
            -webkit-font-smoothing: antialiased !important;
            -moz-osx-font-smoothing: grayscale !important;
          }
          body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 
                         Roboto, 'Helvetica Neue', Arial, sans-serif !important;
            line-height: 1.6 !important;
            word-wrap: break-word !important;
          }
          img, video { 
            max-width: 100% !important; 
            height: auto !important; 
          }
          table { 
            width: 100% !important; 
            table-layout: fixed !important; 
          }
          pre, code { 
            white-space: pre-wrap !important; 
            word-wrap: break-word !important; 
          }
        \`;
        document.head.appendChild(style);

        // 5. Disable các script tracking không cần thiết
        var scripts = document.querySelectorAll('script[src*="analytics"], script[src*="tracking"]');
        scripts.forEach(function(script) {
          script.remove();
        });

        console.log('GeNews: Page optimized for mobile viewing');
      } catch (error) {
        console.log('GeNews: Optimization error:', error);
      }
    })();
  ''';

  static const String lightAdBlockScript = '''
    (function() {
      try {
        var adSelectors = [
          'iframe[src*="doubleclick"]',
          'iframe[src*="googlesyndication"]', 
          'iframe[src*="googleadservices"]',
          '[id*="google_ads"]',
          '.advertisement',
          '.ads',
          '.banner'
        ];
        
        var processedElements = new WeakSet();
        var removedCount = 0;
        
        function removeAdsEfficiently() {
          requestAnimationFrame(function() {
            adSelectors.forEach(function(selector) {
              try {
                var elements = document.querySelectorAll(selector);
                elements.forEach(function(el) {
                  if (!processedElements.has(el) && el.parentNode) {
                    el.style.display = 'none';
                    processedElements.add(el);
                    removedCount++;
                  }
                });
              } catch (e) {}
            });
          });
        }
        
        removeAdsEfficiently();
        
        // Observer nhẹ - chỉ observe khi thực sự cần thiết
        var observer = new MutationObserver(function(mutations) {
          var hasNewNodes = mutations.some(function(mutation) {
            return mutation.addedNodes.length > 0;
          });
          if (hasNewNodes) {
            removeAdsEfficiently();
          }
        });
        
        if (document.body) {
          observer.observe(document.body, { 
            childList: true, 
            subtree: true,
            attributes: false,
            characterData: false
          });
        }
        
        console.log('GeNews: Light ad blocker active, removed ' + removedCount + ' elements');
      } catch (error) {
        console.log('GeNews: Ad blocker error:', error);
      }
    })();
  ''';

  static WebViewController createOptimizedController({
    required String url,
    required Function(bool) onLoadingChanged,
    Function(String)? onPageStarted,
    Function(String)? onPageFinished,
    Function(WebResourceError)? onError,
    NavigationDecision Function(NavigationRequest)? onNavigationRequest,
    bool enableAdBlock = false,
  }) {
    late final WebViewController controller;

    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setUserAgent(optimizedUserAgent)
          ..enableZoom(false)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                onLoadingChanged(true);
                onPageStarted?.call(url);
              },
              onPageFinished: (String url) {
                onLoadingChanged(false);

                controller.runJavaScript(performanceOptimizationScript);

                if (enableAdBlock) {
                  controller.runJavaScript(lightAdBlockScript);
                }

                onPageFinished?.call(url);
              },
              onWebResourceError:
                  onError ??
                  (WebResourceError error) {
                    print('WebView Error: ${error.description}');
                  },
              onNavigationRequest:
                  onNavigationRequest ??
                  (NavigationRequest request) {
                    return NavigationDecision.navigate;
                  },
            ),
          );

    return controller;
  }

  static const List<String> basicAdDomains = [
    'doubleclick.net',
    'googleadservices.com',
    'googlesyndication.com',
    'google-analytics.com',
    'googletagmanager.com',
    'facebook.com/tr',
    'amazon-adsystem.com',
    'outbrain.com',
    'taboola.com',
    'ads.google.com',
    'pagead2.googlesyndication.com',
  ];

  static bool isAdUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    return basicAdDomains.any((domain) => uri.host.contains(domain));
  }

  static String getFontSizeScript(int fontSize) {
    return '''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = 'body, p, div, span, article { font-size: ${fontSize}px !important; }';
        document.head.appendChild(style);
      })();
    ''';
  }
}
