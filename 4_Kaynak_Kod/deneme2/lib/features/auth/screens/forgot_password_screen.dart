// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendResetLink() {
    // TODO: Backend'e şifre sıfırlama isteği gönder
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-posta adresiniz kayıtlıysa, sıfırlama bağlantısı gönderildi.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Login ekranıyla tutarlılık için aynı gradyanı tanımlıyoruz
    final primaryGradient = LinearGradient(
      colors: [
        theme.primaryColor.withOpacity(0.9),
        theme.primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final buttonContent = _isLoading
        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Text(
      'GÖNDER',
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Şifremi Unuttum'),
        backgroundColor: Colors.transparent, // Arkaplanı şeffaf yapıyoruz
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İkon
              Icon(Icons.lock_reset, size: 80, color: theme.colorScheme.secondary),
              const SizedBox(height: 24),

              // Başlık ve Açıklama
              Text('Şifremi Unuttum', textAlign: TextAlign.center, style: theme.textTheme.displaySmall),
              const SizedBox(height: 16),
              Text(
                'Şifrenizi sıfırlamak için kayıtlı e-posta adresinizi girin. Size şifre sıfırlama bağlantısı göndereceğiz.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(height: 40),

              // Form
              Text('E-Posta', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'E-posta adresinizi girin', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? 'Geçerli bir e-posta girin.' : null,
              ),
              const SizedBox(height: 32),

              // Gradyanlı Buton
              InkWell(
                onTap: _isLoading ? null : _sendResetLink,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: primaryGradient,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(child: buttonContent),
                ),
              ),
              const SizedBox(height: 16),

              // Giriş Sayfasına Dön Linki
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Giriş Sayfasına Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}