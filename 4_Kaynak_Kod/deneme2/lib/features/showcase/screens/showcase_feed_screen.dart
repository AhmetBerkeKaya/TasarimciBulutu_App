import 'package:deneme2/features/showcase/screens/showcase_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // İskelet yükleyici için
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/showcase_post_model.dart';
import 'create_showcase_post_screen.dart';

// Bu ekranları daha sonra oluşturacağız, şimdilik import ediyoruz.
// import 'create_showcase_post_screen.dart';

class ShowcaseFeedScreen extends StatefulWidget {
  const ShowcaseFeedScreen({super.key});

  @override
  State<ShowcaseFeedScreen> createState() => _ShowcaseFeedScreenState();
}

class _ShowcaseFeedScreenState extends State<ShowcaseFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran ilk açıldığında verileri çekmek için Provider'ı tetikle.
    // 'listen: false' initState içinde zorunludur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShowcaseProvider>(context, listen: false).fetchShowcasePosts();
    });

    // timeago için Türkçe dil desteğini ekleyelim
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı rolünü alalım, "Gönderi Ekle" butonu sadece freelancer'larda görünecek.
    final userRole = context.watch<AuthProvider>().user?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Vitrini'),
        centerTitle: false,
        actions: [
          // Sadece freelancer'lar yeni gönderi ekleyebilir.
          if (userRole == UserRole.freelancer)
            IconButton(
              icon: const Icon(Icons.add_box_outlined),
              tooltip: 'Yeni Gönderi Ekle',
              onPressed: () {
                // --- DEĞİŞİKLİK BURADA ---
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateShowcasePostScreen())
                );
                // --- DEĞİŞİKLİK SONU ---
              },
            ),
        ],
      ),
      // Consumer widget'ı, ShowcaseProvider'daki değişiklikleri dinler ve UI'ı yeniden çizer.
      body: Consumer<ShowcaseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.posts.isEmpty) {
            // Yükleniyorsa ve hiç gönderi yoksa, şık bir iskelet yükleyici göster.
            return const _ShowcaseSkeletonLoader();
          }

          if (provider.error != null) {
            // Bir hata varsa, kullanıcı dostu bir hata mesajı göster.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Gönderiler yüklenemedi.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                    onPressed: () => provider.fetchShowcasePosts(),
                  ),
                ],
              ),
            );
          }

          if (provider.posts.isEmpty) {
            // Hiç gönderi yoksa, kullanıcıyı teşvik eden bir boş durum ekranı göster.
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.palette_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Vitrinde Henüz Bir Şey Yok',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tasarımcıların projelerini paylaştığı ilk kişi olun!',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Her şey yolundaysa, gönderileri bir liste halinde göster.
          return RefreshIndicator(
            onRefresh: () => provider.fetchShowcasePosts(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12.0),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return _ShowcaseCard(post: post);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          );
        },
      ),
    );
  }
}

/// Tek bir vitrin gönderisini gösteren kart widget'ı
/// Tek bir vitrin gönderisini gösteren kart widget'ı
class _ShowcaseCard extends StatelessWidget {
  final ShowcasePost post;
  const _ShowcaseCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeAgo = timeago.format(post.createdAt, locale: 'tr');

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KART BAŞLIĞI: Kullanıcı bilgileri
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(post.owner.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.owner.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text(timeAgo, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
          ),

          // GÖNDERİ İÇERİĞİ: Başlık ve Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: theme.textTheme.titleLarge),
                if (post.description != null && post.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.description!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
                ]
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
          // GÖRSEL/MODEL ALANI: Tıklanabilir hale getirildi.
          InkWell(
            onTap: () {
              // Modelin bir URN'si var mı diye kontrol et.
              // Backend'de çeviri işlemi bittiğinde bu alan dolacak.
              if (post.apsUrn != null && post.apsUrn!.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShowcaseViewerScreen(
                      urn: post.apsUrn!,
                      title: post.title,
                    ),
                  ),
                );
              } else {
                // Eğer URN henüz yoksa (çeviri bitmemişse vs.) kullanıcıya bilgi ver
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bu model henüz görüntülenmeye hazır değil.')),
                );
              }
            },
            child: Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              // a- KUTU GÖRÜNÜMÜNÜ DURUMA GÖRE AYARLA
              decoration: BoxDecoration(
                color: post.apsTranslationStatus == 'failed'
                    ? Colors.red.shade50 // Hata durumu için kırmızımsı arka plan
                    : Colors.grey.shade200, // Diğer durumlar için standart gri
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: post.apsTranslationStatus == 'failed'
                      ? Colors.red.shade300 // Hata durumu için kırmızı çerçeve
                      : Colors.grey.shade300,
                ),
              ),
              // b- İÇERİĞİ DURUMA GÖRE GÖSTER
              child: InkWell(
                onTap: () {
                  // Sadece 'success' durumunda görüntüleyiciyi aç
                  if (post.apsTranslationStatus == 'success') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShowcaseViewerScreen(
                          urn: post.apsUrn!,
                          title: post.title,
                        ),
                      ),
                    );
                  } else {
                    // Diğer durumlarda bilgi mesajı göster
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                            post.apsTranslationStatus == 'failed'
                                ? 'Bu modelin işlenmesinde bir hata oluştu.'
                                : 'Model hala işleniyor, lütfen daha sonra tekrar deneyin.',
                          )),
                    );
                  }
                },
                // c- GÖRSEL İÇERİĞİ DURUMA GÖRE OLUŞTUR
                child: _buildVisualContent(context, post),
              ),
            ),
          ),
          // --- DEĞİŞİKLİK BURADA BİTİYOR ---

          const SizedBox(height: 8),

          // ETKİLEŞİM BUTONLARI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InteractionButton(icon: Icons.thumb_up_outlined, label: 'Beğen', onTap: () {}),
                _InteractionButton(icon: Icons.comment_outlined, label: 'Yorum Yap', onTap: () {}),
                _InteractionButton(icon: Icons.share_outlined, label: 'Paylaş', onTap: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }
}
// _ShowcaseCard sınıfının hemen altına bu yeni fonksiyonu ekle

Widget _buildVisualContent(BuildContext context, ShowcasePost post) {
  switch (post.apsTranslationStatus) {
    case 'inprogress':
    case 'pending':
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Model Hazırlanıyor...',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Bu işlem birkaç dakika sürebilir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    case 'failed':
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50, color: Colors.red.shade700),
            const SizedBox(height: 8),
            Text(
              'İşlem Başarısız Oldu',
              style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
            ),
            Text(
              'Dosya formatı desteklenmiyor olabilir.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ],
        ),
      );
    case 'success':
    default: // Varsayılan olarak 'success' durumunu göster
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_in_ar_outlined, size: 50, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              'Modeli Görüntülemek İçin Tıklayın',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              '(${post.originalFilename})',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
  }
}
/// Kart altındaki etkileşim butonları için özel widget
class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InteractionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: Colors.grey.shade700),
      label: Text(label, style: TextStyle(color: Colors.grey.shade800)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Veri yüklenirken gösterilecek iskelet (skeleton) widget'ı
class _ShowcaseSkeletonLoader extends StatelessWidget {
  const _ShowcaseSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: 5, // 5 tane sahte kart göster
        itemBuilder: (context, index) => const _SkeletonCard(),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
      ),
    );
  }
}

/// Tek bir iskelet kartının yapısı
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 80, height: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(width: double.infinity, height: 20, color: Colors.white),
          const SizedBox(height: 8),
          Container(width: 200, height: 14, color: Colors.white),
          const SizedBox(height: 12),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}