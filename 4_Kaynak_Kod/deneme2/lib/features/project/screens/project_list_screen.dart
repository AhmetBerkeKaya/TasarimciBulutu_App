// lib/features/projects/screens/project_list_screen.dart
import 'package:deneme2/features/project/screens/project_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../data/models/enums.dart';
import '../widgets/project_card.dart';
import 'create_project_screen.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Build metodu içinde provider'ı çağırıyoruz. `listen: false` değil!
    final userRole = Provider.of<AuthProvider>(context).user?.role;
    final bool isClient = userRole == UserRole.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(isClient ? 'Projelerim' : 'Aktif Projeler'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search), tooltip: 'Ara'),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list), tooltip: 'Filtrele'),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoading) {
            return const LoadingIndicator();
          }

          if (projectProvider.errorMessage != null) {
            return Center(child: Text(projectProvider.errorMessage!));
          }

          if (projectProvider.projects.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              message: 'Gösterilecek Proje Bulunamadı',
            );
          }

          return RefreshIndicator(
            onRefresh: () => projectProvider.fetchProjects(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: projectProvider.projects.length,
              itemBuilder: (context, index) {
                final project = projectProvider.projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ProjectDetailScreen(project: project),
                    ));
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isClient
          ? FloatingActionButton.extended(
        onPressed: () async {
          // Proje oluşturma ekranına git ve geri dönüldüğünde listeyi yenile
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateProjectScreen()),
          );
          // Proje eklendikten sonra liste yenilenir
          Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
        },
        label: const Text('Proje Yayınla'),
        icon: const Icon(Icons.add),
      )
          : null,
    );
  }
}