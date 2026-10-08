import 'package:equatable/equatable.dart';
import 'package:fastingapp/data/model/user/home_summary.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/data/model/user/user_progress.dart';

sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.user,
    required this.progress,
    required this.isPremium,
    this.summary,
  });

  final User user;
  final UserProgress progress;
  final bool isPremium;

  /// Kartların gerçek verisi (`GET /user/summary`).
  final HomeSummary? summary;

  @override
  List<Object?> get props => [user, progress, isPremium, summary];
}

final class HomeError extends HomeState {
  const HomeError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
