// lib/screens/product_detail_screen.dart
// ✅ Professional production-level product detail page
// ✅ BigBasket-style image carousel with PageView (slide view)
// ✅ Add → stepper + View Cart sticky bottom
// ✅ Search icon → opens search bottom sheet
// ✅ Share button → uses share_plus to share product
// ✅ Similar products → tap to open their own ProductDetailScreen (recursive navigation)
// ✅ + button on similar products → adds to cart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/theme.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import 'cart_screen.dart';
import 'ready_to_eat_screen.dart' show rteMenuItems, rteMeta;
import 'image_zoom_screen.dart';

const double _pdRefW = 360.0;
const double _pdRefH = 800.0;

// ─── Args ────────────────────────────────────────────────────────────────────

class ProductDetailArgs {
  final MenuItem menuItem;
  final String weight;
  final double? originalPrice;
  final bool isBestseller;
  final String aboutProduct;
  final Map<String, String> otherInfo;
  // Optional: pass multiple images for carousel; defaults to imageUrl repeated
  final List<String>? imageUrls;

  const ProductDetailArgs({
    required this.menuItem,
    required this.weight,
    this.originalPrice,
    this.isBestseller = false,
    required this.aboutProduct,
    required this.otherInfo,
    this.imageUrls,
  });
}

// ─── Similar Products  (clickable → new detail screen) ───────────────────────

class SimilarProductDetail {
  final String name;
  final double price;
  final double? originalPrice;
  final int discountPct;
  final String imageUrl;
  final String id;

  const SimilarProductDetail({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.discountPct = 0,
    this.imageUrl = 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=400&auto=format&fit=crop',
  });
}

