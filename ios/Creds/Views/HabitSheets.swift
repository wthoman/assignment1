import SwiftUI

/// Binding into a field of the open sheet.
extension AppModel {
    func field(_ kp: WritableKeyPath<SheetState, String>) -> Binding<String> {
        Binding(get: { self.sheet?[keyPath: kp] ?? "" }, set: { v in self.sheet?[keyPath: kp] = v })
    }
}

func hashN(_ s: String) -> Int { s.utf16.reduce(0) { $0 + Int($1) } }

// MARK: - Habit details

struct DetailsSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let h = m.H(s.id) {
            let g = m.G(h.group), d = m.isDone(h, "me")
            VStack(spacing: 0) {
                SheetHead {
                    HStack(spacing: 12) {
                        Tile(size: 60, on: d) { HIcon(h.ic, 31) }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(h.name).font(.serif(28)).foregroundStyle(c.ink).lineLimit(2)
                            Text("\(g?.name ?? "Just me") · \(h.freq) · \(h.time)").font(.sans(12.5)).foregroundStyle(c.ink2)
                        }
                    }
                }
                SheetBody {
                    VStack(alignment: .leading, spacing: 0) {
                        BlkHead(left: "Your streak") { DoneTodayLabel(done: d) }
                        StreakBlock(h: h)
                    }
                    .card().padding(.top, 4)
                    VStack(alignment: .leading, spacing: 0) {
                        BlkHead(left: m.shared(h) ? "Today’s photos" : "Today") {
                            Eyebrow(m.shared(h) ? "\(m.doneCount(h)) of \(m.peopleOf(h).count) done" : "Only you")
                        }
                        TodayStrip(h: h)
                    }
                    .blk()
                    VStack(alignment: .leading, spacing: 0) {
                        MonthGrid(h: h)
                        HStack(spacing: 14) {
                            HStack(spacing: 6) { Circle().fill(c.acc).frame(width: 9, height: 9); Text("Done") }
                            HStack(spacing: 6) { Circle().strokeBorder(c.line2, lineWidth: 1).frame(width: 9, height: 9); Text("Missed") }
                        }
                        .font(.sans(12)).foregroundStyle(c.ink2).padding(.top, 10)
                    }
                    .card().blk()
                    HStack(spacing: 8) {
                        if d {
                            if h.mem["me"]?.proof == true {
                                Button { m.viewPost(h.id, "me") } label: { Ico(.camera); Text("Your photo") }.buttonStyle(.btn(.line))
                            } else {
                                Button { m.addPhoto(h.id) } label: { Ico(.camera); Text("Add photo") }.buttonStyle(.btn(.line))
                            }
                        } else {
                            Button { withAnimation { m.check(h.id) } } label: { Ico(h.proof ? .camera : .check); Text("Check in") }.buttonStyle(.btn)
                        }
                        if let g {
                            Button { m.openGroup(g.id) } label: { Ico(.groups, 17); Text("Open group") }.buttonStyle(.btn(.line))
                        } else {
                            Button { m.makeGroup(h.id) } label: { Ico(.invite); Text("Add friends") }.buttonStyle(.btn(.line))
                        }
                    }
                    .padding(.top, 16)
                    if g == nil {
                        Button("Delete habit") { m.deleteHabit(h.id) }.buttonStyle(Btn(kind: .ghost, fg: c.acc)).padding(.top, 6)
                    }
                }
            }
        }
    }
}

