import SwiftUI
import PhotosUI

/// Shown for anyone without a profile picture.
struct DefaultAvatar: View {
    @Environment(\.pal) private var c
    var size: CGFloat = 30
    var body: some View {
        Circle().fill(c.bg2)
            .overlay(Ico(.person, size * 0.5).foregroundStyle(c.ink3).offset(y: size * 0.03))
            .frame(width: size, height: size)
    }
}

/// The user's profile picture, or the default icon until they choose one.
struct ProfilePic: View {
    @Environment(AppModel.self) private var m
    var size: CGFloat = 30
    var body: some View {
        if let img = m.myPhoto {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            DefaultAvatar(size: size)
        }
    }
}

/// Opens the photo library and saves the chosen image as the profile picture.
struct ProfilePhotoPicker<Label: View>: View {
    @Environment(AppModel.self) private var m
    @ViewBuilder var label: () -> Label
    @State private var item: PhotosPickerItem?
    var body: some View {
        PhotosPicker(selection: $item, matching: .images) { label() }
            .onChange(of: item) { _, picked in
                guard let picked else { return }
                Task {
                    if let data = try? await picked.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                        m.setPhoto(img)
                    } else {
                        m.showToast("That photo couldn’t be loaded")
                    }
                    item = nil
                }
            }
    }
}

/// `av(p, size, ok)` — a person's avatar with an optional "done" check badge.
struct Av: View {
    @Environment(\.pal) private var c
    @Environment(AppModel.self) private var m
    let p: String
    var size: CGFloat = 30
    var ok = false
    var body: some View {
        Group {
            if p == "me" { ProfilePic(size: size) } else { DefaultAvatar(size: size) }
        }
        .overlay(alignment: .bottomTrailing) {
            if ok {
                let b = max(12, size * 0.42)
                Circle().fill(c.acc)
                    .overlay(Ico(.check, max(7, size * 0.26)).foregroundStyle(Brand.onWine))
                    .frame(width: b, height: b)
                    .background(Circle().stroke(c.card, lineWidth: 4))
                    .offset(x: 2, y: 2)
            }
        }
        .accessibilityLabel(p == "me" ? "You" : m.person(p).name)
    }
}

/// `avStack(list, size, max, okFn)`.
struct AvStack: View {
    @Environment(\.pal) private var c
    let list: [String]
    var size: CGFloat = 24
    var max = 4
    var ring: Color? = nil
    var ok: ((String) -> Bool)? = nil
    var body: some View {
        let shown = Array(list.prefix(max)), more = list.count - shown.count
        HStack(spacing: -size * 0.3) {
            ForEach(Array(shown.enumerated()), id: \.offset) { _, p in
                Av(p: p, size: size, ok: ok?(p) ?? false)
                    .background(Circle().stroke(ring ?? c.card, lineWidth: 4))
            }
            if more > 0 {
                Text("+\(more)").font(.sans(10, .bold)).foregroundStyle(c.ink2)
                    .frame(width: size, height: size)
                    .background(Circle().fill(c.bg2))
                    .background(Circle().stroke(c.card, lineWidth: 4))
                    .padding(.leading, -8 + size * 0.3)
            }
        }
    }
}
