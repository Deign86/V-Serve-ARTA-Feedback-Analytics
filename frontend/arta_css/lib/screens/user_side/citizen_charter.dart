import 'package:flutter/material.dart';

class CitizenCharterScreen extends StatefulWidget {
  const CitizenCharterScreen({Key? key}) : super(key: key);

  @override
  State<CitizenCharterScreen> createState() => _CitizenCharterScreenState();
}

class _CitizenCharterScreenState extends State<CitizenCharterScreen> {
  String charterAnswer = 'YES';
  final TextEditingController commentController = TextEditingController();

  Widget _progressBar(int activeStep) {
    return Row(
      children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: i < activeStep ? Color(0xFF009FE3) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/city_bg2.png', // Change to your background asset
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SizedBox(
                width: isMobile ? size.width : 1430,
                height: isMobile ? size.height : 660,
                child: Column(
                  children: [
                    // Logo and header area
                    Padding(
                      padding: EdgeInsets.only(top: 20.0, bottom: 6.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/city_logo.png',
                            height: isMobile ? 32 : 40,
                            width: isMobile ? 32 : 40,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "CITY GOVERNMENT OF VALENZUELA",
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003366),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "HELP US SERVE YOU BETTER!",
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 60, vertical: isMobile ? 10 : 18),
                      child: _progressBar(2),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: isMobile ? size.width * 0.98 : 1050,
                          height: isMobile ? size.height * 0.77 : 410,
                          padding: EdgeInsets.all(isMobile ? 16 : 32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 16,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "PART 2.",
                                    style: TextStyle(
                                      fontSize: isMobile ? 17 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003366),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "CITIZEN'S CHARTER",
                                    style: TextStyle(
                                      fontSize: isMobile ? 15 : 20,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 10 : 20),

                              // Main Question
                              Text(
                                "Did you find it easy to locate and understand the Citizen’s Charter?",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: isMobile ? 15 : 19,
                                  color: Color(0xFF003366),
                                ),
                              ),
                              SizedBox(height: isMobile ? 10 : 20),

                              // Yes/No options
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "YES",
                                    groupValue: charterAnswer,
                                    activeColor: Color(0xFF009FE3),
                                    onChanged: (v) {
                                      setState(() {
                                        charterAnswer = v!;
                                      });
                                    },
                                  ),
                                  Text("YES", style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18)),
                                  SizedBox(width: 24),
                                  Radio<String>(
                                    value: "NO",
                                    groupValue: charterAnswer,
                                    activeColor: Color(0xFF009FE3),
                                    onChanged: (v) {
                                      setState(() {
                                        charterAnswer = v!;
                                      });
                                    },
                                  ),
                                  Text("NO", style: TextStyle(fontWeight: FontWeight.w600, fontSize: isMobile ? 16 : 18)),
                                ],
                              ),
                              SizedBox(height: isMobile ? 10 : 20),

                              // Comment Field
                              Text(
                                "If NO, please elaborate:",
                                style: TextStyle(fontSize: isMobile ? 13 : 16),
                              ),
                              SizedBox(height: 6),
                              TextFormField(
                                controller: commentController,
                                enabled: charterAnswer == "NO",
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: "Your comments...",
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              Spacer(),

                              // Bottom-aligned buttons
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Color(0xFF003366)),
                                        minimumSize: Size(150, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "PREVIOUS PAGE",
                                        style: TextStyle(
                                          color: Color(0xFF003366),
                                          fontSize: isMobile ? 13 : 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 14),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF003366),
                                        minimumSize: Size(150, 50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(28),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/cc2');
                                      },
                                      child: Text(
                                        "NEXT PAGE",
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
}
