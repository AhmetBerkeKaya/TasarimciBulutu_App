import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common_widgets/status_chip.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/project_model.dart';
import '../widgets/application_dialog.dart';
import '../../profile/screens/submit_review_screen.dart';
import 'project_aplicants_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Oturum bulunamadı.")));
    }

    // Gerekli tüm koşulları en başta hesaplayalım
    final bool isOwner = currentUser.id == project.owner.id;
    final bool isAcceptedFreelancer = project.acceptedApplication?.freelancer.id == currentUser.id;
    final bool canReview = project.status == ProjectStatus.completed && (isOwner || isAcceptedFreelancer);
    final bool hasAlreadyReviewed = project.reviews.any((review) => review.reviewer.id == currentUser.id);
    final bool isFreelancer = currentUser.role == UserRole.freelancer;
    final bool isProjectOpen = project.status == ProjectStatus.open;
    final bool hasAlreadyApplied = project.applications.any((app) => app.freelancer.id == currentUser.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectHeader(context, project),
            const SizedBox(height: 24),
            _buildDetailsCard(context, project),
            const SizedBox(height: 24),
            _buildDescriptionCard(context, project),
            const SizedBox(height: 24),

            // Kullanıcının rolüne ve proje durumuna göre doğru aksiyon butonlarını göster
            _buildActionButtons(
              context,
              isOwner: isOwner,
              isFreelancer: isFreelancer,
              isProjectOpen: isProjectOpen,
              hasAlreadyApplied: hasAlreadyApplied,
              canReview: canReview,
              hasAlreadyReviewed: hasAlreadyReviewed,
              project: project,
            ),
          ],
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGET'LAR ---

  Widget _buildProjectHeader(BuildContext context, Project project) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.title,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 14, child: Text(project.owner.name.substring(0, 1))),
                const SizedBox(width: 8),
                Text('Firma: ${project.owner.name}', style: theme.textTheme.titleSmall),
              ],
            ),
            StatusChip(status: project.status),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      budgetText = '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
    } else {
      budgetText = 'Teklife Açık';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _InfoTile(icon: Icons.category_outlined, label: 'Kategori', value: project.category),
            _InfoTile(icon: Icons.account_balance_wallet_outlined, label: 'Bütçe', value: budgetText),
            _InfoTile(icon: Icons.timer_outlined, label: 'Yayınlanma', value: timeago.format(project.createdAt, locale: 'tr')),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context, Project project) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Proje Açıklaması', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        Text(
          project.description ?? 'Açıklama bulunmuyor.',
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {
    required bool isOwner,
    required bool isFreelancer,
    required bool isProjectOpen,
    required bool hasAlreadyApplied,
    required bool canReview,
    required bool hasAlreadyReviewed,
    required Project project,
  }) {
    // Firma için Başvuru Yönetim Butonu
    if (isOwner && project.status != ProjectStatus.completed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.people_outline),
          label: Text('Gelen Başvuruları Görüntüle (${project.applications.length})'),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ProjectApplicantsScreen(projectId: project.id, projectTitle: project.title),
          )),
        ),
      );
    }

    // Freelancer için Başvuru Butonu
    if (isFreelancer && isProjectOpen && !hasAlreadyApplied) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.send_outlined),
          label: const Text('Projeye Başvur'),
          onPressed: () => showDialog(
            context: context,
            builder: (context) => ApplicationDialog(projectId: project.id),
          ),
        ),
      );
    }

    // Değerlendirme Butonu
    if (canReview && !hasAlreadyReviewed) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.rate_review_outlined),
          label: const Text('Değerlendirme Yap'),
          onPressed: () async {
            final authProvider = context.read<AuthProvider>();
            final String? revieweeId = isOwner ? project.acceptedApplication?.freelancer.id : project.owner.id;
            final String? revieweeName = isOwner ? project.acceptedApplication?.freelancer.name : project.owner.name;

            if (revieweeId == null || revieweeName == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Değerlendirilecek kullanıcı bulunamadı."), backgroundColor: Colors.red));
              return;
            }

            final bool? reviewSubmitted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (context) => SubmitReviewScreen(projectId: project.id, revieweeId: revieweeId, revieweeName: revieweeName)),
            );

            if (reviewSubmitted == true && context.mounted) {
              context.read<ProjectProvider>().fetchMyProjects();
            }
          },
        ),
      );
    }

    // Hiçbir koşul sağlanmazsa boş bir widget döndür
    return const SizedBox.shrink();
  }
}

/// Detay kartı içindeki küçük bilgi kutucukları için bir widget.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 28),
        const SizedBox(height: 8),
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
