// ignore_for_file: sort_child_properties_last

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav.dart';
import 'explore_screen.dart';
import 'quiz_screen.dart';
import 'scan_screen.dart';
import 'shell_detail_screen.dart';
import 'advisory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedExploreFilter = 'All';

  void _openExploreWithCategory(String category) {
    final normalized = category.trim();
    final mapped =
        {
          'Gastropods': 'Gastropod',
          'Bivalves': 'Bivalve',
          'Cephalopods': 'Cephalopod',
          'Scaphopods': 'Scaphopod',
          'Polyplacophora': 'Polyplacophora',
        }[normalized] ??
        normalized;

    setState(() {
      _selectedExploreFilter = mapped;
      _currentIndex = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Light blue theme colors for this page.
    final Color pageBg = Colors.white;

    final pages = [
      HomeContent(
        onCategoryTap: _openExploreWithCategory,
        onSeeAll: () => setState(() => _currentIndex = 3),
        onScanTap: () => setState(() => _currentIndex = 2),
        onQuizTap: () => setState(() => _currentIndex = 1),
      ),
      QuizScreen(
        onBackPressed: () {
          setState(() => _currentIndex = 0);
        },
      ),
      ScanScreen(
        onBackPressed: () {
          setState(() => _currentIndex = 0);
        },
      ),
      ExploreScreen(initialFilter: _selectedExploreFilter),
      AdvisoryScreen(
        onBackPressed: () {
          setState(() => _currentIndex = 0);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      body: pages[_currentIndex],
      bottomNavigationBar:
          _currentIndex != 2
              ? BottomNav(
                currentIndex: _currentIndex,
                onTap: (i) {
                  setState(() => _currentIndex = i);
                },
              )
              : null,
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.onCategoryTap,
    required this.onSeeAll,
    required this.onScanTap,
    required this.onQuizTap,
  });

  final void Function(String category) onCategoryTap;
  final VoidCallback onSeeAll;
  final VoidCallback onScanTap;
  final VoidCallback onQuizTap;

  @override
  Widget build(BuildContext context) {
    // Light blue theme colors for this page.
    final Color primaryText = const Color(0xFF123B5D);
    final Color secondaryText = const Color(0xFF35627F);
    final Color accent = const Color(0xFF176B87);

    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                // Just a visual indicator, no functionality
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi, Explorer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'What seashell will you discover today?',
                      style: TextStyle(fontSize: 14, color: secondaryText),
                    ),
                    const SizedBox(height: 18),

                    // Banner carousel
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 160,
                      child: _BannerCarousel(
                        images: const [
                          'lib/assets/images/banner/banner1.jpg',
                          'lib/assets/images/banner/banner2.jpg',
                          'lib/assets/images/banner/banner3.jpg',
                        ],
                        viewportFraction: 0.90,
                        autoPlayInterval: Duration(seconds: 5),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Categories row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: onSeeAll,
                          child: const Text(
                            'See All',
                            style: TextStyle(color: Color(0xFF2D7896)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: _AutoScrollCategories(
                        items: const [
                          {
                            'label': 'Gastropods',
                            'url':
                                'lib/assets/images/categories/gastropods.png',
                          },
                          {
                            'label': 'Bivalves',
                            'url': 'lib/assets/images/categories/Bivalves.png',
                          },
                          {
                            'label': 'Cephalopods',
                            'url':
                                'lib/assets/images/categories/Cephalopods.png',
                          },
                          {
                            'label': 'Scaphopods',
                            'url':
                                'lib/assets/images/categories/Scaphopods.png',
                          },
                          {
                            'label': 'Polyplacophora',
                            'url':
                                'lib/assets/images/categories/Polyplacophora.png',
                          },
                        ],
                        onCategoryTap: onCategoryTap,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: onScanTap,
                            child: Container(
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5F2F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Scan Shell',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: primaryText,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Tap to scan and identify seashells',
                                          style: TextStyle(
                                            color: secondaryText,
                                            fontSize: 9,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: onQuizTap,
                            child: Container(
                              height: 96,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCECF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2F86A5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.quiz,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Quiz Time',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: primaryText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Test your knowledge',
                                          style: TextStyle(
                                            color: secondaryText,
                                            fontSize: 9,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Explore shells header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore shells',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                        ),
                        GestureDetector(
                          onTap: onSeeAll,
                          child: const Text(
                            'See All',
                            style: TextStyle(color: Color(0xFF2D7896)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Explore grid (limited to a few items)
                    RandomShellsGrid(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(child: _DriftingSandParticles()),
      ],
    );
  }
}

class _DriftingSandParticles extends StatefulWidget {
  const _DriftingSandParticles();

  @override
  State<_DriftingSandParticles> createState() => _DriftingSandParticlesState();
}

class _DriftingSandParticlesState extends State<_DriftingSandParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_SandParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _createParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  List<_SandParticle> _createParticles() {
    final random = Random(7);
    return List.generate(84, (index) {
      final positionGroup = index % 3;
      return _SandParticle(
        x:
            positionGroup == 0
                ? 0.04 + random.nextDouble() * 0.22
                : positionGroup == 1
                ? 0.74 + random.nextDouble() * 0.22
                : 0.25 + random.nextDouble() * 0.50,
        y: random.nextDouble(),
        size: 1.1 + random.nextDouble() * 1.2,
        speed: 0.18 + random.nextDouble() * 0.32,
        sway: 2.0 + random.nextDouble() * 5.0,
        phase: random.nextDouble() * pi * 2,
        opacity: 0.12 + random.nextDouble() * 0.16,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _SandParticlePainter(
                particles: _particles,
                progress: _controller.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SandParticle {
  const _SandParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.opacity,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double sway;
  final double phase;
  final double opacity;
}

class _SandParticlePainter extends CustomPainter {
  const _SandParticlePainter({required this.particles, required this.progress});

  final List<_SandParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final verticalProgress =
          (particle.y + progress * particle.speed) % 1.15 - 0.075;
      final x =
          size.width * particle.x +
          sin(progress * pi * 2 + particle.phase) * particle.sway;
      final fade = 0.55 + 0.45 * sin(progress * pi * 2 + particle.phase * 1.7);
      final paint =
          Paint()
            ..color = const Color(
              0xFF7EAFC0,
            ).withValues(alpha: (particle.opacity * fade).clamp(0.0, 1.0));

      canvas.drawCircle(
        Offset(x, size.height * verticalProgress),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SandParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel({
    required this.images,
    this.viewportFraction = 0.75,
    this.autoPlayInterval = const Duration(seconds: 3),
  });

  final List<String> images;
  final double viewportFraction;
  final Duration autoPlayInterval;

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;
  final int _loopMultiplier = 1000;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _controller = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: 0,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.images.length;
      _currentPage = nextPage;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.images;

    return PageView.builder(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      padEnds: false,
      pageSnapping: true,
      onPageChanged: (index) => _currentPage = index,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final imagePath = items[index % items.length];
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image:
                  imagePath.startsWith('http')
                      ? NetworkImage(imagePath)
                      : AssetImage(imagePath) as ImageProvider,
              fit: BoxFit.cover,
              width:
                  MediaQuery.of(context).size.width * widget.viewportFraction,
            ),
          ),
        );
      },
    );
  }
}

class _AutoScrollCategories extends StatefulWidget {
  const _AutoScrollCategories({required this.items, this.onCategoryTap});

  final List<Map<String, String>> items;
  final void Function(String category)? onCategoryTap;

  @override
  State<_AutoScrollCategories> createState() => _AutoScrollCategoriesState();
}

class _AutoScrollCategoriesState extends State<_AutoScrollCategories> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  double? _loopStart;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    _timer?.cancel();
    // Wait for layout, then initialize at the middle and scroll left->right (decrement offset)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 200), _startAutoScroll);
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        Future.delayed(const Duration(milliseconds: 300), _startAutoScroll);
        return;
      }

      if (!_initialized) {
        // Start in the middle so the duplicated list can loop smoothly.
        final half = maxScroll / 2;
        _loopStart = half;
        _scrollController.jumpTo(half.clamp(0.0, maxScroll));
        _initialized = true;
      }

      final loopStart = _loopStart ?? maxScroll / 2;

      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (!mounted || !_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        if (max <= 0) return;

        final next = _scrollController.offset - 0.6;
        if (next <= 0) {
          // wrap: move forward by half to continue seamlessly
          final resetTo = next + loopStart;
          _scrollController.jumpTo(resetTo.clamp(0.0, max));
        } else {
          _scrollController.jumpTo(next);
        }
      });
    });
  }

  void _pauseAutoScroll() {
    _timer?.cancel();
    _timer = null;
  }

  void _resumeAutoScroll() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, String>>.from(widget.items)
      ..addAll(widget.items);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _pauseAutoScroll();
        } else if (notification is ScrollUpdateNotification &&
            notification.dragDetails != null) {
          _pauseAutoScroll();
        } else if (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle) {
          _resumeAutoScroll();
        }
        return false;
      },
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        dragStartBehavior: DragStartBehavior.start,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final label = item['label'] ?? 'All';

          return GestureDetector(
            onTap: () => widget.onCategoryTap?.call(label),
            child: Container(
              width: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA9D0DF)),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image(
                        image:
                            (item['url'] ?? '').startsWith('http')
                                ? NetworkImage(item['url']!) as ImageProvider
                                : AssetImage(item['url'] ?? '')
                                    as ImageProvider,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RandomShellsGrid extends StatefulWidget {
  const RandomShellsGrid({super.key});

  @override
  State<RandomShellsGrid> createState() => _RandomShellsGridState();
}

class _RandomShellsGridState extends State<RandomShellsGrid> {
  late Future<List<Map<String, dynamic>>> _randomShellsFuture;

  @override
  void initState() {
    super.initState();
    _randomShellsFuture = _loadRandomShells();
  }

  Future<List<Map<String, dynamic>>> _loadRandomShells() async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/assets/images/shell-json.json',
      );
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return [];

      final shells =
          decoded
              .whereType<Map>()
              .map((shell) => Map<String, dynamic>.from(shell))
              .where((shell) => shell['basic_identification'] is Map)
              .toList();

      // Shuffle and get first 9 shells
      shells.shuffle();
      return shells.take(9).toList();
    } catch (e) {
      print('Error loading shells: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _randomShellsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 100,
            child: Center(child: Text('Error loading shells')),
          );
        }

        final shells = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 170,
          ),
          itemCount: shells.length,
          itemBuilder: (context, index) {
            final shell = shells[index];
            final identification = shell['basic_identification'];
            final commonName =
                identification is Map
                    ? identification['common_name']?.toString() ?? 'Unknown'
                    : 'Unknown';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShellDetailScreen(shell: shell),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA9D0DF)),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            shell['image_path'] ?? 'lib/assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'lib/assets/images/logo.png',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      commonName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
