// lib/features/showcase/widgets/post_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/showcase_provider.dart';
import '../../../data/models/showcase_post_model.dart';

class PostCard extends StatelessWidget {
  final ShowcasePost post;

  const PostCard({super.key, required this.post});
// --- YENİ SAVUNMA FONKSİYONU ---
  String _getCorrectImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    const marker = '.amazonaws.com';
    final index = url.indexOf(marker);

    if (index != -1) {
      final nextCharIndex = index + marker.length;
      if (nextCharIndex < url.length && url[nextCharIndex] != '/') {
        // Eğer .com'dan sonra / yoksa, onu buraya zorla ekle.
        return url.substring(0, nextCharIndex) + '/' + url.substring(nextCharIndex);
      }
    }
    return url;
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final correctedFileUrl = _getCorrectImageUrl(post.fileUrl);

    timeago.setLocaleMessages('tr', timeago.TrMessages());

    final currentUserId = Provider
        .of<AuthProvider>(context, listen: false)
        .user
        ?.id;
    final isLikedByMe = post.likes.any((like) => like.userId == currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      elevation: 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: post.owner.profilePictureUrl != null
                    ? NetworkImage(post.owner.profilePictureUrl!)
                    : null,
                child: post.owner.profilePictureUrl == null
                    ? Text(
                    post.owner.name.isNotEmpty ? post.owner.name[0] : 'U')
                    : null,
              ),
              title: Text(post.owner.name,
                  style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                timeago.format(post.createdAt, locale: 'tr'),
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 8),

            Text(post.title, style: textTheme.titleLarge),
            if (post.description != null && post.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                post.description!,
                style: textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // --- GÜNCELLENEN GÖRSEL BÖLÜMÜ ---
            if (correctedFileUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  correctedFileUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print("Image Load Error: $error"); // Hata loglaması
                    return Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                              Icons.broken_image, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("Resim yüklenemedi",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            // --- BİTTİ ---

            const SizedBox(height: 8),
            Row(
              children: [
                if (post.likes.isNotEmpty)
                  Text('${post.likes.length} beğeni',
                      style: textTheme.bodySmall),
                const Spacer(),
                if (post.comments.isNotEmpty)
                  Text('${post.comments.length} yorum',
                      style: textTheme.bodySmall),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  context: context,
                  icon: isLikedByMe ? Icons.thumb_up_alt_rounded : Icons
                      .thumb_up_alt_outlined,
                  label: 'Beğen',
                  color: isLikedByMe ? theme.primaryColor : Colors.grey[700],
                  onTap: () {
                    if (currentUserId != null) {
                      Provider.of<ShowcaseProvider>(context, listen: false)
                          .toggleLike(post.id, currentUserId);
                    }
                  },
                ),
                _buildActionButton(context: context,
                    icon: Icons.comment_outlined,
                    label: 'Yorum Yap',
                    onTap: () {}),
                _buildActionButton(context: context,
                    icon: Icons.share_outlined,
                    label: 'Paylaş',
                    onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }


Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color ?? Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
