import 'package:fastingapp/core/utils/weight_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kilo verme ve alma hedefinde yön doğru', () {
    expect(weightProgressOf(start: 80, goal: 70, current: 75), 0.5);
    expect(weightProgressOf(start: 60, goal: 70, current: 65), 0.5);
    expect(weightProgressOf(start: 60, goal: 70, current: 58), 0);
  });

  test('başlangıç = hedef: hedefe 1 kg yakınsa tamam', () {
    expect(weightProgressOf(start: 70, goal: 70, current: 70.5), 1);
    expect(weightProgressOf(start: 70, goal: 70, current: 73), 0);
  });

  test('eksik veri: 0', () {
    expect(weightProgressOf(start: null, goal: 70, current: 70), 0);
  });
}
