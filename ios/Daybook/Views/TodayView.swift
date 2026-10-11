import SwiftUI

/// STRIP: Mon…Sun → index in the 7-day window (today = Wed).
private let strip: [Int?] = [4, 5, 6, nil, nil, nil, nil]

struct TodayView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c

    var body: some View {
        Page { proxy in
            GHead(eyebrow: Day.fmt(Seed.today, "EEEEMMMMd"), title: "Today") {
                IconBtn(badge: m.unreadCount, label: "Notifications", action: { m.push(.notifs) }) { Ico(.bell, 18) }
                Button { m.push(.profile) } label: { Av(p: "me", size: 38) }
                    .buttonStyle(.press)
                    .accessibilityLabel("Profile")
            }
            Text("Good evening, \(Text(m.person("me").name).fontWeight(.semibold).foregroundStyle(c.acc)).")
                .font(.sans(15)).foregroundStyle(c.ink2)
                .padding(.top, 4).padding(.horizontal, 2)
            WeekStrip().padding(.top, 14)
            ProgressCard().padding(.top, 10)
            if m.day == 6 {
                HStack {
                    Spacer()
                    IconBtn(acc: true, label: "New habit", action: { m.openCreate() }) { Ico(.plus, 18) }
                }
                .padding(.top, 14).padding(.bottom, 2)
                HabitList(readonly: false, proxy: proxy)
            } else {
                PastDayHeader()
                HabitList(readonly: true, proxy: proxy)
            }
        }
    }
}

private struct WeekStrip: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<7, id: \.self) { k in
                let i = strip[k], fut = i == nil, sel = m.day == i
                Button { if let i { withAnimation(.easeOut(duration: 0.2)) { m.selectDay(i) } } } label: {
                    VStack(spacing: 4) {
                        Text(["M", "T", "W", "T", "F", "S", "S"][k]).font(.mono(9.5)).tracking(0.76)
                            .foregroundStyle(sel ? Brand.onWine.opacity(0.7) : c.ink3)
                        ZStack {
                            if let i {
                                Ring(size: 30, stroke: 2.5, pct: m.dayRatio(i), track: sel ? .white.opacity(0.25) : c.line, color: sel ? Brand.onWine : c.acc)
                            }
                            Text("\(5 + k)").font(.serif(17))
                        }
                        .frame(width: 30, height: 30)
                        Circle().fill(i == 6 ? (sel ? Brand.onWine : c.acc) : .clear).frame(width: 4, height: 4)
                    }
                    .foregroundStyle(sel ? Brand.onWine : c.ink)
                    .padding(.top, 6).padding(.bottom, 7)
                    .frame(maxWidth: .infinity, minHeight: 62)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(sel ? c.acc : .clear))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(fut)
                .opacity(fut ? 0.38 : 1)
            }
        }
        .padding(6)
        .card(0, radius: 16)
    }
}

private struct ProgressCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let req = m.required
        let doneN = req.filter { m.isDone($0, "me") }.count
        let pct = req.isEmpty ? 0 : Double(doneN) / Double(req.count)
        HStack(spacing: 14) {
            ZStack {
                Ring(size: 56, stroke: 5, pct: pct, track: c.line, color: c.acc)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(doneN)").font(.sans(17, .bold))
                    Text("/").font(.sans(13, .medium)).foregroundStyle(c.ink3)
                    Text("\(req.count)").font(.sans(17, .bold))
                }
                .foregroundStyle(c.ink)
            }
            Text("Done today").font(.sans(16, .semibold)).foregroundStyle(c.ink).frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 0) {
                Eyebrow("Your week", size: 9).padding(.bottom, 6)
                Dots7(states: (0..<7).map { i in let r = m.dayRatio(i); return r >= 1 ? .on : r > 0 ? .half : .off }, size: 13, radius: 4, gap: 4)
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(Day.narrow(Day.date(i))).font(.mono(9, i == 6 ? .medium : .regular))
                            .foregroundStyle(i == 6 ? c.acc : c.ink3).frame(width: 13)
                    }
                }
                .padding(.top, 4)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Your week, " + (0..<7).map { i in
                let r = m.dayRatio(i)
                return "\(i == 6 ? "today" : Day.weekday(Day.date(i))) \(r >= 1 ? "all done" : r > 0 ? "some done" : "none done")"
            }.joined(separator: ", "))
        }
        .card(v: 13, h: 16)
    }
}

