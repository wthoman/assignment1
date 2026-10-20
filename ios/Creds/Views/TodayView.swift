import SwiftUI

/// Days shown in the strip: the 7-day window (0…6, today = 6) plus three days ahead.
private let stripDays = Array(0...9)

struct TodayView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c

    var body: some View {
        let t = c.today
        Page { proxy in
            TodayHeader()
            WeekStrip().padding(.top, 18)
            StarHero().padding(.top, 26)
            HStack(spacing: 12) {
                Text(m.day == 6 ? "Today’s Tasks" : "\(Day.weekday(Day.date(m.day)))’s Tasks").font(.sans(24, .bold)).foregroundStyle(t.text)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button { m.openCreate() } label: {
                    Ico(.plus, 22).foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(t.red))
                }
                .buttonStyle(.press)
                .accessibilityLabel("New habit")
            }
            .padding(.top, 22)
            HabitList(readonly: m.day != 6, proxy: proxy).padding(.top, 10)
        }
        .background(t.bg.ignoresSafeArea())
    }
}

/// "Hi Name!" with the selected date, plus notifications and profile.
private struct TodayHeader: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let t = c.today
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi \(m.person("me").name)!")
                    .font(.system(size: 38, weight: .bold, design: .serif)).tracking(-0.4)
                    .foregroundStyle(t.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 0) {
                    Text(Day.fmt(Day.date(m.day), "MMMMdyyyy")).font(.sans(15, .medium)).foregroundStyle(t.muted)
                    if m.day != 6 {
                        Text(" · ").font(.sans(15, .medium)).foregroundStyle(t.muted)
                        Button("Back to today") { withAnimation(.easeOut(duration: 0.2)) { m.selectDay(6) } }
                            .font(.sans(15, .semibold)).foregroundStyle(t.red)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                IconBtn(badge: m.unreadCount, label: "Notifications", action: { m.push(.notifs) }) { Ico(.bell, 18) }
                Button { m.push(.profile) } label: { Av(p: "me", size: 38) }
                    .buttonStyle(.press)
                    .accessibilityLabel("Profile")
            }
            .padding(.top, 4)
        }
    }
}

/// Weekday labels over round date buttons; the selected day is filled red.
private struct WeekStrip: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let t = c.today
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(stripDays, id: \.self) { i in
                        let date = Day.date(i), sel = m.day == i, fut = i > 6, today = i == 6
                        Button { withAnimation(.easeOut(duration: 0.2)) { m.selectDay(i) } } label: {
                            VStack(spacing: 10) {
                                Text(Day.fmt(date, "EEE")).font(.sans(15, sel ? .semibold : .regular))
                                    .foregroundStyle(sel ? t.ink : t.muted)
                                Text("\(Day.cal.component(.day, from: date))")
                                    .font(.sans(16, sel || today ? .semibold : .regular))
                                    .foregroundStyle(sel ? .white : today ? t.red : t.muted)
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(sel ? t.red : t.circle))
                            }
                            .frame(width: 50)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(fut)
                        .opacity(fut ? 0.55 : 1)
                        .id(i)
                        .accessibilityLabel("\(today ? "Today, " : "")\(Day.fmt(date, "EEEEMMMMd"))")
                        .accessibilityAddTraits(sel ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .padding(.horizontal, -16)
            .onAppear { proxy.scrollTo(m.day, anchor: .center) }
        }
    }
}

