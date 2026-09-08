/// İlerleme verisi iş kuralı hataları.
final class ProgressException implements Exception {
  const ProgressException(this.message);

  factory ProgressException.notFound() =>
      const ProgressException('İlerleme verisi bulunamadı.');

  final String message;

  @override
  String toString() => 'ProgressException: $message';
}
