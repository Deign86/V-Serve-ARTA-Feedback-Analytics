import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SQDScreen extends StatefulWidget {
  const SQDScreen({Key? key}) : super(key: key);

  @override
  State<SQDScreen> createState() => _SQDScreenState();
}

class _SQDScreenState extends State<SQDScreen> {
  late ScrollController _scrollController;

  // Example answers for 8 SQD questions
  List<int?> answers = List<int?>.filled(9, null);

  // Example question list (replace with your own)
  final List<Map<String, dynamic>> questions = [
    {'label': 'SQD 0:', 'question': 'I am satisfied with the service that I availed.'},
    {'label': 'SQD 1:', 'question': 'I spent a reasonable amount of time for my transaction.'},
    {'label': 'SQD 2:', 'question': 'The office followed the transaction\'s requirements and steps based on the information provided.'},
    {'label': 'SQD 3:', 'question': 'The steps (including payment) I needed to do for my transaction were easy and simple.'},
    {'label': 'SQD 4:', 'question': 'I easily found information about my transaction from the office or its website.'},
    {'label': 'SQD 5:', 'question': 'I paid a reasonable amount of fees for my transaction. (If service was free, mark the \'N/A\' column)'},
    {'label': 'SQD 6:', 'question': 'I feel the office was fair to everyone, or \'walang palakasan\', during my transaction.'},
    {'label': 'SQD 7:', 'question': 'I was treated courteously by the staff, and (if asked for help) the staff was helpful.'},
    {'label': 'SQD 8:', 'question': 'I got what I needed from the government office, or (if denied) denial of request was sufficiently explained to me.'},
  ];

  // Updated: emoji asset list (use your real paths)
  final List<String> emojis = [
    'assets/emojis/strongly_disagree.png',
    'assets/emojis/disagree.png',
    'assets/emojis/neutral.png',
    'assets/emojis/agree.png',
    'assets/emojis/strongly_agree.png',
    'N/A',// text-only option
  ];

  final List<String> labels = [
    'Strongly Disagree',
    'Disagree',
    'Neither Agree nor Disagree',
    'Agree',
    'Strongly Agree',
    'Not Applicable',
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
                    _buildProgressBar(isMobile, 3, 4),
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
              Text(
                'PART 3: SQD',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF003366),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Container(
                width: double.infinity,
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
                    children: const [
                      TextSpan(
                        text: 'INSTRUCTIONS: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'For SQD -8',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ', please select the best corresponds to your answer. '),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              ...List.generate(questions.length, (i) => _sqdQuestion(isMobile, i)),
              SizedBox(height: isMobile ? 24 : 40),
              _buildNavigationButtons(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sqdQuestion(bool isMobile, int index) {
  final q = questions[index];

  final List<Color> borderColors = [
    Colors.red,         // Strongly Disagree
    Colors.deepOrange,  // Disagree
    Colors.amber,       // Neutral
    Colors.lightGreen,  // Agree
    Colors.green,       // Strongly Agree
    Colors.grey,        // N/A
  ];

  final List<Color> bgColors = [
    Colors.red.shade50,
    Colors.orange.shade50,
    Colors.yellow.shade50,
    Colors.lightGreen.shade50,
    Colors.green.shade50,
    Colors.grey.shade100,
  ];

  return Padding(
    padding: EdgeInsets.only(bottom: isMobile ? 28 : 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question header
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF003366),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                q['label'],
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFACF1F),
                  fontSize: isMobile ? 13 : 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                q['question'],
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 14 : 19,
                  color: const Color(0xFF133C66),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),

        // ✅ Centered, evenly aligned emoji options
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: List.generate(emojis.length, (optIdx) {
              final bool selected = answers[index] == optIdx;
              final bool isNA = optIdx == 5;

              return GestureDetector(
                onTap: () => setState(() => answers[index] = optIdx),
                child: Container(
                  width: isMobile ? 85 : 110,
                  height: isMobile ? 115 : 130,
                  decoration: BoxDecoration(
                    color: selected ? bgColors[optIdx] : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? borderColors[optIdx] : Colors.grey.shade300,
                      width: selected ? 3 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: selected ? 10 : 5,
                        offset: Offset(0, selected ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ Emoji (centered and same height)
                      SizedBox(
                        height: isMobile ? 50 : 65, // adjust emoji height
                        child: isNA
                            ? Center(
                                child: Text(
                                  'N/A',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 26 : 32, // adjust N/A font
                                  ),
                                ),
                              )
                            : Center(
                                child: Image.asset(
                                  emojis[optIdx],
                                  width: isMobile ? 50 : 65, // adjust emoji width
                                  height: isMobile ? 50 : 65, // adjust emoji height
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),

                      const SizedBox(height: 8),

                      // ✅ Label text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          labels[optIdx],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 14, // adjust label font
                            color: isNA ? Colors.red.shade700 : Colors.black87,
                            fontWeight: isNA ? FontWeight.bold : FontWeight.w500,
                            height: 1.3, // adjust text line spacing
                          ),
                        ),
                      ),
                    ],
                  ),

                ),
              );
            }),
          ),
        ),
      ],
    ),
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
          width: isMobile ? 140 : 160,
          height: isMobile ? 44 : 50,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/suggestions');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003366),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
