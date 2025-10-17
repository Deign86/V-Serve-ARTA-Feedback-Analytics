import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CitizenCharterScreen extends StatefulWidget {
  const CitizenCharterScreen({Key? key}) : super(key: key);

  @override
  State<CitizenCharterScreen> createState() => _CitizenCharterScreenState();
}

class _CitizenCharterScreenState extends State<CitizenCharterScreen> {
  late ScrollController _scrollController;

  String? cc1Answer;
  String? cc2Answer;
  String? cc3Answer;

  final cc1Options = [
    '1. Easy to see',
    '2. Somewhat easy to see',
    '3. Difficult to see',
    '4. Not visible at all',
    '5. N/A',
  ];

  final cc2Options = [
    '1. Helped very much',
    '2. Somewhat helped',
    '3. Did not help',
    '4. N/A',
  ];

  final cc3Options = [
    '1. I know what a CC is and I saw this office\'s CC.',
    '2. I know what a CC is but I did NOT see this office\'s CC.',
    '3. I learned of the CC only when I saw this office\'s CC.',
    '4. I do not know what a CC is and I did not see one in this office. (Answer \'N/A\' on CC2 and CC3)',
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final currentStep = 2; // Set this to 2 for Citizen's Charter
    final totalSteps = 4;  // Full flow: Profile, Charter, SDQ, Thank You

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
          backgroundImage: AssetImage('assets/city_logo.png'),
          onBackgroundImageError: (exception, stackTrace) {},
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
                  ? Color(0xFF0099FF)
                  : isCompleted
                    ? Color(0xFF36A0E1)
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
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Text(
                'PART 2. CITIZEN\'S CHARTER',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Color(0xFF003368).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 11 : 13,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF003368),
                    ),
                    children: [
                      TextSpan(text: 'INSTRUCTIONS: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'Please place a '),
                      TextSpan(text: 'Check mark (✓) ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'in the designated box that corresponds to your answer on the '),
                      TextSpan(text: 'Citizen\'s Charter (CC) ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'questions. The '),
                      TextSpan(text: 'Citizen\'s Charter ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'is an '),
                      TextSpan(text: 'official document ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'that reflects the services of a government agency/office including its '),
                      TextSpan(text: 'requirements, fees, and processing times ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: 'among others.'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              // CC1
              _ccCard(
                code: 'CC1',
                question: 'If aware of CC (answered 1-3 in CC1), would you say that the CC of this office was ...?',
                options: cc1Options,
                selectedValue: cc1Answer,
                onChanged: (val) => setState(() => cc1Answer = val),
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 32),
              // CC2
              _ccCard(
                code: 'CC2',
                question: 'If aware of CC (answered codes 1-3 in CC1), how much did the CC help you in your transaction?',
                options: cc2Options,
                selectedValue: cc2Answer,
                onChanged: (val) => setState(() => cc2Answer = val),
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 32),
              // CC3
              _ccCard(
                code: 'CC3',
                question: 'Which of the following best describes your awareness of a CC?',
                options: cc3Options,
                selectedValue: cc3Answer,
                onChanged: (val) => setState(() => cc3Answer = val),
                isMobile: isMobile,
              ),
              SizedBox(height: isMobile ? 24 : 40),
              _buildNavigationButtons(isMobile),
            ],
          ),
        ),
      ),
    );
  }

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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF003366),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            code,
            style: GoogleFonts.montserrat(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFACF1F),
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          question,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 12),
        Column(
          children: options
              .map((option) => GestureDetector(
                    onTap: () => onChanged(option),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selectedValue == option,
                            onChanged: (checked) => onChanged(checked == true ? option : null),
                            activeColor: const Color(0xFF003366),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
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
              side: BorderSide(color: const Color(0xFF003366)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          width: isMobile ? 140 : 160,
          height: isMobile ? 44 : 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/sqd');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    );
  }
}
