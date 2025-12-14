import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/export_filters.dart';
// HTTP services for cross-platform compatibility (no Firebase dependency)
import '../services/feedback_service_http.dart';
import '../services/export_service.dart';
import '../services/export_settings_service.dart';
import '../services/audit_log_service_http.dart';
import '../services/auth_services_http.dart';
import '../screens/admin/admin_screens.dart' show brandBlue, brandRed;
import 'package:provider/provider.dart';

/// Export type enum
enum ExportType { csv, json, pdfCompliance, pdfDetailed }

/// Dialog for selecting export filters and format
class ExportFilterDialog extends StatefulWidget {
  final FeedbackServiceHttp feedbackService;
  final ExportType? preselectedType;

  const ExportFilterDialog({
    super.key,
    required this.feedbackService,
    this.preselectedType,
  });

  @override
  State<ExportFilterDialog> createState() => _ExportFilterDialogState();
}

class _ExportFilterDialogState extends State<ExportFilterDialog> {
  ExportFilters _filters = ExportFilters.none;
  ExportType _selectedType = ExportType.csv;
  bool _isExporting = false;
  
  // Quick date presets
  String? _selectedPreset;
  
  // Controllers for custom date range
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientTypes = widget.feedbackService.getUniqueClientTypes();
    final regions = widget.feedbackService.getUniqueRegions();
    final services = widget.feedbackService.getUniqueServices();
    final dateRange = widget.feedbackService.getFeedbackDateRange();
    
    // Get filtered count for preview
    final filteredData = widget.feedbackService.exportFilteredFeedbacks(_filters);
    final totalCount = widget.feedbackService.feedbacks.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: brandBlue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Export Data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${filteredData.length} of $totalCount records selected',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Export Format Selection
                    _buildSection(
                      'Export Format',
                      Icons.description,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFormatChip(ExportType.csv, 'CSV', Icons.table_chart, Colors.green),
                          _buildFormatChip(ExportType.json, 'JSON', Icons.code, Colors.blue),
                          _buildFormatChip(ExportType.pdfCompliance, 'PDF Report', Icons.picture_as_pdf, Colors.red),
                          _buildFormatChip(ExportType.pdfDetailed, 'PDF Analysis', Icons.analytics, Colors.purple),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Date Range Section
                    _buildSection(
                      'Date Range',
                      Icons.date_range,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick presets
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildPresetChip('All Time', null),
                              _buildPresetChip('Last 7 Days', 'week'),
                              _buildPresetChip('Last 30 Days', 'month'),
                              _buildPresetChip('Last 90 Days', 'quarter'),
                              _buildPresetChip('This Year', 'year'),
                              _buildPresetChip('Custom', 'custom'),
                            ],
                          ),
                          
