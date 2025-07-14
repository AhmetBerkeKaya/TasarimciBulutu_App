// ------------------------------------------------------------------
// DOSYA 3: lib/features/profile/screens/terms_of_service_screen.dart (YENİ)
// ------------------------------------------------------------------
import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDisclaimer(context),
            _buildSection(context, '1. Taraflar ve Tanımlar', 'Bu Kullanım Koşulları ("Sözleşme"), "Tasarımcı Bulutu" platformu ("Platform") ile Platform\'a üye olan kullanıcı ("Kullanıcı", "Freelancer", "Firma") arasındaki ilişkiyi düzenler.'),
            _buildSection(context, '2. Platformun Amacı', 'Platform, tasarım ve mühendislik alanında uzmanlaşmış serbest çalışanlar (Freelancer) ile bu hizmetlere ihtiyaç duyan firmaları (Firma) bir araya getirmeyi amaçlayan bir pazar yeridir.'),
            _buildSection(context, '3. Kullanıcı Yükümlülükleri', 'Kullanıcı, sağladığı tüm bilgilerin (profil, yetkinlik, proje detayları vb.) doğru ve güncel olduğunu kabul ve taahhüt eder. Platform üzerinde yasa dışı, yanıltıcı veya üçüncü şahısların haklarını ihlal eden içerik paylaşılamaz.'),
            _buildSection(context, '4. Fikri Mülkiyet', 'Kullanıcılar tarafından projeler kapsamında oluşturulan tüm tasarımlar, çizimler ve diğer fikri ürünler, Freelancer ve Firma arasında aksi belirtilmedikçe, işin tamamlanması ve ödemenin yapılmasıyla birlikte Firma\'ya ait olur.'),
            _buildSection(context, '5. Sorumluluğun Sınırlandırılması', 'Tasarımcı Bulutu, bir aracı platformdur. Kullanıcılar arasındaki iletişim, anlaşma ve işin kalitesinden doğrudan sorumlu değildir. Ancak, anlaşmazlık durumlarında iyi niyet çerçevesinde çözüm için destek olabilir.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'YASAL UYARI: Bu metinler sadece birer örnektir ve yasal geçerliliği yoktur. Gerçek bir uygulama için mutlaka bir hukuk danışmanıyla çalışarak kendi metinlerinizi oluşturmalısınız.',
        textAlign: TextAlign.center,
      ),
    );
  }
}