import 'package:easy_localization/easy_localization.dart';
import 'package:fastingapp/core/di/injection.dart';
import 'package:fastingapp/core/dialogs/app_dialogs.dart';
import 'package:fastingapp/core/network/network_exception.dart';
import 'package:fastingapp/core/snackbar/app_snackbar.dart';
import 'package:fastingapp/core/sync/data_sync.dart';
import 'package:fastingapp/core/utils/enum/snackbar_type.dart';
import 'package:fastingapp/domain/trackers/trackers_repository.dart';
import 'package:fastingapp/presentation/home/bloc/home_bloc.dart';
import 'package:fastingapp/presentation/home/bloc/home_event.dart';
import 'package:fastingapp/presentation/home/view/home_view.dart';
import 'package:flutter/widgets.dart';

/// Kilo kartındaki kalem (ana sayfa, oruç sekmesi): pencere → `POST /weights`
/// → ana sayfa + profil tazelenir. Hata olursa sunucu mesajı gösterilir.
abstract final class WeightEntryFlow {
  static Future<void> open(BuildContext context, {double? currentKg}) async {
    final result = await AppDialogs.instance.showEditWeight(
      context,
      initialWeightKg: currentKg ?? HomeWeightCard.fallbackKg,
    );
    if (result == null) return;
    final kg = (result.weightKg * 10).round() / 10;
    // Aynı kilo da yeni bir tartıdır (bugünün kaydı); yalnızca değer
    // değiştiyse kart iyimser güncellenir.
    if (kg != currentKg) getIt<HomeBloc>().add(HomeWeightOptimistic(kg));
    try {
      await getIt<TrackersRepository>().createWeight(weightKg: kg);
      DataSync.afterWrite(profile: true);
    } on Object catch (e) {
      getIt<HomeBloc>().add(const HomeRefreshRequested());
      if (!context.mounted) return;
      AppSnackbar.show(
        context: context,
        text: e is NetworkException ? e.message : 'common.failed'.tr(),
        type: SnackBarType.failure,
      );
    }
  }
}
