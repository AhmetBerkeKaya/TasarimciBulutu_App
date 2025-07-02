// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Şifre Sıfırlama')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Kayıtlı e-posta adresinizi girerek şifrenizi sıfırlamak için bağlantı alabilirsiniz.', textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'E-posta Adresi', prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: () {
                      // Sıfırlama linki gönderme logiği
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sıfırlama bağlantısı gönderildi (eğer e-posta kayıtlıysa).')),
                      );
                      Navigator.of(context).pop();
                    }, child: const Text('SIFIRLAMA LİNKİ GÖNDER')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}