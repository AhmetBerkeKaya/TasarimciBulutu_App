// lib/features/showcase/screens/showcase_feed_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/showcase_provider.dart';
import '../widgets/post_card.dart';
import '../../../common_widgets/loading_indicator.dart';
import '../../../common_widgets/empty_state.dart';
import 'create_post_screen.dart'; // YENİ EKRANI IMPORT ET

class ShowcaseFeedScreen extends StatefulWidget {
  const ShowcaseFeedScreen({super.key});

  @override
  State<ShowcaseFeedScreen> createState() => _ShowcaseFeedScreenState();
}

class _ShowcaseFeedScreenState extends State<ShowcaseFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = Provider.of<ShowcaseProvider>(context, listen: false);
      if (provider.state == ShowcaseState.initial) {
        provider.fetchPosts();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ShowcaseProvider>(context, listen: false);
      if (provider.state != ShowcaseState.loadingMore && provider.hasMorePosts) {
        provider.fetchMorePosts();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Vitrini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<ShowcaseProvider>(
        builder: (context, provider, child) {
          switch (provider.state) {
            case ShowcaseState.initial:
            case ShowcaseState.loading:
              return const LoadingIndicator();

            case ShowcaseState.error:
              return Center(
                child: EmptyState(
                  icon: Icons.error_outline,
                  message: provider.errorMessage ?? "Bir hata oluştu.",
                  actionButton: ElevatedButton(
                    onPressed: () => provider.fetchPosts(),
                    child: const Text('Tekrar Dene'),
                  ),
                ),
              );

            case ShowcaseState.loaded:
            case ShowcaseState.loadingMore:
              if (provider.posts.isEmpty) {
                return Center(
                  child: EmptyState(
                    icon: Icons.dynamic_feed_outlined,
                    message: "Henüz hiç gönderi yok.",
                    suggestion: "İlk gönderiyi ekleyerek vitrini canlandır!",
                    actionButton: ElevatedButton(
                      onPressed: () => provider.fetchPosts(),
                      child: const Text('Sayfayı Yenile'),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => provider.fetchPosts(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: provider.posts.length + (provider.hasMorePosts ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final post = provider.posts[index];
                    return PostCard(post: post);
                  },
                ),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // --- GÜNCELLENEN KISIM ---
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        // --- BİTTİ ---
        child: const Icon(Icons.add),
      ),
    );
  }
}
