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
                Text("Creds").font(.serif(96)).italic().tracking(-2.5).foregroundStyle(Brand.cream)
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
    var body: some View {
        @Bindable var m = m
        ObScaffold {
            ObHeading(eyebrow: "Create account", lead: "Take your ", em: "seat.", sub: "So your friends can find you.")
            ProfilePhotoPicker {
                let none = m.myPhoto == nil
                VStack(spacing: 0) {
                    ProfilePic(size: 128)
                        .padding(5)
                        .overlay(Circle().strokeBorder(c.acc.opacity(none ? 0.6 : 1), style: StrokeStyle(lineWidth: 2, dash: none ? [6, 5] : [])))
                        .overlay(alignment: .bottomTrailing) {
                            Ico(none ? .plus : .camera, 18).foregroundStyle(Brand.onWine).frame(width: 42, height: 42)
                                .background(Circle().fill(c.acc)).background(Circle().stroke(c.card, lineWidth: 5))
                                .offset(x: -2, y: -2)
                        }
                    Text(none ? "Add a profile picture" : "Looking good!")
                        .font(.sans(17, .semibold)).foregroundStyle(c.ink).padding(.top, 14)
                    Text("Friends see it next to your check-ins.")
                        .font(.sans(13.5)).foregroundStyle(c.ink2).padding(.top, 3)
                    HStack(spacing: 7) { Ico(.camera, 15); Text(none ? "Choose a photo" : "Change photo") }
                        .font(.sans(15, .semibold))
                        .foregroundStyle(none ? Brand.onWine : c.acc)
                        .padding(.horizontal, 18).frame(height: 42)
                        .background(Capsule().fill(none ? c.acc : c.accSoft))
                        .padding(.top, 14)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20).padding(.horizontal, 16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(none ? c.accOn(0.05) : c.card))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(c.acc.opacity(none ? 0.35 : 0.15), lineWidth: 1.2))
                .contentShape(Rectangle())
            }
            .buttonStyle(.press)
            .accessibilityLabel(m.myPhoto == nil ? "Add a profile picture" : "Change profile picture")
            .accessibilityHint("Opens your photo library")
            .padding(.bottom, 20)
            VStack(spacing: 8) {
                Field(label: "Name", placeholder: "Your name", text: $m.obName,
                      error: m.obAttempted ? m.obNameError : nil, capitalization: .words)
                Field(label: "Email", placeholder: "you@school.edu", text: $m.obEmail,
                      error: m.obAttempted ? m.obEmailError : nil, keyboard: .emailAddress, capitalization: .never)
                Field(label: "Password", placeholder: "At least 8 characters", text: $m.obPassword, secure: true,
                      error: m.obAttempted ? m.obPasswordError : nil)
            }
        } foot: {
            if m.obAttempted && (m.obNameError != nil || m.obEmailError != nil || m.obPasswordError != nil) {
                ValidationNote(text: "Fill in the highlighted details to continue.")
            }
            Button("Continue") { withAnimation(.easeOut(duration: 0.2)) { m.obAccountContinue() } }.buttonStyle(.btn)
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
                            Tile(size: 46, on: on) { HIcon(g.ic, 27) }
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
            if m.obGoals.isEmpty {
                ValidationNote(text: "Pick at least one goal to continue.")
            }
            Button("Continue · \(m.obGoals.count) selected") { m.obNext() }.buttonStyle(.btn).disabled(m.obGoals.isEmpty)
        }
    }
}

private struct PeopleStep: View {
    @Environment(AppModel.self) private var m
    @Environment(\.pal) private var c
    var body: some View {
        ObScaffold {
            ObHeading(eyebrow: "Your circle", lead: "Find your ", em: "people.", sub: "These contacts are already on Creds.")
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

/// Message above Continue when the step isn't complete yet.
private struct ValidationNote: View {
    @Environment(\.pal) private var c
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Ico(.info, 14)
            Text(text).font(.sans(13, .semibold))
        }
        .foregroundStyle(c.acc)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
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
