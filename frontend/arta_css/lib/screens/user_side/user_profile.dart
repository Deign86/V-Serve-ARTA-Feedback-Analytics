import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

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
                height: MediaQuery.of(context).size.height - (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom + 50),
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 40, vertical: isMobile ? 16 : 24),
                child: Column(
                  children: [
                    _buildHeader(isMobile),
                    SizedBox(height: isMobile ? 16 : 24),
                    _buildProgressBar(isMobile, 1),
                    SizedBox(height: isMobile ? 16 : 24),
                    Expanded(
                      child: _buildFormCard(isMobile),
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

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        CircleAvatar(
          radius: isMobile ? 16 : 22, // smaller logo
          backgroundImage: AssetImage('assets/city_logo.png'),
          onBackgroundImageError: (exception, stackTrace) {},
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

  Widget _buildProgressBar(bool isMobile, int currentPage) {
    final totalPages = 3;
    return Row(
      children: List.generate(totalPages, (index) {
        final isCompleted = index < currentPage - 1;
        final isActive = index == currentPage - 1;
        return Expanded(
          child: Container(
            height: isMobile ? 6 : 8,
            margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isCompleted || isActive
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black12)],
      ),
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
                  width: isMobile ? 140 : 180,
                  height: isMobile ? 44 : 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'PREVIOUS PAGE',
                      style: GoogleFonts.montserrat(
                        fontSize: isMobile ? 12 : 14,
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
                    onPressed: () => Navigator.pushNamed(context, '/citizenCharter'),
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
            ),
          )
        ],
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
        Row(
          children: [
            Expanded(child: _buildDateField(isMobile)),
            SizedBox(width: 16),
            Expanded(child: _buildSexField(isMobile)),
            SizedBox(width: 16),
            Expanded(child: _buildAgeField(isMobile)),
          ],
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Row(
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
          spacing: isMobile ? 16 : 24,
          runSpacing: 8,
          children: ['CITIZEN', 'BUSINESS', 'GOVERNMENT (EMPLOYEE OR ANOTHER AGENCY)']
              .map((type) => SizedBox(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: type,
                          groupValue: clientType,
                          activeColor: const Color(0xFF003366),
                          onChanged: (value) => setState(() => clientType = value),
                        ),
                        Text(
                          type,
                          style: GoogleFonts.poppins(
                              fontSize: isMobile ? 12 : 14,
                              color: Color(0xFF003366)),
                        ),
                      ],
                    ),
                  ))
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
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => selectedDate = picked);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate?.toString().split(' ')[0] ?? 'Select date',
                  style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
                ),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
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
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: ['MALE', 'FEMALE']
              .map((s) => Expanded(
                    child: Row(
                      children: [
                        Radio<String>(
                          value: s,
                          groupValue: sex,
                          activeColor: const Color(0xFF003366),
                          onChanged: (value) => setState(() => sex = value),
                        ),
                        Text(
                          s,
                          style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 13, color: Color(0xFF003366)),
                        ),
                      ],
                    ),
                  ))
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
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          keyboardType: TextInputType.number,
          onChanged: (value) => setState(() => age = value),
          decoration: InputDecoration(
            hintText: 'Age',
            hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          onChanged: (value) => setState(() => region = value),
          decoration: InputDecoration(
            hintText: 'Enter your region',
            hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            fontSize: isMobile ? 13 : 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF003366),
          ),
        ),
        SizedBox(height: 10),
        TextField(
          onChanged: (value) => setState(() => serviceAvailed = value),
          decoration: InputDecoration(
            hintText: 'Enter the service availed',
            hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
