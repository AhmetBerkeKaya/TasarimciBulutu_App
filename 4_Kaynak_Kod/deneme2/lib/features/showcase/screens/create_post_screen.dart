// lib/features/showcase/screens/create_post_screen.dart

import 'dart:io'; // YENİ IMPORT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // YENİ IMPORT
import '../../../core/providers/showcase_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile; // YENİ: Seçilen dosyayı tutacak state

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image, // Sadece resim seçilmesine izin veriyoruz
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      print("Dosya seçme hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dosya seçilirken bir hata oluştu.")),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = Provider.of<ShowcaseProvider>(context, listen: false);

    final success = await provider.createPost(
      title: _titleController.text,
      description: _descriptionController.text,
      fileToUpload: _selectedFile, // YENİ: Seçilen dosyayı provider'a gönder
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderiniz başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShowcaseProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Gönderi Oluştur'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: provider.isCreatingPost
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator()))
                : TextButton(
              onPressed: _submitPost,
              child: const Text('YAYINLA'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gönderi Başlığı', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Projenize dikkat çekici bir başlık verin',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık alanı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text('Açıklama (İsteğe Bağlı)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Projenizin detaylarını, kullandığınız teknolojileri veya hikayesini anlatın...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // --- YENİ DOSYA YÜKLEME BÖLÜMÜ ---
              Text('Görsel Ekle (İsteğe Bağlı)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_selectedFile != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedFile!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                      onPressed: () => setState(() => _selectedFile = null),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Dosya Seç'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              // --- BİTTİ ---
            ],
          ),
        ),
      ),
    );
  }
}
