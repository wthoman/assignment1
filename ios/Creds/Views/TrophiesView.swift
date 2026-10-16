import SwiftUI

/// Trophies tab — Creds' book layout, filled with trophies & medals.
struct TrophiesView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c

    private func pass(_ t: Trophy) -> Bool {
        m.trFilter == "All" || (m.trFilter == "Earned" ? t.got != nil : t.got == nil)
    }

    var body: some View {
        let got = m.trophies.filter { $0.got != nil }.count, total = m.trophies.count
        Page { proxy in
            GHead(eyebrow: "Your case", title: "Trophies") {
                IconBtn(label: m.trView == "book" ? "Grid view" : "Book view", action: { m.trView = m.trView == "book" ? "grid" : "book" }) {
                    Ico(m.trView == "book" ? .grid : .book)
                }
            }
            HStack(spacing: 14) {
                ZStack {
                    Ring(size: 56, stroke: 6, pct: Double(got) / Double(total), track: c.line, color: c.acc)
                    Text("\(got)").font(.sans(19, .bold)).foregroundStyle(c.ink)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(got) of \(total) earned").font(.serif(24)).foregroundStyle(c.ink)
                    Text("Tap any trophy or medal for a closer look.").font(.sans(12.5)).foregroundStyle(c.ink3)
                }
                Spacer(minLength: 0)
            }
            .card()
            .padding(.top, 12)
            Bleed(inset: 16, spacing: 6) {
                ForEach(["All", "Earned", "Still locked"], id: \.self) { f in Chip(label: f, on: m.trFilter == f) { m.trFilter = f } }
            }
            .padding(.top, 12)
            if m.trView == "book" {
                FlowLayout(spacing: 4) {
                    ForEach(Seed.pages, id: \.id) { pg in
                        Button { withAnimation { proxy.scrollTo("page-" + pg.id, anchor: .top) } } label: {
                            Text(pg.name).font(.sans(12.5, .semibold)).foregroundStyle(c.ink)
                                .padding(.horizontal, 11).frame(height: 30)
                                .background(UnevenRoundedRectangle(topLeadingRadius: 9, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 9).fill(c.bg2))
                                .overlay(UnevenRoundedRectangle(topLeadingRadius: 9, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 9).strokeBorder(c.line, lineWidth: 1))
                        }
                        .buttonStyle(.press)
                    }
                }
                .padding(.top, 14)
                let pages = Seed.pages.enumerated().compactMap { i, pg -> (Int, TrophyPage, [Trophy])? in
                    let items = m.trophies.filter { $0.pg == pg.id && pass($0) }
                    return items.isEmpty ? nil : (i, pg, items)
                }
                if pages.isEmpty {
                    EmptyNote(text: "Nothing here yet.").padding(.top, 14)
                }
                ForEach(pages, id: \.1.id) { i, pg, items in
                    BookPage(index: i, page: pg, items: items).id("page-" + pg.id)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(m.trophies.filter(pass)) { t in
                        TrophyItem(t: t, grid: true)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12).padding(.horizontal, 6)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.card))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(c.line, lineWidth: 1))
                    }
                }
                .padding(.top, 14)
            }
        }
    }
}

private struct BookPage: View {
    @Environment(\.pal) private var c
    let index: Int
    let page: TrophyPage
    let items: [Trophy]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(page.name).font(.serif(24)).foregroundStyle(c.ink)
                Spacer(minLength: 0)
                Text(page.note).font(.serifRaw(16)).italic().foregroundStyle(c.acc).rotationEffect(.degrees(-3))
            }
            .padding(.leading, 18)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 4) {
                ForEach(items) { TrophyItem(t: $0, grid: false) }
            }
            .padding(.leading, 12).padding(.top, 10)
        }
        .padding(.top, 20).padding(.horizontal, 16).padding(.bottom, 14)
        .background(
            ZStack {
                c.card
                Ruled(color: c.acc.opacity(0.09), marginX: 26, marginColor: c.acc.opacity(0.22))
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: Color(hex: 0x3A0A12, alpha: 0.25), radius: 5, x: 2, y: 4)
        )
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(c.line, lineWidth: 1))
        .overlay(alignment: .topLeading) { Tape(wine: index % 2 == 1).rotationEffect(.degrees(-14)).offset(x: 14, y: -7) }
        .overlay(alignment: .topTrailing) { Tape(wine: index % 2 == 0).rotationEffect(.degrees(10)).offset(x: -16, y: -7) }
        .padding(.top, 16)
    }
}

