import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

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
      icon: Icons.newspaper_rounded,
      title: 'தமிழ் செய்திகள்\nஉங்கள் விரல் நுனியில்',
      description: 'தமிழ்நாடு, இந்தியா, உலகம் மற்றும் தொழில்நுட்பம் — அனைத்து செய்திகளும் ஒரே இடத்தில்.',
      color: Color(0xFF1E5631),
    ),
    _OnboardItem(
      icon: Icons.swipe_rounded,
      title: 'Swipe to Flip\nLike a Real Newspaper',
      description: 'மேலே ஸ்வைப் செய்து அடுத்த செய்திக்கு செல்லுங்கள். நிஜ பேப்பர் புரட்டும் அனுபவம்.',
      color: Color(0xFFE94560),
    ),
    _OnboardItem(
      icon: Icons.bolt_rounded,
      title: 'Stay Updated\nStay Ahead',
      description: 'லைக், கமெண்ட் செய்து செய்திகளில் உங்கள் கருத்தை பகிருங்கள். எப்போதும் அப்டேட்டாக இருங்கள்.',
      color: Color(0xFFFF9500),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_index < _items.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColors = theme.extension<AppCardColors>()!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _goToAuth,
                child: Text('Skip', style: TextStyle(color: cardColors.descriptionColor)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 56, color: item.color),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: cardColors.titleColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: cardColors.descriptionColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? theme.colorScheme.primary : cardColors.descriptionColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Action
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _goNext,
                  child: Text(
                    _index == _items.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardItem({required this.icon, required this.title, required this.description, required this.color});
}