// ─── Similar products built LIVE from real rteMenuItems — no fake data ─────────
List<SimilarProductDetail> get _sharedSimilar => rteMenuItems.map((item) {
  final meta = rteMeta[item.id];
  final orig = meta?.originalPrice;
  final discPct = orig != null
      ? (((orig - item.price) / orig) * 100).round()
      : 0;
  return SimilarProductDetail(
    id: item.id,
    name: item.name,
    price: item.price,
    originalPrice: orig,
    discountPct: discPct,
    imageUrl: item.imageUrl, // local asset path
  );
}).toList();

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProductDetailScreen extends StatefulWidget {
  final ProductDetailArgs args;

  const ProductDetailScreen({super.key, required this.args});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _aboutExpanded = true;
  bool _otherInfoExpanded = false;
  bool _hideDetails = false;
  int _currentImageIndex = 0;
  late final PageController _pageController;

  MenuItem get _item => widget.args.menuItem;

  List<String> get _images {
    if (widget.args.imageUrls != null && widget.args.imageUrls!.isNotEmpty) {
      return widget.args.imageUrls!;
    }
    // Default: show same image 3 times for carousel demo
    return [
      _item.imageUrl,
      _item.imageUrl,
      _item.imageUrl,
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _cartQty(AppProvider provider) => provider.cartItems
      .where((c) => c.menuItem.id == _item.id)
      .fold(0, (s, c) => s + c.quantity);

  // ── Share product ──────────────────────────────────────────────────────────
  void _shareProduct() {
    final args = widget.args;
    Share.share(
      '🥗 Check out ${_item.name} on HappyBowl!\n\n'
          '${_item.description}\n\n'
          '💰 Only ₹${_item.price.toInt()}${args.originalPrice != null ? ' (was ₹${args.originalPrice!.toInt()})' : ''}\n\n'
          '⭐ ${_item.rating} · ${_item.reviewCount} reviews\n\n'
          'Download the HappyBowl app to order!',
      subject: _item.name,
    );
  }

  // ── Search bottom sheet ────────────────────────────────────────────────────
  void _openSearch(BuildContext context, double ws, double hs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(ws: ws, hs: hs),
    );
  }

  // ── Navigate to similar product detail — uses real rteMenuItems + rteMeta ──
  void _openSimilarDetail(BuildContext context, SimilarProductDetail similar) {
    HapticFeedback.mediumImpact();
    // Look up real MenuItem and meta from our product database
    final realItem = rteMenuItems.firstWhere(
          (m) => m.id == similar.id,
      orElse: () => MenuItem(
        id: similar.id,
        name: similar.name,
        description: 'Premium healthy snack from HappyBowl.',
        price: similar.price,
        calories: 0,
        rating: 4.5,
        reviewCount: 100,
        imageUrl: similar.imageUrl,
        emoji: '🥗',
        category: 'Snacks',
        tags: ['Healthy', 'Natural'],
        isVeg: true,
      ),
    );
    final realMeta = rteMeta[similar.id];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          args: ProductDetailArgs(
            menuItem: realItem,
            weight: realMeta?.weight ?? '100g',
            originalPrice: similar.originalPrice,
            isBestseller: realMeta?.isBestseller ?? false,
            aboutProduct: realMeta?.aboutProduct ??
                'A premium HappyBowl product crafted with the finest natural ingredients. '
                    'No preservatives, no artificial flavours. Made with care in India.',
            otherInfo: realMeta?.otherInfo ?? {
              'Brand': 'HappyBowl',
              'Country of Origin': 'India',
              'Preservatives': 'None',
            },
            imageUrls: realMeta?.imageUrls,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final cartCount = _cartQty(provider);
        final ws = MediaQuery.of(context).size.width / _pdRefW;
        final hs = MediaQuery.of(context).size.height / _pdRefH;
        final args = widget.args;
        final hasDiscount = args.originalPrice != null;
        final discountPct = hasDiscount
            ? ((args.originalPrice! - _item.price) / args.originalPrice! * 100)
            .round()
            : 0;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Stack(
              children: [
                // ── Scrollable ───────────────────────────────────────────────
                CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // ── Hero Image Carousel SliverAppBar ─────────────────────
                    SliverAppBar(
                      expandedHeight: 300 * hs,
                      pinned: true,
                      backgroundColor: Colors.white,
                      elevation: 0.5,
                      leading: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: EdgeInsets.all(8 * ws),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6)
                            ],
                          ),
                          child: Icon(Icons.arrow_back,
                              size: 18 * ws, color: Colors.black87),
                        ),
                      ),
                      title: Text(_item.name,
                          style: TextStyle(
                              fontSize: 13 * ws,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontFamily: 'Poppins'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      actions: [
                        // ── Search button ──────────────────────────────────
                        _ABar(
                          icon: Icons.search_rounded,
                          ws: ws,
                          onTap: () => _openSearch(context, ws, hs),
                        ),
                        // ── Favourite ──────────────────────────────────────
                        _ABar(
                          icon: _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          ws: ws,
                          iconColor:
                          _isFavorite ? Colors.red : Colors.black87,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFavorite = !_isFavorite);
                            provider.toggleFavorite(_item.id);
                          },
                        ),
                        // ── Share button ───────────────────────────────────
                        _ABar(
                          icon: Icons.share_rounded,
                          ws: ws,
                          onTap: _shareProduct,
                        ),
                        SizedBox(width: 4 * ws),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ── Image Carousel (BigBasket-style) ──────────
                            // Tap on image → Flipkart full-screen zoom viewer
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    opaque: false,
                                    barrierColor: Colors.black,
                                    transitionDuration:
                                    const Duration(milliseconds: 320),
                                    pageBuilder: (_, __, ___) =>
                                        ImageZoomScreen(
                                          args: ImageZoomArgs(
                                            imageUrls: _images,
                                            initialIndex: _currentImageIndex,
                                            productName: _item.name,
                                          ),
                                        ),
                                    transitionsBuilder:
                                        (_, anim, __, child) =>
                                        FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                  ),
                                );
                              },
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _images.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImageIndex = i),
                                itemBuilder: (_, i) => _images[i].startsWith('http')
                                    ? Image.network(
                                  _images[i],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (ctx, child, progress) =>
                                  progress == null ? child : Container(
                                    color: const Color(0xFFF0FDF4),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF10B981),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF0FDF4),
                                    child: const Center(
                                      child: Text('🥗', style: TextStyle(fontSize: 60)),
                                    ),
                                  ),
                                )
                                    : Image.asset(_images[i], fit: BoxFit.cover),
                              ),
                            ),

                            // Top gradient
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 80 * hs,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.15),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Bestseller badge
                            if (args.isBestseller)
                              Positioned(
                                top: 56 * hs,
                                right: 12 * ws,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10 * ws, vertical: 4 * hs),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B),
                                      borderRadius:
                                      BorderRadius.circular(20 * ws)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🏆',
                                          style:
                                          TextStyle(fontSize: 10 * ws)),
                                      SizedBox(width: 3 * ws),
                                      Text('Bestseller',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10 * ws,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Poppins')),
                                    ],
                                  ),
                                ),
                              ),

                            // ── Dot indicators ─────────────────────────────
                            Positioned(
                              bottom: 10 * hs,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _images.length,
                                      (i) => AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 250),
                                    width: i == _currentImageIndex
                                        ? 18 * ws
                                        : 6 * ws,
                                    height: 6 * ws,
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 2 * ws),
                                    decoration: BoxDecoration(
                                      color: i == _currentImageIndex
                                          ? AppTheme.primaryGreen
                                          : Colors.white.withOpacity(0.7),
                                      borderRadius:
                                      BorderRadius.circular(3 * ws),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Image counter badge (top left, below leading)
                            Positioned(
                              bottom: 10 * hs,
                              right: 12 * ws,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8 * ws, vertical: 3 * hs),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius:
                                  BorderRadius.circular(20 * ws),
                                ),
                                child: Text(
                                  '${_currentImageIndex + 1}/${_images.length}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10 * ws,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Product Info ──────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * ws),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 14 * hs),
                            // Brand
                            Row(
                              children: [
                                Text('HappyBowl',
                                    style: TextStyle(
                                        fontSize: 12 * ws,
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins')),
                                Icon(Icons.chevron_right_rounded,
                                    size: 16 * ws,
                                    color: AppTheme.primaryGreen),
                              ],
                            ),
                            SizedBox(height: 4 * hs),
                            Text(_item.name,
                                style: TextStyle(
                                    fontSize: 20 * ws,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    fontFamily: 'Poppins',
                                    height: 1.2)),
                            SizedBox(height: 8 * hs),
                            // Tags
                            if (_item.tags.isNotEmpty)
                              Wrap(
                                spacing: 6 * ws,
                                runSpacing: 4 * hs,
                                children: _item.tags.map((tag) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8 * ws, vertical: 3 * hs),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.08),
                                      borderRadius:
                                      BorderRadius.circular(4 * ws),
                                      border: Border.all(
                                          color: AppTheme.primaryGreen
                                              .withOpacity(0.25),
                                          width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt,
                                            size: 10 * ws,
                                            color: AppTheme.primaryGreen),
                                        SizedBox(width: 2 * ws),
                                        Text(tag,
                                            style: TextStyle(
                                                fontSize: 10 * ws,
                                                color: AppTheme.primaryGreen,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Poppins')),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            SizedBox(height: 14 * hs),
                            // Price row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('₹${_item.price.toInt()}',
                                    style: TextStyle(
                                        fontSize: 22 * ws,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                        fontFamily: 'Poppins')),
                                if (hasDiscount) ...[
                                  SizedBox(width: 8 * ws),
                                  Text('₹${args.originalPrice!.toInt()}',
                                      style: TextStyle(
                                          fontSize: 14 * ws,
                                          color: Colors.grey.shade400,
                                          fontFamily: 'Poppins',
                                          decoration:
                                          TextDecoration.lineThrough)),
                                  SizedBox(width: 6 * ws),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6 * ws, vertical: 2 * hs),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(4 * ws),
                                    ),
                                    child: Text('$discountPct% OFF',
                                        style: TextStyle(
                                            fontSize: 10 * ws,
                                            color: const Color(0xFF16A34A),
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Poppins')),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 8 * hs),
                            // Rating row
                            Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 14 * ws,
                                    color: const Color(0xFFF59E0B)),
                                SizedBox(width: 3 * ws),
                                Text(
                                    '${_item.rating} · ${_item.reviewCount} reviews · ${args.weight}',
                                    style: TextStyle(
                                        fontSize: 11 * ws,
                                        color: Colors.grey.shade500,
                                        fontFamily: 'Poppins')),
                              ],
                            ),
                            SizedBox(height: 20 * hs),
                          ],
                        ),
                      ),
                    ),

                    // ── Divider ───────────────────────────────────────────────
                    SliverToBoxAdapter(
                        child: Container(
                            height: 6 * hs,
                            color: const Color(0xFFF1F5F9))),

                    // ── Pack Sizes ────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            16 * ws, 14 * hs, 16 * ws, 14 * hs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pack Sizes',
                                style: TextStyle(
                                    fontSize: 13 * ws,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    fontFamily: 'Poppins')),
                            SizedBox(height: 10 * hs),
                            // Horizontal scrollable pack size chips — BigBasket style
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _PackChip(
                                    pcs: '1 pc',
                                    weight: args.weight,
                                    price: _item.price,
                                    originalPrice: args.originalPrice,
                                    selected: true,
                                    ws: ws,
                                    hs: hs,
                                  ),
                                  SizedBox(width: 10 * ws),
                                  _PackChip(
                                    pcs: '2 pcs',
                                    weight: args.weight,
                                    price: _item.price * 2,
                                    originalPrice: args.originalPrice != null
                                        ? args.originalPrice! * 2
                                        : null,
                                    selected: false,
                                    ws: ws,
                                    hs: hs,
                                  ),
                                  SizedBox(width: 10 * ws),
                                  _PackChip(
                                    pcs: '3 pcs',
                                    weight: args.weight,
                                    price: _item.price * 3,
                                    originalPrice: args.originalPrice != null
                                        ? args.originalPrice! * 3
                                        : null,
                                    selected: false,
                                    ws: ws,
                                    hs: hs,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Divider ───────────────────────────────────────────────
                    SliverToBoxAdapter(
                        child: Container(
                            height: 6 * hs,
                            color: const Color(0xFFF1F5F9))),

                    // ── Variants (thumbnail carousel) ─────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            16 * ws, 16 * hs, 16 * ws, 16 * hs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Variants:',
                                style: TextStyle(
                                    fontSize: 13 * ws,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'Poppins')),
                            SizedBox(height: 10 * hs),
                            SizedBox(
                              height: 85 * hs,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 8 * ws),
                                itemBuilder: (_, i) => GestureDetector(
                                  onTap: () {
                                    _pageController.animateToPage(i,
                                        duration:
                                        const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 76 * ws,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: i == _currentImageIndex
                                              ? AppTheme.primaryGreen
                                              : const Color(0xFFE2E8F0),
                                          width: i == _currentImageIndex
                                              ? 2
                                              : 1),
                                      borderRadius:
                                      BorderRadius.circular(8 * ws),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(7 * ws),
                                      child: _images[i].startsWith('http')
                                          ? Image.network(
                                        _images[i],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: const Color(0xFFF0FDF4),
                                          child: const Center(
                                            child: Text('🥗', style: TextStyle(fontSize: 20)),
                                          ),
                                        ),
                                      )
                                          : Image.asset(_images[i], fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Hide/Show product details toggle ──────────────────────
                    SliverToBoxAdapter(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _hideDetails = !_hideDetails),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 16 * ws),
                          padding: EdgeInsets.symmetric(vertical: 12 * hs),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10 * ws),
                            border: Border.all(
                                color:
                                AppTheme.primaryGreen.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _hideDetails
                                    ? 'Show product details'
                                    : 'Hide product details',
                                style: TextStyle(
                                    fontSize: 12 * ws,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                              ),
                              SizedBox(width: 4 * ws),
                              Icon(
                                _hideDetails
                                    ? Icons.keyboard_arrow_down_rounded
                                    : Icons.keyboard_arrow_up_rounded,
                                size: 18 * ws,
                                color: AppTheme.primaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 8 * hs)),

                    // ── Accordions ────────────────────────────────────────────
                    if (!_hideDetails) ...[
                      SliverToBoxAdapter(
                        child: _Accordion(
                          title: 'About the Product',
                          isExpanded: _aboutExpanded,
                          ws: ws,
                          hs: hs,
                          onTap: () => setState(
                                  () => _aboutExpanded = !_aboutExpanded),
                          content: args.aboutProduct,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Divider(
                            height: 1, color: const Color(0xFFE2E8F0)),
                      ),
                      SliverToBoxAdapter(
                        child: _Accordion(
                          title: 'Other Product Info',
                          isExpanded: _otherInfoExpanded,
                          ws: ws,
                          hs: hs,
                          onTap: () => setState(() =>
                          _otherInfoExpanded = !_otherInfoExpanded),
                          otherInfo: args.otherInfo,
                        ),
                      ),
                    ],

                    // ── Divider ───────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                          height: 6 * hs,
                          color: const Color(0xFFF1F5F9),
                          margin: EdgeInsets.only(top: 8 * hs)),
                    ),

                    // ── You may also like ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            16 * ws, 16 * hs, 0, 16 * hs),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('You may also like',
                                      style: TextStyle(
                                          fontSize: 15 * ws,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                          fontFamily: 'Poppins')),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    margin: EdgeInsets.only(right: 16 * ws),
                                    padding: EdgeInsets.all(6 * ws),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                            const Color(0xFFE2E8F0)),
                                        shape: BoxShape.circle),
                                    child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 12 * ws,
                                        color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12 * hs),
                            // Horizontal list of similar products
                            SizedBox(
                              height: 200 * hs,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _sharedSimilar
                                    .where((s) => s.id != _item.id)
                                    .length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(width: 10 * ws),
                                itemBuilder: (ctx, i) {
                                  final filtered = _sharedSimilar
                                      .where((s) => s.id != _item.id)
                                      .toList();
                                  final product = filtered[i];
                                  return _SimilarCard(
                                    product: product,
                                    ws: ws,
                                    hs: hs,
                                    onTap: () =>
                                        _openSimilarDetail(ctx, product),
                                    onAdd: () {
                                      HapticFeedback.mediumImpact();
                                      // Use real MenuItem from rteMenuItems
                                      final realItem = rteMenuItems.firstWhere(
                                            (m) => m.id == product.id,
                                        orElse: () => MenuItem(
                                          id: product.id,
                                          name: product.name,
                                          description: 'Premium HappyBowl snack.',
                                          price: product.price,
                                          calories: 0,
                                          rating: 4.5,
                                          reviewCount: 100,
                                          imageUrl: product.imageUrl,
                                          emoji: '🥗',
                                          category: 'Snacks',
                                          tags: ['Healthy'],
                                          isVeg: true,
                                        ),
                                      );
                                      Provider.of<AppProvider>(context,
                                          listen: false)
                                          .addToCart(realItem);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            '${product.name} added to cart!',
                                            style: const TextStyle(
                                                fontFamily: 'Poppins')),
                                        backgroundColor:
                                        AppTheme.primaryGreen,
                                        duration:
                                        const Duration(seconds: 1),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom padding for sticky bar
                    SliverToBoxAdapter(
                        child: SizedBox(height: 100 * hs)),
                  ],
                ),

                // ── Sticky Bottom Bar ─────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4))
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            16 * ws, 12 * hs, 16 * ws, 12 * hs),
                        child: cartCount == 0
                            ? _AddBtn(
                          ws: ws,
                          hs: hs,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            provider.addToCart(_item);
                          },
                        )
                            : _CartActions(
                          ws: ws,
                          hs: hs,
                          count: cartCount,
                          onAdd: () {
                            HapticFeedback.lightImpact();
                            provider.addToCart(_item);
                          },
                          onRemove: () {
                            HapticFeedback.lightImpact();
                            provider.updateQuantity(
                                _item.id, cartCount - 1);
                          },
                          onViewCart: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ), // Scaffold
        ); // AnnotatedRegion
      },
    );
  }
}

