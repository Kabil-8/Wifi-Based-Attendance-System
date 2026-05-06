import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/routes.dart';

// ── Bubble data ──────────────────────────────────────────────────────────────
class _Bubble {
  double x, y, r, dx, dy, opacity;
  _Bubble(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        r = 30 + rng.nextDouble() * 80,
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
    Color(0xFF7C4DFF), Color(0xFF448AFF),
    Color(0xFF00BFA5), Color(0xFFAB47BC),
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < bubbles.length; i++) {
      final b = bubbles[i];
      final c = Offset(b.x * size.width, b.y * size.height);
      canvas.drawCircle(
        c, b.r,
        Paint()
          ..shader = RadialGradient(colors: [
            palette[i % palette.length].withOpacity(b.opacity),
            palette[i % palette.length].withOpacity(0),
          ]).createShader(Rect.fromCircle(center: c, radius: b.r)),
      );
    }
  }
  @override
  bool shouldRepaint(_BubblePainter _) => true;
}

// ── SelectRoleScreen ─────────────────────────────────────────────────────────
class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});
  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen>
    with TickerProviderStateMixin {
  final List<_Bubble> _bubbles = List.generate(8, (_) => _Bubble(Random()));
  late final AnimationController _bubbleCtrl;
  late final AnimationController _bgCtrl;
  late final AnimationController _enterCtrl;

  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _card1Fade;
  late Animation<Offset> _card1Slide;
  late Animation<double> _card2Fade;
  late Animation<Offset> _card2Slide;

  // Which card is being pressed
  int? _pressed;

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
        vsync: this, duration: const Duration(milliseconds: 1200));

    _logoFade = _fade(0.0, 0.4);
    _logoSlide = _slide(0.0, 0.45, dy: -0.35);
    _subtitleFade = _fade(0.25, 0.55);
    _card1Fade = _fade(0.40, 0.72);
    _card1Slide = _slide(0.40, 0.72, dx: -0.25);
    _card2Fade = _fade(0.52, 0.82);
    _card2Slide = _slide(0.52, 0.82, dx: 0.25);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _enterCtrl.forward());
  }

  Animation<double> _fade(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _enterCtrl, curve: Interval(s, e, curve: Curves.easeOut)));

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
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, child) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(const Color(0xFFF3E8FF),
                    const Color(0xFFE8F0FE), _bgCtrl.value)!,
                Color.lerp(const Color(0xFFEDE7F6),
                    const Color(0xFFE3F2FD), _bgCtrl.value)!,
                Color.lerp(const Color(0xFFE8F0FE),
                    const Color(0xFFF3E8FF), _bgCtrl.value)!,
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: child,
        ),
        child: Stack(children: [
          CustomPaint(
              painter: _BubblePainter(_bubbles),
              child: const SizedBox.expand()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 40),
                child: Column(children: [
                  // Logo section
                  FadeTransition(
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
                                color: const Color(0xFF7C4DFF)
                                    .withOpacity(0.35),
                                blurRadius: 22,
                                spreadRadius: 4,
                              )
                            ],
                          ),
                          child: const Icon(Icons.wifi_rounded,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 18),
                        const Text('WiFi Attendance',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1035),
                              letterSpacing: 0.3,
                            )),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text("Who are you?",
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.black.withOpacity(0.45),
                            fontWeight: FontWeight.w500)),
                  ),

                  const SizedBox(height: 42),

                  // Role cards
                  Row(
                    children: [
                      Expanded(
                        child: FadeTransition(
                          opacity: _card1Fade,
                          child: SlideTransition(
                            position: _card1Slide,
                            child: _buildRoleCard(
                              role: 'Student',
                              icon: Icons.school_rounded,
                              description: 'Track your attendance & schedule',
                              color: const Color(0xFF7C4DFF),
                              index: 0,
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, Routes.studentDashboard),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FadeTransition(
                          opacity: _card2Fade,
                          child: SlideTransition(
                            position: _card2Slide,
                            child: _buildRoleCard(
                              role: 'Staff',
                              icon: Icons.badge_rounded,
                              description: 'Manage classes & attendance',
                              color: const Color(0xFF448AFF),
                              index: 1,
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, Routes.staffDashboard),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String description,
    required Color color,
    required int index,
    required VoidCallback onTap,
  }) {
    final pressed = _pressed == index;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = index),
      onTapUp: (_) {
        setState(() => _pressed = null);
        onTap();
      },
      onTapCancel: () => setState(() => _pressed = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(pressed ? 0.95 : 1.0, pressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: pressed ? color : Colors.white.withOpacity(0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(pressed ? 0.20 : 0.10),
              blurRadius: pressed ? 28 : 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 16),
            Text(role,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.2,
                )),
            const SizedBox(height: 6),
            Text(description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.45),
                  height: 1.4,
                )),
            const SizedBox(height: 18),
            // "Go" button
            Row(children: [
              Text('Continue',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color)),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 15, color: color),
            ]),
          ],
        ),
      ),
    );
  }
}
