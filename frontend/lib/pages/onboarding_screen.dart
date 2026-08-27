// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});


  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'lib/assets/images/onboarding_background.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.42),
                    Colors.black.withOpacity(0.16),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    Colors.black.withOpacity(0.16),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          const Positioned(
            top: -70,
            left: -70,
            child: SizedBox(
              width: 360,
              height: 360,
              child: CustomPaint(
                painter: _SunRaysPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 28.0, left: 15.0, right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.08),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'lib/assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Discover the world of sea shells',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 74, 156, 239),
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      height: 0.9,
                      letterSpacing: 0.3,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 320,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF3E2B18),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Identify seashells instantly with AI, explore detailed species information, and discover the beauty of marine life.',
                            style: const TextStyle(
                              backgroundColor: Color.fromARGB(255, 191, 233, 255),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _GlowingButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Center(
                              child: Text(
                                'Get Started',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 18,
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Text(
                        'Start exploring seashells offline.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 2, 56, 91),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  const _SunRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.22, size.height * 0.24);
    final rayPaint = Paint()..color = const Color.fromARGB(255, 122, 217, 255).withOpacity(0.11);
    final rayAngles = [-0.55, -0.2, 0.15, 0.5, 0.85, 1.2];

    for (var index = 0; index < rayAngles.length; index++) {
      final angle = rayAngles[index];
      final rayWidth = index.isEven ? 0.07 : 0.045;
      final start = center + Offset.fromDirection(angle, 18);
      final end = center + Offset.fromDirection(angle, size.width * 1.15);
      final side = Offset.fromDirection(angle + 1.5708, size.width * rayWidth);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx + side.dx, end.dy + side.dy)
        ..lineTo(end.dx - side.dx, end.dy - side.dy)
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    canvas.drawCircle(
      center,
      45,
      Paint()..color = const Color.fromARGB(255, 18, 61, 142).withOpacity(0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowingButton extends StatefulWidget {
  const _GlowingButton({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<_GlowingButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  AnimationController? _shimmerController;

  AnimationController _ensureShimmerController() {
    return _shimmerController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void initState() {
    super.initState();
    _ensureShimmerController();
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _pressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 10),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 191, 233, 255),
              Color.fromARGB(255, 39, 90, 141),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 133, 193, 238).withOpacity(_pressed ? 0.55 : 0.35),
              blurRadius: _pressed ? 30 : 20,
              spreadRadius: _pressed ? 2 : 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color.fromARGB(255, 141, 230, 248).withOpacity(_pressed ? 0.28 : 0.18),
              blurRadius: _pressed ? 32 : 28,
              spreadRadius: _pressed ? 2 : 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const shimmerWidth = 52.0;
              final shimmerController = _ensureShimmerController();
              return AnimatedBuilder(
                animation: shimmerController,
                builder: (context, child) {
                  final left = -shimmerWidth +
                      (constraints.maxWidth + shimmerWidth * 2) *
                          shimmerController.value;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      child!,
                      Positioned(
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: shimmerWidth,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.28),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
}
