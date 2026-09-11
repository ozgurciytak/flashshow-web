import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('empty_fields'.tr()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final String? errorMessage = _isLogin
      ? await authService.signIn(email, password)
      : await authService.signUp(email, password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              const Icon(Icons.flash_on, size: 80, color: Colors.yellow),
              const SizedBox(height: 16),
              Text('app_name'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.yellow)),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.yellow)
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_isLogin ? 'login'.tr() : 'signup'.tr()),
                  ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'signup'.tr() : 'login'.tr(), style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.flash_on, color: Colors.yellow),
                label: Text('guest_login'.tr(), style: const TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.yellow),
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Provider.of<AuthService>(context, listen: false).loginAsGuest();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
