import 'package:equatable/equatable.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Yükle (zaten yüklüyse ya da yükleniyorsa bir şey yapmaz). [force]:
/// yüklüyken de sessizce tazeler.
final class ProfileStarted extends ProfileEvent {
  const ProfileStarted({this.force = false});

  final bool force;

  @override
  List<Object?> get props => [force];
}

/// Çıkış / hesap değişimi: önceki kullanıcının verisi bırakılır.
final class ProfileCleared extends ProfileEvent {
  const ProfileCleared();
}

final class ProfileNameChanged extends ProfileEvent {
  const ProfileNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Seçilen fotoğrafın yerel yolu (önizleme + yükleme).
final class ProfilePhotoPicked extends ProfileEvent {
  const ProfilePhotoPicked(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

/// `PATCH /user/profile` gövdesi + ekranda hemen gösterilecek hâl.
final class ProfileFieldsChanged extends ProfileEvent {
  const ProfileFieldsChanged({required this.fields, required this.optimistic});

  final Map<String, dynamic> fields;
  final UserProfile optimistic;

  @override
  List<Object?> get props => [fields, optimistic];
}

final class ProfilePlanChanged extends ProfileEvent {
  const ProfilePlanChanged(this.plan, {this.safetyAcknowledged = false});

  final OnboardingFastingPlan plan;

  /// Uzun plan güvenlik uyarısı kullanıcıya gösterilip onaylandı.
  final bool safetyAcknowledged;

  @override
  List<Object?> get props => [plan, safetyAcknowledged];
}
