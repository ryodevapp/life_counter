/// 日付バリデーション
class DateValidator {
  DateValidator._();

  /// 指定した年月の日数を返す
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 年月日が有効かチェック
  static bool isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > daysInMonth(year, month)) return false;
    return true;
  }

  /// 生年月日として有効かチェック（未来日でない、1920年以降）
  static String? validateBirthDate(int year, int month, int day) {
    if (!isValidDate(year, month, day)) {
      return 'この日付は選べません';
    }
    final date = DateTime(year, month, day);
    if (date.isAfter(DateTime.now())) {
      return '今日までの日付を選べます';
    }
    if (year < 1920) {
      return '1920年以降の日付を選べます';
    }
    return null; // OK
  }
}
