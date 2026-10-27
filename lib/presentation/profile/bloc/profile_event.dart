import 'package:equatable/equatable.dart';
import 'package:fastingapp/domain/profile/profile_repository.dart';

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

/// Oruç oturumundaki plan değişti (Planlar / oruç sekmesi / Profili
/// Düzenle); profil ekranı aynı planı gösterir.
final class ProfileSessionPlanChanged extends ProfileEvent {
  const ProfileSessionPlanChanged(this.planCode);

  final String? planCode;

  @override
  List<Object?> get props => [planCode];
}