/// The star mascot standing on a soft oval shadow.
private struct StarHero: View {
    @Environment(\.pal) private var c
    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse().fill(c.today.shadow).frame(width: 276, height: 60)
            Image("Star").resizable().scaledToFit()
                .frame(width: 200)
                .padding(.bottom, 26)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// To-Do and Completed sections, each sorted by time.
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
        let done = { (h: Habit) in readonly ? m.week(h, "me")[m.day] != 0 : m.isDone(h, "me") }
        let todo = sorted.filter { !done($0) }, completed = sorted.filter(done)
        VStack(alignment: .leading, spacing: 0) {
            section("To-Do", todo, empty: readonly ? "Nothing was left undone." : "All done for today.")
            section("Completed", completed, empty: readonly ? "Nothing was checked off." : "Nothing checked off yet.")
                .padding(.top, 14)
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

    @ViewBuilder private func section(_ title: String, _ list: [Habit], empty: String) -> some View {
        let t = c.today
        Text("\(title) (\(list.count))").font(.sans(18, .semibold)).foregroundStyle(t.section)
            .padding(.horizontal, 2).padding(.bottom, 10)
            .accessibilityAddTraits(.isHeader)
        if list.isEmpty {
            Text(empty).font(.sans(14)).foregroundStyle(t.muted).padding(.horizontal, 2).padding(.bottom, 6)
        }
        ForEach(list) { h in
            HabitCard(h: h, readonly: readonly, dayIdx: m.day).id(h.id)
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

struct HabitCard: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit
    var readonly = false
    var dayIdx = 6

    var body: some View {
        let t = c.today
        let d = readonly ? m.week(h, "me")[dayIdx] != 0 : m.isDone(h, "me")
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        HStack(spacing: 16) {
            HIcon(h.ic, 34).foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(t.red))
            VStack(alignment: .leading, spacing: 9) {
                Text(h.name).font(.sans(16, .medium)).foregroundStyle(t.text).lineLimit(2)
                DoneCircles(h: h, readonly: readonly, dayIdx: dayIdx)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CheckButton(done: d, readonly: readonly, name: h.name, tint: t.red, size: 30) { m.check(h.id) }
        }
        .padding(.leading, 14).padding(.trailing, 16).padding(.vertical, 14)
        .background(shape.fill(t.card))
        .contentShape(shape)
        // the whole card opens the task; the check keeps its own tap
        .onTapGesture { if !readonly { m.openDetails(h.id) } }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open details") { if !readonly { m.openDetails(h.id) } }
        .padding(.bottom, 10)
        .animation(.easeOut(duration: 0.25), value: d)
    }
}

/// One circle per person on the habit (you first): a red check once they're done.
private struct DoneCircles: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit
    var readonly = false
    var dayIdx = 6
    private let maxShown = 6

    var body: some View {
        let t = c.today
        let ppl = ["me"] + m.peopleOf(h).filter { $0 != "me" }
        let isDone = { (p: String) in readonly ? m.week(h, p)[dayIdx] != 0 : m.isDone(h, p) }
        let shown = Array(ppl.prefix(maxShown)), more = ppl.count - shown.count
        HStack(spacing: 4) {
            ForEach(shown, id: \.self) { p in
                let on = isDone(p)
                Circle().fill(on ? t.red : t.dot)
                    .frame(width: 24, height: 24)
                    .overlay { if on { Ico(.check, 11).foregroundStyle(.white) } }
            }
            if more > 0 {
                Text("+\(more)").font(.sans(12, .semibold)).foregroundStyle(t.section).padding(.leading, 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ppl.count == 1 ? (isDone("me") ? "Done" : "Not done")
                            : "\(ppl.filter(isDone).count) of \(ppl.count) done")
    }
}

/// The check: Creds stamp look, tap-to-tick behaviour.
struct CheckButton: View {
    @Environment(\.pal) private var c
    let done: Bool
    var readonly = false
    let name: String
    var tint: Color? = nil
    var size: CGFloat = 26
    let action: () -> Void
    @State private var ring = false

    var body: some View {
        let acc = tint ?? c.acc
        let face = ZStack {
            Circle().fill(done ? acc : c.card)
            if !done { Circle().strokeBorder(acc.opacity(0.6), lineWidth: 1.6) }
            if done {
                Ico(.check, size * 0.46).foregroundStyle(Brand.onWine)
                    .transition(.asymmetric(insertion: .scale(scale: 1.7).combined(with: .opacity), removal: .opacity))
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(done ? -6 : 0))
        .background(
            Circle().stroke(acc.opacity(ring ? 0 : 0.5), lineWidth: ring ? 14 : 0).scaleEffect(ring ? 1.5 : 1).opacity(ring ? 0 : 1)
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
            } label: { face.frame(width: 44, height: 44).contentShape(Circle()) }
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

/// Today's photos, three to a row: you first, then friends (done first, by time).
struct TodayStrip: View {
    @Environment(AppModel.self) private var m
    let h: Habit
    var body: some View {
        let others = stableSorted(m.peopleOf(h).filter { $0 != "me" }) { a, b in
            let da = m.isDone(h, a) ? 1 : 0, db = m.isDone(h, b) ? 1 : 0
            if db - da != 0 { return db - da }
            return da == 1 ? Day.tmin(h.mem[a]?.done ?? "") - Day.tmin(h.mem[b]?.done ?? "") : 0
        }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top), count: 3), spacing: 14) {
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
                            Image(uiImage: img).resizable().scaledToFill()
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
                // fixed portrait shape at whatever width the column gives
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(78.0 / 98.0, contentMode: .fit)
                .clipShape(shape)
                .overlay {
                    if d && !m.hasPhoto(h, p) { shape.strokeBorder(c.line, lineWidth: 1) }
                    else if !d { shape.strokeBorder(me ? c.acc : c.line2, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])) }
                }
                Text(m.person(p).full).font(.sans(12.5, .semibold)).foregroundStyle(!d && !me ? c.ink3 : c.ink)
                    .lineLimit(1).truncationMode(.tail).padding(.top, 6)
                Text(d ? photoTime : "Not yet").font(.sans(11)).foregroundStyle(c.ink3).lineLimit(1).padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.press)
        .disabled(!d && !me)
    }

    /// When the photo was taken: your saved photo's time, otherwise the check-in time.
    private var photoTime: String {
        if p == "me", m.hasPhoto(h, p), let item = m.storyItem(for: h.id) { return item.time }
        return h.mem[p]?.done ?? ""
    }
}

private struct TileLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.mono(8.5)).tracking(1).textCase(.uppercase).multilineTextAlignment(.center).lineSpacing(1)
    }
}
