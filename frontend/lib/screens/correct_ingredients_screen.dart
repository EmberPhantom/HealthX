import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'counting_calories_screen.dart';

class CorrectIngredientsScreen extends StatefulWidget {
  final File imageFile;
  final String meal;
  final String? mealDescription;
  final bool isTextBased;
  final Map<String, dynamic> nutritionData;

  const CorrectIngredientsScreen({
    super.key,
    required this.imageFile,
    required this.meal,
    this.mealDescription,
    this.isTextBased = false,
    required this.nutritionData,
  });

  @override
  State<CorrectIngredientsScreen> createState() =>
      _CorrectIngredientsScreenState();
}

class _CorrectIngredientsScreenState extends State<CorrectIngredientsScreen> {
  List<_Ingredient> _ingredients = [];

  @override
  void initState() {
    super.initState();
    final rawList = widget.nutritionData['ingredients'] as List?;
    if (rawList != null) {
      _ingredients = rawList.map((x) {
        final str = x.toString();
        final parts = str.split(' - ');
        if (parts.length >= 2) {
          return _Ingredient(name: parts[0], qty: parts[1]);
        }
        return _Ingredient(name: str, qty: '1 serving');
      }).toList();
    } else {
      _ingredients = [
        _Ingredient(name: 'Sweet corn kernels', qty: '1 cup'),
        _Ingredient(name: 'Sliced carrots', qty: '1 cup'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = MediaQuery.of(context).size.height;

        const double refW = 360;
        const double refH = 800;

        final double ws = screenWidth / refW;
        final double hs = screenHeight / refH;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      18 * ws, 14 * hs, 18 * ws, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20 * ws, color: const Color(0xFF1A1A2E)),
                      ),
                      SizedBox(width: 12 * ws),
                      Expanded(
                        child: Text(
                          'Correct ingredients',
                          style: GoogleFonts.poppins(
                            fontSize: 16 * ws,
                            fontWeight: FontWeight.w600,
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
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 16 * hs, color: const Color(0xFFE5E7EB)),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        18 * ws, 8 * hs, 18 * ws, 100 * hs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text-based description
                        if (widget.isTextBased &&
                            widget.mealDescription != null) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(14 * ws),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F5FF),
                              borderRadius:
                              BorderRadius.circular(10 * ws),
                              border: Border.all(
                                  color: const Color(0xFFBBD0FF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your description',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11 * ws,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5C6BC0),
                                  ),
                                ),
                                SizedBox(height: 4 * hs),
                                Text(
                                  widget.mealDescription!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13 * ws,
                                    color: const Color(0xFF1A1A2E),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * hs),
                        ],

                        // Meal name tag
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 14 * ws,
                              vertical: 10 * hs),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10 * ws),
                          ),
                          child: Text(
                            widget.nutritionData['foodName'] ?? widget.nutritionData['name'] ?? 'Identified Food',
                            style: GoogleFonts.poppins(
                              fontSize: 13 * ws,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                        SizedBox(height: 18 * hs),

                        Text(
                          'Ingredients',
                          style: GoogleFonts.poppins(
                            fontSize: 15 * ws,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 10 * hs),

                        // Ingredients list
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ingredients.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                          itemBuilder: (context, i) {
                            final ing = _ingredients[i];
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 10 * hs),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32 * ws,
                                    height: 32 * ws,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius:
                                      BorderRadius.circular(16 * ws),
                                    ),
                                    child: Center(
                                        child: Text('🥘',
                                            style: TextStyle(
                                                fontSize: 14 * ws))),
                                  ),
                                  SizedBox(width: 10 * ws),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ing.name.length > 26
                                              ? '${ing.name.substring(0, 26)}...'
                                              : ing.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13 * ws,
                                            fontWeight: FontWeight.w500,
                                            color:
                                            const Color(0xFF1A1A2E),
                                          ),
                                        ),
                                        Text(
                                          ing.qty,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11 * ws,
                                            color:
                                            const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.edit_outlined,
                                        size: 16 * ws,
                                        color: const Color(0xFF6B7280)),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                        minWidth: 30 * ws,
                                        minHeight: 30 * ws),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _ingredients.removeAt(i);
                                      });
                                    },
                                    icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16 * ws,
                                        color: const Color(0xFF6B7280)),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(
                                        minWidth: 30 * ws,
                                        minHeight: 30 * ws),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 10 * hs),

                        // Add ingredient button
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding:
                            EdgeInsets.symmetric(vertical: 14 * hs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(12 * ws),
                              border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1.5,
                                  style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    size: 16 * ws,
                                    color: const Color(0xFF1A1A2E)),
                                SizedBox(width: 6 * ws),
                                Text(
                                  'Ingredient',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13 * ws,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Next button
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      18 * ws, 8 * hs, 18 * ws, 20 * hs),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CountingCaloriesScreen(
                              imageFile: widget.imageFile,
                              meal: widget.meal,
                              isTextBased: widget.isTextBased,
                              nutritionData: widget.nutritionData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding:
                        EdgeInsets.symmetric(vertical: 16 * hs),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14 * ws),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 15 * ws,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Ingredient {
  String name;
  String qty;
  _Ingredient({required this.name, required this.qty});
}