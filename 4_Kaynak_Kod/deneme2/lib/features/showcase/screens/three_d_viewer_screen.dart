// lib/features/showcase/screens/three_d_viewer_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThreeDViewerScreen extends StatefulWidget {
  final String modelUrl;
  final String title;

  const ThreeDViewerScreen({
    super.key,
    required this.modelUrl,
    required this.title,
  });

  @override
  State<ThreeDViewerScreen> createState() => _ThreeDViewerScreenState();
}

class _ThreeDViewerScreenState extends State<ThreeDViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkModelUrl();
  }

  Future<void> _checkModelUrl() async {
    // URL boş veya null ise hiç deneme
    if (widget.modelUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Geçerli bir model URL'si bulunamadı.";
      });
      return;
    }

    try {
      final dio = Dio();
      final response = await dio.head(widget.modelUrl);

      if (response.statusCode != 200) {
        throw 'Dosya bulunamadı veya erişim izni yok. (Hata Kodu: ${response.statusCode})';
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });

    } catch (e) {
      print("URL Check Error: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Model URL\'sine erişilemiyor. Lütfen S3 dosya izinlerini (CORS) veya URL\'yi kontrol edin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Model URL\'si kontrol ediliyor...', style: TextStyle(color: Colors.white)),
        ],
      );
    } else if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('Model Yüklenemedi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          ],
        ),
      );
    } else {
      // Her şey yolunda, veritabanından gelen modeli gösteriyoruz
      return ModelViewer(
        src: widget.modelUrl,
        alt: "A 3D model of ${widget.title}",
        ar: true,
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Colors.black,
      );
    }
  }
}