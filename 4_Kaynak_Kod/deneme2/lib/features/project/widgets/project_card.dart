import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common_widgets/status_chip.dart';
import '../../../data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final Widget? actionButton;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      if (project.budgetMin == project.budgetMax) {
        budgetText = currencyFormat.format(project.budgetMin);
      } else {
        budgetText = '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
      }
    } else {
      budgetText = 'Teklife Açık';
    }

    return Card(
      // --- YENİ TASARIM ---
      // Daha yumuşak bir gölge ve modern bir kenarlık
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      // --- BİTTİ ---
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ÜST KISIM: Firma ve Zaman (Yeniden Düzenlendi) ---
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(project.owner.name.substring(0, 1)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.owner.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeago.format(project.createdAt, locale: 'tr'),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),

              // --- ORTA KISIM: Başlık, Durum ve Açıklama (Yeniden Düzenlendi) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              if (project.description != null)
                Text(
                  project.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 16),

              // --- ALT KISIM: Bütçe ve Kategori Etiketleri (Yeniden Tasarlandı) ---
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Bütçe Etiketi
                  _InfoChip(
                    icon: Icons.account_balance_wallet_outlined,
                    text: budgetText,
                    color: theme.colorScheme.primary,
                  ),
                  // Kategori Etiketi
                  if (project.category != null)
                    _InfoChip(
                      icon: Icons.category_outlined,
                      text: project.category!,
                      color: theme.colorScheme.secondary,
                    ),
                ],
              ),

              // --- AKSİYON BUTONU BÖLÜMÜ ---
              if (actionButton != null) ...[
                const Divider(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: actionButton,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- YENİ YARDIMCI WIDGET: Şık bilgi etiketleri için ---
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}