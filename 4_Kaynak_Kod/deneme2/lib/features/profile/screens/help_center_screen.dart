// ------------------------------------------------------------------
// DOSYA 2: lib/features/profile/screens/help_center_screen.dart (YENİ)
// ------------------------------------------------------------------
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım Merkezi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Sıkça Sorulan Sorular',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFaqSection(
            context,
            title: 'Freelancer\'lar İçin',
            questions: const {
              'Nasıl proje başvurusu yapabilirim?': 'Proje ilanları sayfasından ilgilendiğiniz projeyi seçip, detay sayfasındaki "Projeye Başvur" butonu ile teklifinizi ve kapak yazınızı gönderebilirsiniz.',
              'Profilimi nasıl daha çekici hale getirebilirim?': 'Profilinize yeteneklerinizi, geçmiş iş deneyimlerinizi ve özellikle görsel çalışmalarınızı içeren bir portfolyo eklemek, firmaların dikkatini çekmede en önemli faktördür.',
              'Değerlendirme sistemi nasıl çalışır?': 'Tamamlanan her proje sonrası, hem sizin firmayı hem de firmanın sizi değerlendirme hakkı bulunur. Aldığınız olumlu değerlendirmeler, profilinizin güvenilirliğini artırır.',
            },
          ),
          const SizedBox(height: 20),
          _buildFaqSection(
            context,
            title: 'Firmalar İçin',
            questions: const {
              'Nasıl proje yayınlarım?': 'Panelinizdeki "Proje Yayınla" butonu ile projenizin detaylarını, bütçesini ve aradığınız nitelikleri belirterek kolayca ilan oluşturabilirsiniz.',
              'Doğru freelancer\'ı nasıl seçerim?': 'Gelen başvuruları incelerken freelancer\'ların profillerini, portfolyolarını, yeteneklerini ve daha önceki işlerinden aldıkları değerlendirmeleri dikkatle incelemenizi öneririz.',
              'Proje tamamlama süreci nasıl işler?': 'Freelancer işi teslim ettiğinde, projeniz "İncelemede" sekmesine düşer. Teslimatı kontrol ettikten sonra "Onayla ve Tamamla" butonuyla projeyi sonlandırabilir veya "Revizyon İste" ile değişiklik talep edebilirsiniz.',
            },
          ),
          const Divider(height: 48),
          Center(
            child: Column(
              children: [
                Text("Aradığınızı bulamadınız mı?", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () { /* TODO: Canlı destek veya iletişim formu aç */ },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Destek Ekibiyle İletişime Geç"),
                ),
                const SizedBox(height: 8),
                const Text("(Yakında eklenecek Chatbot ile 7/24 destek)", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context, {required String title, required Map<String, String> questions}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(top: 0),
        children: questions.entries.map((entry) {
          return ExpansionTile(
            shape: const Border(), // İçteki ayırıcı çizgiyi kaldırır
            title: Text(entry.key, style: theme.textTheme.titleMedium),
            childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
            children: [
              Text(
                entry.value,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.grey.shade700),
              )
            ],
          );
        }).toList(),
      ),
    );
  }
}