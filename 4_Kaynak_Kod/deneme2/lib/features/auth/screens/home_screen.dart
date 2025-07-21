// lib/features/auth/screens/home_screen.dart (YENİ HALİ)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Gerekli tüm ekranları import ettiğimizden emin olalım
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../project/screens/project_list_screen.dart';
import '../../applications/screens/my_applications_screen.dart';
import '../../messages/screens/message_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../showcase/screens/showcase_feed_screen.dart';
// --- YENİ EKLENDİ ---
// Bu ekranı bir sonraki adımda oluşturacağız, şimdilik import ediyoruz.


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- FREELANCER İÇİN YENİ NAVİGASYON ---
  static const List<Widget> _freelancerPages = [
    ProjectListScreen(),      // Proje ilanları
    ShowcaseFeedScreen(),     // YENİ: Proje Vitrini
    MyApplicationsScreen(),   // Başvuruları
    MessageListScreen(),      // Mesajlar
    ProfileScreen(),          // Profil (Artık 'Panelim'e buradan erişilecek)
  ];

  static const List<BottomNavigationBarItem> _freelancerNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Keşfet'),
    // YENİ: Vitrin için yeni bir ikon (örn: lightbulb, palette)
    BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline), label: 'Vitrini'),
    BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), label: 'Başvurularım'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  // --- FİRMA (CLIENT) İÇİN YENİ NAVİGASYON ---
  static const List<Widget> _clientPages = [
    DashboardScreen(),        // Kendi projelerini yönettiği panel
    ShowcaseFeedScreen(),     // YENİ: Freelancer'ları keşfedeceği Vitrin akışı
    MessageListScreen(),      // Mesajlar
    ProfileScreen(),          // Profil
  ];

  static const List<BottomNavigationBarItem> _clientNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Panelim'),
    // YENİ: Freelancer'ları keşfetmek için bir ikon
    BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Tasarımcılar'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // AuthProvider'dan kullanıcı rolünü ve durumunu al
    final authProvider = context.watch<AuthProvider>();
    final userRole = authProvider.user?.role;

    // Eğer kullanıcı bilgisi henüz gelmediyse bir yüklenme ekranı göster
    if (authProvider.isLoading || userRole == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Role göre doğru sayfaları ve navigasyon item'larını seç
    final bool isClient = userRole == UserRole.client;
    final List<Widget> pages = isClient ? _clientPages : _freelancerPages;
    final List<BottomNavigationBarItem> navItems = isClient ? _clientNavItems : _freelancerNavItems;

    // Rol değişikliği gibi durumlarda index hatasını önlemek için kontrol
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 4 veya daha fazla item için en iyisi
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: navItems,
      ),
    );
  }
}