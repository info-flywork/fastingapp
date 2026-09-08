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
    } on Exception catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted());
  }
}
