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
            WeekStrip().padding(.top, 28)
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
                HStack(spacing: 12) {
                    ForEach(stripDays, id: \.self) { i in
                        let date = Day.date(i), sel = m.day == i, fut = i > 6, today = i == 6
                        Button { withAnimation(.easeOut(duration: 0.2)) { m.selectDay(i) } } label: {
                            VStack(spacing: 7) {
                                Text(Day.fmt(date, "EEE")).font(.sans(13, sel ? .semibold : .regular))
                                    .foregroundStyle(sel ? t.ink : t.muted)
                                Text("\(Day.cal.component(.day, from: date))")
                                    .font(.sans(14, sel || today ? .semibold : .regular))
                                    .foregroundStyle(sel ? .white : today ? t.red : t.muted)
                                    .frame(width: 38, height: 38)
                                    .background(Circle().fill(sel ? t.red : t.circle))
                            }
                            .frame(width: 44)
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
            Ellipse().fill(c.today.shadow).frame(width: 207, height: 45)
            Image("Star").resizable().scaledToFit()
                .frame(width: 150)
                .padding(.bottom, 20)
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
        // not on the schedule that day (and not done anyway): a rest day, not a to-do
        let date = Day.date(m.day)
        let resting = { (h: Habit) in !done(h) && !m.scheduled(h, date) }
        let todo = sorted.filter { !done($0) && !resting($0) }, completed = sorted.filter(done), rest = sorted.filter(resting)
        VStack(alignment: .leading, spacing: 0) {
            section("To-Do", todo, empty: readonly ? "Nothing was left undone." : "All done for today.")
            section("Completed", completed, empty: readonly ? "Nothing was checked off." : "Nothing checked off yet.")
                .padding(.top, 14)
            if !rest.isEmpty {
                section("Rest day", rest, empty: "")
                    .padding(.top, 14)
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

    @ViewBuilder private func section(_ title: String, _ list: [Habit], empty: String) -> some View {
        let t = c.today
        Text("\(title) (\(list.count))").font(.sans(16, .semibold)).foregroundStyle(t.section)
            .padding(.horizontal, 2).padding(.bottom, title == "Rest day" ? 2 : 8)
            .accessibilityAddTraits(.isHeader)
        if title == "Rest day" {
            Text("Not on the schedule \(m.day == 6 ? "today" : "this day"). Checking in still counts.")
                .font(.sans(13)).foregroundStyle(t.muted).padding(.horizontal, 2).padding(.bottom, 8)
        }
        if list.isEmpty {
            Text(empty).font(.sans(14)).foregroundStyle(t.muted).padding(.horizontal, 2).padding(.bottom, 6)
        }
        ForEach(list) { h in
            HabitCard(h: h, readonly: readonly, dayIdx: m.day).id(h.id)
                .opacity(title == "Rest day" ? 0.7 : 1)
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
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let tile = RoundedRectangle(cornerRadius: 9, style: .continuous)
        HStack(spacing: 12) {
            // a soft tile like the Groups icons; it turns solid red once you've checked in
            HIcon(h.ic, 24).foregroundStyle(d ? .white : t.red)
                .frame(width: 44, height: 44)
                .background(tile.fill(d ? t.red : c.tile))
                .overlay { if !d { tile.strokeBorder(c.line.opacity(0.7), lineWidth: 1) } }
            VStack(alignment: .leading, spacing: 6) {
                Text(h.name).font(.sans(15, .medium)).foregroundStyle(t.text).lineLimit(2)
                DoneCircles(h: h, readonly: readonly, dayIdx: dayIdx)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            CheckButton(done: d, readonly: readonly, name: h.name, tint: t.red, size: 26) { m.check(h.id) }
        }
        .padding(.leading, 12).padding(.trailing, 12).padding(.vertical, 10)
        // hairline card: an outline, no shadow (shadows are for floating things like the tab bar)
        .background(shape.fill(c.card))
        .overlay(shape.strokeBorder(c.line, lineWidth: 1))
        .contentShape(shape)
        // the whole card opens the task; the check keeps its own tap
        .onTapGesture { if !readonly { m.openDetails(h.id) } }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Open details") { if !readonly { m.openDetails(h.id) } }
        .padding(.bottom, 8)
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
        HStack(spacing: 3) {
            ForEach(shown, id: \.self) { p in
                let on = isDone(p)
                Circle().fill(on ? t.red : t.dot)
                    .frame(width: 18, height: 18)
                    .overlay { if on { Ico(.check, 9).foregroundStyle(.white) } }
            }
            if more > 0 {
                Text("+\(more)").font(.sans(11, .semibold)).foregroundStyle(t.section).padding(.leading, 2)
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

/// One frame in a photo grid: a person's check-in on a task.
struct PhotoEntry: Hashable {
    let habit: String
    let p: String
}

/// Today's photos for one task. Your frame (photo or "Take photo") is always first;
/// then friends, done first by time. Big groups show everyone's taken photos and no empty frames.
struct TodayStrip: View {
    @Environment(AppModel.self) private var m
    let h: Habit
    var body: some View {
        let pool = m.isLarge(h) ? h.mem.keys.filter { $0 != "me" && m.hasPhoto(h, $0) } : m.peopleOf(h).filter { $0 != "me" }
        let others = stableSorted(pool) { a, b in
            let da = m.isDone(h, a) ? 1 : 0, db = m.isDone(h, b) ? 1 : 0
            if db - da != 0 { return db - da }
            return da == 1 ? Day.tmin(h.mem[a]?.done ?? "") - Day.tmin(h.mem[b]?.done ?? "") : 0
        }
        PhotoGrid(entries: (["me"] + others).map { PhotoEntry(habit: h.id, p: $0) })
    }
}

/// Three-column photo grid: the first 9, then "Show More" adds 15 at a time.
struct PhotoGrid: View {
    @Environment(\.pal) private var c
    let entries: [PhotoEntry]
    @State private var limit = 9
    var body: some View {
        let t = c.today
        if entries.isEmpty {
            Text("No photos yet today.").font(.sans(15)).foregroundStyle(t.muted)
        } else {
            VStack(spacing: 0) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16, alignment: .top), count: 3), spacing: 20) {
                    ForEach(entries.prefix(limit), id: \.self) { e in PersonTile(entry: e) }
                }
                if entries.count > limit {
                    let next = min(15, entries.count - limit)
                    Button { withAnimation(.easeOut(duration: 0.25)) { limit += 15 } } label: {
                        Text("Show More").font(.sans(16, .medium)).foregroundStyle(t.red)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(t.red, lineWidth: 1.2))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.press)
                    .padding(.top, 22)
                    .accessibilityHint("Shows \(next) more photo\(next == 1 ? "" : "s")")
                }
            }
        }
    }
}

/// A check-in photo: your saved photo, a demo sample from seed data, or the drawn stand-in.
struct CheckinPhoto: View {
    @Environment(AppModel.self) private var m
    let h: Habit
    let p: String
    var body: some View {
        if p == "me", h.mem["me"]?.proof == true, let item = m.storyItem(for: h.id), let img = m.storyImage(item) {
            Image(uiImage: img).resizable().scaledToFill()
                .accessibilityLabel("Your photo")
        } else {
            SamplePhoto(ic: h.ic, variant: h.mem[p]?.sample ?? hashN(p))
        }
    }
}

/// One photo frame with the person's full name and when the photo was taken.
struct PersonTile: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let entry: PhotoEntry
    var body: some View {
        if let h = m.H(entry.habit) { tile(h) }
    }

    @ViewBuilder private func tile(_ h: Habit) -> some View {
        let p = entry.p, t = c.today, me = p == "me", pic = m.hasPhoto(h, p)
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        Button {
            if pic { m.viewPost(h.id, p) } else if me { m.check(h.id) }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    t.card
                    if pic {
                        CheckinPhoto(h: h, p: p)
                    } else if me {
                        VStack(spacing: 8) {
                            Ico(.camera, 24)
                            Text("Take photo").font(.sans(13, .semibold))
                        }
                        .foregroundStyle(t.red)
                    }
                }
                // fixed portrait shape at whatever width the column gives
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(146.0 / 168.0, contentMode: .fit)
                .clipShape(shape)
                .overlay { if me && !pic { shape.strokeBorder(t.red.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])) } }
                Text(m.person(p).full).font(.sans(16, .medium)).foregroundStyle(t.text)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true).padding(.top, 10)
                Text(pic ? photoTime(h) : "Not yet").font(.sans(14)).foregroundStyle(t.muted).lineLimit(1).padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.press)
        .disabled(!pic && !me)
    }

    /// When the photo was taken: your saved photo's time, otherwise the check-in time.
    private func photoTime(_ h: Habit) -> String {
        let p = entry.p
        if p == "me", h.mem["me"]?.proof == true, let item = m.storyItem(for: h.id) { return item.time }
        return h.mem[p]?.done ?? ""
    }
}

// MARK: - Previews (Editor → Canvas)

#Preview("Today") { CredsPreview() }
#Preview("Today · Stage theme") { CredsPreview(theme: .stage) }
