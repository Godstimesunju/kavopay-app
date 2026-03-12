import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KavopayApp());
}

class KavopayApp extends StatelessWidget {
  const KavopayApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kavopay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1aaba0)),
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071427),
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: WebUri('https://kavopay.web.app'),
          ),
          initialSettings: _settings,
          onWebViewCreated: (controller) {
            _controller = controller;
          },
          shouldOverrideUrlLoading: (controller, action) async {
            final url = action.request.url.toString();
            if (url.startsWith('https://accounts.google.com') ||
                url.startsWith('https://kavopay.web.app') ||
                url.startsWith('https://kavopay.firebaseapp.com')) {
              return NavigationActionPolicy.ALLOW;
            }
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            return NavigationActionPolicy.CANCEL;
          },
          onDownloadStartRequest: (controller, request) async {
            await launchUrl(Uri.parse(request.url.toString()),
                mode: LaunchMode.externalApplication);
          },
        ),
      ),
    );
  }
}
