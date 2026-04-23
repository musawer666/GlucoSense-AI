/// BMI from height (cm) and weight (kg).
double? computeBmi({required int heightCm, required double weightKg}) {
  if (heightCm <= 0 || weightKg <= 0) return null;
  final hM = heightCm / 100.0;
  if (hM <= 0) return null;
  return weightKg / (hM * hM);
}

/// Short label for badge (design: HEALTHY RANGE, etc.).
String bmiRangeLabel(double bmi) {
  if (bmi < 18.5) return 'UNDERWEIGHT';
  if (bmi < 25) return 'HEALTHY RANGE';
  if (bmi < 30) return 'OVERWEIGHT';
  return 'OBESE RANGE';
}