private struct PastDayHeader: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let req = m.required
        let done = req.filter { m.week($0, "me")[m.day] != 0 }.count
        VStack(alignment: .leading, spacing: 3) {
            Text(Day.weekday(Day.date(m.day))).font(.serif(23)).foregroundStyle(c.ink)
            HStack(spacing: 0) {
                Text("\(done) of \(req.count) done · ").font(.sans(12.5)).foregroundStyle(c.ink3)
                Button("Back to today") { withAnimation(.easeOut(duration: 0.2)) { m.selectDay(6) } }
                    .font(.sans(12.5, .semibold)).foregroundStyle(c.acc)
            }
        }
        .padding(.horizontal, 2).padding(.top, 22).padding(.bottom, 8)
    }
}

/// Habits sorted by time, each timed one under its time label.
private struct HabitList: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let readonly: Bool
    let proxy: ScrollViewProxy

    var body: some View {
        let sorted = stableSorted(m.habits) { a, b in
            let ta = Day.hasTime(a) ? 1 : 0, tb = Day.hasTime(b) ? 1 : 0
            if tb - ta != 0 { return tb - ta }
            return ta == 1 ? Day.tmin(a.time) - Day.tmin(b.time) : 0
        }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, h in
                if Day.hasTime(h) {
                    HStack(spacing: 8) {
                        Text(h.time).font(.mono(10.5)).tracking(1.26).textCase(.uppercase).foregroundStyle(c.ink2)
                        Rectangle().fill(c.line).frame(height: 1)
                    }
                    .padding(.horizontal, 4).padding(.top, idx == 0 && !readonly ? 0 : 8).padding(.bottom, 4)
                }
                HabitCard(h: h, readonly: readonly, dayIdx: m.day, proxy: proxy).id(h.id)
            }
        }
        .onChange(of: m.anim) { _, id in
            guard let id else { return }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 30_000_000)
                withAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.32)) { m.anim = nil }
                withAnimation { proxy.scrollTo(id) }
            }
        }
    }
}

struct HabitCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit
    var readonly = false
    var dayIdx = 6
    let proxy: ScrollViewProxy

    var body: some View {
        let d = readonly ? m.week(h, "me")[dayIdx] != 0 : m.isDone(h, "me")
        let open = !readonly && m.expanded == h.id && m.anim != h.id
        let ppl = m.peopleOf(h)
        let w = m.week(h, "me")
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CheckButton(done: d, readonly: readonly, name: h.name) { m.check(h.id) }
                Button {
                    withAnimation(.timingCurve(0.2, 0.9, 0.25, 1, duration: 0.32)) { m.toggleExpand(h.id) }
                    if m.expanded == h.id {
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 340_000_000)
                            withAnimation { proxy.scrollTo(h.id) }
                        }
                    }
                } label: {
                    HStack(spacing: 11) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(h.name).font(.sans(15, .semibold)).tracking(-0.075).lineLimit(1)
                                .foregroundStyle(d ? c.ink2 : c.ink)
                                .strikethrough(d, color: c.acc.opacity(0.6))
                            HStack(spacing: 10) {
                                Dots7(states: Dots7.from(w))
                                if m.shared(h) {
                                    AvStack(list: ppl.filter { $0 != "me" }, size: 22, max: 4, ok: { m.isDone(h, $0) })
                                }
                            }
                            .frame(minHeight: 20)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Tile(size: 36, on: d) { HIcon(h.ic, 18) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(readonly)
                .accessibilityValue(open ? "Expanded" : "Collapsed")
            }
            .padding(.leading, 14).padding(.trailing, 11).padding(.vertical, 9)

            if open {
                Button { m.openDetails(h.id) } label: {
                    HStack(spacing: 12) {
                        Tile(size: 32, rotate: false, radiusScale: 0.95) { Ico(.info, 17) }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Details").font(.sans(14, .semibold)).foregroundStyle(c.ink)
                            Text(m.shared(h) ? "Streak, today’s photos and calendar · \(m.doneCount(h))/\(ppl.count) done" : "Streak and calendar")
                                .font(.sans(12)).foregroundStyle(c.ink3).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Ico(.right, 14).foregroundStyle(c.acc)
                    }
                    .padding(.vertical, 11).padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(c.card2))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(c.line, lineWidth: 1))
                }
                .buttonStyle(.press)
                .padding(.horizontal, 14).padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipShape(shape)
        .background(shape.fill(d ? c.accOn(0.05) : c.card).shadow(color: c.shadow.opacity(0.75), radius: 6, y: 5))
        .overlay(shape.strokeBorder(d ? c.acc.opacity(0.55) : c.acc.opacity(0.14), lineWidth: d ? 1.2 : 1))
        .padding(.bottom, 6)
        .animation(.easeOut(duration: 0.25), value: d)
    }
}

