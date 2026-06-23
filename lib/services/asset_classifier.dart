/// Keyword-based document classification service.
///
/// Matches the asset name against Arabic keyword lists to determine
/// the sensitivity classification (HIGH / MEDIUM / LOW).
///
/// When the backend is ready, this logic can be moved server-side.
import '../data/models/asset_model.dart';

class AssetClassifier {
  AssetClassifier._();

  // ── HIGH sensitivity keywords ──────────────────────────────────────
  static const List<String> _highKeywords = [
    'تقسيم الإرث',
    'تقسيم التركة',
    'حصر الورثة',
    'وثيقة إرث',
    'شهادة وفاة',
    'مبلغ مستحق',
    'سداد دين',
    'فدية صيام',
    'زكاة فطرة',
    'قضاء',
    'كفارات',
    'إقرار مديونية',
    'إقرار أمانات',
    'وثيقة وصية',
    'وصية شرعية',
    'إقرار زكاة',
    'إقرار كفارات',
    'إقرار فدية',
  ];

  // ── MEDIUM sensitivity keywords ───────────────────────────────────
  static const List<String> _mediumKeywords = [
    'رقم هوية',
    'رقم الهوية الوطنية',
    'هوية وطنية',
    'بطاقة الهوية',
    'رقم السجل المدني',
    'بيانات الهوية',
    'إثبات هوية',
    'حساب بنكي',
    'رقم الحساب',
    'بطاقة بنكية',
    'بطاقة ائتمان',
    'بطاقة مصرفية',
    'بيانات الحساب',
    'كشف حساب',
    'رقم الآيبان',
    'IBAN',
    'تحويل بنكي',
    'وثيقة رسمية',
    'وثيقة قانونية',
    'عقد رسمي',
    'عقد بيع',
    'عقد إيجار',
    'اتفاقية',
    'إقرار قانوني',
    'تفويض رسمي',
    'توكيل شرعي',
    'وكالة شرعية',
    'صك ملكية',
    'رقم الصك',
    'العقار',
    'عقار',
    'ملكية عقار',
    'أرض',
    'قطعة أرض',
    'ملكية الأرض',
    'وصية',
    'وصية شرعية',
    'تركة مالية',
    'تركة عقارية',
    'مجمع تجاري',
    'عقد شراكة',
  ];

  // ── LOW sensitivity keywords ──────────────────────────────────────
  static const List<String> _lowKeywords = [
    'فاتورة كهرباء',
    'فاتورة ماء',
    'فاتورة هاتف',
    'وصل استلام',
    'نموذج طلب',
    'تقرير شهري',
    'إيصال دفع',
    'شهادة حضور',
    'مراسلة بريدية',
    'مذكرة داخلية',
  ];

  /// Classify a document based on its name.
  ///
  /// Checks HIGH first, then MEDIUM, then LOW. If no match is found,
  /// defaults to [AssetClassification.low].
  static AssetClassification classifyByName(String assetName) {
    final name = assetName.trim();

    for (final keyword in _highKeywords) {
      if (name.contains(keyword)) {
        return AssetClassification.high;
      }
    }

    for (final keyword in _mediumKeywords) {
      if (name.contains(keyword)) {
        return AssetClassification.medium;
      }
    }

    for (final keyword in _lowKeywords) {
      if (name.contains(keyword)) {
        return AssetClassification.low;
      }
    }

    // Default: if no keyword matched, classify as LOW
    return AssetClassification.low;
  }

  /// Returns a human-readable label for the classification level.
  static String labelFor(AssetClassification c) {
    switch (c) {
      case AssetClassification.high:
        return 'High';
      case AssetClassification.medium:
        return 'Medium';
      case AssetClassification.low:
        return 'Low';
    }
  }
}
