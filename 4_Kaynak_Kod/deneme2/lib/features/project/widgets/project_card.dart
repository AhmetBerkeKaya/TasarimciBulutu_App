// lib/features/projects/widgets/project_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    String budgetText;
    if (project.budgetMin != null && project.budgetMax != null) {
      budgetText = '${currencyFormat.format(project.budgetMin)} - ${currencyFormat.format(project.budgetMax)}';
    } else if (project.budgetMin != null) {
      budgetText = 'Min. ${currencyFormat.format(project.budgetMin)}';
    } else {
      budgetText = 'Teklife Açık';
    }

    return Card(
      clipBehavior: Clip.antiAlias, // InkWell'in kartın dışına taşmasını önler
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.apartment_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  // TODO: Gerçek projede usersId ile firma adını getireceğiz.
                  Text('Bir Firma', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 16, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Text(project.category ?? 'Kategori Belirtilmemiş', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bütçe Aralığı', style: theme.textTheme.titleMedium),
                  Text(
                    budgetText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}