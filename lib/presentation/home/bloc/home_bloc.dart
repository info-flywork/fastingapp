import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/data/model/user/home_summary.dart';
import 'package:fastingapp/domain/hunger/hunger_store.dart';
import 'package:fastingapp/domain/revenue_cat/revenue_cat_service.dart';
import 'package:fastingapp/domain/trackers/steps_store.dart';
import 'package:fastingapp/domain/trackers/water_store.dart';
import 'package:fastingapp/domain/trackers/weight_store.dart';
import 'package:fastingapp/domain/user/user_repository.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_bloc.dart';
import 'package:fastingapp/presentation/auth/bloc/auth_state.dart';
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
    on<HomeMetricsOptimistic>(_onMetricsOptimistic);
    on<HomeChallengeUpdated>(_onChallengeUpdated);
    on<HomePremiumTapped>(_onPremiumTapped);
    getIt<StepsStore>().addListener(_onTrackerStoreChanged);
    getIt<WaterStore>().addListener(_onTrackerStoreChanged);
    getIt<WeightStore>().addListener(_onTrackerStoreChanged);
    getIt<HungerStore>().addListener(_onTrackerStoreChanged);
  }

  final UserRepository _userRepository;

  /// [HomeWeightOptimistic] state'i sunucudan bağımsız değiştirdi.
  bool _locallyEdited = false;

  /// Uçuşta bir özet isteği varken gelen yenilemeler tek bir "sonra bir kez
  /// daha" isteğine katlanır: eski yanıt yenisini ezemez, istek yağmuru olmaz.
  bool _inFlight = false;
  bool _again = false;

  /// [HomeCleared] (çıkış / hesap değişimi) sonrası dönen eski yanıt yok sayılır.
  int _epoch = 0;

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    if (_inFlight) {
      _again = true;
      return;
    }
    _inFlight = true;
    try {
      do {
        _again = false;
        await _load(emit);
      } while (_again && !emit.isDone);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _load(Emitter<HomeState> emit) async {
    final epoch = _epoch;
    // Yenilemede mevcut UI kalsın; ilk açılışta shimmer iskelet.
    var keepLoaded = state is HomeLoaded;
    if (!keepLoaded) {
      // Bugünün saklı özeti varsa iskelet yerine hemen o çizilir; ağ yanıtı
      // gelince sessizce yenilenir. Oruç cubit'e de yazılır — sayaçlar
      // startedAt'ten hesaplanır, uzak özet gelene kadar boş ekran kalmaz.
      final auth = getIt<AuthBloc>().state;
      final cached = auth is AuthAuthenticated
          ? _userRepository.cachedSummary(auth.user.id)
          : null;
      if (cached != null) {
        getIt<FastingSessionCubit>().applyFromSummary(
          fast: cached.activeFast,
          eatingWindow: cached.eatingWindow,
          plan: cached.plan,
          serverTime: cached.serverTime,
        );
        emit(
          HomeLoaded(
            user: cached.user,
            progress: cached.progress,
            isPremium: cached.user.isPremium,
            summary: cached,
          ),
        );
        keepLoaded = true;
      } else {
        emit(const HomeLoading());
      }
    }
    try {
      // Tek çağrı: kullanıcı, ilerleme ve kart verileri.
      final generation = DataSync.generation;
      final summary = await _userRepository.getSummary();
      if (epoch != _epoch || emit.isDone) return;
      // İstek sürerken bir yazma oldu: yanıt eski (ör. yeni başlatılan
      // oruç kaybolup geri gelirdi). Yazmanın tetiklediği yenileme kuyrukta.
      if (generation != DataSync.generation) {
        _again = true;
        return;
      }
      final shown = _overlayPending(summary);
      getIt<FastingSessionCubit>().applyFromSummary(
        fast: summary.activeFast,
        eatingWindow: summary.eatingWindow,
        plan: summary.plan,
        serverTime: summary.serverTime,
      );
      // Premium'un tek kaynağı sunucu; profil / oruç ekranı aynı değeri görür.
      getIt<RevenueCatService>().applyServerPremium(summary.user.isPremium);
      // Veri değişmediyse kartlar yeniden kurulmasın (özet Equatable değil).
      // Ekrandaki state yerelde değiştirildiyse (iyimser kilo) sunucu yanıtı
      // aynı olsa da yeniden çizilir; yoksa hata sonrası yanlış değer kalırdı.
      if (keepLoaded &&
          _userRepository.lastSummaryUnchanged &&
          !_locallyEdited) {
        return;
      }
      _locallyEdited = false;
      emit(
        HomeLoaded(
          user: shown.user,
          progress: shown.progress,
          isPremium: shown.user.isPremium,
          summary: shown,
        ),
      );
    } on Object catch (e) {
      // Ayrıştırma hataları (TypeError, StateError) da sonsuz shimmer bırakmasın.
      if (keepLoaded || epoch != _epoch || emit.isDone) return;
      emit(HomeError(message: errorMessageOf(e)));
    }
  }

  void _onCleared(HomeCleared event, Emitter<HomeState> emit) {
    _epoch++;
    _again = false;
    emit(const HomeInitial());
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    add(const HomeStarted());
  }

  /// Sunucunun henüz onaylamadığı su / adım / hedef her özetin üstüne
  /// biner ([WaterStore], [StepsStore]): yoldaki eski özet sayıyı geri alamaz.
  HomeSummary _overlayPending(HomeSummary summary) {
    final steps = getIt<StepsStore>();
    final water = getIt<WaterStore>();
    final weight = getIt<WeightStore>();
    final hunger = getIt<HungerStore>().pendingToday;
    final today = DateTime.now();
    return summary.copyWith(
      hungerPhysical: hunger?.physical,
      hungerEmotional: hunger?.emotional,
      waterMl: water.pendingTotal(today),
      waterGoalMl: water.pendingGoal,
      steps: steps.pendingSteps(today),
      stepsGoal: steps.pendingGoal,
      weightCurrentKg: weight.pendingKg,
      weightGoalKg: weight.pendingGoal,
    );
  }

  /// Detay ekranlarındaki onaylanmamış değer ana sayfa kartına anında yansır.
  void _onTrackerStoreChanged() {
    final steps = getIt<StepsStore>();
    final water = getIt<WaterStore>();
    final weight = getIt<WeightStore>();
    final hunger = getIt<HungerStore>().pendingToday;
    final today = DateTime.now();
    final event = HomeMetricsOptimistic(
      hungerPhysical: hunger?.physical,
      hungerEmotional: hunger?.emotional,
      waterMl: water.pendingTotal(today),
      waterGoalMl: water.pendingGoal,
      steps: steps.pendingSteps(today),
      stepsGoal: steps.pendingGoal,
      weightKg: weight.pendingKg,
      weightGoalKg: weight.pendingGoal,
    );
    if (event.props.every((v) => v == null)) return;
    add(event);
  }

  void _onMetricsOptimistic(
    HomeMetricsOptimistic event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) return;
    final summary = current.summary;
    if (summary == null) return;
    _locallyEdited = true;
    emit(
      HomeLoaded(
        user: current.user,
        progress: current.progress,
        isPremium: current.isPremium,
        summary: summary.copyWith(
          waterMl: event.waterMl,
          waterGoalMl: event.waterGoalMl,
          steps: event.steps,
          stepsGoal: event.stepsGoal,
          weightCurrentKg: event.weightKg,
          weightGoalKg: event.weightGoalKg,
          hungerPhysical: event.hungerPhysical,
          hungerEmotional: event.hungerEmotional,
        ),
      ),
    );
  }

  void _onChallengeUpdated(
    HomeChallengeUpdated event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) return;
    final summary = current.summary;
    if (summary == null) return;
    _locallyEdited = true;
    emit(
      HomeLoaded(
        user: current.user,
        progress: current.progress,
        isPremium: current.isPremium,
        summary: summary.copyWith(featuredChallenge: event.challenge),
      ),
    );
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
