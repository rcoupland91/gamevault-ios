import SwiftUI

struct GameDetailView: View {
    @StateObject private var vm: GameDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var theme
    var onSave: (() -> Void)?

    init(game: Game, onSave: (() -> Void)? = nil) {
        _vm = StateObject(wrappedValue: GameDetailViewModel(game: game))
        self.onSave = onSave
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.bottom, 16)

                    VStack(spacing: 14) {
                        heroMetaSection
                        coreDetailsCard
                        metadataCard
                        reviewNotesCard

                        if let err = vm.error {
                            ErrorBanner(message: err) { vm.error = nil }
                        }

                        VaultButton(
                            title: vm.saveSuccess ? "Saved!" : "Save Changes",
                            icon: vm.saveSuccess ? "checkmark.circle.fill" : "checkmark",
                            action: saveAction,
                            isLoading: vm.isSaving
                        )
                        .animation(.spring(response: 0.3), value: vm.saveSuccess)

                        VaultButton(title: "Delete Game", icon: "trash",
                                    action: deleteAction, isDestructive: true, style: .ghost)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(width: proxy.size.width)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(vm.game.title)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 24)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        heroBackground
        .frame(height: 280)
        .frame(maxWidth: .infinity)
    }

    private var heroMetaSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let year = vm.game.year, !year.isEmpty {
                    Text(year)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let mc = vm.game.metacritic {
                    metacriticBadge(mc)
                }
            }

            Text(vm.game.title)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    StatusPill(status: vm.status)
                    if !vm.platform.isEmpty {
                        InfoChip(text: vm.platform, icon: "display")
                    }
                    if !vm.hours.isEmpty {
                        InfoChip(text: "\(vm.hours)h", icon: "clock")
                    }
                    if !vm.genre.isEmpty {
                        InfoChip(text: vm.genre, icon: "tag")
                    }
                }
            }
        }
    }

    private var heroBackground: some View {
        Group {
            if let bgUrl = vm.game.backgroundUrl ?? vm.game.artUrl,
               let url = URL(string: bgUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        theme.accentColor.opacity(0.25)
                    }
                }
            } else {
                LinearGradient(
                    colors: [theme.accentColor.opacity(0.55), theme.accentColor.opacity(0.12)],
                    startPoint: .top, endPoint: .bottom
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .clipped()
        .overlay(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.35),
                    .init(color: Color.black.opacity(0.28), location: 0.72),
                    .init(color: Color(uiColor: .systemBackground).opacity(0.82), location: 0.82),
                    .init(color: Color(uiColor: .systemBackground), location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    private func metacriticBadge(_ score: Int) -> some View {
        HStack(spacing: 4) {
            Text("MC")
                .font(.caption2).fontWeight(.black).foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(metacriticColor(score))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text("\(score)").font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Form cards

    private var coreDetailsCard: some View {
        VaultCard {
            VStack(spacing: 14) {
                formSection("Title") {
                    VaultTextField(placeholder: "Game title", text: $vm.title, icon: "textformat")
                }
                Divider().opacity(0.5)
                formSection("Status") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: GameStatus.allCases.count),
                        spacing: 8
                    ) {
                        ForEach(GameStatus.allCases) { s in
                            StatusSelectButton(status: s, isSelected: vm.status == s) {
                                vm.status = s
                            }
                        }
                    }
                }
                Divider().opacity(0.5)
                formSection("Rating") {
                    HStack {
                        StarRatingView(rating: $vm.rating)
                        Spacer()
                        if vm.rating > 0 {
                            Button { vm.rating = 0 } label: {
                                Text("Clear").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Divider().opacity(0.5)
                formSection("Hours Played") {
                    VaultTextField(placeholder: "e.g. 45", text: $vm.hours,
                                   icon: "clock", keyboardType: .decimalPad,
                                   autocapitalization: .never, autocorrect: false)
                }
            }
        }
    }

    private var metadataCard: some View {
        VaultCard {
            VStack(spacing: 14) {
                formSection("Platform") {
                    Menu {
                        ForEach(GameDetailViewModel.allPlatforms, id: \.self) { p in
                            Button(p) { vm.platform = p }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "display").foregroundStyle(.secondary).frame(width: 20)
                            Text(vm.platform.isEmpty ? "Select platform" : vm.platform)
                                .foregroundStyle(vm.platform.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                Divider().opacity(0.5)
                formSection("Genre") {
                    VaultTextField(placeholder: "e.g. Action RPG", text: $vm.genre, icon: "tag",
                                   autocapitalization: .words, autocorrect: false)
                }
                Divider().opacity(0.5)
                formSection("Year") {
                    VaultTextField(placeholder: "e.g. 2024", text: $vm.year, icon: "calendar",
                                   keyboardType: .numberPad, autocapitalization: .never, autocorrect: false)
                }
                Divider().opacity(0.5)
                formSection("Developer") {
                    VaultTextField(placeholder: "Studio name", text: $vm.developer, icon: "hammer",
                                   autocapitalization: .words, autocorrect: false)
                }
                Divider().opacity(0.5)
                formSection("Publisher") {
                    VaultTextField(placeholder: "Publisher name", text: $vm.publisher, icon: "building.2",
                                   autocapitalization: .words, autocorrect: false)
                }
            }
        }
    }

    private var reviewNotesCard: some View {
        VaultCard {
            VStack(alignment: .leading, spacing: 14) {
                formSection("Review") {
                    TextEditor(text: $vm.review)
                        .frame(minHeight: 90)
                        .padding(10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Divider().opacity(0.5)
                formSection("Private Notes") {
                    TextEditor(text: $vm.notes)
                        .frame(minHeight: 70)
                        .padding(10)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formSection<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
        }
    }

    private func metacriticColor(_ score: Int) -> Color {
        score >= 75 ? .green : (score >= 50 ? .yellow : .red)
    }

    private func saveAction() {
        Task {
            await vm.save()
            onSave?()
            if vm.status == .played {
                NotificationService.shared.scheduleReviewReminder(for: vm.game)
            } else {
                NotificationService.shared.cancelReviewReminder(for: vm.game.id)
            }
        }
    }

    private func deleteAction() {
        Task {
            if await vm.delete() {
                onSave?()
                dismiss()
            }
        }
    }
}
