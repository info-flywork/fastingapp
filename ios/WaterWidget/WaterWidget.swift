import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.flywork.mochifast"

struct WaterEntry: TimelineEntry {
  let date: Date
  let smallPath: String?
  let mediumPath: String?
  let largePath: String?
}

struct WaterProvider: TimelineProvider {
  func placeholder(in context: Context) -> WaterEntry {
    WaterEntry(date: Date(), smallPath: nil, mediumPath: nil, largePath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (WaterEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<WaterEntry>) -> Void
  ) {
    completion(Timeline(entries: [load()], policy: .never))
  }

  private func load() -> WaterEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return WaterEntry(
      date: Date(),
      smallPath: data?.string(forKey: "water_widget_image"),
      mediumPath: data?.string(forKey: "water_widget_medium_image"),
      largePath: data?.string(forKey: "water_widget_large_image")
    )
  }
}

struct WaterWidgetView: View {
  @Environment(\.widgetFamily) private var family
  var entry: WaterEntry

  var body: some View {
    let path = family == .systemMedium
      ? entry.mediumPath
      : family == .systemLarge ? entry.largePath : entry.smallPath
    if let path,
      let image = UIImage(contentsOfFile: path)
    {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
    } else {
      Color.white
    }
  }
}

struct WaterWidget: Widget {
  let kind: String = "WaterWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: WaterProvider()) { entry in
      WaterWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://water?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.water))
    .description(WidgetText.description(.water))
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

/// Canlı geri sayım katmanı (Flutter `FastingWidgetSync` → `fasting_live_spec`).
/// Görselde süre metni ve ilerleme yayı boş bırakılır; burada çizilir ki
/// uygulama kapalıyken de sayaç saniye saniye aksın.
struct LiveSpec {
  let w: Double
  let h: Double
  let tx: Double
  let ty: Double
  let leading: Bool
  let ts: Double
  /// Sola dayalı metnin genişliği (yoksa iki kenar boşluğu arası).
  let tw: Double?
  let tc: Color
  let ring: (x: Double, y: Double, r: Double, s: Double, c: Color)?

  init?(_ any: Any?) {
    guard let d = any as? [String: Any],
      let w = d["w"] as? Double ?? (d["w"] as? Int).map(Double.init),
      let h = d["h"] as? Double ?? (d["h"] as? Int).map(Double.init)
    else { return nil }
    func num(_ k: String) -> Double {
      d[k] as? Double ?? (d[k] as? Int).map(Double.init) ?? 0
    }
    self.w = w
    self.h = h
    tx = num("tx")
    ty = num("ty")
    leading = (d["ta"] as? String) == "l"
    ts = num("ts")
    tw = d["tw"] != nil ? num("tw") : nil
    tc = Color(hex: d["tc"] as? String)
    if d["rr"] != nil {
      ring = (num("rx"), num("ry"), num("rr"), num("rs"), Color(hex: d["rc"] as? String))
    } else {
      ring = nil
    }
  }
}

struct LiveCountdown {
  let start: Date
  let end: Date
  let spec: LiveSpec
  let suffix: String?

  func progress(at date: Date) -> Double {
    let total = end.timeIntervalSince(start)
    guard total > 0 else { return 0 }
    return min(max(date.timeIntervalSince(start) / total, 0), 1)
  }

  /// `kind`: "small" | "medium" | "detail".
  static func load(_ kind: String) -> LiveCountdown? {
    let data = UserDefaults(suiteName: widgetGroupId)
    guard data?.integer(forKey: "fasting_live") == 1,
      let startMs = (data?.object(forKey: "fasting_start_ms") as? NSNumber)?.doubleValue,
      let endMs = (data?.object(forKey: "fasting_end_ms") as? NSNumber)?.doubleValue,
      startMs > 0, endMs > startMs,
      let raw = data?.string(forKey: "fasting_live_spec")?.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: raw) as? [String: Any],
      let spec = LiveSpec(json[kind])
    else { return nil }
    return LiveCountdown(
      start: Date(timeIntervalSince1970: startMs / 1000),
      end: Date(timeIntervalSince1970: endMs / 1000),
      spec: spec,
      suffix: kind == "medium" ? data?.string(forKey: "fasting_left_label") : nil
    )
  }

