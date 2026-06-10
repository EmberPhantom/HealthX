import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'correct_ingredients_screen.dart';
import 'dart:io';
import '../theme/theme.dart';
import '../services/api/api_service.dart';

class LogFromTextScreen extends StatefulWidget {
  final String meal;
  const LogFromTextScreen({super.key, required this.meal});

  @override
  State<LogFromTextScreen> createState() => _LogFromTextScreenState();
}

class _LogFromTextScreenState extends State<LogFromTextScreen> {
  final TextEditingController _controller = TextEditingController();
  bool get _hasText => _controller.text.trim().isNotEmpty;

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  void _onNext() async {
    if (!_hasText) return;
    setState(() => _isLoading = true);

    final response = await ApiService().identifyMeal(
      text: _controller.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CorrectIngredientsScreen(
            imageFile: File(''),
            meal: widget.meal,
            mealDescription: _controller.text.trim(),
            isTextBased: true,
            nutritionData: response.data!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.error ?? 'Failed to identify meal details',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(18 * ws, 14 * hs, 18 * ws, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20 * ws,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(width: 12 * ws),
                      Expanded(
                        child: Text(
                          'Log from text',
                          style: GoogleFonts.poppins(
                            fontSize: 18 * ws,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14 * ws,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 20 * hs, color: const Color(0xFFE5E7EB)),

                // ── Instruction ─────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18 * ws),
                  child: Text(
                    'Please give us as many details about the\nmeal as you can',
                    style: GoogleFonts.poppins(
                      fontSize: 14 * ws,
                      color: const Color(0xFF1A1A2E),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 16 * hs),

                // ── Text Input ──────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18 * ws),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreen.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14 * ws),
                        border: Border.all(
                          color: _hasText
                              ? AppTheme.primaryGreen.withOpacity(0.7)
                              : AppTheme.divider,
                          width: 1.5,
                        ),
                      ),
                      padding: EdgeInsets.all(16 * ws),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: GoogleFonts.poppins(
                          fontSize: 15 * ws,
                          color: const Color(0xFF1E2646),
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText:
                          'Example:\nKale Salad with Carrot Ginger Dressing',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14 * ws,
                            color: const Color(0xFF4CAF50).withOpacity(0.7),
                            height: 1.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        autofocus: true,
                      ),
                    ),
                  ),
                ),

                // ── Next Button ─────────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _hasText
                      ? Padding(
                    key: const ValueKey('next_btn'),
                    padding: EdgeInsets.fromLTRB(
                        18 * ws, 12 * hs, 18 * ws, 20 * hs),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding:
                          EdgeInsets.symmetric(vertical: 16 * hs),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(14 * ws),
                          ),
                          elevation: 3,
                          shadowColor: AppTheme.primaryGreen.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Next',
                                style: GoogleFonts.poppins(
                                  fontSize: 15 * ws,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  )
                      : SizedBox(
                      key: const ValueKey('empty'), height: 20 * hs),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}