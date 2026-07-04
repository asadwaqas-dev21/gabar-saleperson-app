import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salesperson_app/core/constants/app_colors.dart';
import 'package:salesperson_app/presentation/widgets/app_button.dart';
import 'package:salesperson_app/presentation/widgets/app_input.dart';
import 'package:salesperson_app/presentation/pages/main_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController(text: 'usman@gmail.com');
  final _passwordController = TextEditingController(text: '553134');
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 42),

                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/applogo.png',
                      width: 118,
                      height: 118,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Title
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to manage your villages, customers and sales.',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),

                const SizedBox(height: 40),

                // Form
                const Text(
                  'PHONE OR EMAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                AppInput(
                  controller: _emailController,
                  placeholder: '0300-1234567',
                ),

                const SizedBox(height: 16),

                const Text(
                  'PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                AppInput(
                  controller: _passwordController,
                  placeholder: '••••••••',
                  obscureText: true,
                ),

                const SizedBox(height: 24),

                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brand,
                        ),
                      )
                    : AppButton(
                        text: 'Login',
                        isFullWidth: true,
                        onPressed: _login,
                      ),

                const SizedBox(height: 12),

                AppButton(
                  text: 'Use Offline Data',
                  type: ButtonType.light,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MainLayout()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