/// Monthly calendar (Creds', shown in habit details).
struct MonthGrid: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let h: Habit

    private func monthDone(_ y: Int, _ mo: Int, _ day: Int) -> Int? {
        let d = Day.cal.date(from: DateComponents(year: y, month: mo + 1, day: day))!
        let diff = Day.cal.dateComponents([.day], from: d, to: Seed.today).day ?? 0
        if diff < 0 { return nil }
        if diff <= 6 { return m.week(h, "me")[6 - diff] }
        let seed = (day * 7 + h.id.utf16.count * 13 + mo * 3) % 10
        return seed < 8 ? 1 : 0
    }

    var body: some View {
        let y = m.detY, mo = m.detMo
        let first = Day.cal.date(from: DateComponents(year: y, month: mo + 1, day: 1))!
        let days = Day.cal.range(of: .day, in: .month, for: first)!.count
        let lead = (Day.cal.component(.weekday, from: first) + 5) % 7   // Monday-first
        let todayMo = Day.cal.component(.month, from: Seed.today) - 1
        VStack(spacing: 0) {
            HStack {
                Button { m.monthNav(-1) } label: { Ico(.left).frame(width: 30, height: 30) }.foregroundStyle(c.acc)
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(Day.fmt(first, "MMMMyyyy")).font(.serif(22)).foregroundStyle(c.ink)
                Spacer()
                Button { m.monthNav(1) } label: { Ico(.right).frame(width: 30, height: 30) }.foregroundStyle(c.acc)
                    .disabled(mo >= todayMo).opacity(mo >= todayMo ? 0.3 : 1)
                    .accessibilityLabel("Next month")
            }
            .padding(.bottom, 8)
            let cols = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)
            LazyVGrid(columns: cols, spacing: 3) {
                ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, l in
                    Text(l).font(.mono(9.5)).foregroundStyle(c.ink3).padding(.bottom, 4)
                }
                ForEach(0..<lead, id: \.self) { i in Color.clear.frame(height: 40).id("lead\(i)") }
                ForEach(1...days, id: \.self) { d in
                    let date = Day.cal.date(from: DateComponents(year: y, month: mo + 1, day: d))!
                    let fut = date > Seed.today, isToday = date == Seed.today
                    let v = fut ? nil : monthDone(y, mo, d)
                    let done = v == 1, miss = !fut && !done && date < Seed.today
                    let shape = RoundedRectangle(cornerRadius: 9, style: .continuous)
                    Text("\(d)")
                        .font(.sans(12.5, isToday ? .bold : .medium))
                        .foregroundStyle(done ? Brand.onWine : fut ? c.ink3 : c.ink)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(shape.fill(done ? c.acc : .clear))
                        .overlay {
                            if isToday && !done { shape.strokeBorder(c.ink, lineWidth: 1.6) }
                            else if miss { shape.strokeBorder(c.line2, lineWidth: 1) }
                        }
                        .opacity(fut ? 0.5 : 1)
                }
            }
        }
    }
}

// MARK: - New habit

struct CreateHabitSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            VStack(spacing: 0) {
                SheetHead {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("New habit", acc: true)
                        EmTitle(lead: "What are you ", em: "starting?", size: 26)
                    }
                }
                SheetBody {
                    Field(label: "Habit", placeholder: "e.g. Drink 5L of water", text: m.field(\.name))
                    Lbl(text: "Icon")
                    IconPicker(selected: s.ic) { m.sheet?.ic = $0 }
                    Lbl(text: "How often")
                    HStack(spacing: 6) {
                        ForEach(["Every day", "Weekdays", "Custom"], id: \.self) { f in
                            Chip(label: f, on: s.freq == f) { withAnimation(.easeOut(duration: 0.2)) { m.sheet?.freq = f } }
                        }
                    }
                    if s.freq == "Custom" {
                        DayPicker(selected: s.days) { m.toggleDay($0) }
                            .padding(.top, 10)
                            .transition(.opacity)
                    }
                    Lbl(text: "With")
                    Seg(options: [("solo", "Just me"), ("friends", "Friends"), ("group", "A group")], selected: s.with) { m.sheet?.with = $0 }
                    if s.with == "friends" {
                        FriendPicker(list: m.friends, selected: s.friends) { p in
                            if let i = m.sheet?.friends.firstIndex(of: p) { m.sheet?.friends.remove(at: i) } else { m.sheet?.friends.append(p) }
                        }
                        .padding(.top, 12)
                    }
                    if s.with == "group" {
                        FlowLayout(spacing: 6) {
                            ForEach(m.groups) { g in Chip(label: g.name, on: s.gid == g.id) { m.sheet?.gid = g.id } }
                        }
                        .padding(.top, 12)
                    }
                }
                // pinned so it stays reachable however tall the form gets
                Button("Add habit") { m.createGo() }.buttonStyle(.btn)
                    .padding(.horizontal, 18).padding(.top, 10).padding(.bottom, 12)
                    .overlay(alignment: .top) { Rectangle().fill(c.line).frame(height: 1) }
            }
        }
    }
}

