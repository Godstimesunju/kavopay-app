import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

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
    userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
  );

  Future<void> _saveBase64Image(String dataUrl, String filename) async {
    try {
      final base64Str = dataUrl.split(',').last;
      final bytes = base64Decode(base64Str);
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

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

            // JavaScript bridge for receipt downloads
            controller.addJavaScriptHandler(
              handlerName: 'downloadReceipt',
              callback: (args) async {
                if (args.isNotEmpty) {
                  final dataUrl = args[0].toString();
                  final filename = args.length > 1
                      ? args[1].toString()
                      : 'kavopay_receipt.png';
                  await _saveBase64Image(dataUrl, filename);
                }
              },
            );
          },
          onLoadStop: (controller, url) async {
            // Inject JS to intercept anchor downloads
            await controller.evaluateJavascript(source: '''
              (function(){
                const orig = HTMLAnchorElement.prototype.click;
                HTMLAnchorElement.prototype.click = function() {
                  if (this.download && this.href && this.href.startsWith('data:')) {
                    window.flutter_inappwebview.callHandler('downloadReceipt', this.href, this.download);
                    return;
                  }
                  orig.call(this);
                };
              })();
            ''');
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
