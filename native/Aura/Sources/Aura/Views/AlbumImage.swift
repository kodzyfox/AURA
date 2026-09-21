import SwiftUI

/// Displays album artwork with a smooth cross-fade + subtle scale transition
/// whenever the image changes. Wrap in `.frame()` and `.clipShape()` at the call site.
struct AlbumImage: View {
    var image: NSImage?

    /// A stable identity string derived from the image object pointer —
    /// changes whenever SwiftUI receives a new NSImage, triggering the transition.
    private var imageID: String {
        image.map { "\(ObjectIdentifier($0).hashValue)" } ?? "placeholder"
    }

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .id(imageID)
                    .transition(
                        .asymmetric(
                            insertion: .opacity
                                .combined(with: .scale(scale: 1.06))
                                .animation(.easeOut(duration: 0.38)),
                            removal: .opacity
                                .combined(with: .scale(scale: 0.94))
                                .animation(.easeIn(duration: 0.22))
                        )
                    )
            } else {
                LinearGradient(
                    colors: [Theme.accent.opacity(0.5), Theme.accent, .brown],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay(
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.6))
                )
                .id("placeholder")
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .clipped()
        .animation(.easeInOut(duration: 0.38), value: imageID)
    }
}
