// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers/application_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/project_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR'); // <-- DÜZELTİLMİŞ SATIR

  runApp(
    MultiProvider(
      providers: [
        // AuthProvider önce oluşturulur
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Sonra, AuthProvider'dan token'ı alıp ApplicationProvider'ı oluştururuz
        ChangeNotifierProxyProvider<AuthProvider, ApplicationProvider>(
          create: (context) => ApplicationProvider(null), // Başlangıçta token yok
          update: (context, auth, previous) => ApplicationProvider(auth.token),
        ),

        // ProjectProvider'ı da ekleyelim
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TasarımcıBulutu',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (auth.isLoggedIn) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}