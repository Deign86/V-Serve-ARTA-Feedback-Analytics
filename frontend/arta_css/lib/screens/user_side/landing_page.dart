import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // FULL SCREEN BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/city_bg2.png',
              fit: BoxFit.cover,
            ),
          ),
          // MAIN CONTENT
          SafeArea(
            child: Center(
              child: Container(
                width: isMobile ? double.infinity : 1430,
                height: isMobile ? null : 660,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 0 : 40,
                  vertical: isMobile ? 0 : 36,
                ),
                child: isMobile
                    // MOBILE: content and image stack vertically and scroll
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildImageCarousel(isMobile),
                            SizedBox(height: 24),
                            _buildTextCard(context, isMobile),
                          ],
                        ),
                      )
                    // DESKTOP: text left, image right
                    : Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildTextCard(context, isMobile),
                            ),
                          ),
                          SizedBox(width: 24),
                          Container(
                            width: 400,
                            height: double.infinity,
                            child: _buildImageCarousel(isMobile),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 40),
      margin: isMobile ? EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(blurRadius: 18, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isMobile ? 22 : 32,
                backgroundImage: AssetImage('assets/city_logo.png'),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CITY GOVERNMENT OF VALENZUELA",
                    style: GoogleFonts.montserrat(
                      fontSize: isMobile ? 14 : 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  Text(
                    "HELP US SERVE YOU BETTER!",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 10 : 24,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 50),
          Text(
            "ARTA",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 48 : 96,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
          Text(
            "CLIENT SATISFACTION FORM",
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 18 : 28,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 16),
          Text(
            "We want to hear about your recently concluded transaction with us. Your feedback is valuable to improve our service.",
            style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 24),
          ),
          SizedBox(height: isMobile ? 6 : 8),
          GestureDetector(
            onTap: () {},
            child: Text(
              "recently concluded transaction",
              style: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 24,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          SizedBox(height: isMobile ? 20 : 32),
          Row(
            mainAxisAlignment:
                isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              SizedBox(
                width: isMobile ? double.infinity : 180,
                height: isMobile ? 44 : 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    "TAKE SURVEY",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(bool isMobile) {
    return Container(
      height: isMobile ? 200 : 400,
      margin: isMobile ? EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: AssetImage('assets/nai_1.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(true),
              SizedBox(width: 8),
              _buildDot(false),
              SizedBox(width: 8),
              _buildDot(false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Color(0xFF003366) : Colors.grey.shade300,
      ),
    );
  }
}
