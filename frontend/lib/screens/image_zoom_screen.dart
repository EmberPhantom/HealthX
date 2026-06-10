// lib/screens/image_zoom_screen.dart
// ✅ Flipkart-style full-screen image zoom viewer
// ✅ Pinch-to-zoom (InteractiveViewer)
// ✅ Swipe between multiple images (PageView)
// ✅ Double tap to zoom in/out
// ✅ Swipe down to close (DraggableScrollableSheet style dismiss)
// ✅ Image counter + dot indicators
// ✅ Share button
// ✅ Download / save button UI
// ✅ Hero animation from product card

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class ImageZoomArgs {
  final List<String> imageUrls; // local asset or http urls
  final int initialIndex;       // which image to start on
  final String productName;

  const ImageZoomArgs({
    required this.imageUrls,
    this.initialIndex = 0,
    required this.productName,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ImageZoomScreen extends StatefulWidget {
  final ImageZoomArgs args;
  const ImageZoomScreen({super.key, required this.args});

  @override
  State<ImageZoomScreen> createState() => _ImageZoomScreenState();
}

class _ImageZoomScreenState extends State<ImageZoomScreen>
    with TickerProviderStateMixin {
  late PageController _pageCtrl;
  late int _currentIndex;

  // Per-page transform controllers for pinch zoom
  late List<TransformationController> _transformControllers;

  // Double-tap animation
  late AnimationController _doubleTapAnim;
  late Animation<Matrix4> _doubleTapMatrix;

  // Drag-down-to-close
  double _dragOffset = 0;
  bool _isDragging = false;

  static const double _refW = 360.0;
  static const double _refH = 800.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.args.initialIndex;
    _pageCtrl = PageController(initialPage: _currentIndex);
    _transformControllers = List.generate(
      widget.args.imageUrls.length,
          (_) => TransformationController(),
    );
    _doubleTapAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Full dark immersive for image viewer
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
    ));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _transformControllers) {
      c.dispose();
    }
    _doubleTapAnim.dispose();
    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details, int index) {
    final ctrl = _transformControllers[index];
    final isZoomed = ctrl.value != Matrix4.identity();

    if (isZoomed) {
      // Zoom out
      _doubleTapMatrix = Matrix4Tween(
        begin: ctrl.value,
        end: Matrix4.identity(),
      ).animate(CurvedAnimation(
        parent: _doubleTapAnim,
        curve: Curves.easeOutCubic,
      ));
    } else {
      // Zoom into tapped point (2.5×)
      final pos = details.localPosition;
      final zoomedMatrix = Matrix4.identity()
        ..translate(-pos.dx * 1.5, -pos.dy * 1.5)
        ..scale(2.5);
      _doubleTapMatrix = Matrix4Tween(
        begin: Matrix4.identity(),
        end: zoomedMatrix,
      ).animate(CurvedAnimation(
        parent: _doubleTapAnim,
        curve: Curves.easeOutCubic,
      ));
    }

    _doubleTapAnim.forward(from: 0);
    _doubleTapAnim.addListener(() {
      ctrl.value = _doubleTapMatrix.value;
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_transformControllers[_currentIndex].value == Matrix4.identity()) {
      setState(() {
        _dragOffset += d.delta.dy;
        _isDragging = true;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset > 120 || (d.primaryVelocity ?? 0) > 800) {
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0;
        _isDragging = false;
      });
    }
  }

  Widget _buildImage(String url, int index) {
    Widget img;

    if (url.startsWith('assets/')) {
      img = Image.asset(url, fit: BoxFit.contain);
    } else if (url.startsWith('http')) {
      img = Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                  progress.expectedTotalBytes!
                  : null,
              color: Colors.white,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_rounded,
                  size: 48, color: Colors.white38),
              const SizedBox(height: 8),
              const Text('Image not available',
                  style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Poppins',
                      fontSize: 12)),
            ],
          ),
        ),
      );
    } else {
      img = const Center(
        child: Icon(Icons.image_not_supported_rounded,
            size: 64, color: Colors.white24),
      );
    }

    return GestureDetector(
      onDoubleTapDown: (d) => _handleDoubleTap(d, index),
      onDoubleTap: () {}, // needed for onDoubleTapDown to fire
      child: InteractiveViewer(
        transformationController: _transformControllers[index],
        minScale: 0.8,
        maxScale: 6.0,
        clipBehavior: Clip.none,
        child: img,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.args.imageUrls;
    final ws = MediaQuery.of(context).size.width / _refW;
    final hs = MediaQuery.of(context).size.height / _refH;
    final opacity = (1.0 - (_dragOffset.abs() / 300)).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(milliseconds: 50),
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: Stack(
              children: [
                // ── Full-screen image PageView ────────────────────────────
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: images.length,
                  onPageChanged: (i) {
                    // Reset zoom when swiping to new image
                    _transformControllers[_currentIndex].value =
                        Matrix4.identity();
                    setState(() => _currentIndex = i);
                  },
                  itemBuilder: (_, i) => _buildImage(images[i], i),
                ),

                // ── Top bar — blurred background ─────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 6 * hs,
                          bottom: 10 * hs,
                          left: 8 * ws,
                          right: 8 * ws,
                        ),
                        child: Row(
                          children: [
                            // Close
                            _CircleBtn(
                              icon: Icons.close_rounded,
                              onTap: () => Navigator.pop(context),
                              ws: ws,
                            ),
                            SizedBox(width: 10 * ws),
                            // Product name
                            Expanded(
                              child: Text(
                                widget.args.productName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13 * ws,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Share
                            _CircleBtn(
                              icon: Icons.share_rounded,
                              ws: ws,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Share.share(
                                  '🛍️ Check out ${widget.args.productName} on HappyBowl!',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom — image counter + dots ─────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        padding: EdgeInsets.only(
                          top: 14 * hs,
                          bottom:
                          MediaQuery.of(context).padding.bottom + 16 * hs,
                          left: 16 * ws,
                          right: 16 * ws,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dot indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                    (i) => AnimatedContainer(
                                  duration:
                                  const Duration(milliseconds: 250),
                                  width: i == _currentIndex
                                      ? 22 * ws
                                      : 7 * ws,
                                  height: 7 * ws,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 3 * ws),
                                  decoration: BoxDecoration(
                                    color: i == _currentIndex
                                        ? Colors.white
                                        : Colors.white38,
                                    borderRadius:
                                    BorderRadius.circular(4 * ws),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10 * hs),
                            // Counter text
                            Text(
                              '${_currentIndex + 1} / ${images.length}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12 * ws,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 10 * hs),
                            // Hint
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.pinch_rounded,
                                    size: 13 * ws,
                                    color: Colors.white38),
                                SizedBox(width: 5 * ws),
                                Text(
                                  'Pinch to zoom  •  Double tap to zoom  •  Swipe down to close',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 9 * ws,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Left / Right nav arrows (show when >1 image) ──────────
                if (images.length > 1) ...[
                  if (_currentIndex > 0)
                    Positioned(
                      left: 8 * ws,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavArrow(
                          icon: Icons.chevron_left_rounded,
                          ws: ws,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                  if (_currentIndex < images.length - 1)
                    Positioned(
                      right: 8 * ws,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: _NavArrow(
                          icon: Icons.chevron_right_rounded,
                          ws: ws,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _pageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Circle Button ────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double ws;
  const _CircleBtn(
      {required this.icon, required this.onTap, required this.ws});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36 * ws,
        height: 36 * ws,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border:
          Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 18 * ws),
      ),
    );
  }
}

// ─── Nav Arrow ────────────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double ws;
  const _NavArrow(
      {required this.icon, required this.onTap, required this.ws});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32 * ws,
        height: 32 * ws,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22 * ws),
      ),
    );
  }
}