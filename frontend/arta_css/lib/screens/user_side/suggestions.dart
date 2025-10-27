import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  late TextEditingController _suggestionsController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _suggestionsController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _suggestionsController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/city_bg2.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                width: isMobile ? double.infinity : 1200,
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top +
                        MediaQuery.of(context).padding.bottom +
                        50),
                padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 40, vertical: isMobile ? 16 : 24),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildProgressBar(isMobile, 4, 4),
                    SizedBox(height: isMobile ? 16 : 24),
                    Expanded(child: _buildFormCard(isMobile)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        CircleAvatar(
          radius: isMobile ? 16 : 22,
          backgroundImage: AssetImage('assets/city_logo.png'),
        ),
        SizedBox(height: isMobile ? 7 : 10),
        Text(
          'CITY GOVERNMENT OF VALENZUELA',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isMobile, int current, int total) {
    return Row(
      children: List.generate(total, (index) {
        final isActive = index == current - 1;
        final isCompleted = index < current - 1;
        return Expanded(
          child: Container(
            height: isMobile ? 6 : 8,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive || isCompleted
                  ? const Color(0xFF0099FF)
                  : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFormCard(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
  color: Colors.white.withAlpha(250),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PART 3: SUGGESTIONS (OPTIONAL)',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 32),
              _buildSuggestionsField(isMobile),
              SizedBox(height: isMobile ? 24 : 32),
              _buildEmailField(isMobile),
              SizedBox(height: isMobile ? 32 : 48),
              _buildNavigationButtons(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions on how we can further improve our services (Optional)',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.red.shade600,
                Color(0XFF1C1E97),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: TextField(
            controller: _suggestionsController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Write your suggestions here...',
              hintStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address (Optional)',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                 Colors.red.shade600,
                Color(0XFF1C1E97),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha(76),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email address here...',
              hintStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 12 : 14,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 10 : 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 12 : 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: isMobile ? 140 : 180,
          height: isMobile ? 44 : 50,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF003366)),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'PREVIOUS PAGE',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF003366),
              ),
            ),
          ),
        ),
        SizedBox(
          width: isMobile ? 140 : 180,
          height: isMobile ? 44 : 50,
          child: ElevatedButton(
            onPressed: () {
              // Handle survey submission
              Navigator.pushNamed(context, '/confirmation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: Text(
              'SUBMIT SURVEY',
              style: GoogleFonts.montserrat(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}