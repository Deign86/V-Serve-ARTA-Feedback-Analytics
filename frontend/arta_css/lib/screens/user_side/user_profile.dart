import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String clientType = 'CITIZEN';
  DateTime? selectedDate;
  String sex = 'MALE';

  final ageController = TextEditingController();
  final regionController = TextEditingController();
  final serviceController = TextEditingController();

  void _pickDate(BuildContext context) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

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
          // Main layout
          SafeArea(
            child: Center(
              child: SizedBox(
                width: isMobile ? size.width : 1430,
                height: isMobile ? size.height : 660,
                child: Column(
                  children: [
                    // Logo/header (small and at top)
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
                      child: _progressBar(1),
                    ),
                    // Main card content (never overflows)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: isMobile ? size.width * 0.98 : 1050,
                          height: isMobile ? size.height * 0.77 : 480,
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
                              // Main fields area - take up all extra space, scroll if needed
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "PART 1.",
                                            style: TextStyle(
                                              fontSize: isMobile ? 17 : 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF003366),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "USER PROFILE",
                                            style: TextStyle(
                                              fontSize: isMobile ? 15 : 20,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 10 : 20),
                                      // CLIENT TYPE
                                      Text("CLIENT TYPE:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                      SizedBox(height: 4),
                                      Wrap(
                                        spacing: 20,
                                        alignment: WrapAlignment.start,
                                        children: [
                                          _radioOption("CITIZEN", clientType),
                                          _radioOption("BUSINESS", clientType),
                                          _radioOption("GOVERNMENT", clientType, label: "GOVERNMENT (EMPLOYEE OR ANOTHER AGENCY)"),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 7 : 20),
                                      // DATE, SEX, AGE
                                      Row(
                                        children: [
                                          // DATE
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("DATE:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                                SizedBox(height: 2),
                                                GestureDetector(
                                                  onTap: () => _pickDate(context),
                                                  child: AbsorbPointer(
                                                    child: TextFormField(
                                                      decoration: InputDecoration(
                                                        hintText: selectedDate == null
                                                            ? "Select date"
                                                            : "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}",
                                                        suffixIcon: Icon(Icons.calendar_today),
                                                        filled: true,
                                                        fillColor: Colors.grey[100],
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 6 : 20),
                                          // SEX
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("SEX:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                                SizedBox(height: 2),
                                                Wrap(
                                                  spacing: 16,
                                                  children: [
                                                    _radioOption("MALE", sex, group: "sex"),
                                                    _radioOption("FEMALE", sex, group: "sex"),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 6 : 20),
                                          // AGE
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("AGE:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                                SizedBox(height: 2),
                                                TextFormField(
                                                  controller: ageController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: "Age",
                                                    filled: true,
                                                    fillColor: Colors.grey[100],
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 7 : 20),
                                      // REGION, SERVICE
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("REGION OF RESIDENCE:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                                SizedBox(height: 2),
                                                TextFormField(
                                                  controller: regionController,
                                                  decoration: InputDecoration(
                                                    hintText: "Enter your region",
                                                    filled: true,
                                                    fillColor: Colors.grey[100],
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: isMobile ? 6 : 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text("SERVICE AVAILED:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: isMobile ? 13 : 18, color: Color(0xFF003366))),
                                                SizedBox(height: 2),
                                                TextFormField(
                                                  controller: serviceController,
                                                  decoration: InputDecoration(
                                                    hintText: "Enter the service availed",
                                                    filled: true,
                                                    fillColor: Colors.grey[100],
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // At the very end of your main card's Column:
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
                                        Navigator.pushNamed(context, '/citizenCharter');
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

  Widget _radioOption(String value, String groupValue,
      {String? label, String group = "clientType"}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: (group == "clientType") ? clientType : sex,
          activeColor: Color(0xFF009FE3),
          onChanged: (v) {
            setState(() {
              if (group == "clientType") {
                clientType = v!;
              } else {
                sex = v!;
              }
            });
          },
        ),
        Flexible(child: Text(label ?? value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  void dispose() {
    ageController.dispose();
    regionController.dispose();
    serviceController.dispose();
    super.dispose();
  }
}
