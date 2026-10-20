import SwiftUI

// MARK: - Recap hub

struct RecapHubView: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        let r = m.recapPicks()
        let sign = r.delta >= 0 ? "+" : "−"
        Page { _ in
            GHead(eyebrow: "Week \(Day.weekNum())", title: "Recap") {
                IconBtn(label: "Share", action: { m.showToast("Recap card shared (mock)") }) { Ico(.share) }
            }
            Ticket(pct: r.pct, sign: sign, delta: abs(r.delta)).padding(.top, 12)
            VStack(alignment: .leading, spacing: 0) {
                BlkHead(left: "Past 7 days") { Eyebrow("Habit by habit") }
                HStack(spacing: 12) {
                    Text("\(r.pct)%").font(.sans(32, .bold)).tracking(-0.64).foregroundStyle(c.ink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("of scheduled check-ins done · rest days don’t count").font(.sans(13)).foregroundStyle(c.ink2)
                        Text("\(r.delta >= 0 ? "▲" : "▼") \(abs(r.delta)) pts vs the week before")
                            .font(.mono(10)).tracking(0.4).foregroundStyle(c.yelInk)
                            .padding(.horizontal, 7).padding(.vertical, 2).background(Capsule().fill(c.yelSoft))
                    }
                }
                .padding(.top, 4).padding(.bottom, 12)
                HStack(spacing: 10) {
                    Spacer()
                    HStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { i in
                            Text(Day.narrow(Day.date(i))).font(.sans(10, i == 6 ? .bold : .medium)).foregroundStyle(i == 6 ? c.today.ink : c.ink3).frame(width: 17)
                        }
                    }
                    Color.clear.frame(width: 30, height: 1)
                }
                .padding(.bottom, 4)
                ForEach(r.rows, id: \.h.id) { x in
                    Button { m.openDetails(x.h.id) } label: {
                        HStack(spacing: 10) {
                            Text(x.h.name).font(.sans(14, .medium)).foregroundStyle(c.ink).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                            HStack(spacing: 3) {
                                ForEach(Array(x.marks.enumerated()), id: \.offset) { _, k in DayDot(mark: k, size: 17) }
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(x.marks.enumerated().map { i, k in "\(Day.weekday(Day.date(i))) \(k.label)" }.joined(separator: ", "))
                            Text("\(x.n)/\(x.due)").font(.sans(12, .medium)).foregroundStyle(c.ink2).frame(width: 30, alignment: .trailing)
                                .accessibilityLabel("\(x.n) of \(x.due) scheduled days")
                        }
                        .padding(.vertical, 8)
                        .overlay(alignment: .top) { Rectangle().fill(c.line).frame(height: 1) }
                    }
                    .buttonStyle(.press)
                }
                DayLegend().padding(.top, 10)
                if let best = r.best, let weak = r.weak {
                    HStack(spacing: 8) {
                        Insight(eyebrow: "Most consistent", eyebrowColor: c.yelInk, title: best.h.name, sub: "\(best.n) of \(best.due) days", fill: c.yelSoft)
                        Insight(eyebrow: "Needs a push", eyebrowColor: c.acc, title: weak.h.name, sub: "\(weak.n) of \(weak.due) days · try an earlier time?", fill: c.bg2)
                    }
                    .padding(.top, 12)
                }
            }
            .card().blk()
            Sec(title: "Past weeks")
            VStack(spacing: 0) {
                ForEach(Array([(Day.weekEnd(1), "Two comebacks and a full Sunday", "27 check-ins · Comeback Kid"),
                               (Day.weekEnd(2), "Your steadiest week yet", "33 check-ins · Early Bird"),
                               (Day.weekEnd(3), "Small steps, still counted", "24 check-ins · Most Consistent")]
                    .map { (Day.fmt($0.0, "MMM"), Day.cal.component(.day, from: $0.0), $0.1, $0.2) }.enumerated()), id: \.offset) { i, w in
                    Button { m.playRecap() } label: {
                        Divided(first: i == 0) {
                            HStack(spacing: 12) {
                                DateBox(month: w.0, day: w.1)
                                TwoLine(title: w.2, sub: w.3)
                                Ico(.right).foregroundStyle(c.ink)
                            }
                        }
                    }
                    .buttonStyle(.press)
                }
            }
            .card(v: 4, h: 14)
        }
    }
}

