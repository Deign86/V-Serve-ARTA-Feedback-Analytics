import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/survey_data.dart';
import '../../services/survey_config_service.dart';
import 'citizen_charter.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late ScrollController _scrollController;
  
  // Default values
  String clientType = 'CITIZEN';
  String sex = 'MALE';
  
  DateTime? selectedDate;
  String? age;
  String? region;
  String? serviceAvailed;

  // Validation State for Date (since it's not a text field)
  bool _showDateError = false;

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

  void _validateAndSubmit() {
    final configService = context.read<SurveyConfigService>();
    final demographicsEnabled = configService.demographicsEnabled;
    
    setState(() {
      // Check if date is missing
      _showDateError = (selectedDate == null);
    });

    // 1. Validate Text Fields (Age, Region, Service - only if demographics enabled)
    bool isTextFormValid = _formKey.currentState?.validate() ?? false;

    // 2. Validate Date
    bool isDateValid = selectedDate != null;

    if (isTextFormValid && isDateValid) {
      // Create Data Object - only include demographics if enabled
      final surveyData = SurveyData(
        clientType: clientType,
        date: selectedDate,
        sex: demographicsEnabled ? sex : null,
        age: demographicsEnabled && age != null ? int.tryParse(age!) : null,
        regionOfResidence: demographicsEnabled ? region?.trim() : null,
        serviceAvailed: serviceAvailed?.trim(),
      );

      // Smooth Transition
      Navigator.push(
        context,
        SmoothPageRoute(
          page: CitizenCharterScreen(surveyData: surveyData),
        ),
      );
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in red before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                height: MediaQuery.of(context).size.height -
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
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 14, color: Colors.black12)],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
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
                      onPressed: _validateAndSubmit,
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
    final configService = context.watch<SurveyConfigService>();
    final demographicsEnabled = configService.demographicsEnabled;
    
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
        SizedBox(height: isMobile ? 24 : 32),
        _buildClientTypeField(isMobile),
        SizedBox(height: isMobile ? 24 : 32),
        // Date field is always shown, demographics are conditional
        if (demographicsEnabled) ...[
          // Wrap date, sex, and age fields
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateField(isMobile),
                    SizedBox(height: 16),
                    _buildSexField(isMobile),
                    SizedBox(height: 16),
                    _buildAgeField(isMobile),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDateField(isMobile)),
                    SizedBox(width: 24),
                    Expanded(child: _buildSexField(isMobile)),
                    SizedBox(width: 24),
                    Expanded(child: _buildAgeField(isMobile)),
                  ],
                ),
          SizedBox(height: isMobile ? 24 : 32),
          // Wrap region and service fields
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRegionField(isMobile),
                    SizedBox(height: 16),
                    _buildServiceAvailedField(isMobile),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildRegionField(isMobile)),
                    SizedBox(width: 24),
                    Expanded(child: _buildServiceAvailedField(isMobile)),
                  ],
                ),
        ] else ...[
          // Only show date and service when demographics disabled
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateField(isMobile),
                    SizedBox(height: 16),
                    _buildServiceAvailedField(isMobile),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildDateField(isMobile)),
                    SizedBox(width: 24),
                    Expanded(child: _buildServiceAvailedField(isMobile)),
                  ],
                ),
        ],
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
                          // ignore: deprecated_member_use
                          Radio<String>(
                            value: type,
                            // ignore: deprecated_member_use
                            groupValue: clientType,
                            activeColor: const Color(0xFF003366),
                            // ignore: deprecated_member_use
                            onChanged: (value) =>
                                setState(() => clientType = value!),
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
          fontSize: isMobile ? 12 : 15, 
          fontWeight: FontWeight.bold,
          color: _showDateError ? Colors.red : const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 6 : 10),
      GestureDetector(
        onTap: () async {
          setState(() => _showDateError = false); // Clear error on tap
          final picked = await showGeneralDialog<DateTime>(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Dismiss',
            barrierColor: Colors.black54,
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, anim1, anim2) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF003366),
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: DatePickerDialog(
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                ),
              );
            },
            transitionBuilder: (context, anim1, anim2, child) {
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: anim1,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeIn,
                ),
                child: FadeTransition(
                  opacity: anim1,
                  child: child,
                ),
              );
            },
          );

          if (picked != null) {
            setState(() => selectedDate = picked);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              // TURN RED IF ERROR
              color: _showDateError ? Colors.red : Colors.grey.shade400,
              width: _showDateError ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedDate == null
                      ? 'Select date'
                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2,'0')}-${selectedDate!.day.toString().padLeft(2,'0')}", 
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 12 : 14,
                    color: _showDateError ? Colors.red : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.calendar_today,
                size: isMobile ? 18 : 20,
                color: _showDateError ? Colors.red : Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
      if (_showDateError)
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            'Date is required',
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
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
          fontSize: isMobile ? 12 : 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 10),
      Row(
        children: ['MALE', 'FEMALE']
            .map(
              (s) => Expanded(
                child: Row(
                  children: [
                    // ignore: deprecated_member_use
                    Radio<String>(
                      value: s,
                      // ignore: deprecated_member_use
                      groupValue: sex,
                      activeColor: const Color(0xFF003366),
                      // ignore: deprecated_member_use
                      onChanged: (value) => setState(() => sex = value!),
                    ),
                    Flexible(
                      child: Text(
                        s,
                        style: GoogleFonts.ptSansNarrow(
                          fontSize: isMobile ? 11 : 13,
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
          fontSize: isMobile ? 12 : 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 8),
      TextFormField(
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        onChanged: (value) => setState(() => age = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Required';
          
          final intAge = int.tryParse(value);
          if (intAge == null) return 'Invalid number';
          if (intAge < 18) return 'Must be 18+';
          if (intAge > 120) return 'Invalid age';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Age',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
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
          fontSize: isMobile ? 11 : 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 8),
      TextFormField(
        onChanged: (value) => setState(() => region = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Region is required';
          if (value.trim().length < 3) return 'Please be more specific';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter your region',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          prefixIcon: Icon(Icons.map_outlined, color: Colors.grey.shade600, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
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
          fontSize: isMobile ? 10 : 15,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF003366),
        ),
      ),
      SizedBox(height: isMobile ? 4 : 10),
      TextFormField(
        onChanged: (value) => setState(() => serviceAvailed = value),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Service is required';
          if (value.trim().length < 3) return 'Please be more specific';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter the service availed',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          prefixIcon: Icon(Icons.assignment_outlined, color: Colors.grey.shade600, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
        ),
      ),
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