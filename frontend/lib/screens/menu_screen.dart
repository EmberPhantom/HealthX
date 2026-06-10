// lib/screens/menu_screen.dart
// ✅ Search bar on top
// ✅ Vertical list of themed category banners (like reference screenshots)
// ✅ Tap banner → CategoryDetailScreen with 20 products
// ✅ Fully connected to AppProvider cart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import 'category_detail_screen.dart';

const double _refW = 390.0;
const double _refH = 844.0;

// ─── Banner data model ────────────────────────────────────────────────────────

class CategoryBannerData {
  final String categoryKey;
  final String imageUrl;
  final String titleLine1;
  final String titleLine2;
  final String tagline;
  final Color bgColor;
  final Color titleColor1;
  final Color titleColor2;
  final String itemCount;

  const CategoryBannerData({
    required this.categoryKey,
    required this.imageUrl,
    required this.titleLine1,
    required this.titleLine2,
    required this.tagline,
    required this.bgColor,
    required this.titleColor1,
    required this.titleColor2,
    required this.itemCount,
  });
}

const List<CategoryBannerData> kCategoryBanners = [
  CategoryBannerData(
    categoryKey: 'Healthy Bowls',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'HEARTY',
    titleLine2: 'BREAKFAST',
    tagline: 'Loaded with goodness',
    bgColor: Color(0xFFFFF8E7),
    titleColor1: Color(0xFF2D5016),
    titleColor2: Color(0xFF2D5016),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Salads',
    imageUrl: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'DELHI-STYLE',
    titleLine2: 'CHAATS',
    tagline: 'SERVED FRESH AND CRISP',
    bgColor: Color(0xFF1B5E20),
    titleColor1: Color(0xFFFFD700),
    titleColor2: Color(0xFFFFFFFF),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Protein Meals',
    imageUrl: 'https://images.unsplash.com/photo-1529694157872-4e0c0f3b238b?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'CRISPY',
    titleLine2: 'BITES',
    tagline: 'ALL CRUNCH · NO SOGGINESS',
    bgColor: Color(0xFFFF8C00),
    titleColor1: Color(0xFFFFFFFF),
    titleColor2: Color(0xFF5C1A00),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Smoothies',
    imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'CHILLED',
    titleLine2: 'DRINKS',
    tagline: 'Refreshing & fruity',
    bgColor: Color(0xFF0277BD),
    titleColor1: Color(0xFFFFFFFF),
    titleColor2: Color(0xFFFFFFFF),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Keto',
    imageUrl: 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'SANDWICHES',
    titleLine2: '& WRAPS',
    tagline: '100% FRESH · 100% DAIRY PANEER',
    bgColor: Color(0xFFFFF3E0),
    titleColor1: Color(0xFF7C2D12),
    titleColor2: Color(0xFF7C2D12),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Healthy Bowls',
    imageUrl: 'https://images.unsplash.com/photo-1551024601-bec78aea704b?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'Sweet for',
    titleLine2: 'Sweet tooths',
    tagline: 'Desserts & Sweet Treats',
    bgColor: Color(0xFF1A237E),
    titleColor1: Color(0xFFFFFFFF),
    titleColor2: Color(0xFFFFFFFF),
    itemCount: '20',
  ),
  CategoryBannerData(
    categoryKey: 'Protein Meals',
    imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?q=80&w=800&auto=format&fit=crop',
    titleLine1: 'MAGGI',
    titleLine2: 'MANIAAAAA!',
    tagline: 'Noodles & Quick Bites · 6 items',
    bgColor: Color(0xFFFFD600),
    titleColor1: Color(0xFFD32F2F),
    titleColor2: Color(0xFFD32F2F),
    itemCount: '20',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CategoryBannerData> get _filtered => _searchQuery.isEmpty
      ? kCategoryBanners
      : kCategoryBanners.where((b) =>
  b.categoryKey.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      b.titleLine1.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      b.titleLine2.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ───────────────────────────────────────────────────
            _SearchBar(
              ws: ws, hs: hs,
              ctrl: _searchCtrl,
              query: _searchQuery,
              cartCount: provider.cartItemCount,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
            ),

            // ── Banner list ──────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _EmptySearch(ws: ws)
                  : ListView.separated(
                padding: EdgeInsets.fromLTRB(14 * ws, 10 * hs, 14 * ws, 80 * hs),
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => SizedBox(height: 12 * hs),
                itemBuilder: (ctx, i) => _BannerCard(
                  data: filtered[i],
                  ws: ws, hs: hs,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(banner: filtered[i]),
                    ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final double ws, hs;
  final TextEditingController ctrl;
  final String query;
  final int cartCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.ws, required this.hs, required this.ctrl,
    required this.query, required this.cartCount,
    required this.onChanged, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: EdgeInsets.fromLTRB(14 * ws, 10 * hs, 14 * ws, 10 * hs),
      child: Container(
        height: 44 * hs,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(12 * ws),
        ),
        child: Row(
          children: [
            SizedBox(width: 12 * ws),
            Icon(Icons.search_rounded, size: 20 * ws, color: const Color(0xFF94A3B8)),
            SizedBox(width: 8 * ws),
            Expanded(
              child: TextField(
                controller: ctrl,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 14 * ws, fontFamily: 'Poppins',
                  color: const Color(0xFF0F172A), fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search "Bhel Puri"',
                  hintStyle: TextStyle(
                    fontSize: 14 * ws, fontFamily: 'Poppins',
                    color: const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (query.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: EdgeInsets.all(10 * ws),
                  child: Icon(Icons.close_rounded, size: 16 * ws, color: const Color(0xFF94A3B8)),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.only(right: 10 * ws),
                child: Container(
                  width: 28 * ws, height: 28 * ws,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(7 * ws),
                  ),
                  child: Icon(Icons.tune_rounded, size: 15 * ws, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner Card ──────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final CategoryBannerData data;
  final double ws, hs;
  final VoidCallback onTap;

  const _BannerCard({required this.data, required this.ws, required this.hs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * ws),
        child: SizedBox(
          height: 190 * hs,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Solid bg
              Container(color: data.bgColor),

              // Right-side image
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: screenW * 0.62,
                child: Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: data.bgColor),
                ),
              ),

              // Gradient fade from left
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data.bgColor,
                        data.bgColor,
                        data.bgColor.withOpacity(0.90),
                        data.bgColor.withOpacity(0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.28, 0.44, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // Nav buttons
              Positioned(
                top: 12 * hs, left: 12 * ws,
                child: _CircleBtn(ws: ws, icon: Icons.chevron_left_rounded),
              ),

              // Title + tagline
              Positioned(
                left: 16 * ws, bottom: 28 * hs,
                right: screenW * 0.38,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.titleLine1,
                      style: TextStyle(
                        fontSize: 28 * ws, fontWeight: FontWeight.w900,
                        color: data.titleColor1, fontFamily: 'Poppins',
                        height: 1.0, letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      data.titleLine2,
                      style: TextStyle(
                        fontSize: 28 * ws, fontWeight: FontWeight.w900,
                        color: data.titleColor2, fontFamily: 'Poppins',
                        height: 1.05, letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 5 * hs),
                    Text(
                      data.tagline,
                      style: TextStyle(
                        fontSize: 9 * ws, color: data.titleColor1.withOpacity(0.68),
                        fontFamily: 'Poppins', fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              // Item count badge
              Positioned(
                bottom: 12 * hs, left: 14 * ws,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * ws, vertical: 4 * hs),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(20 * ws),
                  ),
                  child: Text(
                    '${data.itemCount} items',
                    style: TextStyle(
                      fontSize: 10 * ws, color: Colors.white,
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final double ws;
  final IconData icon;
  const _CircleBtn({required this.ws, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34 * ws, height: 34 * ws,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
      ),
      child: Icon(icon, size: 18 * ws, color: const Color(0xFF0F172A)),
    );
  }
}

// ─── Empty Search ─────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  final double ws;
  const _EmptySearch({required this.ws});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔍', style: TextStyle(fontSize: 44 * ws)),
          SizedBox(height: 12 * ws),
          Text('No categories found',
              style: TextStyle(fontSize: 16 * ws, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A), fontFamily: 'Poppins')),
          SizedBox(height: 4 * ws),
          Text('Try a different search',
              style: TextStyle(fontSize: 12 * ws, color: const Color(0xFF94A3B8), fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}