  /// Yay için zaman çizelgesi: bitişe kadar ~5 dk'da bir giriş (en çok 120),
  /// bitişte son giriş. Metin `Text(timerInterval:)` ile kendiliğinden akar.
  func entryDates(from now: Date) -> [Date] {
    guard end > now else { return [now] }
    let remaining = end.timeIntervalSince(now)
    let step = max(300, remaining / 120)
    var dates: [Date] = []
    var t = now
    while t < end {
      dates.append(t)
      t = t.addingTimeInterval(step)
    }
    dates.append(end)
    return dates
  }
}

extension Color {
  init(hex: String?) {
    let value = UInt64((hex ?? "").replacingOccurrences(of: "#", with: ""), radix: 16) ?? 0
    self.init(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}

/// Görselin üstüne (aynı ölçek ve kırpmayla) yay + geri sayım.
struct LiveOverlay: View {
  let live: LiveCountdown
  let date: Date
  /// Görsel `.fill` mi (`.fit` değil) — konum ölçeği buna göre.
  let fill: Bool

  var body: some View {
    GeometryReader { geo in
      let spec = live.spec
      let sx = geo.size.width / spec.w
      let sy = geo.size.height / spec.h
      let scale = fill ? max(sx, sy) : min(sx, sy)
      let ox = (geo.size.width - spec.w * scale) / 2
      let oy = (geo.size.height - spec.h * scale) / 2
      let leadingWidth = spec.tw ?? (spec.w - spec.tx * 2)
      ZStack {
        if let ring = spec.ring {
          Circle()
            .trim(from: 0, to: live.progress(at: date))
            .stroke(ring.c, style: StrokeStyle(lineWidth: ring.s * scale, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .frame(width: ring.r * 2 * scale, height: ring.r * 2 * scale)
            .position(x: ring.x * scale + ox, y: ring.y * scale + oy)
        }
        timer(scale: scale)
          .font(.system(size: spec.ts * scale, weight: spec.leading ? .medium : .semibold))
          .monospacedDigit()
          .foregroundColor(spec.tc)
          .lineLimit(1)
          .minimumScaleFactor(0.5)
          .multilineTextAlignment(spec.leading ? .leading : .center)
          // Halkada metin halkanın iç çapına sığar (saniyeli sayaç, gerekirse küçülür).
          .frame(
            width: spec.leading
              ? leadingWidth * scale
              : (spec.ring.map { ($0.r - $0.s) * 2 } ?? spec.ts * 4) * scale,
            alignment: spec.leading ? .leading : .center
          )
          .position(
            x: spec.leading
              ? spec.tx * scale + ox + leadingWidth * scale / 2
              : spec.tx * scale + ox,
            y: spec.ty * scale + oy
          )
      }
    }
  }

  private func timer(scale: Double) -> Text {
    let base = date < live.end
      ? Text(timerInterval: date...live.end, countsDown: true)
      : Text("0:00")
    guard let suffix = live.suffix, !suffix.isEmpty else { return base }
    return base + Text(" " + suffix)
  }
}

struct FastingEntry: TimelineEntry {
  let date: Date
  let smallPath: String?
  let mediumPath: String?
  var live: LiveCountdown? = nil
}

/// Canlı sayaçlı oruç widget'larının ortak zaman çizelgesi.
func liveTimeline(_ entry: FastingEntry) -> Timeline<FastingEntry> {
  guard let live = entry.live else {
    let next = Date().addingTimeInterval(15 * 60)
    return Timeline(entries: [entry], policy: .after(next))
  }
  let entries = live.entryDates(from: Date()).map {
    FastingEntry(date: $0, smallPath: entry.smallPath, mediumPath: entry.mediumPath, live: live)
  }
  return Timeline(entries: entries, policy: .atEnd)
}

struct FastingProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    completion(liveTimeline(load()))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return FastingEntry(
      date: Date(),
      smallPath: data?.string(forKey: "fasting_widget_image"),
      mediumPath: data?.string(forKey: "fasting_widget_medium_image"),
      live: LiveCountdown.load("small")
    )
  }
}

struct FastingWidgetView: View {
  @Environment(\.widgetFamily) private var family
  var entry: FastingEntry
  var fit: Bool = false

  var body: some View {
    let path = family == .systemMedium ? entry.mediumPath : entry.smallPath
    if let path, let image = UIImage(contentsOfFile: path) {
      ZStack {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: fit ? .fit : .fill)
        if let live = entry.live {
          LiveOverlay(live: live, date: entry.date, fill: !fit)
        }
      }
    } else {
      Color.white
    }
  }
}

struct FastingWidget: Widget {
  let kind: String = "FastingWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.fasting))
    .description(WidgetText.description(.fasting))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct FastingCardProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    completion(liveTimeline(load()))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_medium_image")
    return FastingEntry(
      date: Date(), smallPath: path, mediumPath: path, live: LiveCountdown.load("medium"))
  }
}

