import 'package:equatable/equatable.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:flutter/widgets.dart';

enum ProfileStatus { initial, loading, loaded, failure }

/// Kaydetme hatası (tek seferlik snackbar). [message] null ise genel mesaj.
/// [id] her hatada artar: aynı mesaj üst üste gelse de dinleyici tetiklenir.
final class ProfileSaveError extends Equatable {
  const ProfileSaveError(this.id, this.message);

  final int id;
  final String? message;

  @override
  List<Object?> get props => [id, message];
}

/// Kullanıcının profil bilgileri: Profil sekmesi başlığı ve Profili Düzenle.
final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.name,
    this.avatarUrl,
    this.localPhotoPath,
    this.profile = const UserProfile(),
    this.plan,
    this.planCode,
    this.loadError,
    this.saveError,
  });

  final ProfileStatus status;
  final String? name;
  final String? avatarUrl;

  /// Yeni seçilen fotoğraf (yüklenirken ve sonrasında önizleme).
  final String? localPhotoPath;
  final UserProfile profile;

  /// Etkin plan; yoksa bekleyen premium plan.
  final OnboardingFastingPlan? plan;

  /// Sunucudaki plan kodu ([plan] onboarding listesinde olmayan planlarda
  /// null kalır; başlık bundan gösterilir).
  final String? planCode;

  /// İlk yükleme hatası (null: genel mesaj gösterilir).
  final String? loadError;
  final ProfileSaveError? saveError;

  bool get isLoaded => status == ProfileStatus.loaded;

  /// "Ayşe Yılmaz" → "AY"; ad yoksa boş.
  String get initials => (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .take(2)
      .map((p) => p.characters.first)
      .join()
      .toUpperCase();

  ProfileState copyWith({
    ProfileStatus? status,
    ValueGetter<String?>? name,
    ValueGetter<String?>? avatarUrl,
    ValueGetter<String?>? localPhotoPath,
    UserProfile? profile,
    ValueGetter<OnboardingFastingPlan?>? plan,
    ValueGetter<String?>? planCode,
    ValueGetter<String?>? loadError,
    ProfileSaveError? saveError,
  }) => ProfileState(
    status: status ?? this.status,
    name: name != null ? name() : this.name,
    avatarUrl: avatarUrl != null ? avatarUrl() : this.avatarUrl,
    localPhotoPath: localPhotoPath != null
        ? localPhotoPath()
        : this.localPhotoPath,
    profile: profile ?? this.profile,
    plan: plan != null ? plan() : this.plan,
    planCode: planCode != null ? planCode() : this.planCode,
    loadError: loadError != null ? loadError() : this.loadError,
    saveError: saveError ?? this.saveError,
  );

  @override
  List<Object?> get props => [
    status,
    name,
    avatarUrl,
    localPhotoPath,
    profile,
    plan,
    planCode,
    loadError,
    saveError,
  ];
}
