// lib/features/showcase/screens/create_post_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/providers/showcase_provider.dart';


class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _submitAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _submitAnimation;

  File? _selectedFile;
  File? _selected3dModelFile;
  bool _isSubmitting = false;
  final _previewerKey = GlobalKey();
  bool _isPreviewGenerating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializeAnimations() {
    // ... içerik aynı
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _submitAnimation = CurvedAnimation(
      parent: _submitAnimationController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _pickFile() async {
    // ... içerik aynı
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );
      if (result != null) {
        setState(() {
          _selected3dModelFile = null;
          _selectedFile = File(result.files.single.path!);
        });
        _showSnackBar('Görsel başarıyla seçildi!', isSuccess: true);
      }
    } catch (e) {
      _showSnackBar('Görsel seçilirken bir hata oluştu', isSuccess: false);
    }
  }

  Future<void> _pick3dFile() async {
    // ... içerik aynı
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        const allowedExtensions = ['obj', 'glb', 'gltf', 'stl'];
        final fileExtension = result.files.single.extension?.toLowerCase();

        if (fileExtension != null && allowedExtensions.contains(fileExtension)) {
          final modelFile = File(result.files.single.path!);
          setState(() => _selected3dModelFile = modelFile);
          _showSnackBar('3D Model seçildi, önizleme oluşturuluyor...', isSuccess: true);
          _generatePreviewFrom3d(modelFile);
        } else {
          _showSnackBar('Geçersiz dosya formatı. Lütfen OBJ, GLB, STL, GLTF seçin.', isSuccess: false);
        }
      }
    } catch (e) {
      _showSnackBar('3D Model seçilirken bir hata oluştu: $e', isSuccess: false);
    }
  }

  // --- GÜNCELLENEN FONKSİYON: OTOMATİK ÖNİZLEME OLUŞTURUCU ---
  Future<void> _generatePreviewFrom3d(File modelFile) async {
    if (!mounted) return;
    setState(() {
      _isPreviewGenerating = true;
      _selectedFile = null;
    });

    try {
      // Artık kullanıcıya ne olduğunu gösteren bir dialog açıyoruz.
      showDialog(
        context: context,
        barrierDismissible: false, // Kullanıcı kapatamasın
        builder: (context) => Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modelin render olması için gizli bir RepaintBoundary kullanıyoruz
                RepaintBoundary(
                  key: _previewerKey,
                  child: SizedBox(
                    width: 500,
                    height: 500,
                    child: ModelViewer(
                      src: 'file://${modelFile.path}',
                      backgroundColor: Colors.transparent,
                      cameraControls: false,
                      autoRotate: true, // Model dönsün ki güzel bir açı yakalayalım
                    ),
                  ),
                ),
                // Kullanıcıya gösterilen kısım
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  "Modelden Önizleme Oluşturuluyor...",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      // Bekleme süresini büyük modeller için 5 saniyeye çıkarıyoruz
      await Future.delayed(const Duration(seconds: 5));

      if (_previewerKey.currentContext != null) {
        RenderRepaintBoundary boundary = _previewerKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 1.5);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(pngBytes);

        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Dialog'u kapat
          setState(() {
            _selectedFile = file;
          });
          _showSnackBar('Önizleme başarıyla oluşturuldu!', isSuccess: true);
        }
      } else {
        throw Exception("Preview context could not be found.");
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Önizleme oluşturulamadı: $e', isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isPreviewGenerating = false);
      }
    }
  }

  // ... (Geri kalan tüm fonksiyonlar ve build metodu aynı)
  void _removeFile() => setState(() {
    _selectedFile = null;
    if (_selected3dModelFile != null) {
      _selected3dModelFile = null;
    }
  });

  void _remove3dFile() => setState(() {
    _selected3dModelFile = null;
    if (_selectedFile != null) {
      _selectedFile = null;
    }
  });

  Future<void> _submitPost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedFile == null) {
      _showSnackBar('Lütfen bir proje ana görseli seçin.', isSuccess: false);
      return;
    }
    setState(() => _isSubmitting = true);
    final provider = Provider.of<ShowcaseProvider>(context, listen: false);
    try {
      final success = await provider.createPost(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageFile: _selectedFile,
        modelFile: _selected3dModelFile,
      );
      if (mounted) {
        if (success) {
          _showSnackBar('Proje başarıyla paylaşıldı! 🎉', isSuccess: true);
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.of(context).pop();
        } else {
          _showSnackBar(provider.errorMessage ?? 'Bir hata oluştu. Lütfen tekrar deneyin.', isSuccess: false);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    _submitAnimationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: _buildModernAppBar(theme, isDark),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(theme, isDark),
                  const SizedBox(height: 32),
                  _buildTitleSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(theme, isDark),
                  const SizedBox(height: 24),
                  _buildImageSection(theme, isDark),
                  const SizedBox(height: 24),
                  _build3dModelSection(theme, isDark),
                  const SizedBox(height: 40),
                  _buildSubmitButton(theme, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  AppBar _buildModernAppBar(ThemeData theme, bool isDark) => AppBar(
    backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: theme.primaryColor, size: 20), onPressed: () => Navigator.of(context).pop()),
    ),
    title: Text('Yeni Proje Paylaş', style: TextStyle(color: isDark ? Colors.white : Colors.grey[800], fontWeight: FontWeight.w700, fontSize: 20)),
    centerTitle: true,
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 16),
        child: Consumer<ShowcaseProvider>(builder: (context, provider, child) {
          return provider.isCreatingPost
              ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor)))))
              : ScaleTransition(
            scale: _submitAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _submitPost,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: const Text('PAYLAŞ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                ),
              ),
            ),
          );
        }),
      ),
    ],
  );
  Widget _buildWelcomeSection(ThemeData theme, bool isDark) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [theme.primaryColor.withOpacity(0.1), theme.primaryColor.withOpacity(0.05)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.primaryColor.withOpacity(0.2), width: 1),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.primaryColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
        child: const Icon(Icons.rocket_launch, color: Colors.white, size: 32),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Projenizi Dünyayla Paylaşın', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.grey[800])),
          const SizedBox(height: 8),
          Text('Yaratıcılığınızı gösterin ve topluluktan geri bildirim alın', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.4)),
        ]),
      ),
    ]),
  );
  Widget _buildTitleSection(ThemeData theme, bool isDark) => _buildSection(
    title: 'Proje Başlığı',
    subtitle: 'Projeniz için dikkat çekici bir başlık yazın',
    child: TextFormField(
      controller: _titleController,
      decoration: _buildInputDecoration(hintText: 'Örn: Akıllı Ev Kontrol Sistemi', prefixIcon: Icons.title, theme: theme, isDark: isDark),
      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.grey[800]),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'Başlık alanı boş bırakılamaz';
        if (value.trim().length < 3) return 'Başlık en az 3 karakter olmalıdır';
        return null;
      },
    ),
  );
  Widget _buildDescriptionSection(ThemeData theme, bool isDark) => _buildSection(
    title: 'Proje Açıklaması',
    subtitle: 'Projenizi detaylı olarak tanıtın',
    child: TextFormField(
      controller: _descriptionController,
      decoration: _buildInputDecoration(hintText: 'Projenizin özelliklerini, kullandığınız teknolojileri ve hikayesini anlatın...', prefixIcon: Icons.description, theme: theme, isDark: isDark),
      maxLines: 6,
      style: TextStyle(color: isDark ? Colors.white : Colors.grey[800], height: 1.5),
      validator: (value) {
        if (value != null && value.trim().length > 1000) return 'Açıklama 1000 karakterden fazla olamaz';
        return null;
      },
    ),
  );
  Widget _buildImageSection(ThemeData theme, bool isDark) => _buildSection(
    title: 'Proje Görseli',
    subtitle: 'Projenizi temsil eden bir kapak görseli ekleyin',
    child: _isPreviewGenerating
        ? Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 16),
            const Text('3D Modelden önizleme oluşturuluyor...'),
          ],
        ),
      ),
    )
        : _selectedFile != null
        ? _buildSelectedImagePreview(theme, isDark)
        : _buildImagePicker(theme, isDark),
  );
  Widget _buildSelectedImagePreview(ThemeData theme, bool isDark) => Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2)),
    child: Stack(children: [
      ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_selectedFile!, width: double.infinity, height: 200, fit: BoxFit.cover)),
      Positioned(top: 12, right: 12, child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: _removeFile))),
      Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: const Text('✓ Görsel seçildi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)))),
    ]),
  );
  Widget _buildImagePicker(ThemeData theme, bool isDark) => _buildFilePickerContainer(
    theme: theme,
    isDark: isDark,
    onTap: _pickFile,
    icon: Icons.image,
    title: 'Görsel Yükle',
    subtitle: 'JPG, PNG, GIF formatında\nMaksimum 15MB',
  );
  Widget _build3dModelSection(ThemeData theme, bool isDark) => _buildSection(
    title: '3D Model (Opsiyonel)',
    subtitle: 'Projenizi interaktif olarak tanıtacak bir 3D model ekleyin',
    child: _selected3dModelFile != null
        ? _buildSelectedFilePreview(
      theme: theme,
      isDark: isDark,
      file: _selected3dModelFile!,
      onRemove: _remove3dFile,
      label: '✓ 3D Model Seçildi',
      icon: Icons.view_in_ar,
    )
        : _build3dModelPicker(theme, isDark),
  );
  Widget _build3dModelPicker(ThemeData theme, bool isDark) => _buildFilePickerContainer(
    theme: theme,
    isDark: isDark,
    onTap: _pick3dFile,
    icon: Icons.view_in_ar,
    title: '3D Model Yükle',
    subtitle: 'OBJ, GLB, STL, GLTF formatında\nMaksimum 100MB',
  );
  Widget _buildSelectedFilePreview({required ThemeData theme, required bool isDark, required File file, required VoidCallback onRemove, required String label, required IconData icon}) {
    final fileName = file.path.split('/').last;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2)),
      child: Stack(children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1F1F1F) : Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 48, color: theme.primaryColor),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(fileName, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87))),
          ]),
        ),
        Positioned(top: 12, right: 12, child: Container(decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: onRemove))),
        Positioned(bottom: 12, left: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)))),
      ]),
    );
  }
  Widget _buildFilePickerContainer({required ThemeData theme, required bool isDark, required VoidCallback onTap, required IconData icon, required String title, required String subtitle}) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300, style: BorderStyle.solid),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[800])),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
          ]),
        ),
      ),
    ),
  );
  Widget _buildSubmitButton(ThemeData theme, bool isDark) => Container(
    width: double.infinity,
    height: 56,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.primaryColor,
          theme.primaryColor.withOpacity(0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.primaryColor.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSubmitting ? null : _submitPost,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Projeyi Paylaş',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          height: 1.4,
        ),
      ),
      const SizedBox(height: 16),
      child,
    ],
  );
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
    required bool isDark,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: Colors.grey[500],
      fontWeight: FontWeight.w400,
    ),
    prefixIcon: Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        prefixIcon,
        color: theme.primaryColor,
        size: 20,
      ),
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.primaryColor,
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    errorStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
  );
}