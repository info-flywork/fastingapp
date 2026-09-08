import 'package:bloc_test/bloc_test.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/domain/progress/progress_repository.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  late UserRepository userRepository;
  late ProgressRepository progressRepository;

  setUp(() {
    userRepository = _MockUserRepository();
    progressRepository = _MockProgressRepository();
  });

  HomeBloc buildBloc() => HomeBloc(userRepository, progressRepository);

  group('HomeBloc', () {
    blocTest<HomeBloc, HomeState>(
      'HomeStarted → [HomeLoading, HomeLoaded]',
      setUp: () {
        when(userRepository.getCurrentUser).thenAnswer(
          (_) async => const User(name: 'Test'),
        );
        when(progressRepository.getProgress).thenAnswer(
          (_) async => const UserProgress(level: 2),
        );
        when(userRepository.isPremium).thenAnswer((_) async => false);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const HomeStarted()),
      expect: () => [
        const HomeLoading(),
        const HomeLoaded(
          user: User(name: 'Test'),
          progress: UserProgress(level: 2),
          isPremium: false,
        ),
      ],
    );
  });
}
