import SwiftUI
import WidgetKit

struct CatalystBellEntry: TimelineEntry {
    let date: Date
}

struct CatalystBellProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatalystBellEntry {
        CatalystBellEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CatalystBellEntry) -> Void) {
        completion(CatalystBellEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CatalystBellEntry>) -> Void) {
        completion(Timeline(entries: [CatalystBellEntry(date: Date())], policy: .never))
    }
}

struct CatalystBellComplicationView: View {
    var body: some View {
        Image("ComplicationBellSilhouette")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(.white)
            .padding(5)
        .containerBackground(.black, for: .widget)
        .widgetURL(URL(string: "catalystbell://start?source=complication"))
    }
}

struct CatalystBellComplication: Widget {
    let kind = "CatalystBellComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatalystBellProvider()) { _ in
            CatalystBellComplicationView()
        }
        .configurationDisplayName("Catalyst Bell")
        .description("Start a discreet haptic anchor.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}

@main
struct CatalystBellComplicationBundle: WidgetBundle {
    var body: some Widget {
        CatalystBellComplication()
    }
}
