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
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    bool success = false;
    if (_isLogin) {
      success = await authService.signIn(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
    } else {
      success = await authService.signUp(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
    }
    
    setState(() => _isLoading = false);
    
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bir hata oluştu. Bilgilerinizi kontrol edin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
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
