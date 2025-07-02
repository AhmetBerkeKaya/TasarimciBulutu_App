// lib/features/applications/widgets/application_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/enums.dart';

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({
    super.key,
    required this.projectTitle,
    required this.companyName,
    required this.status,
    required this.appliedDate,
  });

  final String projectTitle;
  final String companyName;
  final ApplicationStatus status;
  final DateTime appliedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Duruma göre renk ve metin belirleme
    final Map<ApplicationStatus, dynamic> statusInfo = {
      ApplicationStatus.pending: {'text': 'İnceleniyor', 'color': Colors.orange.shade700},
      ApplicationStatus.accepted: {'text': 'Kabul Edildi', 'color': Colors.green.shade700},
      ApplicationStatus.rejected: {'text': 'Reddedildi', 'color': theme.colorScheme.error},
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(projectTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(companyName, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary)),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(appliedDate)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusInfo[status]['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusInfo[status]['text'],
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusInfo[status]['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}