/// The check: Daybook stamp look, tap-to-tick behaviour.
struct CheckButton: View {
    @Environment(\.pal) private var c
    let done: Bool
    var readonly = false
    let name: String
    let action: () -> Void
    @State private var ring = false

    var body: some View {
        let face = ZStack {
            Circle().fill(done ? c.acc : c.card)
            if !done { Circle().strokeBorder(c.acc.opacity(0.6), lineWidth: 1.6) }
            if done {
                Ico(.check, 12).foregroundStyle(Brand.onWine)
                    .transition(.asymmetric(insertion: .scale(scale: 1.7).combined(with: .opacity), removal: .opacity))
            }
        }
        .frame(width: 26, height: 26)
        .rotationEffect(.degrees(done ? -6 : 0))
        .background(
            Circle().stroke(c.acc.opacity(ring ? 0 : 0.5), lineWidth: ring ? 14 : 0).scaleEffect(ring ? 1.5 : 1).opacity(ring ? 0 : 1)
        )
        if readonly {
            face.opacity(done ? 1 : 0.5)
        } else {
            Button {
                if !done {
                    ring = false
                    withAnimation(.easeOut(duration: 0.6)) { ring = true }
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) { action() }
            } label: { face }
            .buttonStyle(PressStyle(scale: 0.88))
            .accessibilityLabel(done ? "Undo check-in for \(name)" : "Check off \(name)")
        }
    }
}

// MARK: - Shared habit blocks (details popup + group page)

struct StreakBlock: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit
    var body: some View {
        let w = m.week(h, "me")
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 14) {
                Text("\(m.streak(h, "me"))").font(.serif(46)).foregroundStyle(c.acc)
                Text("day streak\non \(h.name)").font(.sans(13)).foregroundStyle(c.ink2).lineSpacing(2)
            }
            .padding(.bottom, 12)
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    let on = w[i] != 0, today = i == 6
                    VStack(spacing: 5) {
                        ZStack {
                            Circle().fill(on ? c.acc : .clear)
                            if !on { Circle().strokeBorder(today ? c.ink : c.line2, lineWidth: today ? 1.5 : 1.4) }
                            if on { Ico(.check, 12).foregroundStyle(Brand.onWine) }
                        }
                        .frame(width: 30, height: 30)
                        Text(today ? "Today" : Day.narrow(Day.date(i))).font(.mono(9.5, today ? .medium : .regular))
                            .foregroundStyle(today ? c.ink : c.ink3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

/// Block header: eyebrow left, eyebrow right.
struct BlkHead<Right: View>: View {
    let left: String
    @ViewBuilder var right: Right
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Eyebrow(left)
            Spacer(minLength: 0)
            right
        }
        .padding(.bottom, 8)
    }
}

