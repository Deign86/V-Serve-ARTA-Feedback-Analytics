import 'package:flutter/material.dart';
import '../../services/survey_provider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/survey_data.dart';
import '../../services/survey_config_service.dart';
import '../../services/offline_queue.dart';
import '../../widgets/offline_queue_widget.dart';
import 'citizen_charter.dart';
import 'sqd.dart';
import 'suggestions.dart'; // ThankYouScreen is defined here
import '../../widgets/smooth_scroll_view.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isPreviewMode;
  
  const UserProfileScreen({super.key, this.isPreviewMode = false});

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
  
  // Controller for "Other" service input
  late TextEditingController _otherServiceController;
  bool _isOtherService = false;

  final List<String> regions = [
    'NCR',
    'CAR',
    'Region I',
    'Region II',
    'Region III',
    'Region IV-A',
    'Region IV-B',
    'Region V',
    'Region VI',
    'Region VII',
    'Region VIII',
    'Region IX',
    'Region X',
    'Region XI',
    'Region XII',
    'Region XIII',
    'BARMM',
  ];

  final List<String> services = [
    'Business Permit',
    'Real Property Tax',
    'Civil Registry',
    'Health Services',
    'Building Official',
    'Zoning',
    'Social Welfare',
    'Garbage Collection',
    'Traffic Management',
    'Other',
  ];

  // Validation State for Date (since it's not a text field)
  bool _showDateError = false;

  final _formKey = GlobalKey<FormState>();
  
  // Keys for auto-scrolling
  final _dateKey = GlobalKey();
  final _ageKey = GlobalKey();
  final _regionKey = GlobalKey();
  final _serviceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _otherServiceController = TextEditingController();
    
    // Initialize from provider if data exists
    final surveyData = context.read<SurveyProvider>().surveyData;
    if (surveyData.clientType != null) clientType = surveyData.clientType!;
    if (surveyData.date != null) selectedDate = surveyData.date;
    if (surveyData.sex != null) sex = surveyData.sex!;
    if (surveyData.age != null) age = surveyData.age.toString();
    if (surveyData.regionOfResidence != null) region = surveyData.regionOfResidence;
    
    if (surveyData.serviceAvailed != null) {
      if (services.contains(surveyData.serviceAvailed)) {
        serviceAvailed = surveyData.serviceAvailed;
        _isOtherService = false;
      } else {
        serviceAvailed = 'Other';
        _isOtherService = true;
        _otherServiceController.text = surveyData.serviceAvailed!;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _otherServiceController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    }
  }

  void _validateAndSubmit() {
    final configService = context.read<SurveyConfigService>();
    final demographicsEnabled = configService.demographicsEnabled;
    
    // Check Date Validity
    final isDateValid = selectedDate != null;
    setState(() => _showDateError = !isDateValid);

    // Check Text Fields Validity
    final isTextFormValid = _formKey.currentState?.validate() ?? false;

    if (isTextFormValid && isDateValid) {
      // Update Provider
      context.read<SurveyProvider>().updateProfile(
        clientType: clientType,
        date: selectedDate,
        sex: demographicsEnabled ? sex : null,
        age: demographicsEnabled && age != null ? int.tryParse(age!) : null,
        region: demographicsEnabled ? region?.trim() : null,
        serviceAvailed: _isOtherService 
            ? _otherServiceController.text.trim() 
            : serviceAvailed?.trim(),
      );
      
      final surveyData = context.read<SurveyProvider>().surveyData;

      // Navigate based on which sections are enabled
      _navigateToNextSection(surveyData, configService);
    } else {
      // Determine invalid field to scroll to (in order)
      if (!isDateValid) {
         _scrollToKey(_dateKey);
      } else if (demographicsEnabled) {
         // Check Age
         final intAge = age == null ? null : int.tryParse(age!);
         if (age == null || age!.trim().isEmpty || intAge == null || intAge < 18 || intAge > 120) {
           _scrollToKey(_ageKey);
         }
         // Check Region
         else if (region == null || region!.trim().length < 3) {
           _scrollToKey(_regionKey);
         }
         // Check Service
         else if (serviceAvailed == null || 
                  (_isOtherService && _otherServiceController.text.trim().isEmpty)) {
           _scrollToKey(_serviceKey);
         }
      } else {
         // Demographics disabled, check Service
         if (serviceAvailed == null || 
             (_isOtherService && _otherServiceController.text.trim().isEmpty)) {
           _scrollToKey(_serviceKey);
         }
      }

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the highlighted errors before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToNextSection(SurveyData surveyData, SurveyConfigService configService) async {
    // Determine the next screen based on enabled sections
    if (configService.ccEnabled) {
      // Go to Citizen's Charter
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CitizenCharterScreen(isPreviewMode: widget.isPreviewMode)),
      );
    } else if (configService.sqdEnabled) {
      // Skip CC, go to SQD
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SQDScreen(isPreviewMode: widget.isPreviewMode)),
      );
    } else if (configService.suggestionsEnabled) {
      // Skip CC and SQD, go to Suggestions
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SuggestionsScreen(isPreviewMode: widget.isPreviewMode)),
      );
    } else {
      // All optional sections disabled - submit directly
      // Skip database submission in preview mode
      if (widget.isPreviewMode) {
        if (!mounted) return;
        context.read<SurveyProvider>().resetSurvey();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ThankYouScreen(isPreviewMode: widget.isPreviewMode)),
        );
        return;
      }
      
      try {
        await OfflineQueue.enqueue(surveyData.toJson());
        await OfflineQueue.flush();
        
        // Reset survey after submission
        if (!mounted) return;
        context.read<SurveyProvider>().resetSurvey();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ThankYouScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final configService = context.watch<SurveyConfigService>();
    final currentPage = 1;
    final totalSteps = configService.totalSteps;

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
          // Offline Queue Banner (shows only when needed)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: OfflineQueueBanner(),
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
              child: SmoothScrollView(
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
                      onPressed: () {
                        // Update Provider before going back
                        final configService = context.read<SurveyConfigService>();
                        final demographicsEnabled = configService.demographicsEnabled;
                        context.read<SurveyProvider>().updateProfile(
                          clientType: clientType,
                          date: selectedDate,
                          sex: demographicsEnabled ? sex : null,
                          age: demographicsEnabled && age != null ? int.tryParse(age!) : null,
                          region: demographicsEnabled ? region?.trim() : null,
                          serviceAvailed: _isOtherService 
                              ? _otherServiceController.text.trim() 
                              : serviceAvailed?.trim(),
                        );
                        Navigator.of(context).maybePop();
                      },
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    key: _dateKey,
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
    key: _ageKey,
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
    key: _regionKey,
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
      DropdownButtonFormField<String>(
        initialValue: region,
        isExpanded: true,
        items: regions.map((r) {
          return DropdownMenuItem(
            value: r,
            child: Text(
              r,
              style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => region = value),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Region is required';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Select your region',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          prefixIcon: Icon(Icons.map_outlined, color: Colors.grey.shade600, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F7FA), // Use thematic light grey
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
        ),
        dropdownColor: Colors.white, // Ensure dropdown menu is white
      ),
    ],
  );
}

Widget _buildServiceAvailedField(bool isMobile) {
  return Column(
    key: _serviceKey,
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
      DropdownButtonFormField<String>(
        initialValue: serviceAvailed,
        isExpanded: true,
        items: services.map((s) {
          return DropdownMenuItem(
            value: s,
            child: Text(
              s,
              style: GoogleFonts.poppins(fontSize: isMobile ? 12 : 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            serviceAvailed = value;
            _isOtherService = (value == 'Other');
            if (!_isOtherService) {
              _otherServiceController.clear();
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) return 'Service is required';
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Select service availed',
          hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
          prefixIcon: Icon(Icons.assignment_outlined, color: Colors.grey.shade600, size: 20),
          filled: true,
          fillColor: const Color(0xFFF5F7FA), // Use thematic light grey
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 12,
          ),
        ),
        dropdownColor: Colors.white, // Ensure dropdown menu is white
      ),
      
      // Conditional "Other" Text Field
      if (_isOtherService) ...[
        SizedBox(height: isMobile ? 8 : 12),
        TextFormField(
          controller: _otherServiceController,
          validator: (value) {
            if (_isOtherService && (value == null || value.trim().isEmpty)) {
              return 'Please specify the service';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Please specify other service',
            hintStyle: GoogleFonts.poppins(fontSize: isMobile ? 11 : 14),
            prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey.shade600, size: 20),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 12,
            ),
          ),
        ),
      ],
    ],
  );
}
}

