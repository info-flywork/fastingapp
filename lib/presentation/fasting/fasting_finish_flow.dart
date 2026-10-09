import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/router/app_router.dart';
import 'package:fastingapp/core/router/route_paths.dart';
import 'package:fastingapp/presentation/fasting/bloc/fasting_session_cubit.dart';
import 'package:fastingapp/presentation/fasting/view/fasting_finish_view.dart';

/// Orucu bitirme akışı: nereden çağrılırsa çağrılsın (oruç sekmesi, zorlanma
/// akışı, öğün kaydı) bitirme ekranını açar; kaydedilince
/// `POST /fasts/:id/finish` cubit üzerinden gider. Onay, çağıranın işidir.
abstract final class FastingFinishFlow {
  /// Aktif oruç yoksa (ya da yüklenemediyse) false. Kaydedildiyse true.
  static Future<bool> open() async {
    final cubit = getIt<FastingSessionCubit>();
    if (cubit.state.fast == null) await cubit.refresh(showLoading: false);
    final session = cubit.state;
    final fast = session.fast;
    if (fast == null) return false;
    final saved = await appRouter.pushNamed<bool>(
      RoutePaths.fastingFinish.name,
      extra: FastingFinishArgs(
        fastId: fast.id,
        planTitle: session.planTitle,
        start: fast.startedAt,
        // Cihaz saati kaymışsa sunucu "gelecek" diye reddetmesin.
        end: DateTime.now().add(session.clockOffset),
      ),
    );
    return saved ?? false;
  }
}