struct TrophyItem: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let t: Trophy
    let grid: Bool
    var body: some View {
        let h = hashN(t.id)
        let rot = grid ? 0 : Double(h % 15 - 7), dy = grid ? 0 : CGFloat(h % 7 - 3)
        let locked = t.got == nil
        Button { m.openTrophy(t.id) } label: {
            VStack(spacing: 0) {
                PrizeArt(trophy: t, width: 62)
                    .opacity(locked ? 0.28 : 1).grayscale(locked ? 1 : 0)
                Group {
                    if locked {
                        Text("LOCKED").font(.mono(10)).tracking(1).foregroundStyle(c.ink3)
                    } else {
                        Text(t.name).font(.serif(14.5)).italic().foregroundStyle(c.acc)
                    }
                }
                .multilineTextAlignment(.center).padding(.top, 4)
                TierDots(tier: t.tier).padding(.top, 3)
            }
            .padding(.vertical, 6).padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                if t.fresh {
                    Text("NEW").font(.mono(8.5)).tracking(0.85).foregroundStyle(Brand.wineInk)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(RoundedRectangle(cornerRadius: 4).fill(c.yel))
                        .rotationEffect(.degrees(10)).padding(.top, 2).padding(.trailing, 4)
                }
            }
            .rotationEffect(.degrees(rot))
            .offset(y: dy)
        }
        .buttonStyle(.press)
    }
}

struct TrophySheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let t = m.T(s.id) {
            let pinned = m.pinned.contains(t.id), got = t.got
            VStack(spacing: 0) {
                SheetHead { Color.clear.frame(height: 1) }
                SheetBody {
                    VStack(spacing: 0) {
                        PrizeArt(trophy: t, width: 130).opacity(got == nil ? 0.3 : 1).grayscale(got == nil ? 1 : 0)
                        Text(got == nil ? "Not earned yet" : t.name).font(.serif(32)).foregroundStyle(c.acc).padding(.top, 10)
                        HStack(spacing: 8) {
                            TierDots(tier: t.tier)
                            Eyebrow("\(t.tier.prefix(1).uppercased() + t.tier.dropFirst()) \(t.kind)")
                        }
                        .padding(.top, 8)
                        if got != nil {
                            Text("“\(t.blurb)”").font(.serif(19)).italic().foregroundStyle(c.ink).padding(.vertical, 14)
                        }
                        VStack(spacing: 0) {
                            if let got {
                                InfoRow(first: true, icon: .spark, iconSize: 16, label: "Earned for", value: t.how)
                                InfoRow(first: false, icon: .cal, iconSize: nil, label: "Date", value: got)
                            } else {
                                InfoRow(first: true, icon: .lock, iconSize: 16, label: "How to earn", value: t.how)
                            }
                        }
                        .card(v: 4, h: 14)
                        .padding(.top, got == nil ? 16 : 0)
                        if got != nil {
                            HStack(spacing: 8) {
                                Button(pinned ? "Pinned to profile" : "Pin to profile") { m.pin(t.id) }.buttonStyle(.btn(.line))
                                Button { m.showToast("Trophy card shared (mock)") } label: { Ico(.share); Text("Share") }.buttonStyle(.btn)
                            }
                            .padding(.top, 16)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

private struct InfoRow: View {
    @Environment(\.pal) private var c
    let first: Bool
    let icon: UIIcon
    let iconSize: CGFloat?
    let label: String
    let value: String
    var body: some View {
        Divided(first: first) {
            HStack(spacing: 10) {
                Ico(icon, iconSize)
                Text(label).font(.sans(14))
                Spacer(minLength: 8)
                Text(value).font(.sans(13)).foregroundStyle(c.ink3).multilineTextAlignment(.trailing)
            }
            .foregroundStyle(c.ink)
        }
    }
}
