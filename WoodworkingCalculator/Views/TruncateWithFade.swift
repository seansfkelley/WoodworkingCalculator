import SwiftUI

struct TruncateWithFade: ViewModifier {
    var width: CGFloat
    // TODO: startingAt is a hack. We should be able to hide the ellipsis so we can start fading
    // from the leading edge instead of hopping over a bit to make sure we hide the ellipsis.
    var startingAt: CGFloat

    @Environment(\.minimumScaleFactor) private var minimumScaleFactor
    @Environment(\.truncationMode) private var truncationMode

    @State private var computedWidth: CGFloat = 0
    @State private var intrinsicWidth: CGFloat = 0

    func body(content: Content) -> some View {
        let needsFade = intrinsicWidth * max(minimumScaleFactor, 0.01) > computedWidth + 0.5

        let measureableContent = content
            .onGeometryChange(for: CGFloat.self) {
                proxy in proxy.size.width
            } action: { w in
                // Deadband to avoid layout thrash.
                if abs(computedWidth - w) > 0.5 {
                    computedWidth = w
                }
            }
            // Background doesn't interfere with the content's sizing, and consequently, layout.
            // Copy the content into its own background so we can measure the intrinsic size
            // without affecting it.
            .background {
                content
                    .environment(\.minimumScaleFactor, 1)
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { w in
                        // Deadband to avoid layout thrash.
                        if abs(intrinsicWidth - w) > 0.5 {
                            intrinsicWidth = w
                        }
                    }
            }
        
        if needsFade {
            let cutoff = min(max(startingAt + width, 0), 1)
            let stops: [Gradient.Stop] = [
                .init(color: .clear, location: startingAt),
                .init(color: .white, location: cutoff) ,
                .init(color: .white, location: 1),
            ]
            
            switch (truncationMode) {
                case .head:
                    measureableContent.mask(alignment: .leading) {
                        LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
                    }
                case .tail:
                    measureableContent.mask(alignment: .leading) {
                        LinearGradient(stops: stops, startPoint: .trailing, endPoint: .leading)
                    }
                default:
                    measureableContent
            }
        } else {
            measureableContent
        }
    }
}

extension View {
    /// Call before `.minimumScaleFactor(_:)` and/or `.truncationMode(_:)`.
    func truncateWithFade(width: CGFloat = 0.15, startingAt: CGFloat = 0) -> some View {
        modifier(TruncateWithFade(width: width, startingAt: startingAt))
    }
}
