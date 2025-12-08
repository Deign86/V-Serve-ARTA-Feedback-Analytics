import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _carouselImages = [
    'assets/nai_1.jpg',
    'assets/nai_2.jpg',
    'assets/nai_3.png',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-slide every 4 seconds
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _carouselImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/city_bg2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: isMobile
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildMobileLayout(context),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
                    child: _buildDesktopLayout(context),
                  ),
                ),
        ),
      ),
    );
  }

  // ------------------ MOBILE LAYOUT ------------------
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildImageCarousel(true),
        const SizedBox(height: 20),
        _buildTextCard(context, true),
        const SizedBox(height: 8), // minimal space, no more huge gap
      ],
    );
  }

  // ------------------ DESKTOP LAYOUT ------------------
  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: Container(
        width: 1430,
        height: 660, // same as before (carousel height alignment)
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        child: Row(
          children: [
            // Left side (Text + Button)
            Expanded(
              child: SizedBox(
                height: 600, // same fixed height as carousel
                child: _buildTextCard(context, false),
              ),
            ),
            const SizedBox(width: 24),
            // Right side (Carousel)
            SizedBox(
              width: 400,
              height: 600,
              child: _buildImageCarousel(false),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ TEXT CARD ------------------
  Widget _buildTextCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 22 : 32,
                backgroundImage: const AssetImage('assets/city_logo.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CITY GOVERNMENT OF VALENZUELA",
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 14 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF003366),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "HELP US SERVE YOU BETTER!",
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 10 : 20,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 30),
          Text(
            "ARTA",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 48 : 100,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF003366),
            ),
          ),
          Text(
            "CLIENT SATISFACTION FORM",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Text(
            "We want to hear about your recently concluded transaction with us. "
            "Your feedback is valuable to improve our service.",
            style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 18),
          ),
          if (isMobile) const SizedBox(height: 16),
          if (!isMobile) const Spacer(),
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerRight,
            child: SizedBox(
              width: isMobile ? double.infinity : 180,
              height: isMobile ? 44 : 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Text(
                  "TAKE SURVEY",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ IMAGE CAROUSEL ------------------
  Widget _buildImageCarousel(bool isMobile) {
    return Container(
      height: isMobile ? 200 : 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _carouselImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.asset(
                _carouselImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselImages.length,
                (index) => _buildDot(index == _currentPage),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 14 : 10,
      height: isActive ? 14 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF003366) : Colors.grey.shade300,
      ),
    );
  }
}
