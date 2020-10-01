//
//  FiveyWidget.swift
//  FiveyWidget
//
//  Created by Joel Bernstein on 8/30/20.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (FiveyTimelineEntry) -> Void) {

        let sensorID = "55075"

        let dataTask = URLSession.shared.dataTask(with: URL(string: "https://www.purpleair.com/json?show=\(sensorID)")!) {
            (data, response, error) in

            guard let data = data else { return }

            do {
                let results = try JSONDecoder().decode(SensorResults.self, from: data)

                completion(FiveyTimelineEntry(date: Date(), result: results))
            } catch {
                completion(FiveyTimelineEntry(date: Date(), result: nil))
            }
        }

        dataTask.resume()
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<FiveyTimelineEntry>) -> ()) {
        getSnapshot(for: configuration, in: context) { entry in
            completion(Timeline(entries: [entry], policy: .atEnd))
        }
    }

    func placeholder(in context: Context) -> FiveyTimelineEntry {
        FiveyTimelineEntry(date: Date(), result: nil)
    }
}

struct FiveyTimelineEntry: TimelineEntry {
    let date: Date
    let result: SensorResults?
//    let configuration: ConfigurationIntent
}

struct FiveyWidgetEntryView : View {
    var entry: FiveyTimelineEntry
    
    @Environment(\.widgetFamily) private var widgetFamily

    var updatedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    Text(entry.result?.name ?? "-")
                        .font(Font.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Label(updatedDateString, systemImage: "clock")
                        .imageScale(.small)
                        .font(Font.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(entry.result?.aqi ?? "-")
                    .font(Font.system(size: 36, weight: .bold, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)

                Text(entry.result?.description ?? "-")
                    .font(Font.system(size: 16, weight: .bold, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color.white)
            }
            
//            if widgetFamily != .systemSmall {
//                Color(UIColor.systemGroupedBackground)
//                    .overlay(WinProbabilityGraph(poll: entry.poll).padding(.trailing, 8))
//                    .clipShape(ContainerRelativeShape())
//            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight:.infinity)
        .background(entry.result?.color)
        .widgetURL(URL(string: "https://www.purpleair.com/map?opt=1/i/mAQI/a10/cC0#11/37.973/-122.1015")!)
    }
}

@main
struct FiveyWidget: Widget {
    let kind: String = "FiveyWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            FiveyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AQI")
        .description("iOS 14 widget to show PurpleAir AQI")
        .supportedFamilies([.systemSmall])
    }
}

struct FiveyWidget_Previews: PreviewProvider {
    static var previews: some View {
        let data = try? Data(contentsOf: Bundle.main.url(forResource: "fixture", withExtension: "json")!)
        let staticResults = try? JSONDecoder().decode(SensorResults.self, from: data!)
        
        FiveyWidgetEntryView(entry: FiveyTimelineEntry(date: Date(), result: staticResults))
            .previewContext(WidgetPreviewContext(family: .systemSmall))

//        FiveyWidgetEntryView(entry: FiveyTimelineEntry(date: Date(), poll: polls?.first, configuration: ConfigurationIntent()))
//            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
