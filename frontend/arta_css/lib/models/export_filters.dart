/// Model to hold export filter options
class ExportFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? clientType;
  final String? region;
  final String? serviceAvailed;
  final int? minSatisfaction;
  final int? maxSatisfaction;
  final bool? ccAware; // true = Aware (cc0Rating >= 3), false = Not Aware

  const ExportFilters({
    this.startDate,
    this.endDate,
    this.clientType,
    this.region,
    this.serviceAvailed,
    this.minSatisfaction,
    this.maxSatisfaction,
    this.ccAware,
  });

  /// Create a copy with updated values
  ExportFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? clientType,
    String? region,
    String? serviceAvailed,
    int? minSatisfaction,
    int? maxSatisfaction,
    bool? ccAware,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearClientType = false,
    bool clearRegion = false,
    bool clearServiceAvailed = false,
    bool clearMinSatisfaction = false,
    bool clearMaxSatisfaction = false,
    bool clearCcAware = false,
  }) {
    return ExportFilters(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      clientType: clearClientType ? null : (clientType ?? this.clientType),
      region: clearRegion ? null : (region ?? this.region),
      serviceAvailed: clearServiceAvailed ? null : (serviceAvailed ?? this.serviceAvailed),
      minSatisfaction: clearMinSatisfaction ? null : (minSatisfaction ?? this.minSatisfaction),
      maxSatisfaction: clearMaxSatisfaction ? null : (maxSatisfaction ?? this.maxSatisfaction),
      ccAware: clearCcAware ? null : (ccAware ?? this.ccAware),
    );
  }

  /// Check if any filters are active
  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      clientType != null ||
      region != null ||
      serviceAvailed != null ||
      minSatisfaction != null ||
      maxSatisfaction != null ||
      ccAware != null;

  /// Get a summary of active filters for display
  String get filterSummary {
    final parts = <String>[];
    
    if (startDate != null && endDate != null) {
      parts.add('${_formatDate(startDate!)} - ${_formatDate(endDate!)}');
    } else if (startDate != null) {
      parts.add('From ${_formatDate(startDate!)}');
    } else if (endDate != null) {
      parts.add('Until ${_formatDate(endDate!)}');
    }
    
    if (clientType != null) parts.add(clientType!);
    if (region != null) parts.add(region!);
    if (serviceAvailed != null) parts.add(serviceAvailed!);
    
    if (minSatisfaction != null && maxSatisfaction != null) {
      parts.add('Rating: $minSatisfaction-$maxSatisfaction');
    } else if (minSatisfaction != null) {
      parts.add('Rating ≥ $minSatisfaction');
    } else if (maxSatisfaction != null) {
      parts.add('Rating ≤ $maxSatisfaction');
    }
    
    if (ccAware != null) {
      parts.add(ccAware! ? 'CC Aware' : 'CC Not Aware');
    }
    
    return parts.isEmpty ? 'All Data' : parts.join(' • ');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (clientType != null) count++;
    if (region != null) count++;
    if (serviceAvailed != null) count++;
    if (minSatisfaction != null || maxSatisfaction != null) count++;
    if (ccAware != null) count++;
    return count;
  }

  /// Empty filters
  static const ExportFilters none = ExportFilters();

  /// Quick presets
  static ExportFilters lastWeek() {
    final now = DateTime.now();
    return ExportFilters(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  static ExportFilters lastMonth() {
    final now = DateTime.now();
    return ExportFilters(
      startDate: DateTime(now.year, now.month - 1, now.day),
      endDate: now,
    );
  }

  static ExportFilters lastQuarter() {
    final now = DateTime.now();
    return ExportFilters(
      startDate: DateTime(now.year, now.month - 3, now.day),
      endDate: now,
    );
  }

  static ExportFilters thisYear() {
    final now = DateTime.now();
    return ExportFilters(
      startDate: DateTime(now.year, 1, 1),
      endDate: now,
    );
  }
}
