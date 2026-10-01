import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.flywork.fastingapp"

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
    .configurationDisplayName("Su")
    .description("Günlük su hedefi")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

struct FastingEntry: TimelineEntry {
  let date: Date
  let smallPath: String?
  let mediumPath: String?
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
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return FastingEntry(
      date: Date(),
      smallPath: data?.string(forKey: "fasting_widget_image"),
      mediumPath: data?.string(forKey: "fasting_widget_medium_image")
    )
  }
}

struct FastingWidgetView: View {
  @Environment(\.widgetFamily) private var family
  var entry: FastingEntry

  var body: some View {
    let path = family == .systemMedium ? entry.mediumPath : entry.smallPath
    if let path, let image = UIImage(contentsOfFile: path) {
      Image(uiImage: image)
        .resizable()
        .scaledToFill()
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
    .configurationDisplayName("Oruç")
    .description("Kalan oruç süresi")
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
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_medium_image")
    return FastingEntry(date: Date(), smallPath: path, mediumPath: path)
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
    .configurationDisplayName("Oruç kartı")
    .description("Plan ve kalan süre")
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
    let entry = load()
    let next = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
      ?? Date().addingTimeInterval(60)
    completion(Timeline(entries: [entry], policy: .after(next)))
  }

  private func load() -> FastingEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let path = data?.string(forKey: "fasting_widget_detail_image")
    return FastingEntry(date: Date(), smallPath: path, mediumPath: path)
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
    .configurationDisplayName("Oruç özeti")
    .description("Başlangıç, bitiş ve hedef")
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

@main
struct MochiWidgets: WidgetBundle {
  var body: some Widget {
    WaterWidget()
    FastingWidget()
    FastingCardWidget()
    FastingDetailWidget()
  }
}
