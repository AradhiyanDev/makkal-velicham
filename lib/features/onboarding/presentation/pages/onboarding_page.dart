import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardItem> _items = const [
    _OnboardItem(
      imagePath: 'assets/images/intro/intro1.png',
      titleSpan: TextSpan(
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: 'தமிழ் செய்திகள்\n',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'உங்கள் விரல் நுனியில்',
            style: TextStyle(color: Color(0xFFCB75FB)),
          ),
        ],
      ),
      description:
          'தமிழ்நாடு, இந்தியா மற்றும் உலகின்\nமுக்கியச் செய்திகளை ஒரே இடத்தில்\nஉடனுக்குடன் தெரிந்துகொள்ளுங்கள்.',
    ),
    _OnboardItem(
      imagePath: 'assets/images/intro/intro2.png',
      titleSpan: TextSpan(
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: 'Swipe to Flip\n',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Like a Real ',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Newspaper',
            style: TextStyle(color: Color(0xFFCB75FB)),
          ),
        ],
      ),
      description:
          'மேலே ஸ்வைப் செய்து அடுத்த\nசெய்திக்குச் செல்லுங்கள். நிஜ பேப்பர்\nபுரட்டும் அனுபவம் இனி உங்கள்\nமொபைலில்.',
    ),
    _OnboardItem(
      imagePath: 'assets/images/intro/intro3.png',
      titleSpan: TextSpan(
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: 'Stay Updated\n',
            style: TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: 'Stay Ahead',
            style: TextStyle(color: Color(0xFFCB75FB)),
          ),
        ],
      ),
      description:
          'லைக், கமெண்ட் செய்து செய்திகளில்\nஉங்கள் கருத்தைப் பகிருங்கள்.\nமுக்கியச் செய்திகளை\nஉடனுக்குடன் அறிந்துகொள்ளுங்கள்.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index < _items.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF140D24),
                Color(0xFF0C0717),
                Color(0xFF07040D),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Ambient soft glow behind artwork
              Positioned(
                top: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF8B2DE2).withValues(alpha: 0.22),
                          const Color(0xFF6B11A8).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // Top Bar with Skip
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 16),
                        child: TextButton(
                          onPressed: _goToAuth,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.75),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                    ),

                    // Slides PageView
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        onPageChanged: (i) => setState(() => _index = i),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                // Illustration
                                Expanded(
                                  flex: 6,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Image.asset(
                                        item.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Title
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: item.titleSpan,
                                ),
                                const SizedBox(height: 14),

                                // Description
                                Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.55,
                                    color: Color(0xFFBDB8D4),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Page Indicator (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_items.length, (i) {
                        final active = i == _index;
                        return GestureDetector(
                          onTap: () {
                            _controller.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeInOutCubic,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active
                                  ? const Color(0xFFCB75FB)
                                  : const Color(0xFF3E2D58),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFCB75FB)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Action Button (Next / Get Started)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF842FD6),
                              Color(0xFF9E42EC),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B36E2).withValues(alpha: 0.40),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(28),
                            onTap: _goNext,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _index == _items.length - 1 ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

class _OnboardItem {
  final String imagePath;
  final TextSpan titleSpan;
  final String description;

  const _OnboardItem({
    required this.imagePath,
    required this.titleSpan,
    required this.description,
  });
}
