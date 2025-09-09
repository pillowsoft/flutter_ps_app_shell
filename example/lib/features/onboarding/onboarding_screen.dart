import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Example onboarding screen that displays fullscreen without the AppShell navigation wrapper
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Flutter App Shell',
      description:
          'A comprehensive framework for rapid Flutter development with adaptive UI and powerful features.',
      icon: Icons.rocket_launch,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Fullscreen Routes',
      description:
          'This onboarding screen is displayed fullscreen without any navigation UI - perfect for immersive experiences.',
      icon: Icons.fullscreen,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Adaptive UI System',
      description:
          'Switch seamlessly between Material, Cupertino, and ForUI design systems with a single setting.',
      icon: Icons.palette,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Ready to Start?',
      description:
          'Let\'s dive into the main app and explore all the features Flutter App Shell has to offer!',
      icon: Icons.check_circle,
      color: Colors.green,
    ),
  ];

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _completeOnboarding() async {
    // Save that onboarding has been completed
    final prefs = getIt<PreferencesService>();
    prefs.setBool('has_seen_onboarding', true);

    // Navigate to the main app (with shell navigation)
    if (mounted) {
      context.go('/'); // Go to home screen with navigation UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);
    final theme = Theme.of(context);

    return ui.scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: page.color,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Title
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Description
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section with indicators and button
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Page indicators
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      expansionFactor: 2.0,
                      spacing: 8,
                      activeDotColor: _pages[_currentPage].color,
                      dotColor: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
