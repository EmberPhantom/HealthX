import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'ai_identify_screen.dart';
import 'log_from_text_screen.dart';
import 'log_manually_screen.dart';
import '../theme/theme.dart';

class LogMealSheet extends StatefulWidget {
  final String meal;
  const LogMealSheet({super.key, required this.meal});

  @override
  State<LogMealSheet> createState() => _LogMealSheetState();
}

class _LogMealSheetState extends State<LogMealSheet> {
  bool _isLoading = false;

  static const double _refW = 360;
  static const double _refH = 800;

  Future<void> _pickFromGallery() async {
    if (_isLoading) return;
    final nav = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (picked != null) {
        nav.pop();
        nav.push(MaterialPageRoute(
          builder: (_) =>
              AIIdentifyScreen(imageFile: File(picked.path), meal: widget.meal),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Could not open gallery. Please try again.');
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isLoading) return;
    final nav = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final XFile? picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (picked != null) {
        nav.pop();
        nav.push(MaterialPageRoute(
          builder: (_) =>
              AIIdentifyScreen(imageFile: File(picked.path), meal: widget.meal),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Could not open camera. Please check permissions.');
    }
  }

  void _openLogFromText() {
    if (_isLoading) return;
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => LogFromTextScreen(meal: widget.meal)));
  }

  void _openLogManually() {
    if (_isLoading) return;
    Navigator.pop(context);
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => LogManuallyScreen(meal: widget.meal)));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: AppTheme.darkGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;
        final ws = screenWidth / _refW;
        final hs = screenHeight / _refH;

        return Stack(
          children: [
            // Scrim
            GestureDetector(
              onTap: _isLoading ? null : () => Navigator.pop(context),
              child: Container(color: const Color(0xFF0A2018).withOpacity(0.45)),
            ),

            // Bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: EdgeInsets.fromLTRB(
                  20 * ws,
                  12 * hs,
                  20 * ws,
                  32 * hs + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 36 * ws,
                        height: 4 * hs,
                        margin: EdgeInsets.only(bottom: 16 * hs),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2 * ws),
                        ),
                      ),
                    ),

                    // Title row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Log meal',
                          style: GoogleFonts.poppins(
                            fontSize: 18 * ws,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap:
                          _isLoading ? null : () => Navigator.pop(context),
                          child: Icon(Icons.close,
                              size: 22 * ws, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    SizedBox(height: 20 * hs),

                    // Option tiles
                    Row(
                      children: [
                        _OptionTile(
                          label: 'Gallery',
                          icon: Icons.photo_library_outlined,
                          bg: AppTheme.lightGreen,
                          iconColor: AppTheme.primaryGreen,
                          isLoading: _isLoading,
                          onTap: _pickFromGallery,
                          ws: ws,
                          hs: hs,
                        ),
                        SizedBox(width: 12 * ws),
                        _OptionTile(
                          label: 'Camera',
                          icon: Icons.camera_alt_outlined,
                          bg: const Color(0xFFFFF8E1),
                          iconColor: const Color(0xFFFBC02D),
                          isLoading: _isLoading,
                          onTap: _pickFromCamera,
                          ws: ws,
                          hs: hs,
                        ),
                        SizedBox(width: 12 * ws),
                        _OptionTile(
                          label: 'Text',
                          icon: Icons.text_fields_rounded,
                          bg: const Color(0xFFEDE7F6),
                          iconColor: const Color(0xFF7E57C2),
                          isLoading: _isLoading,
                          onTap: _openLogFromText,
                          ws: ws,
                          hs: hs,
                        ),
                      ],
                    ),
                    SizedBox(height: 16 * hs),

                    Center(
                      child: Text(
                        'or',
                        style: GoogleFonts.poppins(
                          fontSize: 12 * ws,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * hs),

                    Center(
                      child: GestureDetector(
                        onTap: _openLogManually,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 14 * ws, color: AppTheme.primaryGreen),
                            SizedBox(width: 6 * ws),
                            Text(
                              'Log macros manually',
                              style: GoogleFonts.poppins(
                                fontSize: 13 * ws,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1A1A2E),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 28 * hs),

                    // Loading spinner
                    if (_isLoading) ...[
                      SizedBox(height: 16 * hs),
                      Center(
                        child: SizedBox(
                          width: 24 * ws,
                          height: 24 * ws,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 28 * hs),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isLoading;
  final double ws;
  final double hs;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    required this.isLoading,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: AnimatedOpacity(
          opacity: isLoading ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18 * hs),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14 * ws),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24 * ws, color: iconColor),
                SizedBox(height: 8 * hs),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12 * ws,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}