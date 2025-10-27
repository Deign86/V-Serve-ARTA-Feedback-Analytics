import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late ScrollController _scrollController;
  String? clientType = 'CITIZEN';
  DateTime? selectedDate;
  String? sex = 'MALE';
  String? age;
  String? region;
  String? serviceAvailed;

  final _formKey = GlobalKey<FormState>();

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
    final currentPage = 1;
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
                height:
                    MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top +
                        MediaQuery.of(context).padding.bottom +
                        50),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 40,
                  vertical: isMobile ? 16 : 24,
                ),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildProgressBar(isMobile, currentPage, totalSteps),
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
          onBackgroundImageError: (e, s) {},
        ),
        SizedBox(height: isMobile ? 7 : 10),
        Text(
          'CITY GOVERNMENT OF VALENZUELA',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 14 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'HELP US SERVE YOU BETTER!',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 10 : 14,
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
                  ? const Color(0xFF0099FF)
                  : isCompleted
                  ? const Color(0xFF36A0E1)
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
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(blurRadius: 14, color: Colors.black12)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 20 : 40),
                  child: _buildPart1(isMobile),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 20 : 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: isMobile ? 150 : 180,
                    height: isMobile ? 44 : 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'PREVIOUS PAGE',
                        style: GoogleFonts.montserrat(
                          fontSize: isMobile ? 11 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 140 : 160,
                    height: isMobile ? 44 : 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Navigator.pushNamed(context, '/citizenCharter');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill out all fields correctly.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
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
      ),
    );
  }

  Widget _buildPart1(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'PART 1. USER PROFILE',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 18 : 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 16 : 24),
      _buildClientTypeField(isMobile),
      SizedBox(height: isMobile ? 16 : 20),
      // Wrap date, sex, and age fields
      isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateField(isMobile),
                SizedBox(height: 12),
                _buildSexField(isMobile),
                SizedBox(height: 12),
                _buildAgeField(isMobile),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildDateField(isMobile)),
                SizedBox(width: 16),
                Expanded(child: _buildSexField(isMobile)),
                SizedBox(width: 16),
                Expanded(child: _buildAgeField(isMobile)),
              ],
            ),
      SizedBox(height: isMobile ? 16 : 20),
      // Wrap region and service fields
      isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRegionField(isMobile),
                SizedBox(height: 12),
                _buildServiceAvailedField(isMobile),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildRegionField(isMobile)),
                SizedBox(width: 16),
                Expanded(child: _buildServiceAvailedField(isMobile)),
              ],
            ),
    ],
  );
}

  Widget _buildClientTypeField(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLIENT TYPE:',
          style: GoogleFonts.montserrat(
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: isMobile ? 10 : 12),
        Wrap(
          spacing: isMobile ? 14 : 24,
          runSpacing: 8,
          children:
              ['CITIZEN', 'BUSINESS', 'GOVERNMENT (EMPLOYEE OR ANOTHER AGENCY)']
                  .map(
                    (type) => SizedBox(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: type,
                            groupValue: clientType,
                            activeColor: const Color(0xFF003366),
                            onChanged: (value) =>
                                setState(() => clientType = value),
                          ),
                          Text(
                            type,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 11 : 14,
                              color: const Color(0xFF003366),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

 Widget _buildDateField(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'DATE:',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 12 : 15, // smaller font on mobile
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 6 : 10),  // reduced vertical spacing
          GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (!mounted) return;
          if (picked != null) {
            setState(() {
              selectedDate = picked;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please fill out all fields correctly.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,  // reduced horizontal padding on mobile
            vertical: isMobile ? 10 : 12,     // reduced vertical padding on mobile
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(  // Make text flexible to avoid overflow
                child: Text(
                  selectedDate == null
                      ? 'Select date'
                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}",  // Short, formatted date
                  style: GoogleFonts.poppins(fontSize: isMobile ? 8 : 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: isMobile ? 12 : 18,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildSexField(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'SEX:',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 12 : 15, // slightly smaller for mobile
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 10),  // reduced spacing here
      Row(
        children: ['MALE', 'FEMALE']
            .map(
              (s) => Expanded(
                child: Row(
                  children: [
                    Radio<String>(
                      value: s,
                      groupValue: sex,
                      activeColor: const Color(0xFF003366),
                      onChanged: (value) => setState(() => sex = value),
                    ),
                    Flexible(  // Add Flexible here to prevent overflow
                      child: Text(
                        s,
                        style: GoogleFonts.ptSansNarrow(
                          fontSize: isMobile ? 9 : 13,
                          color: const Color(0xFF003366),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

Widget _buildAgeField(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'AGE:',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 12 : 15,  // smaller font size for mobile
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 8),  // less vertical spacing
      TextFormField(
        keyboardType: TextInputType.number,
        onChanged: (value) => setState(() => age = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Age is required';
          final intAge = int.tryParse(value);
          if (intAge == null) return 'Must be a valid number';
          if (intAge < 18) return 'Minimum age is 18';
          if (intAge > 120) return 'Invalid age';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Age',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,  // reduce horizontal padding on mobile
            vertical: isMobile ? 8 : 12,     // reduce vertical padding on mobile
          ),
        ),
      ),
    ],
  );
}


 Widget _buildRegionField(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'REGION OF RESIDENCE:',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 11 : 15, // smaller font on mobile
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 8), // reduced spacing
      TextFormField(
        onChanged: (value) => setState(() => region = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Region is required';
          if (value.length < 3) return 'Region must be at least 3 characters';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter your region',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16, // less padding on mobile
            vertical: isMobile ? 8 : 12,
          ),
        ),
      ),
    ],
  );
}

Widget _buildServiceAvailedField(bool isMobile) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'SERVICE AVAILED:',
        style: GoogleFonts.montserrat(
          fontSize: isMobile ? 10 : 15, // smaller font on mobile
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 10), // reduced spacing
      TextFormField(
        onChanged: (value) => setState(() => serviceAvailed = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Service is required';
          if (value.length < 3) return 'Service must be at least 3 characters';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter the service availed',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16, // less padding on mobile
            vertical: isMobile ? 8 : 12,
          ),
        ),
      ),
    ],
  );
}
}