/// Monday-first weekday toggles for a custom schedule.
struct DayPicker: View {
    @Environment(\.pal) private var c
    let selected: [Int]
    let toggle: (Int) -> Void
    private let full = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let on = selected.contains(i)
                Button { toggle(i) } label: {
                    Text(String(Array("MTWTFSS")[i])).font(.sans(14, .semibold))
                        .foregroundStyle(on ? Brand.onWine : c.ink2)
                        .frame(maxWidth: .infinity).frame(height: 40)
                        .background(Circle().fill(on ? c.acc : c.card))
                        .overlay(Circle().strokeBorder(on ? .clear : c.line, lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.press)
                .accessibilityLabel(full[i])
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// Row of the first 12 habit icons.
struct IconPicker: View {
    let selected: String
    let pick: (String) -> Void
    var body: some View {
        Bleed(inset: 18, spacing: 6) {
            ForEach(Array(HabitIcon.all.prefix(12)), id: \.self) { k in
                Button { pick(k) } label: { Tile(size: 50, on: selected == k, rotate: false) { HIcon(k, 25) } }
                    .buttonStyle(.press)
                    .accessibilityLabel(k)
            }
        }
    }
}

/// Avatars to tap on/off (.pickf).
struct FriendPicker: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    let list: [String]
    let selected: [String]
    let toggle: (String) -> Void
    var body: some View {
        Bleed(inset: 18, spacing: 10) {
            ForEach(list, id: \.self) { p in
                let on = selected.contains(p)
                Button { toggle(p) } label: {
                    VStack(spacing: 4) {
                        Av(p: p, size: 44)
                            .background(Circle().stroke(on ? c.acc : .clear, lineWidth: 5))
                            .padding(3)
                        Text(m.person(p).name).font(.sans(11.5, .semibold)).foregroundStyle(on ? c.acc : c.ink2).lineLimit(1)
                    }
                    .frame(width: 52)
                }
                .buttonStyle(.press)
            }
        }
    }
}

/// Wrapping row (flex-wrap).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, w: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > maxW { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing; rowH = max(rowH, sz.height); w = max(w, x - spacing)
        }
        return CGSize(width: proposal.width ?? w, height: y + rowH)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing; rowH = max(rowH, sz.height)
        }
    }
}

// MARK: - After a check-off

struct AskPhotoSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let h = m.H(s.id) {
            SheetBody(top: 14) {
                HStack(spacing: 12) {
                    Ico(.check, 18).foregroundStyle(Brand.onWine)
                        .frame(width: 42, height: 42).background(Circle().fill(c.acc)).rotationEffect(.degrees(-6))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(m.voice).font(.sans(17, .semibold)).foregroundStyle(c.ink)
                        Text("\(h.name) · \(m.streak(h, "me"))-day streak").font(.sans(12.5)).foregroundStyle(c.ink3)
                    }
                }
                Text("Want to add a photo? \(m.shared(h) ? "Your group will see it in today’s photos." : "Only you will see it.")")
                    .font(.sans(14.5)).lineSpacing(4).foregroundStyle(c.ink2)
                    .padding(.top, 14).padding(.bottom, 16)
                Button { m.askPhoto(h.id) } label: { Ico(.camera); Text("Add a photo") }.buttonStyle(.btn)
                Button("Not now") { m.askSkip(h.id) }.buttonStyle(.btn(.ghost)).padding(.top, 4)
            }
        }
    }
}

