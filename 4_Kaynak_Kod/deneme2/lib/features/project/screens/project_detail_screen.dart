import 'package:deneme2/features/project/screens/project_aplicants_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/project_model.dart';
import '../widgets/application_dialog.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    // Projenin sahibi mi?
    final bool isOwner = currentUser?.id == project.usersId;
    // Giriş yapan kullanıcı freelancer mı?
    final bool isFreelancer = currentUser?.role == UserRole.freelancer;

    // --- HATA AYIKLAMA İÇİN EKLENEN KISIM ---
    // Bu print'ler bize sorunun kaynağını gösterecek.
    print("--- ID KONTROLÜ ---");
    print("Giriş Yapan Kullanıcı ID: ${currentUser?.id}");
    print("Projenin Sahibi ID:     ${project.usersId}");
    print("Sonuç (isOwner):          $isOwner");
    print("--------------------");
    // --- BİTTİ ---

    return Scaffold(
      appBar: AppBar(
        title: Text(project.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Buton için boşluk
        child: Text("Proje ID: ${project.id}"), // Şimdilik sadece bu görünsün
      ),
      bottomSheet: _buildBottomSheet(context, isOwner, isFreelancer),
    );
  }

  Widget? _buildBottomSheet(BuildContext context, bool isOwner, bool isFreelancer) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (isOwner) {
      // Eğer projenin sahibi ise, başvuruları görme butonu
      return _buildButton(context, 'Gelen Başvuruları Gör', () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProjectApplicantsScreen(
            projectId: project.id,
            projectTitle: project.title,
          ),
        ));
      });
    } else if (isFreelancer) {
      // Eğer freelancer ise, başvuru yapma butonu
      return _buildButton(context, 'Projeye Başvur', () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ApplicationDialog(
              projectId: project.id,
              token: authProvider.token!,
            );
          },
        );
      });
    }
    // Diğer durumlarda buton gösterme
    return null;
  }

  Widget _buildButton(BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}