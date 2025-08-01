// lib/features/showcase/screens/create_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers/showcase_provider.dart';
import 'package:path_provider/path_provider.dart'; // Dosya yolu için gerekli
import 'package:path/path.dart' as path;
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.single.path != null) {
        const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'obj', 'glb', 'stl', 'gltf', 'stp', 'step', 'igs', 'iges', 'dwg', 'rvt'];
        final fileExtension = result.files.single.extension?.toLowerCase();

        if (fileExtension != null && allowedExtensions.contains(fileExtension)) {
          // --- YENİ EKLENEN KISIM: Dosyayı güvenli bir yere kopyala ---
          final tempFile = File(result.files.single.path!);
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(tempFile.path);
          final savedFile = await tempFile.copy('${appDir.path}/$fileName');

          setState(() => _selectedFile = savedFile); // Güvenli dosyayı state'e ata
          // --- YENİ KISIM SONU ---
        } else {
          _showSnackBar('Seçilen dosya formatı desteklenmiyor.', isSuccess: false);
        }
      }
    } catch (e) {
      _showSnackBar('Dosya seçilirken bir hata oluştu: $e', isSuccess: false);
    }
  }

  Future<void> _submitPost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFile == null) {
      _showSnackBar('Lütfen bir proje dosyası seçin.', isSuccess: false);
      return;
    }

    final provider = context.read<ShowcaseProvider>();
    final success = await provider.createPost(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      fileToUpload: _selectedFile!,
    );

    if (mounted && success) {
      _showSnackBar('Gönderiniz işlenmek üzere alındı! Kısa süre içinde vitrinde görünecektir.', isSuccess: true);
      Navigator.of(context).pop();
    }
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Bu kısım UI/UX açısından daha da güzelleştirilebilir, ancak şimdilik
    // temel işlevselliğe odaklanıyoruz.
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Proje Paylaş")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Başlık'),
                validator: (value) => value!.isEmpty ? 'Başlık boş olamaz' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
              ),
              const SizedBox(height: 20),
              _selectedFile == null
                  ? ElevatedButton(onPressed: _pickFile, child: const Text("Dosya Seç"))
                  : Column(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                Text(_selectedFile!.path.split('/').last),
                TextButton(onPressed: () => setState(() => _selectedFile = null), child: const Text("Dosyayı Kaldır"))
              ]),
              const Spacer(),
              Consumer<ShowcaseProvider>(
                builder: (context, provider, child) {
                  return provider.isCreatingPost
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: _submitPost, child: const Text("Paylaş"));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}