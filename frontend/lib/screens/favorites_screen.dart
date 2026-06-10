import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const double _refW = 360;
  static const double _refH = 800;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final favorites = provider.favoriteItems;
    final size = MediaQuery.sizeOf(context);
    final ws = size.width / _refW;
    final hs = size.height / _refH;
    final hPad = size.width < 600 ? ws * 18 : ws * 24;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            _FavoritesHeader(ws: ws, hs: hs, hPad: hPad, count: favorites.length),

            // ── Body ────────────────────────────────────────────────────
            Expanded(
              child: favorites.isEmpty
                  ? _EmptyFavorites(ws: ws, hs: hs)
                  : ListView.builder(
                padding:
                EdgeInsets.fromLTRB(hPad, hs * 12, hPad, hs * 24),
                physics: const BouncingScrollPhysics(),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  return _FavoriteItemCard(
                    item: favorites[index],
                    ws: ws,
                    hs: hs,
                  )
                      .animate()
                      .fadeIn(
                      duration: 280.ms,
                      delay: Duration(milliseconds: 60 * index))
                      .slideX(begin: 0.03, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _FavoritesHeader extends StatelessWidget {
  final double ws, hs, hPad;
  final int count;

  const _FavoritesHeader({
    required this.ws,
    required this.hs,
    required this.hPad,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(hPad, hs * 16, hPad, hs * 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: ws * 38,
              height: ws * 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(ws * 10),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  size: ws * 19, color: const Color(0xFF0F172A)),
            ),
          ),
          SizedBox(width: ws * 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Favorites',
                  style: TextStyle(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: ws * 21,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  count > 0
                      ? '$count item${count > 1 ? 's' : ''} saved'
                      : 'Your liked items',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: ws * 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          // Heart icon
          Container(
            width: ws * 38,
            height: ws * 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(ws * 10),
            ),
            child: Icon(Icons.favorite_rounded,
                size: ws * 20, color: const Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }
}

// ── Favorite Item Card ─────────────────────────────────────────────────────────

class _FavoriteItemCard extends StatelessWidget {
  final dynamic item;
  final double ws, hs;

  const _FavoriteItemCard(
      {required this.item, required this.ws, required this.hs});

  ProductDetailArgs _toDetailArgs() {
    return ProductDetailArgs(
      menuItem: item,
      weight: '${item.calories} cal',
      originalPrice: null,
      isBestseller: item.rating >= 4.8,
      aboutProduct:
      '${item.name} is a carefully crafted dish made with fresh, high-quality ingredients. '
          '${item.description}. Each serving is prepared fresh to order, ensuring you get the '
          'best taste and nutrition in every bite. A perfect choice for a healthy, balanced meal.',
      otherInfo: {
        'Category': item.category,
        'Calories': '${item.calories} kcal',
        'Protein': 'High',
        'Preparation Time': '15–20 min',
        'Suitable For': item.tags.join(', '),
        'Allergen Info': 'May contain nuts, dairy',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final cartCount = provider.cartItems
        .where((c) => c.menuItem.id == item.id)
        .fold(0, (sum, c) => sum + c.quantity);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(args: _toDetailArgs()),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: hs * 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ws * 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(ws * 12),
          child: Row(
            children: [
              // ── Image ───────────────────────────────────────────────
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ws * 12),
                    child: item.imageUrl != null && item.imageUrl.isNotEmpty
                        ? Image.network(
                      item.imageUrl,
                      width: ws * 82,
                      height: ws * 82,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderBox(ws: ws),
                    )
                        : _PlaceholderBox(ws: ws),
                  ),
                  // Favorite badge
                  Positioned(
                    top: ws * 4,
                    right: ws * 4,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.toggleFavorite(item.id);
                      },
                      child: Container(
                        width: ws * 26,
                        height: ws * 26,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          size: ws * 13,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: ws * 12),

              // ── Info ─────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + veg indicator
                    Row(
                      children: [
                        _VegIndicator(isVeg: item.isVeg, ws: ws),
                        SizedBox(width: ws * 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: ws * 14,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hs * 3),
                    Text(
                      item.description,
                      style: TextStyle(
                        color: const Color(0xFF94A3B8),
                        fontSize: ws * 11,
                        fontFamily: 'Poppins',
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: hs * 5),

                    // Rating + Calories
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppTheme.yellow, size: ws * 13),
                        SizedBox(width: ws * 2),
                        Text(
                          '${item.rating}',
                          style: TextStyle(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w600,
                            fontSize: ws * 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        SizedBox(width: ws * 6),
                        Container(
                          width: ws * 3,
                          height: ws * 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: ws * 6),
                        Text(
                          '${item.calories} cal',
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: ws * 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: hs * 7),

                    // Price + Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${item.price.toInt()}',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: ws * 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        cartCount == 0
                            ? GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            provider.addToCart(item);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: ws * 14, vertical: hs * 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius:
                              BorderRadius.circular(ws * 8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Colors.white, size: ws * 14),
                                SizedBox(width: ws * 3),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: ws * 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(ws * 8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.updateQuantity(
                                      item.id, cartCount - 1);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: ws * 8,
                                      vertical: hs * 6),
                                  child: Icon(Icons.remove,
                                      size: ws * 14,
                                      color: Colors.white),
                                ),
                              ),
                              Text(
                                '$cartCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ws * 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.addToCart(item);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: ws * 8,
                                      vertical: hs * 6),
                                  child: Icon(Icons.add,
                                      size: ws * 14,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _VegIndicator extends StatelessWidget {
  final bool isVeg;
  final double ws;
  const _VegIndicator({required this.isVeg, required this.ws});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ws * 13,
      height: ws * 13,
      decoration: BoxDecoration(
        border: Border.all(
          color:
          isVeg ? AppTheme.primaryGreen : const Color(0xFFEF4444),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(ws * 2),
      ),
      child: Center(
        child: Container(
          width: ws * 6,
          height: ws * 6,
          decoration: BoxDecoration(
            color: isVeg ? AppTheme.primaryGreen : const Color(0xFFEF4444),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  final double ws;
  const _PlaceholderBox({required this.ws});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ws * 82,
      height: ws * 82,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(ws * 12),
      ),
      child: Center(
        child: Text('🥗', style: TextStyle(fontSize: ws * 32)),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  final double ws, hs;
  const _EmptyFavorites({required this.ws, required this.hs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ws * 100,
            height: ws * 100,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🤍', style: TextStyle(fontSize: ws * 44)),
            ),
          ),
          SizedBox(height: hs * 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: ws * 20,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: hs * 8),
          Text(
            'Tap the ♡ on any item to\nsave it here for quick access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: ws * 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
          SizedBox(height: hs * 28),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              context.read<AppProvider>().setTabIndex(1);
            },
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: ws * 24, vertical: hs * 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34D399), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(ws * 14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      color: Colors.white, size: ws * 17),
                  SizedBox(width: ws * 8),
                  Text(
                    'Explore Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: ws * 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}