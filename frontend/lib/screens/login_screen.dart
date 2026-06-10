import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';
import '../config/app_router.dart';
import 'signup_screen.dart';
import 'dart:ui';

const double _refW = 360.0;
const double _refH = 800.0;

class LoginScreen extends StatefulWidget {
  final VoidCallback? onNext;

  const LoginScreen({super.key, this.onNext});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!success) {
      // Navigation is handled automatically by go_router refreshListenable.
      // Only show error when login actually fails.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    // On success: go_router detects isAuthenticated=true and redirects to /home
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        final hPad = 20.0 * ws;
        final borderRadius = BorderRadius.circular(10 * ws);
        final fieldPadding = EdgeInsets.symmetric(
          horizontal: 12 * ws,
          vertical: 12 * hs,
        );

        InputDecoration fieldDecoration({
          required IconData prefixIcon,
          Widget? suffixIcon,
        }) {
          return InputDecoration(
            prefixIcon: Icon(
              prefixIcon,
              color: AppTheme.primaryGreen,
              size: 20 * ws,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: fieldPadding,
            border: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius,
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          );
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/login.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Bottom green shadow
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 0,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.32),
                          AppTheme.primaryGreen.withOpacity(0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),
                ),
              ),
              // Top overlay gradient
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 100 * hs,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xE6FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [0.0, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 140 * hs),

                        // Title
                        Text(
                          'Log In',
                          style: GoogleFonts.inter(
                            fontSize: 26 * ws,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 16 * hs),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                                child: Text(
                                  'Email',
                                  style: GoogleFonts.inter(
                                    fontSize: 12 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: fieldDecoration(
                                  prefixIcon: Icons.email_outlined,
                                ),
                              ),

                              SizedBox(height: 12 * hs),

                              // Password Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                                child: Text(
                                  'Password',
                                  style: GoogleFonts.inter(
                                    fontSize: 12 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _handleLogin(),
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: fieldDecoration(
                                  prefixIcon: Icons.lock_outlined,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.grey[600],
                                      size: 18 * ws,
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    padding: EdgeInsets.all(8 * ws),
                                  ),
                                ),
                              ),

                              SizedBox(height: 12 * hs),

                              SizedBox(height: 8 * hs),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password reset coming soon!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 0),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot password?',
                                    style: GoogleFonts.inter(
                                      fontSize: 11 * ws,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: 16 * hs),

                              // Log In Button with AuthProvider state
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      padding: EdgeInsets.symmetric(vertical: 13 * hs),
                                      shape: RoundedRectangleBorder(borderRadius: borderRadius),
                                      elevation: 0,
                                    ),
                                    child: authProvider.isLoading
                                        ? SizedBox(
                                      height: 16 * ws,
                                      width: 16 * ws,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                        : Text(
                                      'Log In',
                                      style: GoogleFonts.inter(
                                        fontSize: 15 * ws,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                                height: 20 * hs,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8 * ws),
                              child: Text(
                                'or',
                                style: GoogleFonts.inter(
                                  fontSize: 12 * ws,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey[400],
                                thickness: 1,
                                height: 20 * hs,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 12 * hs),

                        // Google Button
                        OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final authProvider = context.read<AuthProvider>();
                            final success = await authProvider.googleLogin();
                            
                            if (!mounted) return;
                            
                            if (!success && authProvider.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(authProvider.error!),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!, width: 1.2),
                            padding: EdgeInsets.symmetric(vertical: 11 * hs),
                            shape: RoundedRectangleBorder(borderRadius: borderRadius),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_translate, color: const Color(0xFF4285F4), size: 18 * ws),
                              SizedBox(width: 8 * ws),
                              Text(
                                'Sign in with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 12 * hs),

                        // Sign Up Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                color: Colors.grey[700],
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (_) => SignupScreen(
                                            onNext: () {
                                              Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                  builder: (_) => LoginScreen(onNext: widget.onNext),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: GoogleFonts.inter(
                                        fontSize: 12 * ws,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24 * hs),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}