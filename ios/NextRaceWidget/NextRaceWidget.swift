import WidgetKit
import SwiftUI

// MARK: - Data

private let appGroup = "group.com.example.czechbmxApp"

struct RaceEntry: TimelineEntry {
    let date: Date
    let raceName: String
    let raceDate: Date?
    let city: String
}

private func loadEntry() -> RaceEntry {
    let defaults = UserDefaults(suiteName: appGroup)
    let name = defaults?.string(forKey: "next_race_name") ?? ""
    let dateStr = defaults?.string(forKey: "next_race_date") ?? ""
    let city = defaults?.string(forKey: "next_race_city") ?? ""

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "UTC")
    let raceDate = formatter.date(from: dateStr)

    return RaceEntry(date: Date(), raceName: name, raceDate: raceDate, city: city)
}

// MARK: - Provider

struct NextRaceProvider: TimelineProvider {
    func placeholder(in context: Context) -> RaceEntry {
        RaceEntry(date: Date(), raceName: "Czech BMX Open", raceDate: Date(), city: "Praha")
    }

    func getSnapshot(in context: Context, completion: @escaping (RaceEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RaceEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh at next midnight
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 0
        let nextMidnight = Calendar.current.date(from: components) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Colors

private extension Color {
    static let bmxBackground = Color(red: 0x12/255, green: 0x14/255, blue: 0x20/255)
    static let bmxOrange = Color(red: 0xE8/255, green: 0x40/255, blue: 0x00/255)
    static let bmxGray = Color(white: 0.55)
}

// MARK: - Helpers

private func daysUntil(_ raceDate: Date?) -> Int? {
    guard let raceDate = raceDate else { return nil }
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let race = calendar.startOfDay(for: raceDate)
    let components = calendar.dateComponents([.day], from: today, to: race)
    return components.day
}

private func formattedDate(_ date: Date?) -> String {
    guard let date = date else { return "—" }
    let f = DateFormatter()
    f.dateFormat = "d. M. yyyy"
    return f.string(from: date)
}

// MARK: - Views

struct SmallWidgetView: View {
    let entry: RaceEntry

    var body: some View {
        let days = daysUntil(entry.raceDate)
        ZStack(alignment: .topLeading) {
            Color.bmxBackground
            VStack(alignment: .leading, spacing: 0) {
                // Orange top bar
                Rectangle()
                    .fill(Color.bmxOrange)
                    .frame(height: 4)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("PŘÍŠTÍ ZÁVOD")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.bmxGray)
                        .textCase(.uppercase)

                    if entry.raceName.isEmpty {
                        Text("Žádný závod")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                    } else {
                        Text(entry.raceName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }

                    if let days = days {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(days)")
                                .font(.system(size: 28, weight: .black))
                                .foregroundColor(.bmxOrange)
                            Text(days == 1 ? "den" : days < 5 ? "dny" : "dní")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.bmxGray)
                        }
                    } else {
                        Text(formattedDate(entry.raceDate))
                            .font(.system(size: 11))
                            .foregroundColor(.bmxGray)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: RaceEntry

    var body: some View {
        let days = daysUntil(entry.raceDate)
        ZStack {
            Color.bmxBackground
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.bmxOrange)
                    .frame(height: 4)

                HStack(alignment: .center, spacing: 0) {
                    // Left: countdown
                    VStack(alignment: .center, spacing: 2) {
                        if let days = days {
                            Text("\(days)")
                                .font(.system(size: 42, weight: .black))
                                .foregroundColor(.bmxOrange)
                            Text(days == 1 ? "DEN" : days < 5 ? "DNY" : "DNÍ")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.bmxGray)
                        } else {
                            Image(systemName: "flag.checkered")
                                .font(.system(size: 32))
                                .foregroundColor(.bmxOrange)
                        }
                    }
                    .frame(width: 80)

                    // Divider
                    Rectangle()
                        .fill(Color.bmxOrange.opacity(0.4))
                        .frame(width: 1)
                        .padding(.vertical, 12)

                    // Right: details
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PŘÍŠTÍ ZÁVOD")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.bmxGray)

                        Text(entry.raceName.isEmpty ? "Žádný závod" : entry.raceName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        if !entry.city.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.bmxOrange)
                                Text(entry.city)
                                    .font(.system(size: 11))
                                    .foregroundColor(.bmxGray)
                            }
                        }

                        Text(formattedDate(entry.raceDate))
                            .font(.system(size: 11))
                            .foregroundColor(.bmxGray)
                    }
                    .padding(.leading, 14)
                    .padding(.trailing, 10)

                    Spacer()
                }
                .padding(.vertical, 12)
            }
        }
    }
}

struct NextRaceWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: RaceEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

@main
struct NextRaceWidget: Widget {
    let kind = "NextRaceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextRaceProvider()) { entry in
            if #available(iOS 17.0, *) {
                NextRaceWidgetEntryView(entry: entry)
                    .containerBackground(Color.bmxBackground, for: .widget)
            } else {
                NextRaceWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Příští závod")
        .description("Zobrazuje počet dní do nejbližšího závodu.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

struct NextRaceWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sample = RaceEntry(
            date: Date(),
            raceName: "Czech BMX Open Brno",
            raceDate: Calendar.current.date(byAdding: .day, value: 12, to: Date()),
            city: "Brno"
        )
        Group {
            NextRaceWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            NextRaceWidgetEntryView(entry: sample)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
