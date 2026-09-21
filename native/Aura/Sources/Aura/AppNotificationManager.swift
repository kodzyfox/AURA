import SwiftUI
import Combine

public enum NotificationType: Sendable {
    case info
    case success
    case warning
    case error

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return Theme.accent
        case .success: return Theme.green
        case .warning: return Theme.orange
        case .error: return Color(red: 1.0, green: 0.3, blue: 0.35)
        }
    }
}

public struct AppNotification: Identifiable, Equatable {
    public let id = UUID()
    public let type: NotificationType
    public let title: String
    public let message: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        type: NotificationType = .info,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor public final class AppNotificationManager: ObservableObject {
    public static let shared = AppNotificationManager()

    @Published public var currentNotification: AppNotification?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    public func show(
        type: NotificationType = .info,
        title: String,
        message: String,
        actionTitle: String? = nil,
        autoDismissSeconds: Double? = 5.0,
        action: (() -> Void)? = nil
    ) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            currentNotification = AppNotification(
                type: type,
                title: title,
                message: message,
                actionTitle: actionTitle,
                action: action
            )
        }

        if let seconds = autoDismissSeconds {
            dismissTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.25)) {
                    if self.currentNotification?.title == title {
                        self.currentNotification = nil
                    }
                }
            }
        }
    }

    public func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            currentNotification = nil
        }
    }
}

public struct AppNotificationBannerView: View {
    @ObservedObject var manager = AppNotificationManager.shared

    public init() {}

    public var body: some View {
        if let notification = manager.currentNotification {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: notification.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(notification.type.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(notification.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text(notification.message)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                if let actionTitle = notification.actionTitle, let action = notification.action {
                    Button {
                        action()
                        manager.dismiss()
                    } label: {
                        Text(actionTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(notification.type.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
                            .foregroundStyle(notification.type.color)
                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(notification.type.color.opacity(0.4)))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    manager.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(notification.type.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 16, y: 6)
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }
}
