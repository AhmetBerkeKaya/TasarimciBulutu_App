// lib/features/projects/screens/project_applicants_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/application_model.dart';

class ProjectApplicantsScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const ProjectApplicantsScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<ProjectApplicantsScreen> createState() => _ProjectApplicantsScreenState();
}

class _ProjectApplicantsScreenState extends State<ProjectApplicantsScreen> {
  late Future<List<Application>> _applicantsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _applicantsFuture = _apiService.getApplicationsForProject(
        projectId: widget.projectId,
        token: token,
      );
    } else {
      _applicantsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('"${widget.projectTitle}" Gelen Başvurular'),
      ),
      body: FutureBuilder<List<Application>>(
        future: _applicantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.person_search_sharp,
              message: 'Henüz Başvuru Yok',
            );
          }
          final applicants = snapshot.data!;
          return ListView.builder(
            itemCount: applicants.length,
            itemBuilder: (context, index) {
              final applicant = applicants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  // TODO: freelancerId ile kullanıcı adını getir
                  title: Text('Freelancer ID: ${applicant.freelancerId.substring(0, 8)}...'),
                  subtitle: Text('Teklifi: ${applicant.proposedBudget?.toStringAsFixed(2) ?? 'N/A'} ₺'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Başvuru detayına veya freelancer profiline git
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}