                          // Custom date pickers (shown when 'Custom' is selected)
                          if (_selectedPreset == 'custom') ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    'Start Date',
                                    _customStartDate,
                                    dateRange.$1,
                                    (date) {
                                      setState(() {
                                        _customStartDate = date;
                                        _updateFiltersFromCustomDates();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    'End Date',
                                    _customEndDate,
                                    dateRange.$2,
                                    (date) {
                                      setState(() {
                                        _customEndDate = date;
                                        _updateFiltersFromCustomDates();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          // Show available date range hint
                          if (dateRange.$1 != null && dateRange.$2 != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Available data: ${_formatDate(dateRange.$1!)} - ${_formatDate(dateRange.$2!)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Filters Section
                    _buildSection(
                      'Filters',
                      Icons.filter_alt,
                      trailing: _filters.hasActiveFilters
                          ? TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear All'),
                              style: TextButton.styleFrom(
                                foregroundColor: brandRed,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                            )
                          : null,
                      child: Column(
                        children: [
                          // Row 1: Client Type and Region
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownFilter(
                                  'Client Type',
                                  _filters.clientType,
                                  clientTypes,
                                  (value) => setState(() {
                                    _filters = value == null 
                                        ? _filters.copyWith(clearClientType: true)
                                        : _filters.copyWith(clientType: value);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownFilter(
                                  'Region',
                                  _filters.region,
                                  regions,
                                  (value) => setState(() {
                                    _filters = value == null 
                                        ? _filters.copyWith(clearRegion: true)
                                        : _filters.copyWith(region: value);
                                  }),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Row 2: Service Availed
                          _buildDropdownFilter(
                            'Service Availed',
                            _filters.serviceAvailed,
                            services,
                            (value) => setState(() {
                              _filters = value == null 
                                  ? _filters.copyWith(clearServiceAvailed: true)
                                  : _filters.copyWith(serviceAvailed: value);
                            }),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Row 3: Satisfaction Rating and CC Awareness
                          Row(
                            children: [
                              Expanded(
                                child: _buildRatingFilter(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCcAwarenessFilter(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer with actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Filter summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filters.filterSummary,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (_filters.hasActiveFilters)
                          Text(
                            '${_filters.activeFilterCount} filter(s) applied',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Cancel button
                  OutlinedButton(
                    onPressed: _isExporting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  // Export button
                  ElevatedButton.icon(
                    onPressed: _isExporting || filteredData.isEmpty ? null : _performExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: Text(_isExporting ? 'Exporting...' : 'Export ${filteredData.length} Records'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildSection(String title, IconData icon, {required Widget child, Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: brandBlue),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: brandBlue,
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildFormatChip(ExportType type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedType = type),
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildPresetChip(String label, String? preset) {
    final isSelected = _selectedPreset == preset;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedPreset = preset;
          _applyDatePreset(preset);
        });
      },
      label: Text(label),
      selectedColor: brandBlue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, DateTime? initialDate, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? initialDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          value != null ? _formatDate(value) : 'Select date',
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String? currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All', style: TextStyle(color: Colors.grey)),
        ),
        ...options.map((option) => DropdownMenuItem<String>(
          value: option,
          child: Text(
            option,
            overflow: TextOverflow.ellipsis,
          ),
        )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Satisfaction Rating',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Spacer(),
            if (_filters.selectedRatings != null && _filters.selectedRatings!.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(clearSelectedRatings: true);
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 20),
                ),
                child: const Text('Select All', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _filters.isRatingSelected(rating);
            final hasFilter = _filters.selectedRatings != null && _filters.selectedRatings!.isNotEmpty;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _filters = _filters.toggleRating(rating);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected && hasFilter
                        ? Colors.amber.shade100
                        : isSelected && !hasFilter
                            ? Colors.grey.shade50
                            : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected && hasFilter
                          ? Colors.amber
                          : Colors.grey.shade300,
                      width: isSelected && hasFilter ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: isSelected && hasFilter
                              ? Colors.amber
                              : isSelected && !hasFilter
                                  ? Colors.amber.shade300
                                  : Colors.grey,
                        ),
                        Text(
                          '$rating',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected && hasFilter
                                ? Colors.amber.shade800
                                : isSelected && !hasFilter
                                    ? Colors.grey.shade600
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap ratings to select/deselect individually',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildCcAwarenessFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CC Awareness',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildAwarenessChip('All', null),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAwarenessChip('Aware', true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAwarenessChip('Not Aware', false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAwarenessChip(String label, bool? value) {
    final isSelected = _filters.ccAware == value;
    return InkWell(
      onTap: () {
        setState(() {
          if (value == null) {
            _filters = _filters.copyWith(clearCcAware: true);
          } else {
            _filters = _filters.copyWith(ccAware: value);
          }
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandBlue.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? brandBlue : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? brandBlue : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  void _applyDatePreset(String? preset) {
    ExportFilters newFilters;
    
    switch (preset) {
      case 'week':
        newFilters = ExportFilters.lastWeek();
        break;
      case 'month':
        newFilters = ExportFilters.lastMonth();
        break;
      case 'quarter':
        newFilters = ExportFilters.lastQuarter();
        break;
      case 'year':
        newFilters = ExportFilters.thisYear();
        break;
      case 'custom':
        // Keep current filters, just show date pickers
        return;
      default:
        // All time - clear date filters
        newFilters = _filters.copyWith(clearStartDate: true, clearEndDate: true);
    }
    
    // Preserve other filters
    _filters = _filters.copyWith(
      startDate: newFilters.startDate,
      endDate: newFilters.endDate,
      clearStartDate: preset == null,
      clearEndDate: preset == null,
    );
  }

  void _updateFiltersFromCustomDates() {
    _filters = _filters.copyWith(
      startDate: _customStartDate,
      endDate: _customEndDate,
      clearStartDate: _customStartDate == null,
      clearEndDate: _customEndDate == null,
    );
  }

  void _clearFilters() {
    setState(() {
      _filters = ExportFilters.none;
      _selectedPreset = null;
      _customStartDate = null;
      _customEndDate = null;
    });
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _performExport() async {
    setState(() => _isExporting = true);
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    // Capture providers before async gap
    AuditLogServiceHttp? auditService;
    AuthServiceHttp? authService;
    try {
      auditService = context.read<AuditLogServiceHttp>();
      authService = context.read<AuthServiceHttp>();
    } catch (_) {
      // Services might not be available
    }
    
    try {
      final data = widget.feedbackService.exportFilteredFeedbacks(_filters);
      
      if (data.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No data matches the selected filters'), backgroundColor: Colors.orange),
        );
        setState(() => _isExporting = false);
        return;
      }
      
      String filename;
      String formatLabel;
      
      switch (_selectedType) {
        case ExportType.csv:
          filename = await ExportService.exportFeedbackCsv('ARTA_Feedback_Data', data);
          formatLabel = 'CSV';
          break;
        case ExportType.json:
          filename = await ExportService.exportFeedbackJson('ARTA_Feedback_Data', data);
          formatLabel = 'JSON';
          break;
        case ExportType.pdfCompliance:
          filename = await ExportService.exportPdf('ARTA_Compliance_Report', data);
          formatLabel = 'PDF Report';
          break;
        case ExportType.pdfDetailed:
          filename = await ExportService.exportDetailedAnalysisPdf('ARTA_Detailed_Analysis', data);
          formatLabel = 'PDF Analysis';
          break;
      }
      
      // Log the export action
      if (auditService != null) {
        try {
          auditService.logFeedbackExported(
            actor: authService?.currentUser,
            exportFormat: formatLabel,
            recordCount: data.length,
            filters: {
              'summary': _filters.filterSummary,
              'dateRange': _filters.startDate != null || _filters.endDate != null
                  ? '${_filters.startDate?.toIso8601String() ?? 'start'} - ${_filters.endDate?.toIso8601String() ?? 'now'}'
                  : null,
              'clientType': _filters.clientType,
              'region': _filters.region,
              'serviceAvailed': _filters.serviceAvailed,
            },
          );
        } catch (_) {
          // Audit logging is optional, don't fail the export
        }
      }
      
      navigator.pop();
      
      // Show success message with location info for native platforms
      String successMessage = '$formatLabel exported: $filename (${data.length} records)';
      if (!kIsWeb) {
        final exportPath = ExportSettingsService.instance.exportPath;
        if (exportPath.isNotEmpty) {
          successMessage = '$formatLabel exported to:\n$exportPath';
        }
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: !kIsWeb ? SnackBarAction(
            label: 'Open Folder',
            textColor: Colors.white,
            onPressed: () {
              ExportSettingsService.instance.openExportDirectory();
            },
          ) : null,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

/// Helper function to show the export dialog
Future<void> showExportFilterDialog(
  BuildContext context,
  FeedbackServiceHttp feedbackService, {
  ExportType? preselectedType,
}) {
  return showDialog(
    context: context,
    builder: (context) => ExportFilterDialog(
      feedbackService: feedbackService,
      preselectedType: preselectedType,
    ),
  );
}
