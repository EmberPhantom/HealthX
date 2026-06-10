import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';
import '../config/app_router.dart';
import 'login_screen.dart';
import 'dart:ui';

const double _refW = 360.0;
const double _refH = 800.0;

class SignupScreen extends StatefulWidget {
  final VoidCallback? onNext;

  const SignupScreen({super.key, this.onNext});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+91'; // Default prefix
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your name';
    if (value.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Please enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signup(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      // TEMPORARY: bypass email verification and go straight to home (where router checks onboarding completion)
      context.go(AppRoutes.home);
    } else {
      // Show error from provider
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Signup failed'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSocialSignup(String provider) async {
    HapticFeedback.mediumImpact();
    // TODO: Wire up when Google/Facebook OAuth is configured
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-up coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        final topSpacer = 120.0 * hs;
        final borderRadius = BorderRadius.circular(10 * ws);
        final fieldPadding = EdgeInsets.symmetric(
          horizontal: 12 * ws,
          vertical: 10 * hs,
        );

        InputDecoration _fieldDecoration({
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
                  'assets/images/signup.jpg',
                  fit: BoxFit.cover,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacer),

                        // Title
                        Text(
                          'Create Your Account',
                          style: GoogleFonts.inter(
                            fontSize: 22 * ws,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 6 * hs),

                        // Subtitle
                        Text(
                          'Track your steps and achieve your fitness goals!',
                          style: GoogleFonts.inter(
                            fontSize: 12 * ws,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 10 * hs),

                        // Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 4 * hs),
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.inter(
                                    fontSize: 12 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                validator: _validateName,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration(
                                  prefixIcon: Icons.person_outline,
                                ),
                              ),

                              SizedBox(height: 8 * hs),

                              // Email Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 4 * hs),
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
                                decoration: _fieldDecoration(
                                  prefixIcon: Icons.email_outlined,
                                ),
                              ),

                              SizedBox(height: 8 * hs),

                              // Phone Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 4 * hs),
                                child: Text(
                                  'Phone Number',
                                  style: GoogleFonts.inter(
                                    fontSize: 12 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // Phone Field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration(
                                  prefixIcon: Icons.phone_outlined,
                                ),
                              ),

                              SizedBox(height: 8 * hs),

                              // Password Label
                              Padding(
                                padding: EdgeInsets.only(left: 2 * ws, bottom: 4 * hs),
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
                                onFieldSubmitted: (_) => _handleSignup(),
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w400,
                                ),
                                decoration: _fieldDecoration(
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

                              SizedBox(height: 10 * hs),

                              // Sign Up Button with AuthProvider state
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _handleSignup,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      padding: EdgeInsets.symmetric(vertical: 11 * hs),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: borderRadius,
                                      ),
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
                                      'Sign Up',
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

                        SizedBox(height: 8 * hs),

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

                        SizedBox(height: 6 * hs),

                        // Google Button
                        OutlinedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final authProvider = context.read<AuthProvider>();
                            final success = await authProvider.googleLogin(isSignup: true);
                            
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
                            padding: EdgeInsets.symmetric(vertical: 9 * hs),
                            shape: RoundedRectangleBorder(borderRadius: borderRadius),
                            backgroundColor: Colors.white,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_translate, color: const Color(0xFF4285F4), size: 18 * ws),
                              SizedBox(width: 8 * ws),
                              Text(
                                'Sign up with Google',
                                style: GoogleFonts.inter(
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 6 * hs),

                        // Login Link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
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
                                          builder: (_) => LoginScreen(onNext: widget.onNext),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Log In',
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

                        SizedBox(height: 8 * hs),
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