// ─── Search Bottom Sheet ──────────────────────────────────────────────────────

class _SearchSheet extends StatefulWidget {
  final double ws, hs;
  const _SearchSheet({required this.ws, required this.hs});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  // Real product names from our catalog
  final _suggestions = rteMenuItems.map((m) => m.name).toList();

  List<String> get _filtered => _query.isEmpty
      ? _suggestions
      : _suggestions
      .where((s) =>
      s.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = widget.ws;
    final hs = widget.hs;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20 * ws)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 10 * hs),
              width: 36 * ws,
              height: 4 * hs,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  16 * ws, 14 * hs, 16 * ws, 10 * hs),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44 * hs,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10 * ws),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        onChanged: (v) =>
                            setState(() => _query = v),
                        style: TextStyle(
                            fontSize: 14 * ws,
                            fontFamily: 'Poppins'),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: TextStyle(
                              fontSize: 13 * ws,
                              color: Colors.grey.shade400,
                              fontFamily: 'Poppins'),
                          prefixIcon: Icon(Icons.search_rounded,
                              size: 20 * ws,
                              color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12 * hs),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * ws),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: 13 * ws,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: const Color(0xFFE2E8F0)),
            if (_query.isNotEmpty && _filtered.isEmpty)
              Padding(
                padding: EdgeInsets.all(32 * ws),
                child: Text('No results found',
                    style: TextStyle(
                        fontSize: 14 * ws,
                        color: Colors.grey.shade500,
                        fontFamily: 'Poppins')),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: const Color(0xFFF1F5F9)),
                  itemBuilder: (_, i) {
                    final s = _filtered[i];
                    return ListTile(
                      leading: Icon(Icons.search_rounded,
                          size: 18 * ws,
                          color: Colors.grey.shade400),
                      title: Text(s,
                          style: TextStyle(
                              fontSize: 13 * ws,
                              fontFamily: 'Poppins',
                              color: const Color(0xFF0F172A))),
                      trailing: Icon(
                          Icons.north_west_rounded,
                          size: 14 * ws,
                          color: Colors.grey.shade400),
                      onTap: () {
                        Navigator.pop(context);
                        // In production: navigate to search results
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── AppBar Action Button ─────────────────────────────────────────────────────

class _ABar extends StatelessWidget {
  final IconData icon;
  final double ws;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ABar(
      {required this.icon,
        required this.ws,
        this.iconColor,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8 * ws, horizontal: 3 * ws),
        width: 34 * ws,
        height: 34 * ws,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 4)
          ],
        ),
        child: Icon(icon,
            size: 17 * ws, color: iconColor ?? Colors.black87),
      ),
    );
  }
}

