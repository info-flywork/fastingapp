import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/bloc/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Home ekranı iş akışı. İnce BLoC: event → repository → state. (Doküman 14)
///
/// Splash sırasında ısıtılır (singleton); ana sayfa açılınca shimmer
/// mümkün olduğunca görünmez.
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._userRepository) : super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeCleared>(_onCleared);
    on<HomeRefreshRequested>(_onRefreshRequested);
    on<HomePremiumTapped>(_onPremiumTapped);
  }

  final UserRepository _userRepository;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    // Splash + route aynı anda tetiklerse çift istek olmasın.
    if (state is HomeLoading) return;

    // Yenilemede mevcut UI kalsın; ilk açılışta shimmer iskelet.
    final keepLoaded = state is HomeLoaded;
    if (!keepLoaded) emit(const HomeLoading());
    try {
      // Tek çağrı: kullanıcı, ilerleme ve kart verileri.
      final summary = await _userRepository.getSummary();
      getIt<FastingSessionCubit>().applyFromSummary(
        fast: summary.activeFast,
        eatingWindow: summary.eatingWindow,
        plan: summary.plan,
        serverTime: summary.serverTime,
      );
      // Premium'un tek kaynağı sunucu; profil / oruç ekranı aynı değeri görür.
      getIt<RevenueCatService>().isPremium.value = summary.user.isPremium;
      emit(
        HomeLoaded(
          user: summary.user,
          progress: summary.progress,
          isPremium: summary.user.isPremium,
          summary: summary,
        ),
      );
    } on Exception catch (e) {
      if (keepLoaded) return;
      emit(
        HomeError(message: e is NetworkException ? e.message : e.toString()),
      );
    }
  }

  void _onCleared(HomeCleared event, Emitter<HomeState> emit) {
    emit(const HomeInitial());
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted());
  }

  /// RevenueCat paywall; premium olduysa özet yenilenir (bekleyen premium
  /// plan sunucuda etkinleşmiş olabilir).
  Future<void> _onPremiumTapped(
    HomePremiumTapped event,
    Emitter<HomeState> emit,
  ) async {
    final premium = await getIt<RevenueCatService>().presentPaywall();
    if (premium) add(const HomeStarted());
  }
}
