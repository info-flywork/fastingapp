import 'package:fastingapp/core/base/model/base_model.dart';
import 'package:fastingapp/core/managers/localization_manager.dart';
import 'package:fastingapp/core/network/network_manager.dart';
import 'package:fastingapp/core/utils/enum/request_type.dart';

/// Uzaktan düzenlenebilen içerik (`/v1/catalog/*`). Dil değişene kadar
/// bellekte tutulur.
final class ContentRepository {
  ContentRepository(this._network);

  final NetworkManager _network;
  List<FaqItem>? _faq;
  String? _faqLang;

  StruggleCatalog? _struggle;
  String? _struggleLang;

  final Map<String, InsightCategory> _categories = {};
  final Map<String, InsightArticle> _articles = {};
  String? _insightsLang;

  /// Çıkış / hesap değişimi: kilitler kullanıcıya özel (premium makaleler
  /// sonraki kullanıcıya bellekten sunulmasın).
  void clearInsights() {
    _insightsLang = null;
    _categories.clear();
    _articles.clear();
  }

  void _resetInsightsIfLangChanged() {
    final lang = LocalizationManager.current.languageCode;
    if (_insightsLang == lang) return;
    _insightsLang = lang;
    _categories.clear();
    _articles.clear();
  }

  /// `GET /insights/categories` → slug → başlık/açıklama.
  Future<Map<String, InsightCategory>> insightCategories() async {
    _resetInsightsIfLangChanged();
    if (_categories.isNotEmpty) return _categories;
    final result = await _network.send<_InsightCategoryList>(
      path: '/insights/categories',
      method: RequestType.get,
      parserModel: _InsightCategoryList.fromJson,
    );
    for (final c in result?.items ?? const <InsightCategory>[]) {
      _categories[c.slug] = c;
    }
    return _categories;
  }

  /// Kategorinin (ilk) makalesi: `GET /insights/articles?category=` →
  /// `GET /insights/articles/:slug`. Yoksa null.
  Future<InsightArticle?> insightArticleFor(String category) async {
    _resetInsightsIfLangChanged();
    final cached = _articles[category];
    if (cached != null) return cached;
    final page = await _network.send<_InsightSlugPage>(
      path: '/insights/articles',
      method: RequestType.get,
      queryParameters: {'category': category, 'limit': 1},
      parserModel: _InsightSlugPage.fromJson,
    );
    final slug = page?.slugs.firstOrNull;
    if (slug == null) return null;
    final article = await _network.send<InsightArticle>(
      path: '/insights/articles/$slug',
      method: RequestType.get,
      parserModel: InsightArticle.fromJson,
    );
    if (article != null) _articles[category] = article;
    return article;
  }

  /// `GET /catalog/faq` (dile göre soru/cevap).
  Future<List<FaqItem>> faq() async {
    final lang = LocalizationManager.current.languageCode;
    final cached = _faq;
    if (cached != null && _faqLang == lang) return cached;
    final result = await _network.send<_FaqList>(
      path: '/catalog/faq',
      method: RequestType.get,
      parserModel: _FaqList.fromJson,
    );
    _faqLang = lang;
    return _faq = result?.items ?? const [];
  }

  /// `GET /catalog/struggle` — zorlanma intro / sebepler / ipuçları.
  Future<StruggleCatalog> struggle() async {
    final lang = LocalizationManager.current.languageCode;
    final cached = _struggle;
    if (cached != null && _struggleLang == lang) return cached;
    final result = await _network.send<StruggleCatalog>(
      path: '/catalog/struggle',
      method: RequestType.get,
      parserModel: StruggleCatalog.fromJson,
    );
    _struggleLang = lang;
    return _struggle = result ?? const StruggleCatalog();
  }
}

/// `GET /catalog/struggle` yanıtı.
final class StruggleCatalog implements BaseModel<StruggleCatalog> {
  const StruggleCatalog({
    this.intro = const StruggleIntro(),
    this.reasons = const [],
    this.tips = const [],
  });

