import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home ekranı iş akışı. İnce BLoC: event → repository → state. (Doküman 14)
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._userRepository) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomePremiumTapped>(_onPremiumTapped);
  }

  final UserRepository _userRepository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      // Tek çağrı: kullanıcı, ilerleme ve kart verileri.
      final summary = await _userRepository.getSummary();
      emit(
        HomeLoaded(
          user: summary.user,
          progress: summary.progress,
          isPremium: summary.user.isPremium,
          summary: summary,
        ),
      );
    } on Exception catch (e) {
      emit(
        HomeError(message: e is NetworkException ? e.message : e.toString()),
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
