import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/managers/auth_cache_manager.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';
import 'package:fastingapp/data/model/user/user.dart';
import 'package:fastingapp/domain/onboarding/onboarding_draft.dart';
import 'package:fastingapp/presentation/auth/onboard/about_you/bloc/about_you_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/diet/bloc/diet_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/fasting_plan/bloc/fasting_plan_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_loves/bloc/food_loves_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/food_skips/bloc/food_skips_bloc.dart';
import 'package:fastingapp/presentation/auth/onboard/goal/bloc/goal_bloc.dart';

const _notificationKeys = [
  'fasting',
  'streak',
  'weight',
  'water',
  'challenges',
  'world',
  'marketing',
];

/// Profili Düzenle ekranı (backend doküman 04 §3): hesap (`/user/me`), profil
/// (`/user/profile`), avatar (`/user/me/avatar`) ve aktif plan
/// (`/plans/current`). Enum'lar API'de istemcideki adlarıyla gider.
final class ProfileRepository {
  ProfileRepository(this._network, this._dio, this._authCache);

  final NetworkManager _network;
  final Dio _dio;
  final AuthCacheManager _authCache;

  /// Ad + avatar (`GET /user/me`).
  Future<ProfileAccount> getAccount() async {
    final result = await _network.send<ProfileAccount>(
      path: '/user/me',
      method: RequestType.get,
      parserModel: ProfileAccount.fromJson,
    );
    return result ?? const ProfileAccount();
  }

  /// Son bilinen ayarlar (profil anahtarları açılışta varsayılandan
  /// zıplamasın; oturum boyunca bellekte).
  UserSettings? cachedSettings;

  /// `GET /user/settings` → bildirim ve sağlık senkronu anahtarları.
  Future<UserSettings> getSettings() async {
    final result = await _network.send<UserSettings>(
      path: '/user/settings',
      method: RequestType.get,
      parserModel: UserSettings.fromJson,
    );
    return cachedSettings = result ?? const UserSettings();
  }

  /// `PATCH /user/settings` (yalnızca verilen alanlar).
  /// [allNotifications] verilirse oruç, seri, kilo, su, meydan okuma, ada ve
  /// pazarlama anahtarları birlikte o değere çekilir.
  Future<UserSettings> updateSettings({
    bool? pushEnabled,
    bool? healthSyncEnabled,
    bool? showInChallenges,
    bool? allNotifications,
  }) async {
    final result = await _network.send<UserSettings>(
      path: '/user/settings',
      method: RequestType.patch,
      data: {
        'pushEnabled': ?pushEnabled,
        'healthSyncEnabled': ?healthSyncEnabled,
        'showInChallenges': ?showInChallenges,
        if (allNotifications != null)
          'notifications': {
            for (final key in _notificationKeys) key: allNotifications,
          },
      },
      parserModel: UserSettings.fromJson,
    );
    return cachedSettings = result ?? const UserSettings();
  }

  Future<UserProfile> getProfile() async {
    final result = await _network.send<UserProfile>(
      path: '/user/profile',
      method: RequestType.get,
      parserModel: UserProfile.fromJson,
    );
    return result ?? const UserProfile();
  }

  /// `PATCH /user/profile`; `weightKg` yeni kilo kaydı açar.
  Future<UserProfile> updateProfile(Map<String, dynamic> fields) async {
    final result = await _network.send<UserProfile>(
      path: '/user/profile',
      method: RequestType.patch,
      data: fields,
      parserModel: UserProfile.fromJson,
    );
    return result ?? const UserProfile();
  }

  /// `PATCH /user/me {locale}`: push ve bildirim kutusu metinleri bu dilde
  /// üretilir.
  Future<void> updateLocale(String languageCode) async {
    await _network.send<ProfileAccount>(
      path: '/user/me',
      method: RequestType.patch,
      data: {'locale': languageCode},
      parserModel: ProfileAccount.fromJson,
    );
  }

  /// `PATCH /user/me {name}`; önbellekteki kullanıcı da güncellenir.
  Future<String?> updateName(String name) async {
    final result = await _network.send<ProfileAccount>(
      path: '/user/me',
      method: RequestType.patch,
      data: {'name': name},
      parserModel: ProfileAccount.fromJson,
    );
    final cached = await _authCache.getUser();
    if (cached != null) {
      await _authCache.saveUser(
        User(
          id: cached.id,
          name: result?.name ?? name,
          email: cached.email,
          isPremium: cached.isPremium,
          isAnsweredQuestions: cached.isAnsweredQuestions,
        ),
      );
    }
    return result?.name ?? name;
  }

  /// `PUT /user/me/avatar` (multipart); yeni avatarın URL'si.
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/user/me/avatar',
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(
            filePath,
            filename: 'avatar.jpg',
          ),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      final avatar = data?['avatar'] as Map<String, dynamic>?;
      return avatar?['url'] as String?;
    } on DioException catch (e) {
      throw NetworkException.fromDio(e);
    }
  }

  /// Etkin planın kodu; yoksa bekleyen plan (`GET /plans/current`). Kod
  /// döner: Planlar sekmesindeki planlar (15:9, 19:5, early_tre…) onboarding
  /// listesinde yok, profil onları da göstermeli.
  Future<String?> getCurrentPlanCode() async {
    final result = await _network.send<_PlanEnvelope>(
      path: '/plans/current',
      method: RequestType.get,
      parserModel: _PlanEnvelope.fromJson,
    );
    return result?.planCode;
  }

  static OnboardingFastingPlan? planFromCode(String? code) {
    for (final entry in OnboardingDraft.planCodes.entries) {
      if (entry.value == code) return entry.key;
    }
    return null;
  }
}

