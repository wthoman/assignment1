import SwiftUI

struct ToastView: View {
    let toast: Toast
    var onAction: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(toast.tint.onColor)
                .frame(width: 30, height: 30)
                .background(Circle().fill(toast.tint.color))
            Text(toast.message)
                .font(.display(.subheadline, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let title = toast.actionTitle {
                Button(title, action: onAction)
                    .font(.display(.subheadline, weight: .heavy))
                    .foregroundStyle(Palette.burgundy)
                    .frame(minWidth: 44, minHeight: 44)
                    .buttonStyle(.plain)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, toast.actionTitle == nil ? 14 : 6)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Palette.cardRaised)
                .shadow(color: Palette.shadow.opacity(2), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(toast.tint.color.opacity(0.5), lineWidth: 1)
        )
        .gesture(DragGesture(minimumDistance: 10).onEnded { value in
            if value.translation.height > 20 { onDismiss() }
        })
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityAction(named: Text(toast.actionTitle ?? "Dismiss")) {
            toast.actionTitle == nil ? onDismiss() : onAction()
        }
    }
}
