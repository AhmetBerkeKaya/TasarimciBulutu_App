// lib/features/applications/screens/my_applications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/application_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';
import '../../../data/models/application_model.dart';
import '../widgets/application_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  late Future<List<Application>> _applicationsFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // initState içinde Provider'dan token alıp Future'ı başlatıyoruz.
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _applicationsFuture = _apiService.getMyApplications(token: token);
    } else {
      // Token yoksa, boş bir Future ata
      _applicationsFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Başvurularım'),
      ),
      body: Consumer<ApplicationProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (appProvider.errorMessage != null) {
            return Center(child: Text(appProvider.errorMessage!));
          }

          if (appProvider.myApplications.isEmpty) {
            return const EmptyState(
              icon: Icons.file_copy_outlined,
              message: 'Henüz Başvurunuz Yok',
              suggestion: 'Projelere başvurduğunuzda burada listelenecektir.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => appProvider.fetchMyApplications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appProvider.myApplications.length,
              itemBuilder: (context, index) {
                final app = appProvider.myApplications[index];
                return ApplicationCard(
                  projectTitle: 'Proje Başlığı #${app.projectId.substring(0, 8)}',
                  companyName: 'Bir Firma',
                  status: app.status,
                  appliedDate: app.createdAt,
                );
              },
            ),
          );
        },
      ),
    );
  }
}