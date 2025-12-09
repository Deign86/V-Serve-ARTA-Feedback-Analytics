// ==================== SCREENS ====================

// lib/screens/role_based_login_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_services.dart';

class RoleBasedLoginScreen extends StatefulWidget {
  const RoleBasedLoginScreen({super.key});

  @override
  State<RoleBasedLoginScreen> createState() => _RoleBasedLoginScreenState();
}

class _RoleBasedLoginScreenState extends State<RoleBasedLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        // Clear all routes and navigate to dashboard for security
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/admin/dashboard',
          (route) => false,
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid email or password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur effect
          Positioned.fill(
            child: Image.asset(
              'assets/city_bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Login card
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo - using city logo image
                          ClipOval(
                            child: Image.asset(
                              'assets/city_logo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          const Text(
                            'CITY GOVERNMENT OF VALENZUELA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Text(
                            'HELP US SERVE YOU BETTER!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Welcome back!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Error message
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: 'Enter your email here',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Enter your password here',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF003366),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Demo credentials
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Demo Credentials:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildCredential('Admin', 'admin@valenzuela.gov.ph', 'admin123'),
                                  _buildCredential('Editor', 'editor@valenzuela.gov.ph', 'editor123'),
                                  _buildCredential('Analyst', 'analyst@valenzuela.gov.ph', 'analyst123'),
                                  _buildCredential('Viewer', 'viewer@valenzuela.gov.ph', 'viewer123'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredential(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$email / $password',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}