struct ProofSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    @State private var flash = 0.0
    var body: some View {
        if let s = m.sheet, let h = m.H(s.id) {
            let done = m.isDone(h, "me")
            VStack(spacing: 0) {
                SheetHead {
                    VStack(alignment: .leading, spacing: 6) {
                        Eyebrow("Photo proof", acc: true)
                        Text(h.name).font(.serif(26)).foregroundStyle(c.ink)
                    }
                }
                SheetBody {
                    if !done {
                        Text("Take a photo to check this off. It’s added to your story once it’s saved.")
                            .font(.sans(13.5)).foregroundStyle(c.ink2).padding(.bottom, 12)
                    }
                    ZStack {
                        if let photo = s.photo {
                            Color.black
                            Image(uiImage: photo).resizable().scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                                .accessibilityLabel("Your photo")
                        } else {
                            LinearGradient(colors: [Color(hex: 0x2B2224), Color(hex: 0x100A0C)], startPoint: UnitPoint(x: 0.3, y: 0), endPoint: UnitPoint(x: 0.7, y: 1))
                            Ico(.camera, 48).foregroundStyle(.white.opacity(0.35))
                        }
                        ViewfinderCorners()
                        Text(s.shot ? "Looking good" : "Point the camera at your proof")
                            .font(.mono(10)).tracking(1.6).textCase(.uppercase).foregroundStyle(.white.opacity(0.7))
                            .frame(maxHeight: .infinity, alignment: .bottom).padding(.bottom, 20)
                        Color.white.opacity(flash).allowsHitTesting(false)
                    }
                    .frame(height: 270)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: s.flash) { _, _ in
                        flash = 1
                        withAnimation(.easeOut(duration: 0.5)) { flash = 0 }
                    }
                    if let err = s.photoError {
                        HStack(alignment: .top, spacing: 6) {
                            Ico(.info, 14).padding(.top, 1)
                            Text(err).font(.sans(13, .medium))
                        }
                        .foregroundStyle(c.acc)
                        .padding(.top, 10)
                        .accessibilityElement(children: .combine)
                    }
                    if s.shot {
                        Field(label: "Caption (optional)", placeholder: "Day \(m.streak(h, "me") + (done ? 0 : 1))", text: m.field(\.caption)).padding(.top, 10)
                        GeometryReader { g in
                            HStack(spacing: 8) {
                                Button("Retake") { m.retake(); m.shoot() }.buttonStyle(.btn(.line)).frame(width: (g.size.width - 8) / 3)
                                Button(s.saving ? "Saving…" : "Post photo") { m.postProof(h.id) }.buttonStyle(.btn).disabled(s.saving)
                            }
                        }
                        .frame(height: 48)
                        .padding(.top, 14)
                    } else {
                        Button { m.shoot() } label: {
                            Circle().fill(c.acc).frame(width: 64, height: 64)
                                .background(Circle().stroke(c.bg, lineWidth: 8))
                                .background(Circle().stroke(c.ink, lineWidth: 10))
                        }
                        .buttonStyle(.press)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16).padding(.bottom, 4)
                        .accessibilityLabel("Take photo")
                        Button(done ? "Skip photo" : "Not now") { m.askSkip(h.id) }.buttonStyle(.btn(.ghost))
                    }
                }
            }
            .fullScreenCover(isPresented: Binding(get: { m.sheet?.showCamera ?? false }, set: { m.sheet?.showCamera = $0 })) {
                CameraPicker(onPhoto: { m.captured($0) }, onCancel: { m.sheet?.showCamera = false })
                    .ignoresSafeArea()
            }
        }
    }
}

private struct ViewfinderCorners: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height, l: CGFloat = 24, i: CGFloat = 14
            Path { p in
                p.move(to: CGPoint(x: i, y: i + l)); p.addLine(to: CGPoint(x: i, y: i)); p.addLine(to: CGPoint(x: i + l, y: i))
                p.move(to: CGPoint(x: w - i - l, y: i)); p.addLine(to: CGPoint(x: w - i, y: i)); p.addLine(to: CGPoint(x: w - i, y: i + l))
                p.move(to: CGPoint(x: i, y: h - i - l)); p.addLine(to: CGPoint(x: i, y: h - i)); p.addLine(to: CGPoint(x: i + l, y: h - i))
                p.move(to: CGPoint(x: w - i - l, y: h - i)); p.addLine(to: CGPoint(x: w - i, y: h - i)); p.addLine(to: CGPoint(x: w - i, y: h - i - l))
            }
            .stroke(.white.opacity(0.7), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - A check-in post

struct PostSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet, let h = m.H(s.id), let r = h.mem[s.p], let done = r.done {
            let p = s.p, pic = m.hasPhoto(h, p), k = "ci-\(h.id)-\(p)"
            let rx = Seed.reactions.first { $0.k == m.reacts[k] }
            VStack(spacing: 0) {
                SheetHead {
                    HStack(spacing: 10) {
                        Av(p: p, size: 38)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(m.nameOf(p)).font(.sans(15, .semibold)).foregroundStyle(c.ink)
                            Text("\(h.name) · \(done)").font(.sans(12.5)).foregroundStyle(c.ink3)
                        }
                    }
                }
                SheetBody {
                    if pic {
                        ZStack(alignment: .topLeading) {
                            if p == "me", let item = m.storyItem(for: h.id), let img = m.storyImage(item) {
                                Color.black
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
                            } else {
                                PhotoFill(floorCell: 36, floorHeight: 130, floorOpacity: 0.35)
                                HIcon(h.ic, 96, 0.9).foregroundStyle(Color(red: 1, green: 236 / 255, blue: 226 / 255).opacity(0.85))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            Text(m.G(h.group)?.name ?? "Just me").font(.mono(9.5)).tracking(1.33).textCase(.uppercase)
                                .foregroundStyle(Color(hex: 0xF6E6E0))
                                .padding(.vertical, 4).padding(.horizontal, 7)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color(red: 20 / 255, green: 8 / 255, blue: 10 / 255).opacity(0.7)))
                                .padding(10)
                        }
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text("“\(m.captionOf(h, p))”").font(.serif(22)).italic().foregroundStyle(c.ink).padding(.top, 14)
                    } else {
                        VStack(spacing: 12) {
                            Ico(.check, 30).foregroundStyle(Brand.onWine).frame(width: 64, height: 64).background(Circle().fill(c.acc))
                            Eyebrow("Checked in · no photo")
                        }
                        .frame(maxWidth: .infinity).frame(height: 300)
                        .card(0, radius: 16, flat: true)
                        Text("\(m.nameOf(p)) checked in at \(done)\(p == "me" ? "." : " without a photo.")")
                            .font(.serif(19)).italic().foregroundStyle(c.ink).padding(.top, 14)
                    }
                    HStack(spacing: 8) {
                        if p == "me" {
                            if pic {
                                Button("Remove photo") { m.removePhoto(h.id) }.buttonStyle(.btn(.line, small: true))
                            } else {
                                Button { m.addPhoto(h.id) } label: { Ico(.camera, 14); Text("Add photo") }.buttonStyle(.btn(.primary, small: true))
                            }
                        } else {
                            InlineAction(on: rx != nil, icon: rx?.ic ?? .clap, label: rx?.l ?? "React") { m.openReact(k) }
                            InlineAction(on: false, icon: .comment, label: "Comment") { m.openComments(k) }
                        }
                    }
                    .padding(.top, 14)
                }
            }
        }
    }
}