// ─── Pack Chip (BigBasket-style compact selectable) ──────────────────────────

class _PackChip extends StatelessWidget {
  final String pcs;
  final String weight;
  final double price;
  final double? originalPrice;
  final bool selected;
  final double ws, hs;

  const _PackChip({
    required this.pcs,
    required this.weight,
    required this.price,
    this.originalPrice,
    required this.selected,
    required this.ws,
    required this.hs,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(horizontal: 12 * ws, vertical: 10 * hs),
      decoration: BoxDecoration(
        color: selected
            ? AppTheme.primaryGreen.withOpacity(0.06)
            : Colors.white,
        border: Border.all(
            color: selected
                ? AppTheme.primaryGreen
                : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1),
        borderRadius: BorderRadius.circular(8 * ws),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Container(
                  width: 14 * ws,
                  height: 14 * ws,
                  margin: EdgeInsets.only(right: 5 * ws),
                  decoration: BoxDecoration(
                      color: AppTheme.primaryGreen, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 9 * ws, color: Colors.white),
                ),
              Text(pcs,
                  style: TextStyle(
                      fontSize: 12 * ws,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryGreen
                          : const Color(0xFF0F172A),
                      fontFamily: 'Poppins')),
            ],
          ),
          SizedBox(height: 2 * hs),
          Text(weight,
              style: TextStyle(
                  fontSize: 10 * ws,
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins')),
          SizedBox(height: 4 * hs),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹${price.toInt()}',
                  style: TextStyle(
                      fontSize: 13 * ws,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      fontFamily: 'Poppins')),
              if (originalPrice != null) ...[
                SizedBox(width: 5 * ws),
                Text('₹${originalPrice!.toInt()}',
                    style: TextStyle(
                        fontSize: 10 * ws,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.lineThrough,
                        fontFamily: 'Poppins')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Accordion ────────────────────────────────────────────────────────────────

class _Accordion extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final double ws, hs;
  final VoidCallback onTap;
  final String? content;
  final Map<String, String>? otherInfo;

  const _Accordion({
    required this.title,
    required this.isExpanded,
    required this.ws,
    required this.hs,
    required this.onTap,
    this.content,
    this.otherInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 16 * ws, vertical: 14 * hs),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 14 * ws,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                          fontFamily: 'Poppins')),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20 * ws,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.fromLTRB(
                16 * ws, 0, 16 * ws, 16 * hs),
            child: content != null
                ? Text(content!,
                style: TextStyle(
                    fontSize: 12 * ws,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                    height: 1.6))
                : Column(
              children: (otherInfo ?? {}).entries.map((e) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8 * hs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120 * ws,
                        child: Text(e.key,
                            style: TextStyle(
                                fontSize: 11 * ws,
                                color: Colors.grey.shade500,
                                fontFamily: 'Poppins')),
                      ),
                      Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 11 * ws,
                                color:
                                const Color(0xFF0F172A),
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Similar Product Card (BigBasket compact style) ──────────────────────────

class _SimilarCard extends StatelessWidget {
  final SimilarProductDetail product;
  final double ws, hs;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _SimilarCard({
    required this.product,
    required this.ws,
    required this.hs,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120 * ws,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * ws),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Image with + button overlay ─────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(10 * ws)),
                  child: product.imageUrl.startsWith('http')
                      ? Image.network(
                    product.imageUrl,
                    height: 110 * hs,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110 * hs,
                      color: const Color(0xFFF0FDF4),
                      child: const Center(
                        child: Text('🥗', style: TextStyle(fontSize: 36)),
                      ),
                    ),
                  )
                      : Image.asset(
                    product.imageUrl,
                    height: 110 * hs,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Discount badge
                if (product.originalPrice != null)
                  Positioned(
                    top: 6 * hs,
                    left: 6 * ws,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5 * ws, vertical: 2 * hs),
                      decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(4 * ws)),
                      child: Text('${product.discountPct}% OFF',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8 * ws,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                // + Add button positioned bottom-right on image
                Positioned(
                  bottom: 6 * hs,
                  right: 6 * ws,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 28 * ws,
                      height: 28 * ws,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7 * ws),
                        border: Border.all(
                            color: AppTheme.primaryGreen, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: Icon(Icons.add,
                          size: 16 * ws,
                          color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  7 * ws, 7 * hs, 7 * ws, 8 * hs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: TextStyle(
                          fontSize: 11 * ws,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                          fontFamily: 'Poppins',
                          height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  SizedBox(height: 5 * hs),
                  // Price row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('₹${product.price.toInt()}',
                          style: TextStyle(
                              fontSize: 13 * ws,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              fontFamily: 'Poppins')),
                      if (product.originalPrice != null) ...[
                        SizedBox(width: 4 * ws),
                        Text('₹${product.originalPrice!.toInt()}',
                            style: TextStyle(
                                fontSize: 9 * ws,
                                color: Colors.grey.shade400,
                                fontFamily: 'Poppins',
                                decoration: TextDecoration.lineThrough)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Button ───────────────────────────────────────────────────────────────

class _AddBtn extends StatelessWidget {
  final double ws, hs;
  final VoidCallback onTap;

  const _AddBtn(
      {required this.ws, required this.hs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50 * hs,
        decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(10 * ws),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ]),
        child: Center(
          child: Text('Add to Cart',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * ws,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins')),
        ),
      ),
    );
  }
}

// ─── Cart Actions (stepper + View Cart) ──────────────────────────────────────

class _CartActions extends StatelessWidget {
  final double ws, hs;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onViewCart;

  const _CartActions({
    required this.ws,
    required this.hs,
    required this.count,
    required this.onAdd,
    required this.onRemove,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stepper
        Container(
          decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(10 * ws)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14 * ws, vertical: 14 * hs),
                  child: Icon(Icons.remove,
                      size: 18 * ws, color: Colors.white),
                ),
              ),
              SizedBox(
                width: 28 * ws,
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * ws,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins')),
              ),
              GestureDetector(
                onTap: onAdd,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14 * ws, vertical: 14 * hs),
                  child: Icon(Icons.add,
                      size: 18 * ws, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12 * ws),
        // View Cart
        Expanded(
          child: GestureDetector(
            onTap: onViewCart,
            child: Container(
              height: 50 * hs,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(10 * ws),
                boxShadow: [
                  BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 18 * ws, color: Colors.white),
                  SizedBox(width: 8 * ws),
                  Text('View Cart',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15 * ws,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                  SizedBox(width: 8 * ws),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 12 * ws, color: Colors.white),
                ],
              ),),
          ),
        ),
      ],
    );
  }
}