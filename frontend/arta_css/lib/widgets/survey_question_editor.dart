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
  String _selectedSection = 'CC'; // 'CC' or 'SQD'

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
                      'Question Editor',
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
              'Edit survey questions and options. Changes reflect immediately on the user survey.',
              style: AdminTheme.bodySmall(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Section Tabs
            Row(
              children: [
                _buildSectionTab('CC', "Citizen's Charter", Icons.article_outlined),
                const SizedBox(width: 12),
                _buildSectionTab('SQD', 'Service Quality', Icons.star_outline),
              ],
            ),
            const SizedBox(height: 20),

            // Questions List
            if (_selectedSection == 'CC')
              ...questionsService.ccQuestions.map(
                (q) => _CcQuestionCard(question: q, questionsService: questionsService),
              )
            else
              ...questionsService.sqdQuestions.asMap().entries.map(
                (entry) => _SqdQuestionCard(
                  index: entry.key,
                  question: entry.value,
                  questionsService: questionsService,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab(String id, String label, IconData icon) {
    final isSelected = _selectedSection == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedSection = id),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? AdminTheme.brandBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AdminTheme.brandBlue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
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
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, SurveyQuestionsService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Questions?', style: AdminTheme.headingSmall(color: Colors.black87)),
        content: Text(
          'This will reset all ${_selectedSection == 'CC' ? "Citizen's Charter" : "SQD"} questions to their default values. This action cannot be undone.',
          style: AdminTheme.bodyMedium(color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AdminTheme.bodyMedium(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedSection == 'CC') {
                service.resetCcToDefaults();
              } else {
                service.resetSqdToDefaults();
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_selectedSection == 'CC' ? "CC" : "SQD"} questions reset to defaults'),
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
