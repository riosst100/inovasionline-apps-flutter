import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/address_picker.dart';
import '../../widgets/password_field.dart';
import '../home/welcome_message.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  AddressSelection _address = const AddressSelection();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_address.isComplete) {
      setState(() => _error = 'Alamat wajib dipilih lengkap.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _passwordConfirmController.text,
          provinceCode: _address.province!.code,
          cityCode: _address.city!.code,
          districtCode: _address.district!.code,
          villageCode: _address.village!.code,
        );

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      final name = ref.read(authProvider).user?.name;
      ref.read(pendingWelcomeProvider.notifier).state = WelcomeMessage(name: name);
      context.go('/');
    } else {
      setState(() => _error = ref.read(authProvider).error);
    }
  }

  Future<void> _submitGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref.read(authProvider.notifier).loginWithGoogle();

    if (!mounted) return;

    setState(() => _loading = false);

    if (success) {
      final name = ref.read(authProvider).user?.name;
      ref.read(pendingWelcomeProvider.notifier).state = WelcomeMessage(name: name);
      context.go('/');
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Email wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Nomor telepon wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Kata Sandi',
                    helperText: 'Minimal 8 karakter, kombinasi huruf besar, kecil, dan angka',
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.length < 8) return 'Kata sandi minimal 8 karakter';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Kata sandi harus mengandung huruf besar';
                    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Kata sandi harus mengandung huruf kecil';
                    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Kata sandi harus mengandung angka';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _passwordConfirmController,
                  decoration: const InputDecoration(labelText: 'Konfirmasi Kata Sandi'),
                  validator: (value) =>
                      value != _passwordController.text ? 'Konfirmasi kata sandi tidak cocok' : null,
                ),
                const SizedBox(height: 24),
                const Text('Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                AddressPicker(onChanged: (address) => setState(() => _address = address)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Daftar'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _submitGoogle,
                  icon: Image.asset(
                    'assets/images/logo_google.webp',
                    height: 20,
                    width: 20,
                  ),
                  label: const Text('Daftar dengan Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
