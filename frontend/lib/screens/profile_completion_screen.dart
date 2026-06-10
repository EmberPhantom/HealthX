import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_shell.dart';
import 'dart:ui';

const double _refW = 360.0;
const double _refH = 800.0;

class ProfileCompletionScreen extends StatefulWidget {
  final VoidCallback? onNext;

  const ProfileCompletionScreen({super.key, this.onNext});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;
  
  String? _selectedGender;
  File? _profileImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    
    // Populate name from auth provider if available
    final authProvider = context.read<AuthProvider>();
    if (authProvider.user != null) {
      _nameController.text = authProvider.user!.name;
      _phoneController.text = authProvider.user!.phone ?? '';
    }

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
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value != null && value.isNotEmpty && value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^\+?[0-9]{10,}$').hasMatch(value.replaceAll(RegExp(r'[^\d+]'), ''))) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  String? _validateDOB(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        DateTime.parse(value);
      } catch (e) {
        return 'Invalid date format (YYYY-MM-DD)';
      }
    }
    return null;
  }

  int _calculateCompletion() {
    int completed = 1; // Email is always completed
    if (_profileImage != null) completed++;
    if (_nameController.text.isNotEmpty) completed++;
    if (_phoneController.text.isNotEmpty) completed++;
    if (_dobController.text.isNotEmpty) completed++;
    if (_selectedGender != null) completed++;
    
    return (completed / 6 * 100).toInt();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() => _profileImage = File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    final authProvider = context.read<AuthProvider>();

    // Upload profile picture if available
    if (_profileImage != null && !_isUploadingImage) {
      setState(() => _isUploadingImage = true);
      final success = await authProvider.uploadProfilePicture(
        imagePath: _profileImage!.path,
      );
      if (!mounted) return;
      setState(() => _isUploadingImage = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to upload profile picture'),
            backgroundColor: AppTheme.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    // Complete onboarding with profile data
    final success = await authProvider.completeOnboarding(
      dateOfBirth: _dobController.text.isNotEmpty ? _dobController.text : null,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      gender: _selectedGender,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to home/app shell
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to complete profile'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
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

        final completion = _calculateCompletion();

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: GoogleFonts.inter(
                    fontSize: 16 * ws,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4 * hs),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2 * ws),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 4 * hs,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * ws),
                    Text(
                      '$completion%',
                      style: GoogleFonts.inter(
                        fontSize: 11 * ws,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            toolbarHeight: 70 * hs,
          ),
          body: Stack(
            children: [
              // Background
              Positioned.fill(
                child: Image.asset(
                  'assets/images/login.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 16 * hs),

                    // Profile Picture Section
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          // Profile picture
                          Container(
                            width: 100 * ws,
                            height: 100 * ws,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryGreen,
                                width: 2 * ws,
                              ),
                              image: _profileImage != null
                                  ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? Icon(
                              Icons.person_outline,
                              size: 50 * ws,
                              color: Colors.grey[400],
                            )
                                : null,
                          ),
                          // Upload button
                          Container(
                            width: 32 * ws,
                            height: 32 * ws,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2 * ws,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(16 * ws),
                                child: Icon(
                                  Icons.camera_alt_outlined,
                                  size: 16 * ws,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20 * hs),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          Padding(
                            padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                            child: Text(
                              'Name (Optional)',
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            validator: _validateName,
                            style: GoogleFonts.inter(
                              fontSize: 13 * ws,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: fieldDecoration(
                              prefixIcon: Icons.person_outline,
                            ),
                          ),

                          SizedBox(height: 12 * hs),

                          // Phone
                          Padding(
                            padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                            child: Text(
                              'Phone (Optional)',
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: _validatePhone,
                            style: GoogleFonts.inter(
                              fontSize: 13 * ws,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: fieldDecoration(
                              prefixIcon: Icons.phone_outlined,
                            ),
                          ),

                          SizedBox(height: 12 * hs),

                          // Date of Birth
                          Padding(
                            padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                            child: Text(
                              'Date of Birth (Optional)',
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _dobController,
                            keyboardType: TextInputType.datetime,
                            validator: _validateDOB,
                            style: GoogleFonts.inter(
                              fontSize: 13 * ws,
                              color: Colors.black87,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: fieldDecoration(
                              prefixIcon: Icons.calendar_today_outlined,
                            ).copyWith(
                              hintText: 'YYYY-MM-DD',
                            ),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                _dobController.text =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                          ),

                          SizedBox(height: 12 * hs),

                          // Gender
                          Padding(
                            padding: EdgeInsets.only(left: 2 * ws, bottom: 6 * hs),
                            child: Text(
                              'Gender (Optional)',
                              style: GoogleFonts.inter(
                                fontSize: 12 * ws,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: borderRadius,
                              border: Border.all(
                                color: _selectedGender != null
                                    ? AppTheme.primaryGreen
                                    : Colors.grey[300]!,
                                width: _selectedGender != null ? 1.5 : 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                hint: Padding(
                                  padding: EdgeInsets.only(left: 4 * ws),
                                  child: Text(
                                    'Select gender',
                                    style: GoogleFonts.inter(
                                      fontSize: 13 * ws,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                isExpanded: true,
                                icon: Padding(
                                  padding: EdgeInsets.only(right: 8 * ws),
                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.primaryGreen,
                                    size: 22 * ws,
                                  ),
                                ),
                                padding: EdgeInsets.only(left: 8 * ws),
                                borderRadius: borderRadius,
                                items: ['Male', 'Female', 'Other'].map((gender) {
                                  return DropdownMenuItem<String>(
                                    value: gender,
                                    child: Row(
                                      children: [
                                        Icon(
                                          gender == 'Male'
                                              ? Icons.male_rounded
                                              : gender == 'Female'
                                              ? Icons.female_rounded
                                              : Icons.person_rounded,
                                          color: gender == 'Male'
                                              ? const Color(0xFF2196F3)
                                              : gender == 'Female'
                                              ? const Color(0xFFE91E8C)
                                              : Colors.grey,
                                          size: 20 * ws,
                                        ),
                                        SizedBox(width: 8 * ws),
                                        Text(
                                          gender,
                                          style: GoogleFonts.inter(
                                            fontSize: 13 * ws,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedGender = value);
                                },
                              ),
                            ),
                          ),

                          SizedBox(height: 20 * hs),

                          // Complete Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return ElevatedButton(
                                onPressed:
                                    (authProvider.isLoading || _isUploadingImage)
                                        ? null
                                        : _handleComplete,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  padding: EdgeInsets.symmetric(vertical: 13 * hs),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: borderRadius,
                                  ),
                                  elevation: 0,
                                ),
                                child: (authProvider.isLoading || _isUploadingImage)
                                    ? SizedBox(
                                  height: 16 * ws,
                                  width: 16 * ws,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : Text(
                                  'Complete Profile',
                                  style: GoogleFonts.inter(
                                    fontSize: 15 * ws,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: 12 * hs),

                          // Skip button
                          OutlinedButton(
                            onPressed: _handleComplete,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppTheme.primaryGreen,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 11 * hs),
                              shape: RoundedRectangleBorder(
                                borderRadius: borderRadius,
                              ),
                            ),
                            child: Text(
                              'Skip for Now',
                              style: GoogleFonts.inter(
                                fontSize: 13 * ws,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),

                          SizedBox(height: 20 * hs),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