struct DoneTodayLabel: View {
    @Environment(\.pal) private var c
    let done: Bool
    var body: some View {
        if done { Text("Done today").eyebrowStyle(c.acc).fontWeight(.medium) } else { Eyebrow("Not yet today") }
    }
}

/// Today's photos row: you first, then friends (done first, by time).
struct TodayStrip: View {
    @Environment(AppModel.self) private var m
    let h: Habit
    var body: some View {
        let others = stableSorted(m.peopleOf(h).filter { $0 != "me" }) { a, b in
            let da = m.isDone(h, a) ? 1 : 0, db = m.isDone(h, b) ? 1 : 0
            if db - da != 0 { return db - da }
            return da == 1 ? Day.tmin(h.mem[a]?.done ?? "") - Day.tmin(h.mem[b]?.done ?? "") : 0
        }
        Bleed(inset: 16, spacing: 8) {
            ForEach(["me"] + others, id: \.self) { p in PersonTile(h: h, p: p) }
        }
    }
}

struct PersonTile: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit
    let p: String
    var body: some View {
        let me = p == "me", d = m.isDone(h, p)
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        Button {
            if d { m.viewPost(h.id, p) } else if me { m.addPhoto(h.id) }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if d && m.hasPhoto(h, p) {
                        if me, let item = m.storyItem(for: h.id), let img = m.storyImage(item) {
                            Image(uiImage: img).resizable().scaledToFill().frame(width: 78, height: 98).clipped()
                        } else {
                            PhotoFill(floorCell: 16, floorHeight: 40, floorOpacity: 0.28, center: UnitPoint(x: 0.5, y: 0.3))
                            HIcon(h.ic, 26, 1.3).foregroundStyle(Color(red: 1, green: 236 / 255, blue: 226 / 255).opacity(0.88))
                        }
                        Av(p: p, size: 20).background(Circle().stroke(Brand.wineInk, lineWidth: 3))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(5)
                    } else if d {
                        c.card
                        VStack(spacing: 7) {
                            Ico(.check, 14).foregroundStyle(Brand.onWine).frame(width: 30, height: 30).background(Circle().fill(c.acc))
                            TileLabel("Done\nno photo")
                        }
                        .foregroundStyle(c.ink2)
                        if me {
                            Text("+ Photo").font(.sans(9, .bold)).foregroundStyle(c.bg)
                                .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(c.ink))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(5)
                        }
                    } else if me {
                        VStack(spacing: 7) { Ico(.camera, 20); TileLabel("Check in") }.foregroundStyle(c.acc)
                    } else {
                        c.bg2
                        VStack(spacing: 7) {
                            Av(p: p, size: 34).grayscale(1).opacity(0.45)
                            TileLabel("Not done\nyet")
                        }
                        .foregroundStyle(c.ink3)
                    }
                }
                .frame(width: 78, height: 98)
                .clipShape(shape)
                .overlay {
                    if d && !m.hasPhoto(h, p) { shape.strokeBorder(c.line, lineWidth: 1) }
                    else if !d { shape.strokeBorder(me ? c.acc : c.line2, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])) }
                }
                Text(me ? "You" : m.person(p).name).font(.sans(12, .semibold)).foregroundStyle(!d && !me ? c.ink3 : c.ink)
                    .lineLimit(1).frame(maxWidth: 78, alignment: .leading).padding(.top, 6)
                Text(d ? (h.mem[p]?.done ?? "") : "Not yet").font(.sans(10.5)).foregroundStyle(c.ink3).lineLimit(1)
            }
            .frame(width: 78, alignment: .leading)
        }
        .buttonStyle(.press)
        .disabled(!d && !me)
    }
}

private struct TileLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.mono(8.5)).tracking(1).textCase(.uppercase).multilineTextAlignment(.center).lineSpacing(1)
    }
}
