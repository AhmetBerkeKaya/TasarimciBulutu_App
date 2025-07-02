// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/enums.dart';
import '../../applications/screens/my_applications_screen.dart';
import '../../messages/screens/message_list_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../project/screens/project_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Freelancer için gösterilecek sayfalar ve navigasyon item'ları
  static const List<Widget> _freelancerPages = <Widget>[
    ProjectListScreen(),
    MyApplicationsScreen(),
    MessageListScreen(),
    ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _freelancerNavItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Projeler'),
    BottomNavigationBarItem(icon: Icon(Icons.file_copy_outlined), label: 'Başvurularım'),
    BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
  ];

  // Client (Firma) için gösterilecek sayfalar ve navigasyon item'ları
  static const List<Widget> _clientPages = <Widget>[
    ProjectListScreen(), // Bu ekran hem proje aramak hem de kendi projelerini yönetmek için kullanılabilir
    MessageListScreen(),
    ProfileScreen(),
  ];

  static const List<BottomNavigationBarItem> _clientNavItems = <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Projelerim'),
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
    // Giriş yapan kullanıcının rolünü Provider'dan al
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;

    // Role göre doğru sayfaları ve navigasyon item'larını seç
    final bool isClient = userRole == UserRole.client;
    final List<Widget> pages = isClient ? _clientPages : _freelancerPages;
    final List<BottomNavigationBarItem> navItems = isClient ? _clientNavItems : _freelancerNavItems;

    return Scaffold(
      // IndexedStack, sekmeler arası geçişte sayfaların durumunu korur (kaydırma pozisyonu vb.)
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 3'ten fazla item için bu önemlidir
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: navItems,
      ),
    );
  }
}