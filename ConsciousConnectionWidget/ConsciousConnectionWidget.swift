import WidgetKit
import SwiftUI

struct ConsciousConnectionWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let symbolName: String
}

struct ConsciousConnectionWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ConsciousConnectionWidgetEntry {
        ConsciousConnectionWidgetEntry(
            date: Date(),
            title: "Good Morning",
            subtitle: "Start gently",
            symbolName: "sun.max.fill"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ConsciousConnectionWidgetEntry) -> Void) {
        completion(entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConsciousConnectionWidgetEntry>) -> Void) {
        let now = Date()
        let currentEntry = entry(for: now)
        let refreshDate = nextRefreshDate(after: now)

        let timeline = Timeline(entries: [currentEntry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func entry(for date: Date) -> ConsciousConnectionWidgetEntry {
        let hour = Calendar.current.component(.hour, from: date)

        if hour >= 6 && hour < 9 {
            return ConsciousConnectionWidgetEntry(
                date: date,
                title: "Good Morning",
                subtitle: "Start gently",
                symbolName: "sun.max.fill"
            )
        } else if hour >= 21 || hour < 6 {
            return ConsciousConnectionWidgetEntry(
                date: date,
                title: "Night Routine",
                subtitle: "Wind down",
                symbolName: "moon.stars.fill"
            )
        } else {
            return ConsciousConnectionWidgetEntry(
                date: date,
                title: "Conscious\nConnection",
                subtitle: "Open home",
                symbolName: "sparkles"
            )
        }
    }

    private func nextRefreshDate(after date: Date) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        guard
            let sixAM = calendar.date(byAdding: .hour, value: 6, to: startOfDay),
            let nineAM = calendar.date(byAdding: .hour, value: 9, to: startOfDay),
            let ninePM = calendar.date(byAdding: .hour, value: 21, to: startOfDay),
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let tomorrowSixAM = calendar.date(byAdding: .hour, value: 6, to: tomorrow)
        else {
            return date.addingTimeInterval(60 * 60)
        }

        if date < sixAM {
            return sixAM
        } else if date < nineAM {
            return nineAM
        } else if date < ninePM {
            return ninePM
        } else {
            return tomorrowSixAM
        }
    }
}

struct ConsciousConnectionWidgetEntryView: View {
    let entry: ConsciousConnectionWidgetProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var inlineTitle: String {
        entry.title.replacingOccurrences(of: "\n", with: " ")
    }

    var body: some View {
        switch family {

        case .accessoryInline:
            Label {
                Text(inlineTitle)
                    .font(.system(size: 14, weight: .semibold))
            } icon: {
                Image(systemName: entry.symbolName)
            }

        case .accessoryCircular:
            ZStack {
                Circle()
                    .fill(.clear)

                Image(systemName: entry.symbolName)
                    .font(.system(size: 20, weight: .bold))
            }

        case .accessoryRectangular:
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 15, weight: .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(entry.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 34, weight: .bold))

                Text(entry.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)

                Text(entry.subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .padding(4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .systemMedium:
            HStack(spacing: 18) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 48, weight: .bold))

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.title)
                        .font(.system(size: 28, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(entry.subtitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        case .systemLarge, .systemExtraLarge:
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 56, weight: .bold))

                Text(entry.title)
                    .font(.system(size: 34, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)

                Text(entry.subtitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

        @unknown default:
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: entry.symbolName)
                    .font(.system(size: 34, weight: .bold))

                Text(entry.title)
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(2)

                Text(entry.subtitle)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct ConsciousConnectionWidget: Widget {
    let kind = "ConsciousConnectionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ConsciousConnectionWidgetProvider()) { entry in
            ConsciousConnectionWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Conscious Connection")
        .description("Shows the right entry point for this time of day.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

#Preview(as: .systemSmall) {
    ConsciousConnectionWidget()
} timeline: {
    ConsciousConnectionWidgetEntry(
        date: .now,
        title: "Good Morning",
        subtitle: "Start gently",
        symbolName: "sun.max.fill"
    )
}
