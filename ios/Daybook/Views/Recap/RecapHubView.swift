import Charts
import SwiftData
import SwiftUI

struct RecapHubView: View {
    @Environment(AppModel.self) private var model
    @Query(sort: \WeeklyRecap.weekStart, order: .reverse) private var past: [WeeklyRecap]
    @Query(sort: \CheckIn.completedAt) private var checkIns: [CheckIn]
    @State private var data: RecapData?
    @State private var playing: RecapData?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data {
                    hero(data)
                    weekChart(data)
                    superlativesPreview(data)
                    quickSettings
                    pastRecaps
                } else {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .padding(Metrics.gutter)
        }
        .background(PaperBackground())
        .navigationTitle("Recap")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { model.router.push(.share(.recap)) } label: { Image(systemName: "square.and.arrow.up") }
                    .accessibilityLabel("Share and export")
            }
        }
        .refreshable { data = model.buildRecap() }
        .onAppear { data = model.buildRecap() }
        .onChange(of: checkIns.count) { _, _ in data = model.buildRecap() }
        .fullScreenCover(item: Binding(get: { playing.map(IdentifiedRecap.init) }, set: { playing = $0?.data })) { wrapper in
            RecapPlayerView(data: wrapper.data)
        }
    }

    private func hero(_ data: RecapData) -> some View {
        Button {
            model.feedback(.superlativeReveal)
            playing = data
        } label: {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22).fill(Palette.spotlight)
                RuledLines(spacing: 28, margin: false).opacity(0.4).clipShape(RoundedRectangle(cornerRadius: 22))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("THIS WEEK'S AWARDS")
                            .font(.eyebrow).tracking(1.4).foregroundStyle(Palette.burgundy)
                        Spacer()
                        InkStamp(text: "Ready", symbol: "film.fill", size: 64).rotationEffect(.degrees(12))
                    }
                    Text(data.headline)
                        .font(.award(.largeTitle))
                        .foregroundStyle(Palette.burgundy)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(data.totalCompletions) check-ins · \(data.consistency?.percentText ?? "—") consistency · \(data.superlatives.count) awards")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                    Label("Play recap", systemImage: "play.fill")
                        .font(.display(.body))
                        .foregroundStyle(Palette.onAccent)
                        .padding(.horizontal, 18)
                        .frame(minHeight: 46)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Palette.burgundy))
                        .padding(.top, 6)
                }
                .padding(20)
            }
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Palette.burgundy.opacity(0.35), lineWidth: 1))
            .shadow(color: Palette.shadow, radius: 8, y: 4)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Play this week's recap. \(data.headline)")
    }

    private func weekChart(_ data: RecapData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("Last 7 days")
            Chart(data.dailyCounts, id: \.day) { entry in
                BarMark(x: .value("Day", entry.day, unit: .day), y: .value("Check-ins", entry.count))
                    .foregroundStyle(Day.weekday(entry.day) == data.strongestWeekday ? Palette.burgundy : Palette.rose)
                    .cornerRadius(5)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) }
            .frame(height: 130)
            HStack {
                StatPill(value: "\(data.comebacks)", label: "comebacks", tint: .orange)
                StatPill(value: "\(data.reactionsSent + data.commentsSent)", label: "cheers sent", tint: .rose)
                StatPill(value: Day.shortName(forWeekday: data.strongestWeekday), label: "best day", tint: .gold)
            }
        }
        .card()
    }

    private func superlativesPreview(_ data: RecapData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Superlatives")
                Spacer()
                HandNote("spoilers inside the recap", size: 14)
            }
            ForEach(data.superlatives.prefix(4)) { award in
                HStack(spacing: 10) {
                    SymbolBadge(symbol: award.symbol, tint: award.tint, size: 34, filled: true)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(award.title).font(.display(.subheadline, weight: .bold)).foregroundStyle(Palette.ink)
                        Text(award.source.rawValue).font(.caption2.weight(.semibold)).foregroundStyle(award.source == .activity ? Palette.sage : Palette.sky)
                    }
                    Spacer()
                    Image(systemName: "envelope.fill").foregroundStyle(Palette.inkFaint)
                        .accessibilityLabel("Sealed until you play the recap")
                }
            }
        }
        .card()
    }

    private var quickSettings: some View {
        @Bindable var prefs = model.prefs
        return VStack(alignment: .leading, spacing: 4) {
            Eyebrow("Recap settings")
            Toggle("Recap sounds", isOn: $prefs.recapSounds).onChange(of: prefs.recapSounds) { _, _ in model.save() }
            Picker("Who can see my recap", selection: $prefs.recapVisibilityRaw) {
                ForEach(Visibility.allCases) { Text($0.label).tag($0.rawValue) }
            }
            .onChange(of: prefs.recapVisibilityRaw) { _, _ in model.save() }
        }
        .tint(Palette.burgundy)
        .card()
    }

    private var pastRecaps: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow("Past weeks")
                Spacer()
                Button("See all") { model.router.push(.recapArchive) }.font(.footnote.weight(.semibold))
            }
            ForEach(past.prefix(3)) { recap in
                PastRecapRow(recap: recap)
            }
        }
        .card()
    }
}

private struct IdentifiedRecap: Identifiable {
    let id = UUID()
    let data: RecapData
}

struct StatPill: View {
    let value: String
    let label: String
    var tint: TintToken = .burgundy

    var body: some View {
        VStack(spacing: 1) {
            Text(value).font(.display(.headline, weight: .heavy)).foregroundStyle(Palette.ink)
            Text(label).font(.caption2).foregroundStyle(Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(RoundedRectangle(cornerRadius: 10).fill(tint.color.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }
}

struct PastRecapRow: View {
    let recap: WeeklyRecap

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text(recap.weekStart.formatted(.dateTime.month(.abbreviated))).font(.caption2.weight(.heavy)).textCase(.uppercase)
                Text(recap.weekStart.formatted(.dateTime.day())).font(.display(.title3, weight: .heavy))
            }
            .foregroundStyle(Palette.burgundy)
            .frame(width: 48, height: 48)
            .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.burgundy.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2])))
            VStack(alignment: .leading, spacing: 2) {
                Text(recap.headline).font(.display(.subheadline, weight: .semibold)).foregroundStyle(Palette.ink)
                Text("\(recap.completions) check-ins · \(recap.consistency.percentText) · \(recap.superlativeTitle)")
                    .font(.caption).foregroundStyle(Palette.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct RecapArchiveView: View {
    @Query(sort: \WeeklyRecap.weekStart, order: .reverse) private var past: [WeeklyRecap]

    var body: some View {
        List {
            if past.isEmpty {
                EmptyStateView(symbol: "film.stack", title: "No past recaps", message: "Your first recap appears after a full week.")
                    .listRowBackground(Color.clear)
            }
            ForEach(past) { recap in
                VStack(alignment: .leading, spacing: 8) {
                    PastRecapRow(recap: recap)
                    HStack {
                        Label("Strongest: \(Day.longName(forWeekday: recap.strongestWeekday))", systemImage: "calendar")
                        Spacer()
                        Label(recap.topHabitName, systemImage: "star.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(Palette.inkSecondary)
                }
                .padding(.vertical, 6)
                .listRowBackground(Palette.card)
            }
        }
        .scrollContentBackground(.hidden)
        .background(PaperBackground())
        .navigationTitle("Past recaps")
    }
}
