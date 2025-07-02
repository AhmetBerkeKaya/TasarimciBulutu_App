// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/models/enums.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.freelancer;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final user = await _authService.signup(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      setState(() => _isLoading = false);

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name}, kaydınız başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt oluşturulamadı. E-posta zaten kullanımda olabilir.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (build metodunun geri kalanı aynı, sadece TextFormField'lara controller ekleyeceğiz)
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hesap Oluştur')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Form(
              key: _formKey,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Birkaç adımda aramıza katılın', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center,),
                      const SizedBox(height: 24),
                      SegmentedButton<UserRole>(
                        segments: const [
                          ButtonSegment<UserRole>(value: UserRole.freelancer, label: Text('Freelancer'), icon: Icon(Icons.person_outline)),
                          ButtonSegment<UserRole>(value: UserRole.client, label: Text('Firma'), icon: Icon(Icons.business_center_outlined)),
                        ],
                        selected: {_selectedRole},
                        onSelectionChanged: (newSelection) => setState(() => _selectedRole = newSelection.first),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: _selectedRole == UserRole.freelancer ? 'Adınız ve Soyadınız' : 'Firma Adı'),
                        validator: (value) => (value == null || value.isEmpty) ? 'Bu alan boş bırakılamaz.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'E-posta Adresi'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => (value == null || !value.contains('@')) ? 'Geçerli bir e-posta girin.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(labelText: 'Şifre'),
                        obscureText: true,
                        validator: (value) => (value == null || value.length < 6) ? 'Şifre en az 6 karakter olmalı.' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signup,
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('HESAP OLUŞTUR'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}