/// `GET /user/me` içinden profil ekranının kullandıkları.
final class ProfileAccount implements BaseModel<ProfileAccount> {
  const ProfileAccount({this.name, this.avatarUrl, this.isGuest = false});

  factory ProfileAccount.fromJson(Map<String, dynamic> json) => ProfileAccount(
    name: json['name'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    isGuest: json['isGuest'] as bool? ?? false,
  );

  final String? name;
  final String? avatarUrl;
  final bool isGuest;

  @override
  ProfileAccount fromJson(Map<String, dynamic> json) =>
      ProfileAccount.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'isGuest': isGuest,
  };
}

/// `GET/PATCH /user/profile`. Onboarding'i bitmemiş hesapta alanlar boş.
final class UserProfile extends Equatable implements BaseModel<UserProfile> {
  const UserProfile({
    this.goal,
    this.gender,
    this.age,
    this.heightCm,
    this.currentWeightKg,
    this.diet,
    this.foodLoves = const {},
    this.foodSkips = const {},
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    goal: _byName(OnboardingGoal.values, json['goal']),
    gender: _byName(OnboardingGender.values, json['gender']),
    age: (json['age'] as num?)?.toInt(),
    heightCm: (json['heightCm'] as num?)?.round(),
    currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble(),
    diet: _byName(OnboardingDiet.values, json['diet']),
    foodLoves: _setOf(OnboardingFoodLove.values, json['foodLoves']),
    foodSkips: _setOf(OnboardingFoodSkip.values, json['foodSkips']),
  );

  final OnboardingGoal? goal;
  final OnboardingGender? gender;
  final int? age;
  final int? heightCm;
  final double? currentWeightKg;
  final OnboardingDiet? diet;
  final Set<OnboardingFoodLove> foodLoves;
  final Set<OnboardingFoodSkip> foodSkips;

  /// İyimser güncelleme için (sunucu yanıtı gelince yerine geçer).
  UserProfile copyWith({
    OnboardingGoal? goal,
    OnboardingGender? gender,
    int? age,
    int? heightCm,
    double? currentWeightKg,
    OnboardingDiet? diet,
    Set<OnboardingFoodLove>? foodLoves,
    Set<OnboardingFoodSkip>? foodSkips,
  }) => UserProfile(
    goal: goal ?? this.goal,
    gender: gender ?? this.gender,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    currentWeightKg: currentWeightKg ?? this.currentWeightKg,
    diet: diet ?? this.diet,
    foodLoves: foodLoves ?? this.foodLoves,
    foodSkips: foodSkips ?? this.foodSkips,
  );

  @override
  List<Object?> get props => [
    goal,
    gender,
    age,
    heightCm,
    currentWeightKg,
    diet,
    foodLoves,
    foodSkips,
  ];

  /// Bilinmeyen (yeni sürümde eklenmiş) değer yok sayılır.
  static T? _byName<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static Set<T> _setOf<T extends Enum>(List<T> values, Object? raw) => {
    if (raw is List)
      for (final name in raw) ?_byName(values, name),
  };

  @override
  UserProfile fromJson(Map<String, dynamic> json) => UserProfile.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'goal': goal?.name,
    'gender': gender?.name,
    'age': age,
    'heightCm': heightCm,
    'currentWeightKg': currentWeightKg,
    'diet': diet?.name,
    'foodLoves': foodLoves.map((e) => e.name).toList(),
    'foodSkips': foodSkips.map((e) => e.name).toList(),
  };
}

/// `/plans/current` yanıtından plan kodu: etkin plan; yoksa kullanıcının
/// seçip premium gerektiği için bekleyen planı.
final class _PlanEnvelope implements BaseModel<_PlanEnvelope> {
  const _PlanEnvelope({this.planCode});

  factory _PlanEnvelope.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    return _PlanEnvelope(
      planCode:
          (plan is Map<String, dynamic> ? plan['planCode'] as String? : null) ??
          json['pendingPlanCode'] as String?,
    );
  }

  final String? planCode;

  @override
  _PlanEnvelope fromJson(Map<String, dynamic> json) =>
      _PlanEnvelope.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {'planCode': planCode};
}

/// `/user/settings` içinden Profil ekranının kullandıkları.
final class UserSettings implements BaseModel<UserSettings> {
  const UserSettings({
    this.pushEnabled = true,
    this.healthSyncEnabled = false,
    this.showInChallenges = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => UserSettings(
    pushEnabled: json['pushEnabled'] as bool? ?? true,
    healthSyncEnabled: json['healthSyncEnabled'] as bool? ?? false,
    showInChallenges: json['showInChallenges'] as bool? ?? false,
  );

  final bool pushEnabled;
  final bool healthSyncEnabled;

  /// Meydan okuma katılımcı listesinde ad + fotoğraf görünsün mü (açık rıza).
  final bool showInChallenges;

  @override
  UserSettings fromJson(Map<String, dynamic> json) =>
      UserSettings.fromJson(json);

  @override
  Map<String, dynamic> toJson() => {
    'pushEnabled': pushEnabled,
    'healthSyncEnabled': healthSyncEnabled,
    'showInChallenges': showInChallenges,
  };
}