private struct Insight: View {
    @Environment(\.pal) private var c
    let eyebrow: String
    let eyebrowColor: Color
    let title, sub: String
    let fill: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(eyebrow, size: 9, color: eyebrowColor).padding(.bottom, 3)
            Text(title).font(.sans(13.5, .semibold)).foregroundStyle(c.ink).lineSpacing(1)
            Text(sub).font(.sans(12)).foregroundStyle(c.ink3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.vertical, 9).padding(.horizontal, 11)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(fill))
    }
}

/// Dashed date tile (.datebox).
struct DateBox: View {
    @Environment(\.pal) private var c
    let month: String
    let day: Int
    var body: some View {
        VStack(spacing: 0) {
            Text(month).font(.mono(9)).tracking(0.9).textCase(.uppercase)
            Text("\(day)").font(.serif(22))
        }
        .foregroundStyle(c.acc)
        .frame(width: 46, height: 50)
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(c.acc.opacity(0.45), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
    }
}

private struct Ticket: View {
    @Environment(AppModel.self) private var m
    let pct: Int
    let sign: String
    let delta: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Now showing · \(Day.span())").font(.mono(10)).tracking(2.2).textCase(.uppercase).foregroundStyle(Brand.gold2)
            Text("Your week,\n\(Text("in review").italic())").font(.serif(38)).lineSpacing(-4).padding(.top, 10).padding(.bottom, 8)
            Text("\(pct)% of your check-ins done · \(sign)\(delta) pts vs the week before").font(.sans(13)).opacity(0.85)
            Button("Raise the curtain") { m.playRecap() }.buttonStyle(.btn(.cream)).padding(.top, 14)
        }
        .foregroundStyle(Brand.onWine)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Stripes.curtain
                GeometryReader { g in
                    RadialGradient(colors: [Color(red: 1, green: 170 / 255, blue: 175 / 255).opacity(0.35), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: g.size.width * 0.55)
                }
                LinearGradient(stops: [.init(color: .clear, location: 0.3), .init(color: Color(red: 10 / 255, green: 2 / 255, blue: 4 / 255).opacity(0.75), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
        )
        .overlay(alignment: .topTrailing) {
            Stamp(size: 66, color: Brand.gold2) { Ico(.film, 16); Text("Ready") }
                .rotationEffect(.degrees(12)).padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { m.playRecap() }
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - The curtain (weekly recap player)

struct RecapCurtain: View {
    @Environment(AppModel.self) private var m
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var picks: AppModel.RecapPicks? = nil
    @State private var opened = false
    @State private var index = -1
    @State private var shownAt = Date()
    @State private var running = false
    @State private var timer: Task<Void, Never>? = nil
    private let slideDuration: Double = 6

    private var slideCount: Int {
        guard let r = picks else { return 0 }
        return 4 + (r.perfect != nil ? 1 : 0) + (r.second != nil ? 1 : 0)
    }
    private var dim: Bool { index >= slideCount - 2 && index >= 0 }

    var body: some View {
        GeometryReader { g in
            let top = g.safeAreaInsets.top
            ZStack {
                Color(hex: 0x0C0608)
                // drape + floor
                ZStack {
                    Stripes.splash
                    RadialGradient(colors: [Color(red: 1, green: 150 / 255, blue: 165 / 255).opacity(0.5), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: g.size.width * 0.55)
                        .scaleEffect(x: 1, y: 0.7, anchor: UnitPoint(x: 0.5, y: 0.4))
                    LinearGradient(stops: [.init(color: .black.opacity(0.6), location: 0), .init(color: .black.opacity(0.08), location: 0.28),
                                           .init(color: .black.opacity(0.25), location: 0.7), .init(color: .black.opacity(0.92), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                }
                .opacity(dim ? 0.2 : 1)
                .animation(.easeInOut(duration: 0.8), value: dim)
                VStack {
                    Spacer()
                    CheckerFloor(cell: 56, tilt: 58, perspective: 0.5)
                        .frame(width: g.size.width * 1.6, height: 230)
                        .offset(y: 60)
                        .opacity(dim ? 0.12 : 0.45)
                        .animation(.easeInOut(duration: 0.8), value: dim)
                }
                // the floor bleeds past the edges; keep it from widening the stage (and pushing slides off-screen)
                .frame(width: g.size.width)

                if let r = picks {
                    ForEach(0..<slideCount, id: \.self) { i in
                        RecapSlide(index: i, picks: r, onShow: i == index)
                            .padding(.top, 96).padding(.bottom, 70).padding(.horizontal, 26)
                            .opacity(i == index ? 1 : 0)
                            .scaleEffect(i == index ? 1 : 0.97)
                            .animation(.easeOut(duration: i == index ? 0.55 : 0.22), value: index)
                            // only the last (share) page has controls; elsewhere taps fall through to the tap zones
                            .allowsHitTesting(i == index && i == slideCount - 1)
                            .zIndex(15)
                    }
                }
                // tap zones (below the slides' buttons)
                HStack(spacing: 0) {
                    Color.clear.contentShape(Rectangle()).frame(width: g.size.width * 0.32).onTapGesture { prev() }
                    Color.clear.contentShape(Rectangle()).onTapGesture { next() }
                }
                .padding(.top, 100 + top)
                .zIndex(12)

                // curtains + valance
                HStack(spacing: 0) {
                    Curtain().frame(width: g.size.width * 0.51).scaleEffect(x: opened ? 0.07 : 1, anchor: .leading)
                    Spacer(minLength: 0)
                    Curtain().frame(width: g.size.width * 0.51).scaleEffect(x: opened ? 0.07 : 1, anchor: .trailing)
                }
                .animation(.timingCurve(0.7, 0, 0.2, 1, duration: 1.7), value: opened)
                .allowsHitTesting(false)
                .zIndex(20)
                VStack {
                    ZStack {
                        Stripes.valance
                        LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                    }
                    .frame(height: 58 + top)
                    .overlay(alignment: .bottom) { Rectangle().fill(Brand.gold).frame(height: 2).offset(y: 2) }
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 10)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(25)

                // intro
                VStack(spacing: 0) {
                    Text("Creds presents").font(.mono(11)).tracking(3.7).textCase(.uppercase).foregroundStyle(Brand.gold2)
                    Text("Your week,\n\(Text("in review").italic())").font(.serif(66)).tracking(-1.3).lineSpacing(-8)
                        .foregroundStyle(.white).shadow(color: .black.opacity(0.5), radius: 15, y: 4)
                        .padding(.top, 16).padding(.bottom, 12)
                    Text("Week \(Day.weekNum()) · \(Day.span())").font(.mono(11)).tracking(1.5).textCase(.uppercase).foregroundStyle(Color(hex: 0xF0D2CC))
                    PulseLabel(text: "Tap to raise the curtain").padding(.top, 42)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { open() }
                .opacity(opened ? 0 : 1)
                .animation(.easeOut(duration: 0.6), value: opened)
                .allowsHitTesting(!opened)
                .zIndex(30)

                // progress bars
                VStack {
                    // the current page's bar fills over its viewing time
                    TimelineView(.animation(paused: !running)) { t in
                        let elapsed = min(1, max(0, t.date.timeIntervalSince(shownAt) / slideDuration))
                        HStack(spacing: 4) {
                            ForEach(0..<slideCount, id: \.self) { k in
                                let fill = k < index ? 1 : k == index ? elapsed : 0
                                Rectangle().fill(Color.white.opacity(0.22)).frame(height: 2)
                                    .overlay(alignment: .leading) {
                                        GeometryReader { b in Rectangle().fill(Color.white).frame(width: b.size.width * fill) }
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, top + 0)
                    .opacity(opened ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: opened)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(40)

                VStack {
                    HStack {
                        Spacer()
                        Button { m.closeOverlay() } label: {
                            Ico(.x).foregroundStyle(.white).frame(width: 34, height: 34).background(Circle().fill(.black.opacity(0.35)))
                        }
                        .accessibilityLabel("Close")
                    }
                    .padding(.trailing, 14).padding(.top, top + 12)
                    Spacer()
                    Text(index >= 0 && index < slideCount - 1 ? "Tap to continue" : "")
                        .font(.mono(10)).tracking(2.6).textCase(.uppercase).foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 30)
                        .allowsHitTesting(false)
                }
                .zIndex(45)
            }
            .ignoresSafeArea()
            // swipe left / right to change pages
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { v in
                        guard opened, abs(v.translation.width) > abs(v.translation.height), abs(v.translation.width) > 40 else { return }
                        if v.translation.width < 0 { next() } else { prev() }
                    }
            )
        }
        .foregroundStyle(Color(hex: 0xF6EBE6))
        .onAppear { picks = m.recapPicks() }
        .onDisappear { timer?.cancel() }
    }

    private func open() {
        guard !opened else { return }
        opened = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            go(0)
        }
    }
    private func next() { if index >= 0 && index < slideCount - 1 { go(index + 1) } }
    private func prev() { if index > 0 { go(index - 1) } }
    private func go(_ i: Int) {
        index = max(0, min(slideCount - 1, i))
        if index >= slideCount - 2 { m.recapReachedAward() }
        startTimer()
    }
    /// (Re)starts the current page's clock; advances when it runs out, and stops on the last page.
    private func startTimer() {
        timer?.cancel()
        shownAt = Date()
        running = true
        let at = index
        timer = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(slideDuration * 1_000_000_000))
            guard !Task.isCancelled, index == at else { return }
            if at < slideCount - 1 { go(at + 1) } else { running = false }
        }
    }
}

private struct Curtain: View {
    var body: some View {
        ZStack {
            Stripes.drape
            LinearGradient(stops: [.init(color: .black.opacity(0.4), location: 0), .init(color: .clear, location: 0.22),
                                   .init(color: .clear, location: 0.76), .init(color: .black.opacity(0.6), location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct PulseLabel: View {
    let text: String
    @State private var dim = false
    var body: some View {
        Text(text).font(.mono(10.5)).tracking(2.9).textCase(.uppercase).foregroundStyle(.white)
            .padding(.vertical, 11).padding(.horizontal, 16)
            .overlay(Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1))
            .opacity(dim ? 0.4 : 1)
            .onAppear { withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { dim = true } }
    }
}

private struct RecapSlide: View {
    @Environment(AppModel.self) private var m
    let index: Int
    let picks: AppModel.RecapPicks
    let onShow: Bool

    private enum Kind { case perfect, second, week, highlight, award, share }
    private var kind: Kind {
        var kinds: [Kind] = []
        if picks.perfect != nil { kinds.append(.perfect) }
        if picks.second != nil { kinds.append(.second) }
        kinds += [.week, .highlight, .award, .share]
        return kinds[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            switch kind {
            case .perfect:
                let p = picks.perfect!
                Kick("Standout of the week")
                SlideTitle(lead: "A perfect ", em: "week")
                StarWrap(p: p.p, show: onShow)
                Text(m.person(p.p).name).font(.serif(38)).foregroundStyle(.white)
                Why("7 of 7 days on \(p.h.name)\n\(p.s) days in a row and counting")
            case .second:
                let e = picks.second!, started = e.kind == "started"
                Kick(started ? "Something new" : "The comeback")
                SlideTitle(lead: started ? "Fresh " : "Back on ", em: started ? "start" : "track")
                StarWrap(p: e.who ?? "", show: onShow)
                Text(m.person(e.who ?? "").name).font(.serif(38)).foregroundStyle(.white)
                Why("\(started ? "Started “\(e.habit ?? "")” on \(e.when == "Tue" ? "Tuesday" : e.when)" : "Came back to \(e.habit ?? "")")\n\(e.text)")
            case .week:
                Kick("Your week")
                SlideTitle(lead: "You showed ", em: "up")
                HStack(spacing: 10) {
                    NumBox(value: "\(picks.myCount)", label: "check-ins")
                    NumBox(value: "\(picks.pct)%", label: "of the plan")
                    NumBox(value: "\(picks.delta >= 0 ? "+" : "−")\(abs(picks.delta))", label: "pts vs last week")
                }
                .padding(.top, 6)
                Why("Every one of those counted.").padding(.top, 6)
            case .highlight:
                let best = picks.myBest.map { m.streak($0, "me") } ?? 0
                Kick("Your highlight")
                Text("\(best)").font(.serif(150)).foregroundStyle(.white).shadow(color: .black.opacity(0.4), radius: 20, y: 6)
                SlideTitle(lead: "days in a ", em: "row").padding(.top, 6)
                Why("on \(picks.myBest?.name ?? "")\nyour longest run yet")
            case .award:
                ZStack {
                    Rays(spin: onShow)
                    Prize(show: onShow)
                }
                Kick("You earned").padding(.top, 18)
                Text("Steady Week").font(.serif(44)).italic().foregroundStyle(Brand.gold2).padding(.top, 12)
                Why("5+ days on 3 habits\nAdded to your trophy case")
            case .share:
                let best = picks.myBest.map { m.streak($0, "me") } ?? 0
                VStack(spacing: 0) {
                    Stamp(size: 74, color: Brand.gold2) { Ico(.trophy, 18); Text("Medal") }
                    Text("CREDS · WEEK 40").font(.mono(7.5)).tracking(2.25).foregroundStyle(Brand.gold2).padding(.top, 10)
                    Text("Steady Week").font(.serif(24)).italic().foregroundStyle(.white).padding(.top, 4)
                    Text("\(picks.myCount) check-ins · \(best)-day streak").font(.mono(8)).textCase(.uppercase).foregroundStyle(Color(hex: 0xF3D6CF)).padding(.top, 6)
                }
                .frame(width: 176, height: 236)
                .background(RadialGradient(stops: [.init(color: Brand.wine3, location: 0), .init(color: Color(hex: 0x4E101C), location: 0.7), .init(color: Color(hex: 0x1E050A), location: 1)],
                                           center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 150))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Brand.gold2.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 20)
                HStack(spacing: 10) {
                    ShareItem(icon: .story, label: "Story", msg: "Shared to your story (mock)")
                    ShareItem(icon: .chat, label: "Message", msg: "Sent to the group chat (mock)")
                    ShareItem(icon: .video, label: "Video", msg: "Shared as a video (mock)")
                    ShareItem(icon: .save, label: "Save", msg: "Saved to Photos (mock)")
                }
                .padding(.top, 24).padding(.bottom, 16)
                Button("View in Trophies") { m.wsTrophies() }.buttonStyle(.btn(.cream))
                Button("Done") { m.closeOverlay() }.buttonStyle(.btn(.ghostLight)).padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct Kick: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).font(.mono(11)).tracking(3.3).textCase(.uppercase).foregroundStyle(Brand.gold2) }
}

private struct SlideTitle: View {
    let lead, em: String
    var body: some View {
        Text("\(lead)\(Text(em).italic())").font(.serif(46)).tracking(-0.9).foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 12, y: 4)
            .padding(.top, 12).padding(.bottom, 16)
    }
}

private struct Why: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.mono(12)).tracking(0.5).lineSpacing(7).foregroundStyle(Color(hex: 0xEFD2CB)).padding(.top, 10)
    }
}

private struct NumBox: View {
    let value, label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.serif(48)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
            Text(label).font(.mono(9.5)).tracking(1.1).textCase(.uppercase).foregroundStyle(Color(hex: 0xEFD2CB)).lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14).padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.white.opacity(0.12), lineWidth: 1))
    }
}

private struct StarShape: Shape {
    func path(in r: CGRect) -> Path {
        let pts: [(CGFloat, CGFloat)] = [(0.5, 0), (0.612, 0.345), (0.976, 0.345), (0.682, 0.559), (0.794, 0.905), (0.5, 0.691), (0.206, 0.905), (0.318, 0.559), (0.024, 0.345), (0.388, 0.345)]
        var p = Path()
        p.move(to: CGPoint(x: r.minX + pts[0].0 * r.width, y: r.minY + pts[0].1 * r.height))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)) }
        p.closeSubpath()
        return p
    }
}

private struct StarWrap: View {
    let p: String
    let show: Bool
    var body: some View {
        ZStack {
            StarShape().fill(Color(hex: 0xFFE9E2))
            Av(p: p, size: 96).padding(.top, 14)
        }
        .frame(width: 210, height: 210)
        .shadow(color: .black.opacity(0.45), radius: 15, y: 18)
        .scaleEffect(show ? 1 : 0.4)
        .rotationEffect(.degrees(show ? 0 : -30))
        .opacity(show ? 1 : 0)
        .animation(.spring(response: 0.9, dampingFraction: 0.65), value: show)
        .padding(.bottom, 16)
    }
}

private struct Rays: View {
    let spin: Bool
    @State private var angle = 0.0
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2), r = size.width / 2
            var p = Path()
            var a = 0.0
            while a < 360 {
                p.move(to: c)
                p.addArc(center: c, radius: r, startAngle: .degrees(a - 90), endAngle: .degrees(a + 7 - 90), clockwise: false)
                p.closeSubpath()
                a += 20
            }
            ctx.fill(p, with: .color(Color(red: 226 / 255, green: 198 / 255, blue: 122 / 255).opacity(0.13)))
        }
        .frame(width: 560, height: 560)
        .mask(RadialGradient(stops: [.init(color: .black, location: 0.18 / 0.71), .init(color: .clear, location: 0.62 / 0.71)], center: .center, startRadius: 0, endRadius: 280 * 1.41))
        .rotationEffect(.degrees(angle))
        .allowsHitTesting(false)
        .frame(width: 10, height: 10)
        .offset(y: -50)
        .onAppear { withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { angle = 360 } }
    }
}

private struct Prize: View {
    let show: Bool
    @State private var float = false
    var body: some View {
        MedalArt(tier: "silver").frame(width: 132)
            .offset(y: show ? (float ? -8 : 0) : 60)
            .scaleEffect(show ? 1 : 0.7)
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 1.1, dampingFraction: 0.7), value: show)
            .onChange(of: show) { _, s in
                if s {
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_100_000_000)
                        withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { float = true }
                    }
                } else { float = false }
            }
    }
}

private struct ShareItem: View {
    @Environment(AppModel.self) private var m
    let icon: UIIcon
    let label: String
    let msg: String
    var body: some View {
        Button { m.showToast(msg) } label: {
            VStack(spacing: 8) {
                Ico(icon, 20).foregroundStyle(Color(hex: 0xF6EBE6))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().strokeBorder(.white.opacity(0.28), lineWidth: 1))
                Text(label).font(.mono(9.5)).tracking(1.1).textCase(.uppercase).foregroundStyle(Color(hex: 0xEADBD4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.press)
    }
}
