import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/survey_data.dart';
import 'sqd.dart';

class CitizenCharterScreen extends StatefulWidget {
  final SurveyData surveyData;
  
  const CitizenCharterScreen({
    super.key,
    required this.surveyData,
  });

  @override
  State<CitizenCharterScreen> createState() => _CitizenCharterScreenState();
}

class _CitizenCharterScreenState extends State<CitizenCharterScreen> {
  late ScrollController _scrollController;

  String? cc1Answer;
  String? cc2Answer;
  String? cc3Answer;

  final cc1Options = [
    '1. I know what a CC is and I saw this office\'s CC.',
    '2. I know what a CC is but I did NOT see this office\'s CC.',
    '3. I learned of the CC only when I saw this office\'s CC.',
    '4. I do not know what a CC is and I did not see one in this office.',
  ];

  final cc2Options = [
    '1. Easy to see',
    '2. Somewhat easy to see',
    '3. Difficult to see',
    '4. Not visible at all',
    '5. Not Applicable',
  ];

  final cc3Options = [
    '1. Helped very much',
    '2. Somewhat helped',
    '3. Did not help',
    '4. Not Applicable',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    if (cc1Answer == null) return false;

    // Logic: If CC1 is Option 4 ("I do not know"), CC2 & CC3 are implicitly N/A or skipped
    // For visual simplicity, we require users to select N/A if that's the case, 
    // OR you can auto-fill them. For now, strict validation:
    if (cc1Answer!.startsWith('4.')) {
      // If user chose 4, we check if they selected N/A for others, or we can just allow them to pass.
      // Let's enforce the "Answer N/A" rule as per instruction text.
      return cc2Answer == cc2Options[4] && cc3Answer == cc3Options[3];
    }

    if (cc2Answer == null || cc3Answer == null) return false;
    return true;
  }

  void _onNextPressed() {
    if (_isFormValid()) {
      final cc0Rating = cc1Answer != null ? int.tryParse(cc1Answer!.substring(0, 1)) : null;
      final cc1Rating = cc2Answer != null ? int.tryParse(cc2Answer!.substring(0, 1)) : null;
      final cc2Rating = cc3Answer != null ? int.tryParse(cc3Answer!.substring(0, 1)) : null;
      
      final updatedData = widget.surveyData.copyWith(
        cc0Rating: cc0Rating,
        cc1Rating: cc1Rating,
        cc2Rating: cc2Rating,
      );
      
      Navigator.push(
        context,
        SmoothPageRoute(page: SQDScreen(surveyData: updatedData)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all required questions correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final currentStep = 2;
    final totalSteps = 4;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/city_bg2.png', fit: BoxFit.cover),
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
                    _buildProgressBar(isMobile, currentStep, totalSteps),
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
          backgroundImage: const AssetImage('assets/city_logo.png'),
          backgroundColor: Colors.white,
        ),
        SizedBox(height: isMobile ? 7 : 10),
        Text(
          'CITY GOVERNMENT OF VALENZUELA',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 4)],
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(bool isMobile, int currentStep, int totalSteps) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep - 1;
        final isActive = index == currentStep - 1;
        return Expanded(
          child: Container(
            height: isMobile ? 6 : 8,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? const Color(0xFF0099FF)
                  : isCompleted
                      ? const Color(0xFF36A0E1)
                      : Colors.white.withValues(alpha: 0.3),
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
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(blurRadius: 20, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.all(isMobile ? 24 : 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Area
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003366),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PART 2',
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFACF1F),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CITIZEN\'S CHARTER',
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 20 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003366),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isMobile ? 16 : 24),
                  
                  // Instruction Box
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD), // Very light blue
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBDEFB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF003366), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'INSTRUCTIONS',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003366),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please select the option that best describes your experience with the Citizen\'s Charter (CC). If you answer "I do not know what a CC is" (Option 4) in CC1, please select "Not Applicable" for CC2 and CC3.',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 24 : 32),
                  
                  // CC1
                  _ccCard(
                    code: 'CC1',
                    question: 'Which of the following best describes your awareness of a CC?',
                    options: cc1Options,
                    selectedValue: cc1Answer,
                    onChanged: (val) => setState(() => cc1Answer = val),
                    isMobile: isMobile,
                  ),
                  
                  SizedBox(height: isMobile ? 32 : 48),
                  
                  // CC2
                  _ccCard(
                    code: 'CC2',
                    question: 'If aware of CC (answered 1-3 in CC1), would you say that the CC of this office was ...?',
                    options: cc2Options,
                    selectedValue: cc2Answer,
                    onChanged: (val) => setState(() => cc2Answer = val),
                    isMobile: isMobile,
                  ),
                  
                  SizedBox(height: isMobile ? 32 : 48),
                  
                  // CC3
                  _ccCard(
                    code: 'CC3',
                    question: 'If aware of CC (answered codes 1-3 in CC1), how much did the CC help you in your transaction?',
                    options: cc3Options,
                    selectedValue: cc3Answer,
                    onChanged: (val) => setState(() => cc3Answer = val),
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Navigation Area
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 40),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: isMobile ? 140 : 180,
                  height: isMobile ? 48 : 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF003366), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'PREVIOUS',
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
                  height: isMobile ? 48 : 55,
                  child: ElevatedButton(
                    onPressed: _onNextPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003366),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'NEXT PAGE',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 12 : 14,
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
    );
  }

  // --- NEW CARD STYLE WIDGET ---
  Widget _ccCard({
    required String code,
    required String question,
    required List<String> options,
    required String? selectedValue,
    required Function(String?) onChanged,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFACF1F),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF003366),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        // Options List (Converted to clickable cards)
        ...options.map((option) {
          final isSelected = selectedValue == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF003366).withValues(alpha: 0.05) 
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF003366) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected 
                      ? [] 
                      : [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    // Custom Radio Circle
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 24,
                      width: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF003366) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF003366) : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, size: 16, color: Colors.white) 
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Option Text
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 13 : 15,
                          color: isSelected ? const Color(0xFF003366) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// === SMOOTH PAGE ROUTE ===
class SmoothPageRoute extends PageRouteBuilder {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 600),
        );
}