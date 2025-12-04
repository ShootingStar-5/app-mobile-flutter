class MedicationData {
  final String? medicationName;
  final int? totalDurationDays;
  final int? dailyFrequency;
  final String? mealContext;
  final int? specificOffsetMinutes;
  final String? specialInstructions;
  final List<String>? specificMeals; // 'breakfast', 'lunch', 'dinner' 중 언급된 것들

  MedicationData({
    this.medicationName,
    this.totalDurationDays,
    this.dailyFrequency,
    this.mealContext,
    this.specificOffsetMinutes,
    this.specialInstructions,
    this.specificMeals,
  });

  factory MedicationData.fromJson(Map<String, dynamic> json) {
    return MedicationData(
      medicationName: json['medication_name'],
      totalDurationDays: json['total_duration_days'],
      dailyFrequency: json['daily_frequency'],
      mealContext: json['meal_context'],
      specificOffsetMinutes: json['specific_offset_minutes'],
      specialInstructions: json['special_instructions'],
      specificMeals: json['specific_meals'] != null
          ? List<String>.from(json['specific_meals'])
          : null,
    );
  }

  /// stt_text에서 식사 시간 파싱해서 MedicationData 생성
  factory MedicationData.fromJsonWithSttParsing(Map<String, dynamic> json, String? sttText) {
    List<String>? parsedMeals;

    if (sttText != null && sttText.isNotEmpty) {
      parsedMeals = _parseMealsFromText(sttText);
    }

    return MedicationData(
      medicationName: json['medication_name'],
      totalDurationDays: json['total_duration_days'],
      dailyFrequency: json['daily_frequency'],
      mealContext: json['meal_context'],
      specificOffsetMinutes: json['specific_offset_minutes'],
      specialInstructions: json['special_instructions'],
      specificMeals: parsedMeals,
    );
  }

  /// 텍스트에서 식사 시간 키워드 추출
  static List<String>? _parseMealsFromText(String text) {
    final meals = <String>[];

    // 아침 키워드
    if (text.contains('아침')) {
      meals.add('breakfast');
    }
    // 점심 키워드
    if (text.contains('점심')) {
      meals.add('lunch');
    }
    // 저녁 키워드
    if (text.contains('저녁')) {
      meals.add('dinner');
    }

    return meals.isEmpty ? null : meals;
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
