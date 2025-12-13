import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/survey_questions_service.dart';
import '../utils/admin_theme.dart';

/// Widget for editing individual survey questions in the admin panel
class SurveyQuestionEditor extends StatefulWidget {
  const SurveyQuestionEditor({super.key});

  @override
  State<SurveyQuestionEditor> createState() => _SurveyQuestionEditorState();
}

class _SurveyQuestionEditorState extends State<SurveyQuestionEditor> {
  String _selectedSection = 'CC'; // 'CC', 'SQD', 'Profile', or 'Suggestions'

  @override
  Widget build(BuildContext context) {
    final questionsService = context.watch<SurveyQuestionsService>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: AdminTheme.brandBlue, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Survey Content Editor',
                      style: AdminTheme.headingSmall(color: Colors.black87),
                    ),
                  ],
                ),
                // Reset button
                TextButton.icon(
                  onPressed: () => _showResetConfirmation(context, questionsService),
                  icon: Icon(Icons.restore, size: 16, color: Colors.orange.shade700),
                  label: Text(
                    'Reset to Defaults',
                    style: AdminTheme.bodySmall(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Edit survey content, questions, and options. Changes reflect immediately on the user survey.',
              style: AdminTheme.bodySmall(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Section Tabs - 2 rows for 4 tabs
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildSectionTab('Profile', 'User Profile', Icons.person_outline),
                _buildSectionTab('CC', "Citizen's Charter", Icons.article_outlined),
                _buildSectionTab('SQD', 'Service Quality', Icons.star_outline),
                _buildSectionTab('Suggestions', 'Suggestions', Icons.feedback_outlined),
              ],
            ),
            const SizedBox(height: 20),

            // Content based on selected section
            _buildSectionContent(questionsService),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(SurveyQuestionsService questionsService) {
    switch (_selectedSection) {
      case 'CC':
        return Column(
          children: [
            _buildHeaderEditor(
              context, 
              'Section Title', 
              questionsService.ccSectionTitle, 
              () => _showEditTitleDialog(context, 'CC Section Title', questionsService.ccSectionTitle, (val) => questionsService.updateCcSectionTitle(val))
            ),
            const SizedBox(height: 16),
            ...questionsService.ccQuestions.map(
              (q) => _CcQuestionCard(question: q, questionsService: questionsService),
            ).toList(),
          ],
        );
      case 'SQD':
        return Column(
          children: [
            _buildHeaderEditor(
              context, 
              'Section Title', 
              questionsService.sqdSectionTitle, 
              () => _showEditTitleDialog(context, 'SQD Section Title', questionsService.sqdSectionTitle, (val) => questionsService.updateSqdSectionTitle(val))
            ),
            const SizedBox(height: 16),
            ...questionsService.sqdQuestions.asMap().entries.map(
              (entry) => _SqdQuestionCard(
                index: entry.key,
                question: entry.value,
                questionsService: questionsService,
              ),
            ).toList(),
          ],
        );
      case 'Profile':
        return _ProfileConfigEditor(questionsService: questionsService);
      case 'Suggestions':
        return _SuggestionsConfigEditor(questionsService: questionsService);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionTab(String id, String label, IconData icon) {
    final isSelected = _selectedSection == id;
    return InkWell(
      onTap: () => setState(() => _selectedSection = id),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: const BoxConstraints(minWidth: 140),
        decoration: BoxDecoration(
          color: isSelected ? AdminTheme.brandBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AdminTheme.brandBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AdminTheme.brandBlue : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AdminTheme.bodySmall(
                color: isSelected ? AdminTheme.brandBlue : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SurveyQuestionsService service) {
    final sectionNames = {
      'CC': "Citizen's Charter",
      'SQD': 'Service Quality Dimensions',
      'Profile': 'User Profile',
      'Suggestions': 'Suggestions',
    };
    final sectionName = sectionNames[_selectedSection] ?? _selectedSection;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset $sectionName?', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: Text(
          'This will reset all $sectionName configuration to default values. This action cannot be undone.',
          style: AdminTheme.bodyMedium(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AdminTheme.bodyMedium(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              switch (_selectedSection) {
                case 'CC':
                  service.resetCcToDefaults();
                  break;
                case 'SQD':
                  service.resetSqdToDefaults();
                  break;
                case 'Profile':
                  service.resetProfileToDefaults();
                  break;
                case 'Suggestions':
                  service.resetSuggestionsToDefaults();
                  break;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$sectionName reset to defaults'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
  Widget _buildHeaderEditor(BuildContext context, String label, String value, VoidCallback onEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(Icons.title, size: 18, color: AdminTheme.brandBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminTheme.bodyXS(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AdminTheme.bodyMedium(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AdminTheme.brandBlue),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }

  void _showEditTitleDialog(BuildContext context, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Title Text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title updated'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for editing a single CC question
class _CcQuestionCard extends StatelessWidget {
  final SurveyQuestion question;
  final SurveyQuestionsService questionsService;

  const _CcQuestionCard({
    required this.question,
    required this.questionsService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AdminTheme.brandBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.label,
                  style: AdminTheme.bodyXS(
                    color: const Color(0xFFFACF1F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: AdminTheme.brandBlue),
                onPressed: () => _showEditQuestionDialog(context),
                tooltip: 'Edit Question',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question Text
          Text(
            question.question,
            style: AdminTheme.bodyMedium(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Options
          ...question.options.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.circle_outlined, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value,
                    style: AdminTheme.bodySmall(color: Colors.grey.shade700),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade500),
                  onPressed: () => _showEditOptionDialog(context, entry.key, entry.value),
                  tooltip: 'Edit Option',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showEditQuestionDialog(BuildContext context) {
    final controller = TextEditingController(text: question.question);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${question.label}', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Question Text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              helperText: 'Edit the question text shown to survey respondents',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                questionsService.updateCcQuestion(question.id, question: controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question updated'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditOptionDialog(BuildContext context, int index, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Option ${index + 1}', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Option Text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              helperText: 'Note: Keep the number prefix (e.g., "1.") for proper scoring',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                questionsService.updateCcQuestionOption(question.id, index, controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Option updated'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Card widget for editing a single SQD question
class _SqdQuestionCard extends StatelessWidget {
  final int index;
  final SurveyQuestion question;
  final SurveyQuestionsService questionsService;

  const _SqdQuestionCard({
    required this.index,
    required this.question,
    required this.questionsService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AdminTheme.brandBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              question.label,
              style: AdminTheme.bodyXS(
                color: const Color(0xFFFACF1F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Question Text
          Expanded(
            child: Text(
              question.question,
              style: AdminTheme.bodyMedium(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Edit Button
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AdminTheme.brandBlue),
            onPressed: () => _showEditDialog(context),
            tooltip: 'Edit Question',
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: question.question);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${question.label}', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SQD questions use a Likert scale (Strongly Disagree to Strongly Agree + N/A). Only the question text can be edited.',
                        style: AdminTheme.bodyXS(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                questionsService.updateSqdQuestion(index, question: controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question updated'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Editor for User Profile configuration
class _ProfileConfigEditor extends StatelessWidget {
  final SurveyQuestionsService questionsService;

  const _ProfileConfigEditor({required this.questionsService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        _buildEditableField(
          context: context,
          label: 'Section Title',
          value: questionsService.profileSectionTitle,
          icon: Icons.title,
          onEdit: () => _showEditTextDialog(
            context,
            'Section Title',
            questionsService.profileSectionTitle,
            (newValue) => questionsService.updateProfileConfig('sectionTitle', newValue),
          ),
        ),
        const SizedBox(height: 24),

        // Client Types
        _buildEditableList(
          context: context,
          label: 'Client Types',
          items: questionsService.clientTypes,
          icon: Icons.people_outline,
          listKey: 'clientTypes',
        ),
        const SizedBox(height: 24),

        // Regions
        _buildEditableList(
          context: context,
          label: 'Regions',
          items: questionsService.regions,
          icon: Icons.map_outlined,
          listKey: 'regions',
        ),
        const SizedBox(height: 24),

        // Services
        _buildEditableList(
          context: context,
          label: 'Services Availed',
          items: questionsService.services,
          icon: Icons.assignment_outlined,
          listKey: 'services',
        ),
        const SizedBox(height: 24),

        // Labels
        _buildSubsection(
          context: context,
          label: 'Field Labels',
          children: [
            _buildEditableField(
              context: context,
              label: 'Client Type Label',
              value: questionsService.clientTypeLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Client Type Label',
                questionsService.clientTypeLabel,
                (newValue) => questionsService.updateProfileConfig('clientTypeLabel', newValue),
              ),
            ),
            _buildEditableField(
              context: context,
              label: 'Date Label',
              value: questionsService.dateLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Date Label',
                questionsService.dateLabel,
                (newValue) => questionsService.updateProfileConfig('dateLabel', newValue),
              ),
            ),
            _buildEditableField(
              context: context,
              label: 'Sex Label',
              value: questionsService.sexLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Sex Label',
                questionsService.sexLabel,
                (newValue) => questionsService.updateProfileConfig('sexLabel', newValue),
              ),
            ),
            _buildEditableField(
              context: context,
              label: 'Age Label',
              value: questionsService.ageLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Age Label',
                questionsService.ageLabel,
                (newValue) => questionsService.updateProfileConfig('ageLabel', newValue),
              ),
            ),
            _buildEditableField(
              context: context,
              label: 'Region Label',
              value: questionsService.regionLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Region Label',
                questionsService.regionLabel,
                (newValue) => questionsService.updateProfileConfig('regionLabel', newValue),
              ),
            ),
            _buildEditableField(
              context: context,
              label: 'Service Label',
              value: questionsService.serviceLabel,
              icon: Icons.label_outline,
              onEdit: () => _showEditTextDialog(
                context,
                'Service Label',
                questionsService.serviceLabel,
                (newValue) => questionsService.updateProfileConfig('serviceLabel', newValue),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminTheme.bodyXS(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AdminTheme.bodyMedium(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AdminTheme.brandBlue),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }

  Widget _buildEditableList({
    required BuildContext context,
    required String label,
    required List<String> items,
    required IconData icon,
    required String listKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AdminTheme.brandBlue),
              const SizedBox(width: 8),
              Text(label, style: AdminTheme.bodyMedium(color: Colors.black87, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddItemDialog(context, label, listKey),
                icon: Icon(Icons.add, size: 16, color: AdminTheme.brandBlue),
                label: Text('Add', style: AdminTheme.bodySmall(color: AdminTheme.brandBlue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) => _buildListItem(
            context: context,
            index: entry.key,
            value: entry.value,
            listKey: listKey,
          )),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required int index,
    required String value,
    required String listKey,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AdminTheme.brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}',
              style: AdminTheme.bodyXS(color: AdminTheme.brandBlue, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: AdminTheme.bodySmall(color: Colors.black87)),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade500),
            onPressed: () => _showEditListItemDialog(context, listKey, index, value),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
            onPressed: () => _showDeleteConfirmation(context, listKey, index, value),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  Widget _buildSubsection({
    required BuildContext context,
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AdminTheme.bodyMedium(color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _showEditTextDialog(BuildContext context, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updated successfully'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, String label, String listKey) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add New $label', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Enter new option',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                questionsService.addProfileListOption(listKey, controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Option added'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditListItemDialog(BuildContext context, String listKey, int index, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Option', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Option text',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                questionsService.updateProfileListOption(listKey, index, controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Option updated'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String listKey, int index, String value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Option?', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: Text(
          'Are you sure you want to delete "$value"?',
          style: AdminTheme.bodyMedium(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              questionsService.removeProfileListOption(listKey, index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Option deleted'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Editor for Suggestions configuration
class _SuggestionsConfigEditor extends StatelessWidget {
  final SurveyQuestionsService questionsService;

  const _SuggestionsConfigEditor({required this.questionsService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Configure the labels and placeholder text shown on the Suggestions section of the survey.',
                  style: AdminTheme.bodySmall(color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Title
        _buildEditableField(
          context: context,
          label: 'Section Title',
          value: questionsService.suggestionsSectionTitle,
          icon: Icons.title,
          onEdit: () => _showEditTextDialog(
            context,
            'Section Title',
            questionsService.suggestionsSectionTitle,
            (newValue) => questionsService.updateSuggestionsConfig('sectionTitle', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Suggestions Label
        _buildEditableField(
          context: context,
          label: 'Suggestions Label',
          value: questionsService.suggestionsLabel,
          icon: Icons.label_outline,
          onEdit: () => _showEditTextDialog(
            context,
            'Suggestions Label',
            questionsService.suggestionsLabel,
            (newValue) => questionsService.updateSuggestionsConfig('suggestionsLabel', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Suggestions Subtitle
        _buildEditableField(
          context: context,
          label: 'Suggestions Subtitle',
          value: questionsService.suggestionsSubtitle,
          icon: Icons.short_text,
          onEdit: () => _showEditTextDialog(
            context,
            'Suggestions Subtitle',
            questionsService.suggestionsSubtitle,
            (newValue) => questionsService.updateSuggestionsConfig('suggestionsSubtitle', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Suggestions Placeholder
        _buildEditableField(
          context: context,
          label: 'Suggestions Placeholder',
          value: questionsService.suggestionsPlaceholder,
          icon: Icons.text_fields,
          onEdit: () => _showEditTextDialog(
            context,
            'Suggestions Placeholder',
            questionsService.suggestionsPlaceholder,
            (newValue) => questionsService.updateSuggestionsConfig('suggestionsPlaceholder', newValue),
          ),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 24),

        // Email Label
        _buildEditableField(
          context: context,
          label: 'Email Label',
          value: questionsService.emailLabel,
          icon: Icons.email_outlined,
          onEdit: () => _showEditTextDialog(
            context,
            'Email Label',
            questionsService.emailLabel,
            (newValue) => questionsService.updateSuggestionsConfig('emailLabel', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Email Subtitle
        _buildEditableField(
          context: context,
          label: 'Email Subtitle',
          value: questionsService.emailSubtitle,
          icon: Icons.short_text,
          onEdit: () => _showEditTextDialog(
            context,
            'Email Subtitle',
            questionsService.emailSubtitle,
            (newValue) => questionsService.updateSuggestionsConfig('emailSubtitle', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Email Placeholder
        _buildEditableField(
          context: context,
          label: 'Email Placeholder',
          value: questionsService.emailPlaceholder,
          icon: Icons.text_fields,
          onEdit: () => _showEditTextDialog(
            context,
            'Email Placeholder',
            questionsService.emailPlaceholder,
            (newValue) => questionsService.updateSuggestionsConfig('emailPlaceholder', newValue),
          ),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 24),

        // Thank You Title
        _buildEditableField(
          context: context,
          label: 'Thank You Title',
          value: questionsService.thankYouTitle,
          icon: Icons.celebration_outlined,
          onEdit: () => _showEditTextDialog(
            context,
            'Thank You Title',
            questionsService.thankYouTitle,
            (newValue) => questionsService.updateSuggestionsConfig('thankYouTitle', newValue),
          ),
        ),
        const SizedBox(height: 16),

        // Thank You Message
        _buildEditableField(
          context: context,
          label: 'Thank You Message',
          value: questionsService.thankYouMessage,
          icon: Icons.message_outlined,
          onEdit: () => _showEditTextDialog(
            context,
            'Thank You Message',
            questionsService.thankYouMessage,
            (newValue) => questionsService.updateSuggestionsConfig('thankYouMessage', newValue),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AdminTheme.bodyXS(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AdminTheme.bodyMedium(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AdminTheme.brandBlue),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
        ],
      ),
    );
  }

  void _showEditTextDialog(BuildContext context, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: title.contains('Message') ? 4 : 1,
            decoration: InputDecoration(
              labelText: title,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updated successfully'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
