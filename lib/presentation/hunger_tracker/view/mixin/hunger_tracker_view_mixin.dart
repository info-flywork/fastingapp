part of '../hunger_tracker_view.dart';

mixin HungerTrackerViewMixin on State<HungerTrackerView> {
  final Set<HungerSymptom> selectedSymptoms = {};

  void toggleSymptom(HungerSymptom symptom) {
    setState(() {
      if (selectedSymptoms.contains(symptom)) {
        selectedSymptoms.remove(symptom);
      } else {
        selectedSymptoms.add(symptom);
      }
    });
  }

  HungerFlowArgs get _flowArgs =>
      HungerFlowArgs(symptoms: Set<HungerSymptom>.of(selectedSymptoms));

  void _openHungerCheck() {
    context.pushNamed(
      RoutePaths.hungerCheck.name,
      extra: _flowArgs,
    );
  }

  void onHungryNowTapped() => _openHungerCheck();

  void onHistoryTapped() {
    // Geçmiş ekranı için yer tutucu.
  }

  void onNextTapped() {
    if (selectedSymptoms.isEmpty) return;
    _openHungerCheck();
  }
}