struct FastingCardWidget: Widget {
  let kind: String = "FastingCardWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingCardProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.card))
    .description(WidgetText.description(.card))
    .supportedFamilies([.systemSmall])
    .contentMarginsDisabled()
  }
}

struct FastingDetailProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    completion(liveTimeline(load()))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_detail_image")
    return FastingEntry(
      date: Date(), smallPath: path, mediumPath: path, live: LiveCountdown.load("detail"))
  }
}

struct FastingDetailWidget: Widget {
  let kind: String = "FastingDetailWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingDetailProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.detail))
    .description(WidgetText.description(.detail))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

struct FastingPlanProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_plan_image")
    return FastingEntry(date: Date(), smallPath: path, mediumPath: path)
  }
}

struct FastingPlanWidget: Widget {
  let kind: String = "FastingPlanWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingPlanProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.plan))
    .description(WidgetText.description(.plan))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

struct FastingOmhProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_omh_image")
    return FastingEntry(date: Date(), smallPath: path, mediumPath: path)
  }
}

struct FastingOmhWidget: Widget {
  let kind: String = "FastingOmhWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingOmhProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.today))
    .description(WidgetText.description(.today))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

struct FastingWeekProvider: TimelineProvider {
  func placeholder(in context: Context) -> FastingEntry {
    FastingEntry(date: Date(), smallPath: nil, mediumPath: nil)
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (FastingEntry) -> Void
  ) {
    completion(load())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<FastingEntry>) -> Void
  ) {
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_week_image")
    return FastingEntry(date: Date(), smallPath: path, mediumPath: path)
  }
}

struct FastingWeekWidget: Widget {
  let kind: String = "FastingWeekWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: FastingWeekProvider()) { entry in
      FastingWidgetView(entry: entry)
        .widgetURL(URL(string: "fastingapp://fasting?homeWidget"))
        .containerBackground(for: .widget) { Color.clear }
    }
    .configurationDisplayName(WidgetText.name(.week))
    .description(WidgetText.description(.week))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

/// Widget galerisi adları / açıklamaları cihaz diline göre (önceden yalnızca
/// Türkçeydi). Uygulamanın 7 dili; diğerlerinde İngilizce.
enum WidgetText {
  case water, fasting, card, detail, plan, today, week

  private static var lang: String {
    let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "en"
    return ["tr", "de", "es", "fr", "it", "ru"].contains(code) ? String(code) : "en"
  }

