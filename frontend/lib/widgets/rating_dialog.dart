// lib/widgets/rating_dialog.dart
// ══════════════════════════════════════════════════════════════════
//  HealthX — Professional Rating Dialog  (v2)
//  ✅ Fixed overflow — responsive star sizing
//  ✅ Big animated rating number + color-coded visual
//  ✅ Animated star fill with individual bounce per star
//  ✅ Dynamic emoji label per rating
//  ✅ Review text field (slides in after selection)
//  ✅ Animated thank-you confirmation state
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/theme.dart';

// ── Public API ────────────────────────────────────────────────────
Future<int?> showRatingDialog(BuildContext context) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Rating',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (_, anim, __, child) {
      final curved =
      CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(curved),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (_, __, ___) => const _RatingDialog(),
  );
}

// ─────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────
const _kLabels = [
  '',
  'Terrible',
  'Bad',
  'Okay',
  'Good',
  'Excellent!',
];

const _kEmojis = ['', '😢', '😕', '😐', '😊', '🤩'];

const _kColors = [
  Color(0xFFCCCCCC), // 0 – unset
  Color(0xFFE53935), // 1 – red
  Color(0xFFFF7043), // 2 – deep orange
  Color(0xFFFFB300), // 3 – amber
  Color(0xFF43A047), // 4 – green
  Color(0xFF00897B), // 5 – teal
];

// ─────────────────────────────────────────────────────────────────
// WIDGET
// ─────────────────────────────────────────────────────────────────
class _RatingDialog extends StatefulWidget {
  const _RatingDialog();
  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog>
    with TickerProviderStateMixin {
  int  _selected  = 0;
  bool _submitted = false;
  bool _loading   = false;

  final _reviewCtrl = TextEditingController();

  // One AnimationController per star for the individual bounce
  late final List<AnimationController> _starCtrl;
  late final List<Animation<double>>   _starScale;

  @override
  void initState() {
    super.initState();
    _starCtrl = List.generate(
      5,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      ),
    );
    _starScale = _starCtrl.map((c) {
      return TweenSequence([
        TweenSequenceItem(
            tween: Tween(begin: 1.0, end: 1.4)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 40),
        TweenSequenceItem(
            tween: Tween(begin: 1.4, end: 0.9)
                .chain(CurveTween(curve: Curves.easeIn)),
            weight: 30),
        TweenSequenceItem(
            tween: Tween(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: Curves.elasticOut)),
            weight: 30),
      ]).animate(c);
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _starCtrl) c.dispose();
    _reviewCtrl.dispose();
    super.dispose();
  }

  void _onStarTap(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
    // Bounce all stars up to selected
    for (int i = 0; i < index; i++) {
      Future.delayed(Duration(milliseconds: i * 40), () {
        if (mounted) {
          _starCtrl[i].forward(from: 0);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_selected == 0) {
      HapticFeedback.heavyImpact();
      _showSnack('Please pick a star rating first ⭐');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() { _loading = false; _submitted = true; });
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) Navigator.of(context).pop(_selected);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Responsive dialog width — max 320, min leaves 32px each side
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = (screenW - 48).clamp(0.0, 320.0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogW,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.93, end: 1.0).animate(
                      CurvedAnimation(
                          parent: anim, curve: Curves.easeOutBack)),
                  child: child,
                ),
              ),
              child: _submitted ? _buildThankYou() : _buildForm(dialogW),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // FORM
  // ─────────────────────────────────────────────────────────────────
  Widget _buildForm(double dialogW) {
    final color = _selected > 0 ? _kColors[_selected] : AppTheme.primaryGreen;

    // Star size = fit 5 stars + spacing inside content width
    final contentW = dialogW - 40; // 20px pad each side
    final starSize  = ((contentW - 32) / 5).clamp(28.0, 42.0);
    final starGap   = ((contentW - starSize * 5) / 6).clamp(2.0, 10.0);

    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── App icon ─────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(Icons.local_dining_rounded,
                color: Colors.white, size: 30),
          )
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 14),

