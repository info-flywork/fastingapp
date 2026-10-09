import 'package:equatable/equatable.dart';
import 'package:fastingapp/domain/fasting/fasting_repository.dart';

final class FastingSessionState extends Equatable {
  const FastingSessionState({
    this.isLoading = false,
    this.errorMessage,
    this.fast,
    this.eatingWindow,
    this.plan,
    this.fetchedAt,
    this.clockOffset = Duration.zero,
    this.bodyStages = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final ActiveFast? fast;
  final EatingWindow? eatingWindow;
  final UserFastingPlan? plan;
  final DateTime? fetchedAt;
  final Duration clockOffset;
  final List<FastingStageItem> bodyStages;

  bool get isFasting => fast != null;
  bool get isEating => fast == null && eatingWindow != null;

  String get planTitle =>
      plan?.titleLabel ?? formatPlanLabel(fast?.planCode, null);

  FastingLiveMetrics? get liveMetrics {
    final at = fetchedAt;
    if (at == null) return null;
    final active = fast;
    if (active != null) {
      return FastingLiveMetrics.active(
        fast: active,
        fetchedAt: at,
        clockOffset: clockOffset,
      );
    }
    final eat = eatingWindow;
    if (eat != null) {
      return FastingLiveMetrics.eating(
        window: eat,
        fetchedAt: at,
        clockOffset: clockOffset,
      );
    }
    return null;
  }

  FastingSessionState copyWith({
    bool? isLoading,
    String? errorMessage,
    ActiveFast? fast,
    EatingWindow? eatingWindow,
    UserFastingPlan? plan,
    DateTime? fetchedAt,
    Duration? clockOffset,
    List<FastingStageItem>? bodyStages,
    bool clearError = false,
    bool clearFast = false,
    bool clearEating = false,
  }) {
    return FastingSessionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fast: clearFast ? null : (fast ?? this.fast),
      eatingWindow: clearEating ? null : (eatingWindow ?? this.eatingWindow),
      plan: plan ?? this.plan,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      clockOffset: clockOffset ?? this.clockOffset,
      bodyStages: bodyStages ?? this.bodyStages,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    errorMessage,
    fast?.id,
    eatingWindow?.endsAt,
    plan?.planCode,
    fetchedAt,
    clockOffset,
    bodyStages.length,
  ];
}
