// lib/features/profile/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      final success = await ApiService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        token: token!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Şifreniz başarıyla güncellendi!' : 'İşlem başarısız! Mevcut şifrenizi kontrol edin.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        Navigator.of(context).pop();
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Değiştir')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
              obscureText: true,
              validator: (v) => v!.isEmpty ? 'Lütfen mevcut şifrenizi girin.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6) ? 'Yeni şifre en az 6 karakter olmalı.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Yeni Şifre (Tekrar)'),
              obscureText: true,
              validator: (v) => v != _newPasswordController.text ? 'Şifreler eşleşmiyor.' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitChangePassword,
              child: _isLoading ? const CircularProgressIndicator() : const Text('GÜNCELLE'),
            ),
          ],
        ),
      ),
    );
  }
}