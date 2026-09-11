import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';
import 'package:fastingapp/domain/progress/progress_repository.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home ekranı iş akışı. İnce BLoC: event → repository → state. (Doküman 14)
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._userRepository, this._progressRepository)
    : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomePremiumTapped>(_onPremiumTapped);
  }

  final UserRepository _userRepository;
  final ProgressRepository _progressRepository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      final user = await _userRepository.getCurrentUser();
      final progress = await _progressRepository.getProgress();
      final isPremium = await _userRepository.isPremium();

      emit(HomeLoaded(user: user, progress: progress, isPremium: isPremium));
    } on Exception {
      // Onboarding sonrası / API yokken home UI'ı yine göstersin.
      emit(
        const HomeLoaded(
          user: User(name: 'Squish'),
          progress: UserProgress(streakDays: 3),
          isPremium: false,
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted());
  }

  void _onPremiumTapped(HomePremiumTapped event, Emitter<HomeState> emit) {
    // TODO(team): RevenueCat paywall aç veya premium rotasına yönlendir.
  }
}
