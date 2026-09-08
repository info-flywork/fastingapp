/// Tüm rota path ve name sabitleri. (Doküman 11)
enum RoutePaths {
  splash('/splash', 'splash'),
  entry('/entry', 'entry'),
  onboarding('/onboarding', 'onboarding'),
  goalHighlight('/goal-highlight', 'goalHighlight'),
  aboutYou('/about-you', 'aboutYou'),
  privacyHighlight('/privacy-highlight', 'privacyHighlight'),
  startingPoint('/starting-point', 'startingPoint'),
  doableHighlight('/doable-highlight', 'doableHighlight'),
  diet('/diet', 'diet'),
  foodLoves('/food-loves', 'foodLoves'),
  foodSkips('/food-skips', 'foodSkips'),
  notedHighlight('/noted-highlight', 'notedHighlight'),
  weightHistory('/weight-history', 'weightHistory'),
  obstacles('/obstacles', 'obstacles'),
  welcome('/welcome', 'welcome'),
  languageLevel('/language-level', 'languageLevel'),
  home('/home', 'home'),
  catalog('/catalog', 'catalog'),
  settings('/settings', 'settings'),
  profile('/profile', 'profile');

  const RoutePaths(this.path, this.name);

  final String path;
  final String name;
}
