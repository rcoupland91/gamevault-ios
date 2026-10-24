import SwiftUI

// MARK: - Vault Card (primary card container)

struct VaultCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 16

    init(cornerRadius: CGFloat = 20, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content      = content()
        self.cornerRadius = cornerRadius
        self.padding      = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

// Legacy alias
typealias GlassCard = VaultCard

// MARK: - Game Row Card

struct GameRowCard: View {
    let game: Game

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            GameArtworkView(url: game.artUrl, cornerRadius: 12, aspectRatio: 3/4)
                .frame(width: 60, height: 78)

            VStack(alignment: .leading, spacing: 5) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    StatusPill(status: game.status)
                    if let platform = game.platform, !platform.isEmpty {
                        InfoChip(text: platform)
                    }
                }

                HStack(spacing: 8) {
                    if let h = game.hoursDisplay, !h.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.caption2).foregroundStyle(.secondary)
                            Text(h).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if let rating = game.rating, rating > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                            Text("\(rating)/5").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }
}

// MARK: - Hero Game Card (featured card in horizontal scroll)

struct HeroGameCard: View {
    let game: Game
    var width: CGFloat = 180

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GameArtworkView(url: game.artUrl, cornerRadius: 14)
                .frame(width: width, height: width * 4/3)
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .overlay(alignment: .topLeading) {
                    StatusPill(status: game.status)
                        .padding(10)
                }
                .overlay(alignment: .topTrailing) {
                    if let rating = game.rating, rating > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                            Text("\(rating)").font(.caption).fontWeight(.bold).foregroundStyle(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(8)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    if let platform = game.platform, !platform.isEmpty {
                        InfoChip(text: platform)
                    } else {
                        StatusPill(status: game.status)
                    }
                    if let hours = game.hoursDisplay {
                        InfoChip(text: hours, icon: "clock")
                    }
                }
            }
        }
        .padding(10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        .frame(width: width)
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    let status: GameStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(status.displayName).font(.caption2).fontWeight(.semibold).foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    var color: Color {
        switch status {
        case .playing: return .green
        case .played:  return .blue
        case .toplay:  return .orange
        }
    }
}

// Legacy alias
typealias StatusBadge = StatusPill

// MARK: - Info Chip

struct InfoChip: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 3) {
            if let icon { Image(systemName: icon).font(.caption2) }
            Text(text).font(.caption2).fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Stat Card (CARROT-style bold stat)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VaultCard(cornerRadius: 22, padding: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(color)
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                }
                Text(value)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(title).font(.subheadline).fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Vault Button

struct VaultButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var isLoading = false
    var isDestructive = false
    var style: VaultButtonStyle = .primary

    enum VaultButtonStyle { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(style == .primary ? .white : .primary).scaleEffect(0.85)
                } else if let icon {
                    Image(systemName: icon)
                }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .foregroundStyle(style == .primary ? .white : (isDestructive ? Color.red : .primary))
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                Group {
                    if style == .ghost {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    }
                }
            )
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var backgroundView: some View {
        if style == .primary {
            if isDestructive {
                LinearGradient(colors: [.red, .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            } else {
                Color.accentColor
            }
        } else if style == .secondary {
            Color.secondary.opacity(0.12)
        } else {
            Color(uiColor: .secondarySystemBackground)
        }
    }
}

// Legacy alias
typealias GlassButton = VaultButton

// MARK: - Vault Text Field

struct VaultTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrect = true

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon).foregroundStyle(.secondary).frame(width: 20)
            }
            Group {
                if isSecure && !isVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                        .autocorrectionDisabled(!autocorrect)
                }
            }
            .textContentType(textContentType)

            if isSecure {
                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash" : "eye").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

// Legacy alias
typealias GlassTextField = VaultTextField

// MARK: - Star Rating

struct StarRatingView: View {
    @Binding var rating: Int
    var isEditable = true
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(star <= rating ? Color.yellow : Color.secondary.opacity(0.3))
                    .onTapGesture {
                        guard isEditable else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            rating = star == rating ? 0 : star
                        }
                    }
            }
        }
        .sensoryFeedback(.selection, trigger: rating)
    }
}

// MARK: - Status Select Button

struct StatusSelectButton: View {
    let status: GameStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: status.icon).font(.title3).frame(height: 24)
                Text(status.displayName).font(.caption2).fontWeight(.medium).lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? statusColor.opacity(0.15) : Color.secondary.opacity(0.08))
            .foregroundStyle(isSelected ? statusColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? statusColor.opacity(0.5) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private var statusColor: Color {
        switch status {
        case .playing: return .green
        case .played:  return .blue
        case .toplay:  return .orange
        }
    }
}

// MARK: - Game Artwork

struct GameArtworkView: View {
    let url: String?
    var cornerRadius: CGFloat = 12
    var aspectRatio: CGFloat = 3/4

    var body: some View {
        // Color.clear establishes the frame bounds so scaledToFill clips correctly
        Color.clear
            .overlay {
                if let str = url, let imageURL = URL(string: str) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            placeholder
                        case .empty:
                            ZStack {
                                Color.secondary.opacity(0.15)
                                ProgressView().tint(.secondary)
                            }
                        @unknown default:
                            placeholder
                        }
                    }
                } else {
                    placeholder
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.indigo.opacity(0.4), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "gamecontroller.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.subheadline).foregroundStyle(.primary).multilineTextAlignment(.leading)
            Spacer()
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String = "See All"

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.title3).fontWeight(.bold)
                if let sub = subtitle {
                    Text(sub).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionTitle).font(.subheadline).fontWeight(.medium).foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 56)).foregroundStyle(.quaternary)
            VStack(spacing: 6) {
                Text(title).font(.title3).fontWeight(.bold)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            if let title = actionTitle, let action {
                Button(action: action) {
                    Text(title)
                        .font(.subheadline).fontWeight(.semibold).foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let color: Color
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.subheadline).foregroundStyle(.primary)
                    if let sub = subtitle {
                        Text(sub).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption2).fontWeight(.semibold).foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(color).clipShape(Capsule())
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var message = "Loading..."

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VaultCard {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text(message).font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(width: 120, height: 100)
            }
        }
    }
}

// (no custom material shim needed — SwiftUI provides .regularMaterial natively)

// MARK: - Game hours display helper

extension Game {
    var hoursDisplay: String? {
        guard let h = hours, h > 0 else { return nil }
        return h == h.rounded() ? "\(Int(h))h" : String(format: "%.1fh", h)
    }
}
