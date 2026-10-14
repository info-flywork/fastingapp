import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/domain/nutrition/nutrition_repository.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/profile/bloc/profile_bloc.dart';

/// Bir ekran sunucuya yazdıktan sonra diğer ekranların verisini tazeler.
/// Ana sayfa özeti (`/user/summary`) su, adım, kilo, oruç, seri ve son öğünü
/// taşıdığı için her yazmadan sonra yenilenir; profil yalnızca profil
/// alanlarını (kilo, plan…) etkileyen yazmalarda.
abstract final class DataSync {
  /// Her yazmada artar. Yazmadan önce başlamış bir özet isteğinin yanıtı
  /// (eski veri) yeni durumu ezmesin diye karşılaştırılır.
  static int generation = 0;

  static void afterWrite({bool profile = false}) {
    generation++;
    getIt<NutritionRepository>().invalidate();
    getIt<HomeBloc>().add(const HomeRefreshRequested());
    if (profile) getIt<ProfileBloc>().add(const ProfileStarted(force: true));
  }
}
