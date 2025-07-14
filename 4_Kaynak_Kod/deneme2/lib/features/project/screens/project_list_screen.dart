import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common_widgets/empty_state.dart';
import '../../../common_widgets/project_card_skeleton.dart';
import '../../../core/providers/project_provider.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/project_card.dart';
import 'project_detail_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProjectProvider>().fetchOpenProjects();
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ProjectProvider>().applyFiltersAndFetch(searchQuery: _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje İlanları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => FilterSheet(currentSearchQuery: _searchController.text),
              isScrollControlled: true,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Proje başlığı veya açıklaması ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                if (projectProvider.isLoading && projectProvider.allOpenProjects.isEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 5,
                    itemBuilder: (context, index) => const ProjectCardSkeleton(),
                  );
                }
                if (projectProvider.allOpenProjects.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    message: 'Aktif proje ilanı bulunamadı.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => projectProvider.fetchOpenProjects(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: projectProvider.allOpenProjects.length,
                    itemBuilder: (context, index) {
                      final project = projectProvider.allOpenProjects[index];
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
          ),
        ],
      ),
    );
  }
}