import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapTilerWebView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  const MapTilerWebView({super.key, required this.latitude, required this.longitude, this.zoom = 11});

  @override
  State<MapTilerWebView> createState() => _MapTilerWebViewState();
}

class _MapTilerWebViewState extends State<MapTilerWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebViewPlatform.instance;
    final key = dotenv.env['MAPTILER_KEY'] ?? '';
    final url = 'https://api.maptiler.com/maps/streets-v2/?key=$key#${widget.zoom}/${widget.latitude}/${widget.longitude}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
