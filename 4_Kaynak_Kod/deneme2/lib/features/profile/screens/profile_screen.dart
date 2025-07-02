// lib/features/profile/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Provider'dan o an giriş yapmış olan kullanıcıyı alıyoruz
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Profili Düzenle', onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Profil Bilgisi
            Row(
              children: [
                CircleAvatar(radius: 40, child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'U')),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(user?.name ?? 'Kullanıcı Adı', style: theme.textTheme.headlineSmall),
                          if (user?.isVerified ?? false) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.verified, color: theme.primaryColor, size: 20),
                          ]
                        ],
                      ),
                      Text(user?.email ?? 'E-posta', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32),

            // --- DOĞRULAMA İÇİN EKLENEN KISIM ---
            Text('Sistemdeki Rolünüz:', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                user?.role.name.toUpperCase() ?? 'BİLİNMİYOR',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            ),
            // --- KONTROL KISMI BİTTİ ---

            const Divider(height: 32),

            // Hakkında
            Text('Hakkımda', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(user?.bio ?? 'Henüz bir biyografi eklenmemiş.', style: theme.textTheme.bodyLarge),

          ],
        ),
      ),
    );
  }
}