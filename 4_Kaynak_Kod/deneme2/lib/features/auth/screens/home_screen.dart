import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';

// Gerekli tüm ekranları import ettiğimizden emin olalım
import '../../dashboard/screens/dashboard_screen.dart';
import '../../project/screens/project_list_screen.dart';
import '../../applications/screens/my_applications_screen.dart';
import '../../messages/screens/message_list_screen.dart';
import '../../profile/screens/profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- FREELANCER İÇİN NAVİGASYON ---
  static const List<Widget> _freelancerPages = [
    ProjectListScreen(),      // Ana ekranı: Proje ilanları
    DashboardScreen(),        // Kendi projelerini yönettiği panel
    MyApplicationsScreen(),   // Başvuruları
    MessageListScreen(),      // Mesajlar
    ProfileScreen(),          // Profil
  ];

  static const List<BottomNavigationBarItem> _freelancerNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Panelim'),
    BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), label: 'Başvurularım'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  // --- FİRMA (CLIENT) İÇİN NAVİGASYON ---
  static const List<Widget> _clientPages = [
    DashboardScreen(),        // Ana ekranı: Proje paneli
    MessageListScreen(),      // Mesajlar
    ProfileScreen(),          // Profil
  ];

  static const List<BottomNavigationBarItem> _clientNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panelim'),
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
    final userRole = context.watch<AuthProvider>().user?.role;

    // Role göre doğru sayfaları ve navigasyon item'larını seç
    final List<Widget> pages = (userRole == UserRole.client) ? _clientPages : _freelancerPages;
    final List<BottomNavigationBarItem> navItems = (userRole == UserRole.client) ? _clientNavItems : _freelancerNavItems;

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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: navItems,
      ),
    );
  }
}