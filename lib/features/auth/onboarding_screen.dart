import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';
import 'package:flutter_application_1/features/matchmaker/browse_talent_screen.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';

/// ONBOARDING SCREEN
/// Luxury minimal aesthetic — Cream background, Gold accents, Editorial typography.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Premium\nTalent Booking',
      subtitle:
          'The platform for brands, agencies,\nand production companies seeking\nexceptional models and creators.',
      isTitleItalic: true,
    ),
    OnboardingData(
      title: 'Global Excellence',
      subtitle:
          'Premium talent standards met with\nseamless technology.',
      features: [
        FeatureData(
          title: 'Curated Talent',
          subtitle:
              'Every model is vetted for quality,\nprofessionalism, and reliability.',
        ),
        FeatureData(
          title: 'Seamless Booking',
          subtitle:
              'Contracts, payments, and logistics\nhandled in one place.',
        ),
        FeatureData(
          title: 'Global Reach',
          subtitle:
              'Access talent across major cities and\ninternational markets.',
        ),
      ],
    ),
    OnboardingData(
      title: 'Elevate Your\nProduction',
      subtitle:
          'Join leading brands and agencies who\ntrust Caztiq for their talent\nbooking needs.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index], index: index);
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 48),
                if (_currentPage == 0)
                  _buildActionButton(
                    label: 'Browse Talent',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BrowseTalentScreen()),
                      );
                    },
                  ),
                if (_currentPage == _pages.length - 1) ...[
                  _buildPrimaryButton(
                    label: 'Apply',
                    icon: LucideIcons.arrowRight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RoleSelectionScreen(isLogin: false),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    label: 'I have an account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RoleSelectionScreen(isLogin: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showStatusModal(context),
                    child: Text(
                      'Application Status',
                      style: GoogleFonts.montserrat(
                        color: AppTheme.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gold primary button (for main CTA)
  Widget _buildPrimaryButton(
      {required String label, IconData? icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.gold,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: AppTheme.black, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Subtle outline button
  Widget _buildActionButton(
      {required String label, IconData? icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.black.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: AppTheme.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: AppTheme.black, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 4,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? AppTheme.gold : AppTheme.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showStatusModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Application Status',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Check the progress of your onboarding application.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(color: AppTheme.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Email address',
                filled: true,
                fillColor: AppTheme.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0DCD5)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Check Now',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final int index;

  const _OnboardingPage({required this.data, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isPage1 = index == 0;
    final bool isPage2 = index == 1;
    final bool isPage3 = index == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isPage1) const Spacer(flex: 3),
          if (isPage2) const Spacer(flex: 2),
          if (isPage3) const Spacer(flex: 1),

          // TITLE
          if (isPage1)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Premium\n',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Talent Booking',
                    style: GoogleFonts.montserrat(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.black,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: isPage2 ? 40 : 48,
                fontWeight: FontWeight.w300,
                fontStyle:
                    data.isTitleItalic ? FontStyle.italic : FontStyle.normal,
                color: AppTheme.black,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),

          SizedBox(height: isPage2 ? 20 : 24),

          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              color: AppTheme.grey,
              height: 1.5,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Features section (Page 2)
          if (data.features != null) ...[
            const SizedBox(height: 48),
            ...data.features!.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      Text(
                        f.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.black,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: AppTheme.grey,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                )),
          ],

          if (isPage1) const Spacer(flex: 3),
          if (isPage2) const Spacer(flex: 2),
          if (isPage3) const Spacer(flex: 5),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final List<FeatureData>? features;
  final bool isTitleItalic;

  OnboardingData({
    required this.title,
    required this.subtitle,
    this.features,
    this.isTitleItalic = false,
  });
}

class FeatureData {
  final String title;
  final String subtitle;

  FeatureData({required this.title, required this.subtitle});
}
