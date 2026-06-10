import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../theme/theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final WebViewController _webViewController;
  bool _webViewReady = false;
  bool _webViewError = false;
  int _loadingProgress = 0;

  static const String _tawkSrc =
      'https://embed.tawk.to/69821ac95a86941c39bba56c/default';

  /// Minimal HTML shell that loads Tawk.to inside a WebView.
  /// Using meta viewport + overflow hidden prevents the annoying bounce
  /// / double-scroll that a plain widget URL sometimes causes.
  static const String _chatHtml = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no"/>
  <style>
    *{margin:0;padding:0;box-sizing:border-box;}
    html,body{width:100%;height:100%;overflow:hidden;background:#f8faf8;}
    #chat-container{
      position:fixed;inset:0;
      display:flex;flex-direction:column;align-items:center;justify-content:center;
    }
    .loader{
      width:40px;height:40px;
      border:3px solid #e0e0e0;
      border-top-color:#2e7d32;
      border-radius:50%;
      animation:spin 0.8s linear infinite;
    }
    @keyframes spin{to{transform:rotate(360deg);}}
    .loader-text{margin-top:14px;font-family:sans-serif;font-size:13px;color:#666;}
  </style>
</head>
<body>
<div id="chat-container">
  <div class="loader"></div>
  <div class="loader-text">Connecting to support…</div>
</div>
<script>
var Tawk_API=Tawk_API||{};
var Tawk_LoadStart=new Date();
Tawk_API.onLoad=function(){
  document.getElementById('chat-container').style.display='none';
  Tawk_API.maximize();
};
(function(){
  var s1=document.createElement("script"),s0=document.getElementsByTagName("script")[0];
  s1.async=true;
  s1.src='$_tawkSrc';
  s1.charset='UTF-8';
  s1.setAttribute('crossorigin','*');
  s0.parentNode.insertBefore(s1,s0);
})();
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAF8))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loadingProgress = 0;
            _webViewError = false;
          }),
          onProgress: (p) => setState(() => _loadingProgress = p),
          onPageFinished: (_) => setState(() {
            _loadingProgress = 100;
            _webViewReady = true;
          }),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? false) {
              setState(() => _webViewError = true);
            }
          },
          onNavigationRequest: (req) {
            // Allow Tawk CDN and the shell itself; block anything else
            final url = req.url;
            if (url.contains('tawk.to') || url == 'about:blank' || url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }
            // Open external links in system browser
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(_chatHtml, baseUrl: 'https://www.healthx.world');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          _buildHeader(context, top),

          // ── Tab Bar ─────────────────────────────────────────────────
          _buildTabBar(),

          // ── Tab Views ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildContactTab(),
                _buildChatTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, double top) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: top + 10, bottom: 20, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'We\'re here to help you',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Online indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF76FF03),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryGreen,
        indicatorWeight: 3,
        labelColor: AppTheme.primaryGreen,
        unselectedLabelColor: AppTheme.textMedium,
        labelStyle:
        const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
        const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Contact Us'),
          Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'Live Chat'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CONTACT US TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          _HeroCard().animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

          const SizedBox(height: 20),

          // Contact info cards
          _ContactCard(
            icon: Icons.email_outlined,
            iconColor: AppTheme.primaryGreen,
            label: 'Email Us',
            value: 'support@healthx.world',
            subtitle: 'We reply within 24 hours',
            onTap: () => _launch('mailto:support@healthx.world'),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: 0.05, end: 0),

          const SizedBox(height: 12),

          _ContactCard(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF1565C0),
            label: 'Call Us',
            value: '+91 888-632-7755',
            subtitle: 'Mon – Sat, 9 AM – 6 PM',
            onTap: () => _launch('tel:+918886327755'),
          ).animate().fadeIn(duration: 400.ms, delay: 180.ms).slideX(begin: 0.05, end: 0),

          const SizedBox(height: 12),

          _ContactCard(
            icon: Icons.location_on_outlined,
            iconColor: AppTheme.red,
            label: 'Our Office',
            value: 'Buddica Global Solutions Pvt Ltd',
            subtitle:
            '49-58/2, beside Port Stadium, Green Park Colony,\nBalayya Sastri Layout, Seethammadara,\nVisakhapatnam, Andhra Pradesh 530013',
            onTap: () => _launch(
                'https://maps.google.com/?q=Buddica+Global+Solutions+Pvt+Ltd+Visakhapatnam'),
          ).animate().fadeIn(duration: 400.ms, delay: 260.ms).slideX(begin: 0.05, end: 0),

          const SizedBox(height: 24),

          // FAQ quick links
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Quick Help',
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 320.ms),

          ..._faqItems.asMap().entries.map((e) {
            return _FaqTile(item: e.value)
                .animate()
                .fadeIn(
              duration: 300.ms,
              delay: Duration(milliseconds: 360 + e.key * 50),
            )
                .slideX(begin: 0.04, end: 0);
          }),
        ],
      ),
    );
  }

  static final List<_FaqItem> _faqItems = [
    _FaqItem(
      q: 'How do I track my order?',
      a: 'Go to Profile → My Orders to see real-time updates on all your deliveries.',
    ),
    _FaqItem(
      q: 'Can I change my delivery address?',
      a: 'Yes! Tap Profile → Addresses before your order is dispatched to update your location.',
    ),
    _FaqItem(
      q: 'How do I cancel a subscription?',
      a: 'Contact our support team via Live Chat or email us at support@healthx.world.',
    ),
    _FaqItem(
      q: 'Is my payment information secure?',
      a: 'Absolutely. We use industry-standard encryption. We never store your card details.',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // LIVE CHAT TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChatTab() {
    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _webViewController),

        // Loading progress bar
        if (_loadingProgress < 100 && !_webViewError)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _loadingProgress / 100,
              backgroundColor: Colors.transparent,
              color: AppTheme.primaryGreen,
              minHeight: 3,
            ),
          ),

        // Error state
        if (_webViewError)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    size: 56, color: AppTheme.textLight),
                const SizedBox(height: 14),
                Text(
                  'Unable to load chat',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please check your internet connection',
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _webViewError = false;
                      _webViewReady = false;
                    });
                    _webViewController.reload();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.12),
            AppTheme.primaryGreen.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.headset_mic, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our team is ready to assist you with\nany questions or concerns.',
                  style: TextStyle(
                    color: AppTheme.textMedium,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textMedium,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppTheme.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem {
  final String q;
  final String a;
  const _FaqItem({required this.q, required this.a});
}

class _FaqTile extends StatefulWidget {
  final _FaqItem item;
  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _expanded = !_expanded);
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item.q,
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: AppTheme.primaryGreen, size: 20),
                    ),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.a,
                    style: TextStyle(
                      color: AppTheme.textMedium,
                      fontSize: 12,
                      height: 1.5,
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