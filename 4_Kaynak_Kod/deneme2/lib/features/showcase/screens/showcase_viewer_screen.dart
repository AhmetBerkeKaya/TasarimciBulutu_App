// lib/features/showcase/screens/showcase_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../core/services/api_service.dart'; // ApiService'i import ediyoruz

class ShowcaseViewerScreen extends StatefulWidget {
  final String urn; // Görüntülenecek modelin kimliği (Base64 formatında)
  final String title; // AppBar'da gösterilecek başlık

  const ShowcaseViewerScreen({
    super.key,
    required this.urn,
    required this.title,
  });

  @override
  State<ShowcaseViewerScreen> createState() => _ShowcaseViewerScreenState();
}

class _ShowcaseViewerScreenState extends State<ShowcaseViewerScreen> {
  InAppWebViewController? _webViewController;
  final ApiService _apiService = ApiService(); // ApiService'ten bir instance oluştur

  String? _token;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  // Backend'den APS token'ını almak için fonksiyon
  Future<void> _fetchToken() async {
    try {
      final response = await _apiService.getViewerToken();
      if (mounted) {
        setState(() {
          _token = response['access_token'];
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Görüntüleyici başlatılamadı: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_token != null) // Token başarıyla alındıysa WebView'i göster
            InAppWebView(
              initialFile: "assets/html/viewer.html", // Oluşturduğumuz HTML dosyasını yükle
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              // HTML sayfası yüklenmeyi bitirdiğinde bu fonksiyon çalışır
              onLoadStop: (controller, url) {
                // Yükleme bitince ve token varsa, JavaScript fonksiyonunu çağırarak modeli yükle
                if (_token != null) {
                  controller.evaluateJavascript(source: "initializeViewer('${widget.urn}', '$_token');");
                }
                setState(() {
                  _isLoading = false;
                });
              },
              onLoadError: (controller, url, code, message) {
                setState(() {
                  _error = "WebView yüklenirken hata oluştu: $message";
                  _isLoading = false;
                });
              },
            ),

          // Yüklenirken veya hata durumunda gösterilecek UI elemanları
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          if (_error != null && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}