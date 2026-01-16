import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_1/features/auth/role_selection_screen.dart';
import 'package:flutter_application_1/features/matchmaker/browse_talent_screen.dart';

/// ONBOARDING SCREEN
/// This screen provides a 3-page introduction to the platform.
/// 
/// STYLING OVERVIEW:
/// - Titles: Lora font (Elegant, high-end)
/// - Body/Subtitles: Inter font (Clean, legible)
/// - Action Buttons: Inter font (Standard, functional)
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
      subtitle: 'The platform for brands, agencies,\nand production companies seeking\nexceptional models and creators.',
      isTitleItalic: true, // Page 1 is italicized
    ),
    OnboardingData(
      title: 'Global Excellence',
      subtitle: 'Premium talent standards met with\nseamless technology.',
      features: [
        FeatureData(
          title: 'Curated Talent',
          subtitle: 'Every model is vetted for quality,\nprofessionalism, and reliability.',
        ),
        FeatureData(
          title: 'Seamless Booking',
          subtitle: 'Contracts, payments, and logistics\nhandled in one place.',
        ),
        FeatureData(
          title: 'Global Reach',
          subtitle: 'Access talent across major cities and\ninternational markets.',
        ),
      ],
    ),
    OnboardingData(
      title: 'Elevate Your\nProduction',
      subtitle: 'Join leading brands and agencies who\ntrust Castiq for their talent\nbooking needs.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                        MaterialPageRoute(builder: (context) => const BrowseTalentScreen()),
                      );
                    },
                  ),
                
                if (_currentPage == _pages.length - 1) ...[
                  _buildActionButton(
                    label: 'Apply',
                    icon: LucideIcons.arrowRight,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen(isLogin: false),
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
                          builder: (context) => const RoleSelectionScreen(isLogin: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showStatusModal(context),
                    child: Text(
                      'Application Status',
                      style: GoogleFonts.inter(
                        color: Colors.white54,
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

  Widget _buildActionButton({required String label, IconData? icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
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
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
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
        color: _currentPage == index ? Colors.white : Colors.white24,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showStatusModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
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
              style: GoogleFonts.tinos(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Check the progress of your onboarding application.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                hintText: 'Email address',
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Check Now'),
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
    // PAGE IDENTIFIERS
    final bool isPage1 = index == 0;
    final bool isPage2 = index == 1; // Features page
    final bool isPage3 = index == 2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // TOP SPACER: 
          // Page 1: 3 flex (Centered)
          // Page 2: 2 flex (Balanced)
          // Page 3: 1 flex (Elevated)
          if (isPage1) const Spacer(flex: 3),
          if (isPage2) const Spacer(flex: 2),
          if (isPage3) const Spacer(flex: 1),
          
          // TITLE FORMATTING
          // PAGE 1 STYLE: "Premium" is Lora Bold/Italic, rest is Inter
          // PAGE 2 STYLE: Lora font, 40px, balanced
          // PAGE 3 STYLE: Lora font, 48px, elevated
          if (isPage1)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Premium\n',
                    style: GoogleFonts.tinos(
                      fontSize: 48,
                      fontWeight: FontWeight.w700, // Bold
                      fontStyle: FontStyle.italic, // Premium is italic
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Talent Booking',
                    style: GoogleFonts.inter(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
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
              style: GoogleFonts.tinos(
                fontSize: isPage2 ? 40 : 48,
                fontWeight: FontWeight.w300,
                // Page 3/2 etc use theme-based italic or normal
                fontStyle: data.isTitleItalic ? FontStyle.italic : FontStyle.normal,
                color: Colors.white,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
          
          // SUBTITLE SPACING
          // Page 2: 20px, Others: 24px
          SizedBox(height: isPage2 ? 20 : 24), 
          
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
              letterSpacing: 0.1,
              fontWeight: FontWeight.w400,
            ),
          ),
          
          // FEATURES SECTION (Page 2 specific)
          if (data.features != null) ...[
            const SizedBox(height: 48), 
            ...data.features!.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  Text(
                    f.title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8), 
                  Text(
                    f.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.65),
                      height: 1.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          // BOTTOM SPACER:
          // Page 1: 3 flex (Symmetric)
          // Page 2: 2 flex (Symmetric)
          // Page 3: 5 flex (Room for actions)
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