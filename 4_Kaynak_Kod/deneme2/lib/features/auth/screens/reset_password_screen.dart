// lib/features/auth/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  void _submitResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.resetPassword(
      token: _codeController.text,
      newPassword: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreniz başarıyla yenilendi!'),
            backgroundColor: Colors.green,
          ),
        );
        // Başarılı olunca giriş ekranına yönlendir
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.lastError ?? 'Bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();

    final buttonContent = authProvider.isLoading
        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Text('ŞİFREYİ SIFIRLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.password_rounded, size: 80, color: theme.colorScheme.secondary),
                const SizedBox(height: 24),
                Text('Yeni Şifre Oluştur', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
                const SizedBox(height: 16),
                Text(
                  '${widget.email} adresine gönderilen 6 haneli kodu ve yeni şifrenizi girin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                const SizedBox(height: 40),

                // Kod alanı
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Sıfırlama Kodu',
                    hintText: 'E-postadaki 6 haneli kod',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.length != 6) {
                      return 'Lütfen 6 haneli kodu girin.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Yeni şifre alanı
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Yeni Şifre',
                    hintText: 'Yeni şifrenizi girin',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buton
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _submitResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: buttonContent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
