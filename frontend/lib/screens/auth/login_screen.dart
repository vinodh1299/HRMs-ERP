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

  void _submit() async {
    final input = _emailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email or username')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulated short delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Use default fallback credentials for simulation
    String email = 'employee@acaindia.org';
    String password = 'employee123';

    if (input.contains('admin')) {
      email = 'admin@acaindia.org';
      password = 'admin123';
    } else if (input.contains('manager')) {
      email = 'manager@acaindia.org';
      password = 'manager123';
    }

    final success = await ref.read(authProvider.notifier).login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully authenticated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showMicrosoftPopup() {
    final msEmailController = TextEditingController();
    final msPassController = TextEditingController();
    bool showPasswordStep = false;
    bool isMsLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 24,
              child: Container(
                width: 440,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Microsoft Quad Logo
                    _buildMicrosoftLogo(size: 34),
                    const SizedBox(height: 24),
                    Text(
                      showPasswordStep ? 'Enter password' : 'Sign in',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF262626),
                        fontFamily: 'Segoe UI',
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!showPasswordStep) ...[
                      TextField(
                        controller: msEmailController,
                        decoration: const InputDecoration(
                          hintText: 'Email, phone, or Skype',
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0067B8), width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0067B8), width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "No account? Create one!",
                        style: TextStyle(color: Color(0xFF0067B8), fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Can't access your account?",
                        style: TextStyle(color: Color(0xFF0067B8), fontSize: 13),
                      ),
                    ] else ...[
                      Text(
                        msEmailController.text,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF262626)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: msPassController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          border: UnderlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Forgot password?",
                        style: TextStyle(color: Color(0xFF0067B8), fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (showPasswordStep)
                          OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                showPasswordStep = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFCCCCCC),
                              side: BorderSide.none,
                              shape: const RoundedRectangleBorder(),
                            ),
                            child: const Text('Back', style: TextStyle(color: Colors.black)),
                          ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isMsLoading
                              ? null
                              : () async {
                                  if (!showPasswordStep) {
                                    if (msEmailController.text.trim().isEmpty) return;
                                    setDialogState(() {
                                      showPasswordStep = true;
                                    });
                                  } else {
                                    if (msPassController.text.trim().isEmpty) return;
                                    setDialogState(() {
                                      isMsLoading = true;
                                    });
                                    await Future.delayed(const Duration(milliseconds: 800));
                                    if (!mounted) return;
                                    Navigator.pop(context); // Close dialog
                                    // Log in user as generic Admin/Employee
                                    final success = await ref.read(authProvider.notifier).login(
                                          msEmailController.text.trim().contains('admin')
                                              ? 'admin@acaindia.org'
                                              : 'employee@acaindia.org',
                                          'employee123',
                                        );
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Successfully authenticated via Microsoft Entra ID'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0067B8),
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: isMsLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(showPasswordStep ? 'Sign in' : 'Next'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    return Image.asset(
      'assets/logo.png', // Fallback to app logo, styled as google colors or circular badge
      height: 20,
      width: 20,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.g_mobiledata_rounded, color: Colors.blue, size: 24);
      },
    );
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
                  onPressed: _isLoading ? null : _submit,
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Simulated OTP sign-in triggered')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Continue with Microsoft
                _buildSocialButton(
                  icon: _buildMicrosoftLogo(size: 16),
                  label: 'Continue with Microsoft',
                  onTap: _showMicrosoftPopup,
                ),
                const SizedBox(height: 12),
                // Continue with Google
                _buildSocialButton(
                  icon: _buildGoogleLogo(),
                  label: 'Continue with Google',
                  onTap: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    await Future.delayed(const Duration(milliseconds: 600));
                    final success = await ref.read(authProvider.notifier).login(
                          'employee@acaindia.org',
                          'employee123',
                        );
                    setState(() {
                      _isLoading = false;
                    });
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully authenticated via Google account simulation'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
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
