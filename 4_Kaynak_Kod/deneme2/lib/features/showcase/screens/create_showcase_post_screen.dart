// lib/features/showcase/screens/create_showcase_post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/showcase_provider.dart';

class CreateShowcasePostScreen extends StatefulWidget {
  const CreateShowcasePostScreen({super.key});

  @override
  State<CreateShowcasePostScreen> createState() => _CreateShowcasePostScreenState();
}

class _CreateShowcasePostScreenState extends State<CreateShowcasePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      // file_picker paketini kullanarak dosya seçimi penceresini aç
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      } else {
        // Kullanıcı dosya seçmeden pencereyi kapattı.
      }
    } catch (e) {
      // Hata yönetimi
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçerken bir hata oluştu: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return; // Zaten yükleniyorsa tekrar göndermeyi engelle

    // Önce dosya seçilmiş mi diye kontrol et
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir proje dosyası seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sonra formun geçerli olup olmadığını kontrol et
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final provider = Provider.of<ShowcaseProvider>(context, listen: false);
      final success = await provider.createShowcasePost(
        title: _titleController.text,
        description: _descriptionController.text,
        filePath: _selectedFile!.path,
      );

      setState(() => _isLoading = false);

      if (mounted) { // Widget'ın hala ekranda olduğundan emin ol
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gönderiniz başarıyla yayınlandı!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Başarılı olunca bir önceki ekrana dön
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gönderi yayınlanırken bir hata oluştu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Vitrin Gönderisi'),
        actions: [
          // Yüklenme durumunda butonu devre dışı bırak ve progress indicator göster
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))),
            )
          else
            TextButton(
              onPressed: _submit,
              child: const Text('Yayınla'),
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
              // Başlık alanı
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Proje Başlığı',
                  border: OutlineInputBorder(),
                  hintText: 'Örn: Endüstriyel Robot Kolu Tasarımı',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Başlık alanı boş bırakılamaz.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Açıklama alanı
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  border: OutlineInputBorder(),
                  hintText: 'Projeniz, kullandığınız yazılımlar ve metodlar hakkında bilgi verin.',
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 24),

              // Dosya seçme alanı
              Text('Proje Dosyası', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedFile == null
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_file, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Text('Dosya Seçmek İçin Tıklayın'),
                    ],
                  )
                      : Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFile!.path.split(Platform.pathSeparator).last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Desteklenen formatlar: .stp, .dwg, .rvt, .obj, .stl vb.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}