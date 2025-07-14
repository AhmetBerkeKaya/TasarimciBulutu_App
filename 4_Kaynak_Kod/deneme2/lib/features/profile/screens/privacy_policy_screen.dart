// ------------------------------------------------------------------
// DOSYA 4: lib/features/profile/screens/privacy_policy_screen.dart (YENİ)
// ------------------------------------------------------------------
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDisclaimer(context),
            _buildSection(context, '1. Toplanan Veriler', 'Platforma kayıt olurken ve profilinizi oluştururken sağladığınız kişisel veriler (isim, e-posta, telefon numarası, yetkinlikler, portfolyo) sistemimizde saklanır.'),
            _buildSection(context, '2. Verilerin Kullanımı', 'Toplanan veriler, hizmetlerimizi sunmak, sizi doğru projelerle veya freelancer\'larla eşleştirmek, platformu iyileştirmek ve sizinle iletişim kurmak amacıyla kullanılır.'),
            _buildSection(context, '3. Verilerin Paylaşımı', 'Kişisel verileriniz, yasal zorunluluklar dışında, sizin açık rızanız olmadan üçüncü şahıslarla paylaşılmaz. Projeye başvurduğunuzda, profilinizdeki ilgili bilgiler proje sahibi firma ile paylaşılır.'),
            _buildSection(context, '4. Veri Güvenliği', 'Verilerinizin güvenliğini sağlamak için endüstri standardı teknik ve idari güvenlik önlemleri alınmaktadır.'),
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