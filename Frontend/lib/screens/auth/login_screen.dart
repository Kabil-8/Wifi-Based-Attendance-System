import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// ── Bubble data ──────────────────────────────────────────────────────────────
class _Bubble {
  double x, y, r, dx, dy, opacity;
  _Bubble(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        r = 30 + rng.nextDouble() * 70,
        dx = (rng.nextDouble() - 0.5) * 0.003,
        dy = (rng.nextDouble() - 0.5) * 0.003,
        opacity = 0.06 + rng.nextDouble() * 0.10;

  void tick() {
    x += dx; y += dy;
    if (x < 0 || x > 1) dx = -dx;
    if (y < 0 || y > 1) dy = -dy;
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  _BubblePainter(this.bubbles);

  static const List<Color> palette = [
    Color(0xFF7C4DFF),
    Color(0xFF448AFF),
    Color(0xFF00BFA5),
    Color(0xFFAB47BC),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final c = Offset(b.x * size.width, b.y * size.height);
      final p = Paint()
        ..shader = RadialGradient(colors: [
          palette[i % palette.length].withOpacity(b.opacity),
          palette[i % palette.length].withOpacity(0),
        ]).createShader(Rect.fromCircle(center: c, radius: b.r));
      canvas.drawCircle(c, b.r, p);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter _) => true;
}

// ── LoginScreen ──────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = 'STUDENT';
  bool _obscure = true;
  bool _emailFocused = false;
  bool _passFocused = false;

  final List<_Bubble> _bubbles = List.generate(9, (_) => _Bubble(Random()));
  late final AnimationController _bubbleCtrl;

  // Gradient shift
  late final AnimationController _bgCtrl;

  // Entrance stagger
  late final AnimationController _enterCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _f1Fade, _f2Fade, _roleFade, _btnFade;
  late Animation<Offset> _f1Slide, _f2Slide;
  late Animation<double> _btnScale;

  // Button press
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();

    _bubbleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();
    _bubbleCtrl.addListener(() {
      for (final b in _bubbles) b.tick();
      setState(() {});
    });

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 7))
      ..repeat(reverse: true);

    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));

    _logoFade = _fade(0.0, 0.35);
    _logoSlide = _slide(0.0, 0.4, dy: -0.4);
    _cardFade = _fade(0.20, 0.55);
    _cardSlide = _slide(0.20, 0.60, dy: 0.15);
    _f1Fade = _fade(0.35, 0.65);
    _f1Slide = _slide(0.35, 0.65, dx: -0.3);
    _f2Fade = _fade(0.45, 0.72);
    _f2Slide = _slide(0.45, 0.72, dx: 0.3);
    _roleFade = _fade(0.55, 0.82);
    _btnFade = _fade(0.70, 1.0);
    _btnScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
        parent: _enterCtrl,
        curve: const Interval(0.70, 1.0, curve: Curves.elasticOut)));

    _pressCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 200));
    _pressScale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) => _enterCtrl.forward());
  }

  Animation<double> _fade(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _enterCtrl,
          curve: Interval(s, e, curve: Curves.easeOut)));

  Animation<Offset> _slide(double s, double e,
      {double dx = 0, double dy = 0}) =>
      Tween<Offset>(begin: Offset(dx, dy), end: Offset.zero).animate(
          CurvedAnimation(
              parent: _enterCtrl,
              curve: Interval(s, e, curve: Curves.easeOut)));

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    _bgCtrl.dispose();
    _enterCtrl.dispose();
    _pressCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                    const Color(0xFFF3E8FF), const Color(0xFFE8F0FE), _bgCtrl.value)!,
                Color.lerp(
                    const Color(0xFFEDE7F6), const Color(0xFFE3F2FD), _bgCtrl.value)!,
                Color.lerp(
                    const Color(0xFFE8F0FE), const Color(0xFFF3E8FF), _bgCtrl.value)!,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: child,
        ),
        child: Stack(children: [
          // Bubbles
          CustomPaint(
            painter: _BubblePainter(_bubbles),
            child: const SizedBox.expand(),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                child: Column(children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildCard(auth),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() => FadeTransition(
        opacity: _logoFade,
        child: SlideTransition(
          position: _logoSlide,
          child: Column(children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.35),
                    blurRadius: 22,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.wifi_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('WiFi Attendance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1035),
                  letterSpacing: 0.3,
                )),
            const SizedBox(height: 4),
            Text('Sign in to continue',
                style: TextStyle(
                    fontSize: 14, color: Colors.black.withOpacity(0.45))),
          ]),
        ),
      );

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(AuthProvider auth) => FadeTransition(
        opacity: _cardFade,
        child: SlideTransition(
          position: _cardSlide,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withOpacity(0.9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.10),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeTransition(opacity: _roleFade, child: _buildRoleTabs()),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _f1Fade,
                  child: SlideTransition(
                    position: _f1Slide,
                    child: _buildField(
                      ctrl: emailCtrl,
                      label: 'Email address',
                      icon: Icons.alternate_email_rounded,
                      focused: _emailFocused,
                      onFocus: (v) => setState(() => _emailFocused = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeTransition(
                  opacity: _f2Fade,
                  child: SlideTransition(
                    position: _f2Slide,
                    child: _buildField(
                      ctrl: passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      focused: _passFocused,
                      onFocus: (v) => setState(() => _passFocused = v),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF7C4DFF).withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _btnFade,
                  child: ScaleTransition(
                      scale: _btnScale, child: _buildButton(auth)),
                ),
              ],
            ),
          ),
        ),
      );

  // ── Role tabs ─────────────────────────────────────────────────────────────
  Widget _buildRoleTabs() => Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFF0ECFF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: ['STUDENT', 'STAFF'].map((r) {
            final sel = role == r;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => role = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: sel
                        ? const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)])
                        : null,
                    boxShadow: sel
                        ? [
                            BoxShadow(
                                color:
                                    const Color(0xFF7C4DFF).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel
                            ? Colors.white
                            : const Color(0xFF7C4DFF).withOpacity(0.6),
                        letterSpacing: 0.6,
                      ),
                      child: Text(r),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  // ── Field ─────────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    bool obscure = false,
    bool focused = false,
    required void Function(bool) onFocus,
    Widget? suffix,
  }) =>
      Focus(
        onFocusChange: onFocus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: focused
                ? const Color(0xFFF3EEFF)
                : const Color(0xFFF8F7FF),
            border: Border.all(
              color: focused
                  ? const Color(0xFF7C4DFF)
                  : const Color(0xFFDDD8F5),
              width: focused ? 1.8 : 1.2,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withOpacity(0.15),
                      blurRadius: 14,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: const TextStyle(
                color: Color(0xFF1A1035), fontSize: 15),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              labelText: label,
              labelStyle: TextStyle(
                color: focused
                    ? const Color(0xFF7C4DFF)
                    : const Color(0xFF9E9BB8),
                fontSize: 14,
              ),
              prefixIcon: Padding(
                padding:
                    const EdgeInsets.only(left: 14, right: 8),
                child: Icon(icon,
                    color: focused
                        ? const Color(0xFF7C4DFF)
                        : const Color(0xFFB0ABCF),
                    size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: suffix,
              border: InputBorder.none,
            ),
          ),
        ),
      );

  // ── Login Button ──────────────────────────────────────────────────────────
  Widget _buildButton(AuthProvider auth) => GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) => _pressCtrl.reverse(),
        onTapCancel: () => _pressCtrl.reverse(),
        onTap: auth.isLoading ? null : () => _handleLogin(auth),
        child: ScaleTransition(
          scale: _pressScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: auth.isLoading
                  ? LinearGradient(colors: [
                      const Color(0xFF7C4DFF).withOpacity(0.45),
                      const Color(0xFF448AFF).withOpacity(0.45),
                    ])
                  : const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: auth.isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(0.40),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (c, a) =>
                    ScaleTransition(scale: a, child: c),
                child: auth.isLoading
                    ? const SizedBox(
                        key: ValueKey('spin'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Row(
                        key: ValueKey('txt'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Sign In',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ),
      );

  // ── Logic ─────────────────────────────────────────────────────────────────
  Future<void> _handleLogin(AuthProvider auth) async {
    // Unfocus all text fields before navigating — prevents Flutter Web
    // "domElement != null" assertion error when the widget tree changes.
    FocusScope.of(context).unfocus();
    final ok = await auth.login(
        emailCtrl.text.trim(), passCtrl.text.trim(), role);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(
          context, role == 'STUDENT' ? '/student-dashboard' : '/staff-dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.errorMessage ?? 'Login failed'),
        backgroundColor: const Color(0xFF7C4DFF),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}