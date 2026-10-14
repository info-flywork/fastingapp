import 'package:fastingapp/presentation/auth/onboard/starting_point/bloc/starting_point_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<StartingPointState> _apply(
  StartingPointBloc bloc,
  StartingPointEvent event,
) async {
  bloc.add(event);
  await Future<void>.delayed(Duration.zero);
  return bloc.state;
}

void main() {
  test('BMI 17.5 alt sınır: 170 cm için 51 kg', () async {
    expect(StartingPointState.minGoalKgFor(170), 51);
    final bloc = StartingPointBloc();
    final s = await _apply(bloc, const StartingPointGoalWeightChanged(40));
    expect(s.goalWeightKg, 51);
    expect(s.isGoalSafe, isTrue);
    await bloc.close();
  });

  test(
    'kilo vermede hedef mevcut kiloyu geçmez, diğer hedeflerde geçer',
    () async {
      final lose = StartingPointBloc();
      expect(
        (await _apply(
          lose,
          const StartingPointGoalWeightChanged(80),
        )).goalWeightKg,
        70,
      );
      await lose.close();
      final other = StartingPointBloc(allowGoalAboveCurrent: true);
      expect(
        (await _apply(
          other,
          const StartingPointGoalWeightChanged(80),
        )).goalWeightKg,
        80,
      );
      await other.close();
    },
  );

  test('mevcut kilo zaten çok düşükse devam edilemez', () async {
    final bloc = StartingPointBloc();
    final s = await _apply(bloc, const StartingPointWeightChanged(45));
    expect(s.goalWeightKg, 45);
    expect(s.isGoalSafe, isFalse);
    await bloc.close();
  });
}