  factory StruggleCatalog.fromJson(Map<String, dynamic> json) =>
      StruggleCatalog(
        intro: StruggleIntro.fromJson(
          json['intro'] as Map<String, dynamic>? ?? const {},
        ),
        reasons: [
          for (final r
              in (json['reasons'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            StruggleReason.fromJson(r),
        ],
        tips: [
          for (final t
              in (json['tips'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>())
            StruggleTip.fromJson(t),
        ],
      );

  final StruggleIntro intro;
  final List<StruggleReason> reasons;
  final List<StruggleTip> tips;

  StruggleReason? reason(String code) {
    for (final r in reasons) {
      if (r.code == code) return r;
    }
    return null;
  }

  StruggleTip? tip(String code) {
    for (final t in tips) {
      if (t.code == code) return t;
    }
    return null;
  }

  @override
  StruggleCatalog fromJson(Map<String, dynamic> json) =>
      StruggleCatalog.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class StruggleIntro {
  const StruggleIntro({this.title = '', this.body = ''});

  factory StruggleIntro.fromJson(Map<String, dynamic> json) => StruggleIntro(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  final String title;
  final String body;
}

final class StruggleReason {
  const StruggleReason({
    required this.code,
    required this.title,
    required this.body,
    this.image = '',
    this.tips = const [],
  });

  factory StruggleReason.fromJson(Map<String, dynamic> json) => StruggleReason(
    code: json['code'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    image: json['image'] as String? ?? '',
    tips: [
      for (final t in json['tips'] as List<dynamic>? ?? const [])
        if (t is String) t,
    ],
  );

  final String code;
  final String title;
  final String body;
  final String image;
  final List<String> tips;
}

final class StruggleTip {
  const StruggleTip({
    required this.code,
    required this.title,
    required this.body,
    this.image = '',
  });

  factory StruggleTip.fromJson(Map<String, dynamic> json) => StruggleTip(
    code: json['code'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    image: json['image'] as String? ?? '',
  );

  final String code;
  final String title;
  final String body;
  final String image;
}

final class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

final class _FaqList implements BaseModel<_FaqList> {
  const _FaqList(this.items);

  factory _FaqList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _FaqList([
      if (raw is List)
        for (final item in raw.whereType<Map<String, dynamic>>())
          if ((item['question'] as String? ?? '').isNotEmpty)
            FaqItem(
              question: item['question'] as String,
              answer: item['answer'] as String? ?? '',
            ),
    ]);
  }

  final List<FaqItem> items;

  @override
  _FaqList fromJson(Map<String, dynamic> json) => _FaqList.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class InsightCategory {
  const InsightCategory({
    required this.slug,
    required this.title,
    required this.description,
    this.isLocked = false,
  });

  final String slug;
  final String title;
  final String description;

  /// Premium kategori, kullanıcı (istek anında) premium değildi.
  final bool isLocked;
}

final class InsightSection {
  const InsightSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  /// `tree` | `flame` | `window` | `heart` | `star`
  final String icon;
  final String title;
  final String body;
}

final class InsightArticle implements BaseModel<InsightArticle> {
  const InsightArticle({
    required this.kicker,
    required this.title,
    this.subtitle,
    this.quote,
    this.tip,
    this.sections = const [],
  });

  factory InsightArticle.fromJson(Map<String, dynamic> json) {
    final raw = json['sections'];
    return InsightArticle(
      kicker: json['kicker'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      quote: json['quote'] as String?,
      tip: json['tip'] as String?,
      sections: [
        if (raw is List)
          for (final s in raw.whereType<Map<String, dynamic>>())
            InsightSection(
              icon: s['icon'] as String? ?? 'tree',
              title: s['title'] as String? ?? '',
              body: s['body'] as String? ?? '',
            ),
      ],
    );
  }

  final String kicker;
  final String title;
  final String? subtitle;
  final String? quote;
  final String? tip;
  final List<InsightSection> sections;

  @override
  InsightArticle fromJson(Map<String, dynamic> json) =>
      InsightArticle.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _InsightCategoryList implements BaseModel<_InsightCategoryList> {
  const _InsightCategoryList(this.items);

  factory _InsightCategoryList.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _InsightCategoryList([
      if (raw is List)
        for (final c in raw.whereType<Map<String, dynamic>>())
          InsightCategory(
            slug: c['slug'] as String? ?? '',
            title: c['title'] as String? ?? '',
            description: c['description'] as String? ?? '',
            isLocked: c['isLocked'] as bool? ?? false,
          ),
    ]);
  }

  final List<InsightCategory> items;

  @override
  _InsightCategoryList fromJson(Map<String, dynamic> json) =>
      _InsightCategoryList.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}

final class _InsightSlugPage implements BaseModel<_InsightSlugPage> {
  const _InsightSlugPage(this.slugs);

  factory _InsightSlugPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return _InsightSlugPage([
      if (raw is List)
        for (final a in raw.whereType<Map<String, dynamic>>())
          if (a['slug'] is String) a['slug'] as String,
    ]);
  }

  final List<String> slugs;

  @override
  _InsightSlugPage fromJson(Map<String, dynamic> json) =>
      _InsightSlugPage.fromJson(json);

  @override
  Map<String, dynamic> toJson() => const {};
}
