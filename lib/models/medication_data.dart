class MedicationData {
  final String? medicationName;
  final int? totalDurationDays;
  final int? dailyFrequency;
  final String? mealContext;
  final int? specificOffsetMinutes;
  final String? specialInstructions;

  MedicationData({
    this.medicationName,
    this.totalDurationDays,
    this.dailyFrequency,
    this.mealContext,
    this.specificOffsetMinutes,
    this.specialInstructions,
  });

  factory MedicationData.fromJson(Map<String, dynamic> json) {
    return MedicationData(
      medicationName: json['medication_name'],
      totalDurationDays: json['total_duration_days'],
      dailyFrequency: json['daily_frequency'],
      mealContext: json['meal_context'],
      specificOffsetMinutes: json['specific_offset_minutes'],
      specialInstructions: json['special_instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medication_name': medicationName,
      'total_duration_days': totalDurationDays,
      'daily_frequency': dailyFrequency,
      'meal_context': mealContext,
      'specific_offset_minutes': specificOffsetMinutes,
      'special_instructions': specialInstructions,
    };
  }

  String getMealContextKorean() {
    switch (mealContext) {
      case 'pre_meal':
        return '식전';
      case 'post_meal':
        return '식후';
      case 'at_bedtime':
        return '취침 전';
      default:
        return '시간 무관';
    }
  }

  @override
  String toString() {
    return 'MedicationData(name: $medicationName, days: $totalDurationDays, '
        'frequency: $dailyFrequency, meal: $mealContext, offset: $specificOffsetMinutes)';
  }
}
