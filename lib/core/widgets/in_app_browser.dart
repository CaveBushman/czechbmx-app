import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/app_colors.dart';

/// Otevře URL v in-app WebView. YouTube a jiné externí schémata se přesměrují
/// na nativní aplikaci — viz [_isExternalUrl].
class InAppBrowserScreen extends StatefulWidget {
  final String url;
  final String? title;

  const InAppBrowserScreen({super.key, required this.url, this.title});

  @override
  State<InAppBrowserScreen> createState() => _InAppBrowserScreenState();
}

class _InAppBrowserScreenState extends State<InAppBrowserScreen> {
  late final WebViewController _controller;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loadingProgress = 0),
        onProgress: (p) => setState(() => _loadingProgress = p),
        onPageFinished: (_) => setState(() => _loadingProgress = 100),
        onWebResourceError: (_) => setState(() => _loadingProgress = 100),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: _loadingProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                  minHeight: 2,
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

/// Otevři URL v in-app browseru. Vrátí Future, který se dokončí,
/// jakmile uživatel browser zavře (přes back / swipe).
Future<void> openInApp(BuildContext context, String url, {String? title}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (ctx, a1, a2) =>
          InAppBrowserScreen(url: url, title: title),
      transitionsBuilder: (ctx, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}
