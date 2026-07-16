import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'employee@acaindia.org');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(String method) async {
    setState(() {
      _isLoading = true;
    });

    // Simulated short delay for presentation realism
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    // Direct dummy sign in as standard employee profile
    final success = await ref.read(authProvider.notifier).login(
          'employee@acaindia.org',
          'employee123',
        );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully authenticated via $method (Demo Mode)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildMicrosoftLogo({double size = 16}) {
    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: size * 0.08,
        crossAxisSpacing: size * 0.08,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(color: const Color(0xFFF25022)), // Red
          Container(color: const Color(0xFF7FBA00)), // Green
          Container(color: const Color(0xFF00A4EF)), // Blue
          Container(color: const Color(0xFFFFB900)), // Yellow
        ],
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header logo representation
                Image.asset(
                  'assets/logo.png',
                  height: 48,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.corporate_fare_outlined,
                    color: Color(0xFF5E4EBD),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                // Input username/email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email or Username',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDCDCDC), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5E4EBD), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Continue Button
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _submit('Username/Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4EBD),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                // Divider "Or"
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE5E5E5), thickness: 1)),
                  ],
                ),
                const SizedBox(height: 24),
                // Continue with Mobile
                _buildSocialButton(
                  icon: const Icon(Icons.phone_iphone_outlined, color: Colors.blue, size: 20),
                  label: 'Continue with Mobile',
                  onTap: () => _submit('Mobile Verification'),
                ),
                const SizedBox(height: 12),
                // Continue with Microsoft
                _buildSocialButton(
                  icon: _buildMicrosoftLogo(size: 16),
                  label: 'Continue with Microsoft',
                  onTap: () => _submit('Microsoft Entra ID'),
                ),
                const SizedBox(height: 12),
                // Continue with Google
                _buildSocialButton(
                  icon: _buildGoogleLogo(),
                  label: 'Continue with Google',
                  onTap: () => _submit('Google Accounts'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2D2D2D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