          Text(
            'Rate Your Experience',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 4),

          Text(
            'How would you rate HealthX?',
            style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
          ).animate().fadeIn(delay: 120.ms),

          const SizedBox(height: 20),

          // ── BIG VISUAL RATING DISPLAY ─────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(
                  alpha: _selected > 0 ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(
                    alpha: _selected > 0 ? 0.25 : 0.1),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Big animated number
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Text(
                    _selected > 0 ? '$_selected.0' : '—',
                    key: ValueKey(_selected),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 38,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mini star row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        final filled = _selected > i;
                        return Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: filled
                              ? color
                              : color.withValues(alpha: 0.3),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _selected > 0
                            ? '${_kEmojis[_selected]}  ${_kLabels[_selected]}'
                            : 'Tap a star below',
                        key: ValueKey(_selected),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.06, end: 0),

          const SizedBox(height: 20),

          // ── INTERACTIVE STARS ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final filled = _selected >= starIndex;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onStarTap(starIndex),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: starGap / 2),
                  child: AnimatedBuilder(
                    animation: _starCtrl[i],
                    builder: (_, child) => Transform.scale(
                      scale: _starScale[i].value,
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: starSize,
                        color: filled
                            ? (_selected > 0
                            ? _kColors[_selected]
                            : AppTheme.yellow)
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 6),

          // Tap hint below stars
          Text(
            _selected > 0
                ? 'You rated $_selected out of 5'
                : 'Tap a star to rate',
            style: TextStyle(
              color: _selected > 0
                  ? _kColors[_selected]
                  : AppTheme.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // ── REVIEW TEXT FIELD ────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _selected > 0
                ? Column(
              children: [
                TextField(
                  controller: _reviewCtrl,
                  maxLines: 3,
                  maxLength: 200,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: _selected >= 4
                        ? 'What did you love most? (optional)'
                        : 'How can we improve? (optional)',
                    hintStyle: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: _kColors[_selected],
                          width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(13),
                    counterStyle: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 10),
                  ),
                  style: TextStyle(
                      color: AppTheme.textDark, fontSize: 13),
                  cursorColor: _kColors[_selected],
                )
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: 14),
              ],
            )
                : const SizedBox.shrink(),
          ),

          // ── SUBMIT BUTTON ────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: _selected > 0
                  ? _kColors[_selected]
                  : AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_selected > 0
                      ? _kColors[_selected]
                      : AppTheme.primaryGreen)
                      .withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _loading ? null : _submit,
                child: Center(
                  child: _loading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selected > 0
                            ? Icons.check_circle_outline
                            : Icons.star_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selected > 0
                            ? 'Submit $_selected★ Rating'
                            : 'Select a Star to Rate',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 260.ms),

          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                  color: AppTheme.textMedium,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // THANK YOU
  // ─────────────────────────────────────────────────────────────────
  Widget _buildThankYou() {
    final color = _kColors[_selected];
    final isPositive = _selected >= 4;

    return Padding(
      key: const ValueKey('ty'),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.favorite_rounded : Icons.thumb_up_rounded,
              color: color,
              size: 38,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 800.ms,
            curve: Curves.easeInOut,
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(),

          const SizedBox(height: 16),

          Text(
            isPositive ? 'Thank You! 🎉' : 'Thanks for the feedback!',
            style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 8),

          // Big rating recap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_selected.0',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                          (i) => Icon(
                        i < _selected
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: i < _selected
                            ? color
                            : color.withValues(alpha: 0.3),
                        size: 18,
                      ),
                    ),
                  ),
                  Text(
                    '${_kEmojis[_selected]} ${_kLabels[_selected]}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 12),

          Text(
            isPositive
                ? 'We\'re thrilled you love HealthX!\nYour support means the world to us.'
                : 'We appreciate your honesty.\nWe\'ll work hard to improve!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMedium,
              fontSize: 13,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}