  private static let names: [WidgetText: [String: String]] = [
    .water: ["en": "Water", "tr": "Su", "de": "Wasser", "es": "Agua", "fr": "Eau", "it": "Acqua", "ru": "Вода"],
    .fasting: ["en": "Fasting", "tr": "Oruç", "de": "Fasten", "es": "Ayuno", "fr": "Jeûne", "it": "Digiuno", "ru": "Голодание"],
    .card: ["en": "Fasting card", "tr": "Oruç kartı", "de": "Fastenkarte", "es": "Tarjeta de ayuno", "fr": "Carte de jeûne", "it": "Scheda digiuno", "ru": "Карточка голодания"],
    .detail: ["en": "Fasting summary", "tr": "Oruç özeti", "de": "Fastenübersicht", "es": "Resumen del ayuno", "fr": "Résumé du jeûne", "it": "Riepilogo digiuno", "ru": "Сводка голодания"],
    .plan: ["en": "Today's plan", "tr": "Bugünün planı", "de": "Plan für heute", "es": "Plan de hoy", "fr": "Plan du jour", "it": "Piano di oggi", "ru": "План на сегодня"],
    .today: ["en": "Today", "tr": "Bugün", "de": "Heute", "es": "Hoy", "fr": "Aujourd'hui", "it": "Oggi", "ru": "Сегодня"],
    .week: ["en": "This week", "tr": "Bu hafta", "de": "Diese Woche", "es": "Esta semana", "fr": "Cette semaine", "it": "Questa settimana", "ru": "Эта неделя"],
  ]

  private static let descriptions: [WidgetText: [String: String]] = [
    .water: ["en": "Daily water goal", "tr": "Günlük su hedefi", "de": "Tägliches Wasserziel", "es": "Objetivo diario de agua", "fr": "Objectif d'eau quotidien", "it": "Obiettivo giornaliero di acqua", "ru": "Дневная цель по воде"],
    .fasting: ["en": "Time left in your fast", "tr": "Kalan oruç süresi", "de": "Verbleibende Fastenzeit", "es": "Tiempo restante de ayuno", "fr": "Temps de jeûne restant", "it": "Tempo di digiuno rimanente", "ru": "Оставшееся время голодания"],
    .card: ["en": "Plan and time left", "tr": "Plan ve kalan süre", "de": "Plan und verbleibende Zeit", "es": "Plan y tiempo restante", "fr": "Plan et temps restant", "it": "Piano e tempo rimanente", "ru": "План и оставшееся время"],
    .detail: ["en": "Start, end and goal", "tr": "Başlangıç, bitiş ve hedef", "de": "Start, Ende und Ziel", "es": "Inicio, fin y objetivo", "fr": "Début, fin et objectif", "it": "Inizio, fine e obiettivo", "ru": "Начало, конец и цель"],
    .plan: ["en": "Your plan and start fasting", "tr": "Plan ve oruca başla", "de": "Dein Plan und Fasten starten", "es": "Tu plan y empezar a ayunar", "fr": "Ton plan et démarrer le jeûne", "it": "Il tuo piano e inizia il digiuno", "ru": "Ваш план и начало голодания"],
    .today: ["en": "Plan and motivation", "tr": "Plan ve motivasyon", "de": "Plan und Motivation", "es": "Plan y motivación", "fr": "Plan et motivation", "it": "Piano e motivazione", "ru": "План и мотивация"],
    .week: ["en": "Weekly fasting summary", "tr": "Haftalık oruç özeti", "de": "Wöchentliche Fastenübersicht", "es": "Resumen semanal de ayuno", "fr": "Résumé hebdomadaire du jeûne", "it": "Riepilogo settimanale digiuno", "ru": "Недельная сводка голодания"],
  ]

  static func name(_ w: WidgetText) -> String { names[w]?[lang] ?? names[w]?["en"] ?? "" }
  static func description(_ w: WidgetText) -> String {
    descriptions[w]?[lang] ?? descriptions[w]?["en"] ?? ""
  }
}

@main
struct MochiWidgets: WidgetBundle {
  var body: some Widget {
    WaterWidget()
    FastingWidget()
    FastingCardWidget()
    FastingDetailWidget()
    FastingPlanWidget()
    FastingOmhWidget()
    FastingWeekWidget()
  }
}
