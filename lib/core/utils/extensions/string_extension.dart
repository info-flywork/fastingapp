/// String yardımcı metodları.
extension StringExtension on String {
  bool get isNullOrEmpty => trim().isEmpty;

  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
