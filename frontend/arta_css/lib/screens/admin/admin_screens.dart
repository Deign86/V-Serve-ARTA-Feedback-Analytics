import 'package:flutter/material.dart';
import '../../services/export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// THEME CONSTANTS
const String fontHeading = 'Montserrat';
const String fontBody = 'Poppins';
final Color brandBlue = Colors.blue.shade900;
final Color brandRed = Colors.red.shade900;

class CreateSurveyScreen extends StatefulWidget {
  final String? existingTitle;
  const CreateSurveyScreen({Key? key, this.existingTitle}) : super(key: key);

  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTitle ?? '');
    _descController = TextEditingController(text: 'Quarterly assessment of client satisfaction across all departments');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: brandBlue),
        title: Text(
          widget.existingTitle == null ? 'Create New Survey' : 'Edit Survey',
          style: TextStyle(fontFamily: fontHeading, color: brandBlue, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Survey saved successfully')),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Survey'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: brandBlue,
                textStyle: const TextStyle(fontFamily: fontBody, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          )
        ],
      ),
      body: Row(
        children: [
          // Sidebar / Settings Area
          Container(
            width: 300,
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Survey Settings", style: TextStyle(fontFamily: fontHeading, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 24),
                _buildStyledTextField(_titleController, 'Survey Title'),
                const SizedBox(height: 16),
                _buildStyledTextField(_descController, 'Description', maxLines: 3),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text("Active Period", style: TextStyle(fontFamily: fontHeading, fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: brandBlue),
                  title: Text("Start Date", style: TextStyle(fontFamily: fontBody, fontSize: 12)),
                  subtitle: Text("Jan 20, 2024", style: TextStyle(fontFamily: fontBody, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Preview Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Simulation
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.account_balance, size: 40, color: brandRed),
                                  const SizedBox(height: 8),
                                  Text("CITY GOVERNMENT OF VALENZUELA", style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                            // Mock Questions
                            _buildMockQuestion(1, "Which department did you visit today?", "dropdown"),
                            _buildMockQuestion(2, "How would you rate the service speed?", "rating"),
                            _buildMockQuestion(3, "Was the staff courteous and helpful?", "yesno"),
                            _buildMockQuestion(4, "Any suggestions for improvement?", "text"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: fontBody, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontFamily: fontBody, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMockQuestion(int number, String question, String type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("$number.", style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold, fontSize: 16, color: brandBlue)),
              const SizedBox(width: 12),
              Text(question, style: TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          if (type == 'text')
            Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            )
          else if (type == 'rating')
             Row(children: List.generate(5, (index) => Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.star_border, color: Colors.amber, size: 30))))
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Row(children: [Text(type == 'dropdown' ? "Select an option..." : "Yes / No", style: TextStyle(fontFamily: fontBody, color: Colors.grey))]),
            )
        ],
      ),
    );
  }
}

class SurveyDetailScreen extends StatelessWidget {
  final String title;
  const SurveyDetailScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Light blue-grey background
      appBar: AppBar(
        title: Text('Survey Preview', style: TextStyle(fontFamily: fontHeading, color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 700,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    // Decorative Header
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: brandRed,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Branding
                          Row(
                            children: [
                               CircleAvatar(backgroundColor: brandBlue, radius: 20, child: const Icon(Icons.account_balance, color: Colors.white, size: 20)),
                               const SizedBox(width: 16),
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text('CITY GOVERNMENT OF VALENZUELA', style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade700)),
                                   Text('Service Excellence Office', style: TextStyle(fontFamily: fontBody, fontSize: 10, color: Colors.grey.shade500)),
                                 ],
                               )
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Survey Header
                          Text(title, style: TextStyle(fontFamily: fontHeading, fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(
                            'Your feedback is important to us. Please help us improve our services by answering the following questions.',
                            style: TextStyle(fontFamily: fontBody, fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const Divider(height: 48),

                          // Sample Content
                          _buildPreviewItem(1, 'Which department did you visit?', ['Business Permit', 'Assessor', 'Treasury', 'Health Office']),
                          _buildPreviewItem(2, 'How satisfied are you with the waiting time?', ['Very Satisfied', 'Satisfied', 'Neutral', 'Dissatisfied']),
                          _buildPreviewItem(3, 'Was the staff knowledgeable?', ['Yes', 'No']),
                          
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: null, // Disabled for preview
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('SUBMIT FEEDBACK', style: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.bold)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text("This is a preview of how the survey appears to citizens.", style: TextStyle(fontFamily: fontBody, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItem(int index, String question, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontFamily: fontBody, fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 12),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(opt, style: TextStyle(fontFamily: fontBody, fontSize: 14, color: Colors.grey.shade800)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// Simple simulation wrappers for other screens to keep code clean
class SurveyAnalyticsScreen extends StatelessWidget {
  final String title;
  const SurveyAnalyticsScreen({Key? key, required this.title}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Analytics: $title'), backgroundColor: brandBlue),
      body: const Center(child: Text("Analytics Graph Simulation")),
    );
  }
}

class AddUserScreen extends StatelessWidget {
  final String? existingName;
  const AddUserScreen({Key? key, this.existingName}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(existingName ?? "Add User")));
}

class UserDetailScreen extends StatelessWidget {
  final String name;
  final String email;
  const UserDetailScreen({Key? key, required this.name, required this.email}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(name)));
}

class ExportPreviewScreen extends StatelessWidget {
  final String filePath;
  const ExportPreviewScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Preview')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Saved file:\n$filePath',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File located at: $filePath')));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Show Path'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExportProcessScreen extends StatefulWidget {
  final String templateName;
  const ExportProcessScreen({Key? key, required this.templateName}) : super(key: key);
  @override
  State<ExportProcessScreen> createState() => _ExportProcessScreenState();
}

class _ExportProcessScreenState extends State<ExportProcessScreen> {
  double _progress = 0.0;
  String? _savedPath;

  @override
  void initState() {
    super.initState();
    _startExport();
  }

  Future<void> _startExport() async {
    // Simulate progress and perform a CSV export with sample data
    final rows = [
      ['id', 'name', 'score'],
      ['1', 'Alice', '95'],
      ['2', 'Bob', '82'],
      ['3', 'Carlos', '77'],
    ];

    for (var i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 180));
      setState(() => _progress = i / 5);
    }

    try {
      final path = await ExportService.exportCsv(widget.templateName, rows);
      setState(() => _savedPath = path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Export: ${widget.templateName}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(_savedPath == null ? 'Preparing export...' : 'Saved: $_savedPath'),
              const SizedBox(height: 12),
              if (_savedPath != null)
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExportPreviewScreen(filePath: _savedPath!))),
                  child: const Text('Open Preview'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _exportFormat = 'csv';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _exportFormat = prefs.getString('exportFormat') ?? 'csv';
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setString('exportFormat', _exportFormat);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
            const SizedBox(height: 8),
            const Text('Default Export Format', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(title: const Text('CSV'), value: 'csv', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            RadioListTile<String>(title: const Text('JSON'), value: 'json', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            RadioListTile<String>(title: const Text('PDF'), value: 'pdf', groupValue: _exportFormat, onChanged: (v) => setState(() => _exportFormat = v!)),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton(onPressed: _savePrefs, child: const Text('Save')),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: _loadPrefs, child: const Text('Reload')),
            ])
          ],
        ),
      ),
    );
  }
}