/// Small accent action (.ia).
struct InlineAction: View {
    @Environment(\.pal) private var c
    let on: Bool
    let icon: UIIcon
    let label: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) { Ico(icon, 14); Text(label) }
                .font(.sans(12.5, .semibold))
                .foregroundStyle(on ? Brand.onWine : c.acc)
                .padding(.horizontal, 11).frame(height: 32)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(on ? c.acc : c.acc.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(on ? .clear : c.acc.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.press)
    }
}

struct ReactSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            let cur = m.reacts[s.k]
            SheetBody(top: 12) {
                EmTitle(lead: "Send a ", em: "reaction", size: 26)
                HStack(spacing: 8) {
                    ForEach(Seed.reactions, id: \.k) { r in
                        let on = cur == r.k
                        Button { m.rxPick(s.k, r.k) } label: {
                            VStack(spacing: 6) {
                                Ico(r.ic, 22).foregroundStyle(on ? Brand.onWine : c.acc)
                                    .frame(width: 52, height: 52).background(Circle().fill(on ? c.acc : c.accSoft))
                                    .scaleEffect(on ? 1.1 : 1)
                                Text(r.l).font(.sans(11.5, .semibold)).foregroundStyle(c.ink2).lineLimit(1).minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.press)
                    }
                }
                .padding(.top, 14)
                if let cur {
                    Button("Remove reaction") { m.rxPick(s.k, cur) }.buttonStyle(.btn(.ghost)).padding(.top, 10)
                }
            }
        }
    }
}

struct CommentsSheet: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        if let s = m.sheet {
            let seed = hashN(s.k) % 3
            let base = [("preston", "Proud of you!"), ("mina", "Same time tomorrow?"), ("ava", "You make it look easy.")].prefix(seed).map { Comment(p: $0.0, t: $0.1) }
            let all = base + (m.comments[s.k] ?? [])
            VStack(spacing: 0) {
                SheetHead { Text("Comments").font(.serif(26)).foregroundStyle(c.ink) }
                SheetBody {
                    if all.isEmpty {
                        Text("No comments yet. Be the first to say something kind.").font(.sans(14)).foregroundStyle(c.ink2)
                    } else {
                        ForEach(Array(all.enumerated()), id: \.offset) { _, cm in
                            HStack(alignment: .top, spacing: 10) {
                                Av(p: cm.p, size: 32)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(m.nameOf(cm.p)).font(.sans(12, .bold))
                                    Text(cm.t).font(.sans(14))
                                }
                                .foregroundStyle(c.ink)
                                .padding(.vertical, 8).padding(.horizontal, 12)
                                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(c.card))
                                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(c.line, lineWidth: 1))
                            }
                            .padding(.bottom, 10)
                        }
                    }
                    Bleed(inset: 18, spacing: 6) {
                        ForEach(["Proud of you!", "Love this.", "Same time tomorrow?", "You make it look easy."], id: \.self) { q in
                            Chip(label: q) { m.sheet?.text = q }
                        }
                    }
                    .padding(.top, 10).padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Field(placeholder: "Say something kind…", text: m.field(\.text), compact: true)
                        IconBtn(acc: true, label: "Send", action: { m.sendComment(s.k) }) { Ico(.right, 16) }
                    }
                }
            }
        }
    }
}
