/// Kilo hedefine ilerleme (0–1), hedefin yönüne göre (verme / alma).
/// Başlangıç = hedef (koruma) ise hedefe 1 kg yakınken tamam sayılır;
/// önceden hep %0 görünüyordu.
double weightProgressOf({double? start, double? goal, double? current}) {
  if (start == null || goal == null || current == null) return 0;
  if ((start - goal).abs() < 0.05) {
    return (current - goal).abs() <= 1 ? 1 : 0;
  }
  return ((current - start) / (goal - start)).clamp(0.0, 1.0);
}
