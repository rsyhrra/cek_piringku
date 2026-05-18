import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../services/database_service.dart';
import '../services/reward_service.dart';
import 'main_navigation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final db = DatabaseService();
    final rewardService = Provider.of<RewardService>(context, listen: false);

    try {
      if (isLogin) {
        final userData = await db.loginUser(_emailController.text, _passwordController.text);
        if (userData != null) {
          await rewardService.refreshUserData();
          _navigateToHome();
        } else {
          _showError("Email atau password salah");
        }
      } else {
        await db.registerUser(
          _nameController.text,
          _gradeController.text,
          _schoolController.text,
          _emailController.text,
          _passwordController.text,
        );
        await rewardService.refreshUserData();
        _navigateToHome();
      }
    } catch (e) {
      _showError("Terjadi kesalahan. Silakan coba lagi.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.alertRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo placeholder
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.spa_rounded, color: AppColors.primaryGreen, size: 60),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isLogin ? 'Selamat Datang Kembali!' : 'Daftar Akun Baru',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? 'Masuk untuk memantau gizimu' : 'Lengkapi data untuk mulai memantau gizi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 40),

                if (!isLogin) ...[
                  _buildTextField(_nameController, 'Nama Lengkap', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildTextField(_schoolController, 'Nama Sekolah', Icons.school_outlined),
                  const SizedBox(height: 16),
                  _buildTextField(_gradeController, 'Kelas (Contoh: 8A)', Icons.class_outlined),
                  const SizedBox(height: 16),
                ],
                
                _buildTextField(_emailController, 'Email', Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outline, isObscure: true),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isLogin ? 'Masuk Sekarang' : 'Daftar Sekarang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isLogin ? 'Belum punya akun?' : 'Sudah punya akun?'),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin ? 'Daftar' : 'Masuk',
                        style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isObscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: (v) => v == null || v.isEmpty ? 'Kolom ini harus diisi' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}
