import SwiftUI

/// Onboarding: splash + 3 steps.
struct OnboardingView: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        Group {
            switch m.step {
            case 0: Splash()
            case 1: AccountStep()
            case 2: GoalsStep()
            default: PeopleStep()
            }
        }
    }
}

private struct Splash: View {
    @Environment(AppModel.self) private var m
    var body: some View {
        ZStack {
            Brand.stage.ignoresSafeArea()
            ZStack {
                Stripes.splash
                GeometryReader { g in
                    RadialGradient(colors: [Color(red: 1, green: 150 / 255, blue: 160 / 255).opacity(0.45), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.38), startRadius: 0, endRadius: g.size.width * 0.6)
                        .scaleEffect(x: 1, y: 0.75, anchor: UnitPoint(x: 0.5, y: 0.38))
                }
                LinearGradient(stops: [.init(color: .black.opacity(0.6), location: 0), .init(color: .black.opacity(0.1), location: 0.3),
                                       .init(color: .black.opacity(0.35), location: 0.64), .init(color: .black.opacity(0.95), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
            VStack {
                Spacer()
                CheckerFloor(cell: 56, tilt: 58, perspective: 0.5)
                    .frame(height: 240)
                    .padding(.horizontal, -120)
                    .mask(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.75)))
                    .opacity(0.45)
                    .offset(y: 50)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Text("Now showing").font(.mono(10.5)).tracking(3.4).textCase(.uppercase).foregroundStyle(Brand.gold2)
                Text("Daybook").font(.serif(96)).italic().tracking(-2.5).foregroundStyle(Brand.cream)
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 8)
                    .padding(.top, 14).padding(.bottom, 18)
                Text("Habits are easier with an audience. Show up, check in, and keep each other going.")
                    .font(.sans(15)).lineSpacing(4).foregroundStyle(Color(hex: 0xF0DCD6))
                    .multilineTextAlignment(.center).frame(maxWidth: 270)
                Spacer()
                VStack(spacing: 6) {
                    Button("Get started") { m.obNext() }.buttonStyle(.btn(.cream))
                    Button("I already have an account") { m.obNext() }.buttonStyle(.btn(.ghostCream))
                }
            }
            .padding(.horizontal, 22).padding(.bottom, 30)
        }
    }
}

private struct ObTop: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                IconBtn(label: "Back", action: { m.obBack() }) { Ico(.back, 19) }
                Spacer()
                Eyebrow("Step \(m.step) of 3")
            }
            .padding(.bottom, 12)
            HStack(spacing: 4) {
                ForEach(1...3, id: \.self) { i in Capsule().fill(m.step >= i ? c.acc : c.line).frame(height: 4) }
            }
            .padding(.top, 4).padding(.bottom, 24)
        }
    }
}

private struct ObScaffold<Content: View, Foot: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var foot: Foot
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                ObTop()
                content
            }
            .padding(.horizontal, 22).padding(.top, 14)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 6) { foot }.padding(.horizontal, 22).padding(.top, 20).padding(.bottom, 30)
        }
    }
}

private struct ObHeading: View {
    @Environment(\.pal) private var c
    let eyebrow, lead, em, sub: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(eyebrow, acc: true)
            EmTitle(lead: lead, em: em).padding(.top, 6)
            Text(sub).font(.sans(15)).lineSpacing(4).foregroundStyle(c.ink2).padding(.top, 10).padding(.bottom, 20)
        }
    }
}

private struct AccountStep: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    @State private var name = "Shannon"
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        ObScaffold {
            ObHeading(eyebrow: "Create account", lead: "Take your ", em: "seat.", sub: "So your friends can find you.")
            VStack(spacing: 8) {
                Field(label: "Name", text: $name)
                Field(label: "Email", placeholder: "you@school.edu", text: $email)
                Field(label: "Password", placeholder: "At least 8 characters", text: $password, secure: true)
            }
            Lbl(text: "Pick your avatar")
            Bleed(inset: 22, spacing: 8) {
                ForEach(Avatars.pickable, id: \.self) { id in
                    Button { m.myAv = id } label: {
                        AvatarArt(id: id).frame(width: 54, height: 54)
                            .padding(3)
                            .overlay(Circle().strokeBorder(m.myAv == id ? c.acc : .clear, lineWidth: 2.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Avatars.all[id]!.n)
                }
            }
        } foot: {
            Button("Continue") { m.obNext() }.buttonStyle(.btn)
        }
    }
}

private struct GoalsStep: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        ObScaffold {
            ObHeading(eyebrow: "Personalize", lead: "What are you ", em: "working on?", sub: "Pick a few. We'll suggest groups and communities that match.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(Seed.onboardingGoals, id: \.id) { g in
                    let on = m.obGoals.contains(g.id)
                    Button { m.toggleGoal(g.id) } label: {
                        HStack(spacing: 10) {
                            Tile(size: 34, on: on) { HIcon(g.ic, 18) }
                            Text(g.l).font(.sans(14, .semibold)).foregroundStyle(c.ink)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(on ? c.accOn(0.06) : c.card))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(on ? c.acc : c.line, lineWidth: on ? 1.6 : 1))
                    }
                    .buttonStyle(.press)
                }
            }
        } foot: {
            Button("Continue · \(m.obGoals.count) selected") { m.obNext() }.buttonStyle(.btn).disabled(m.obGoals.isEmpty)
        }
    }
}

private struct PeopleStep: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        ObScaffold {
            ObHeading(eyebrow: "Your circle", lead: "Find your ", em: "people.", sub: "These contacts are already on Daybook.")
            VStack(spacing: 0) {
                ForEach(Array(m.friends.enumerated()), id: \.element) { i, p in
                    let added = m.obAdded.contains(p)
                    Divided(first: i == 0) {
                        HStack(spacing: 12) {
                            Av(p: p, size: 44)
                            TwoLine(title: m.person(p).full, sub: "@\(m.person(p).handle) · \(m.person(p).mutual ?? 1) mutual", titleSize: 15)
                            JoinButton(joined: added, on: "Added", off: "Add") { m.toggleObAdd(p) }
                        }
                    }
                }
            }
            .card(v: 4, h: 14)
        } foot: {
            Button("Start my first day") { m.obFinish() }.buttonStyle(.btn)
        }
    }
}

/// The small Join / Joined button (.join).
struct JoinButton: View {
    @Environment(\.pal) private var c
    let joined: Bool
    var on = "Joined"
    var off = "Join"
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(joined ? on : off).font(.sans(13, .bold))
                .foregroundStyle(joined ? c.ink2 : Brand.onWine)
                .padding(.horizontal, 13).frame(height: 32)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(joined ? .clear : c.acc))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(joined ? c.line2 : .clear, lineWidth: 1))
        }
        .buttonStyle(.press)
    }
}
