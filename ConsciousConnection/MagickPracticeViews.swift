import SwiftUI
import UIKit

// MARK: - Practice model

enum MagickPracticeStep: String, Hashable, Identifiable {
    case openAltar
    case fourElements
    case meditate
    case tarot
    case magickDiary
    case fireSigil
    case traditionalSymbol
    case closeAltar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .openAltar:
            return "Open the Altar"
        case .fourElements:
            return "The Four Elements"
        case .meditate:
            return "Meditate"
        case .tarot:
            return "Tarot"
        case .magickDiary:
            return "Magick Diary"
        case .fireSigil:
            return "Fire a Sigil"
        case .traditionalSymbol:
            return "Meditate on a Traditional Symbol"
        case .closeAltar:
            return "Close the Altar"
        }
    }

    var assetName: String? {
        switch self {
        case .openAltar:
            return "Openthealtar"
        case .fourElements:
            return "The4Elements"
        case .meditate:
            return "Meditate"
        case .tarot:
            return "Tarot"
        case .magickDiary:
            return "Magickdiary"
        case .fireSigil:
            return "Sigilwork"
        case .traditionalSymbol:
            return nil
        case .closeAltar:
            return "Closethealtar"
        }
    }

    var isRequiredCustomStep: Bool {
        switch self {
        case .openAltar, .fourElements, .magickDiary, .closeAltar:
            return true
        default:
            return false
        }
    }

    static let addableSteps: [MagickPracticeStep] = [
        .tarot,
        .meditate,
        .fireSigil,
        .traditionalSymbol
    ]
}

struct MagickPracticeItem: Identifiable, Hashable {
    let id: UUID
    let step: MagickPracticeStep

    init(id: UUID = UUID(), step: MagickPracticeStep) {
        self.id = id
        self.step = step
    }

    static var dailyPractice: [MagickPracticeItem] {
        [
            MagickPracticeItem(step: .openAltar),
            MagickPracticeItem(step: .fourElements),
            MagickPracticeItem(step: .meditate),
            MagickPracticeItem(step: .tarot),
            MagickPracticeItem(step: .magickDiary),
            MagickPracticeItem(step: .closeAltar)
        ]
    }

    static var defaultCustomPractice: [MagickPracticeItem] {
        [
            MagickPracticeItem(step: .openAltar),
            MagickPracticeItem(step: .fourElements),
            MagickPracticeItem(step: .magickDiary),
            MagickPracticeItem(step: .closeAltar)
        ]
    }
}

private enum TraditionalSymbol: Int, CaseIterable {
    case glyph1 = 1
    case glyph2
    case glyph3
    case glyph4
    case glyph5
    case glyph6
    case glyph7
    case glyph8

    var assetName: String {
        "glyph\(rawValue)"
    }

    var backgroundColor: Color {
        switch self {
        case .glyph1:
            return Color(red: 0.0, green: 151.0 / 255.0, blue: 178.0 / 255.0)
        case .glyph2, .glyph5:
            return Color(red: 33.0 / 255.0, green: 40.0 / 255.0, blue: 58.0 / 255.0)
        case .glyph3:
            return Color(red: 85.0 / 255.0, green: 34.0 / 255.0, blue: 93.0 / 255.0)
        case .glyph4:
            return Color(red: 0.0, green: 0.0, blue: 1.0 / 255.0)
        case .glyph6:
            return Color(red: 195.0 / 255.0, green: 142.0 / 255.0, blue: 43.0 / 255.0)
        case .glyph7:
            return Color(red: 1.0, green: 210.0 / 255.0, blue: 48.0 / 255.0)
        case .glyph8:
            return Color(red: 49.0 / 255.0, green: 49.0 / 255.0, blue: 49.0 / 255.0)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .glyph6, .glyph7:
            return Color.black.opacity(0.82)
        default:
            return .white
        }
    }
}

// MARK: - Portal

struct MagickPortalRootView: View {
    let onReturnHome: () -> Void

    var body: some View {
        NavigationStack {
            MagickPortalView(onReturnHome: onReturnHome)
        }
        .tint(.white)
    }
}

private struct MagickPortalView: View {
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            Image("MagickPortal")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(0.08)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                NavigationLink {
                    MagickPracticeRunnerView(
                        items: MagickPracticeItem.dailyPractice,
                        onReturnHome: onReturnHome
                    )
                } label: {
                    PortalActionLabel(title: "Daily Practice")
                }
                .buttonStyle(MagickPressStyle())

                NavigationLink {
                    MagickPracticeBuilderView(onReturnHome: onReturnHome)
                } label: {
                    PortalActionLabel(title: "Build Your Own Practice")
                }
                .buttonStyle(MagickPressStyle())

                Spacer()
                    .frame(height: 96)
            }
            .padding(.horizontal, 38)

            VStack {
                HStack {
                    Button {
                        makeMagickHaptic()
                        onReturnHome()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.48))
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                            }
                    }
                    .buttonStyle(MagickPressStyle())
                    .accessibilityLabel("Return home")

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PortalActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .semibold, design: .serif))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .padding(.horizontal, 18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.58))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.72), lineWidth: 1.2)
                    }
            }
            .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
    }
}

// MARK: - Custom practice builder

private struct MagickPracticeBuilderView: View {
    let onReturnHome: () -> Void

    @State private var items = MagickPracticeItem.defaultCustomPractice
    @State private var showingAddStep = false
    @State private var showingPractice = false

    private var existingSteps: Set<MagickPracticeStep> {
        Set(items.map(\.step))
    }

    var body: some View {
        ZStack {
            MagickBuilderBackground()

            List {
                Section {
                    ForEach(items) { item in
                        HStack(spacing: 14) {
                            Image(systemName: iconName(for: item.step))
                                .font(.title3)
                                .foregroundStyle(Color(red: 1.0, green: 210.0 / 255.0, blue: 48.0 / 255.0))
                                .frame(width: 30)

                            Text(item.step.title)
                                .font(.system(size: 18, weight: .semibold, design: .serif))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            if item.step.isRequiredCustomStep {
                                Text("Always included")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.58))
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowBackground(Color.white.opacity(0.09))
                        .deleteDisabled(item.step.isRequiredCustomStep)
                        .moveDisabled(item.step == .closeAltar)
                    }
                    .onMove(perform: moveItems)
                    .onDelete(perform: deleteItems)
                } header: {
                    Text("Drag the tokens into your chosen order")
                        .foregroundStyle(.white.opacity(0.72))
                        .textCase(nil)
                } footer: {
                    Text("Open the Altar, The Four Elements, Magick Diary and Close the Altar remain in every practice. Close the Altar always stays last.")
                        .foregroundStyle(.white.opacity(0.62))
                        .textCase(nil)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle("Build Your Own Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(Color(red: 24.0 / 255.0, green: 29.0 / 255.0, blue: 44.0 / 255.0), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    makeMagickHaptic()
                    showingAddStep = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Add a practice token")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()

                Button {
                    makeMagickHaptic()
                    showingPractice = true
                } label: {
                    Image("nextButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 84)
                }
                .buttonStyle(MagickPressStyle())
                .accessibilityLabel("Start custom practice")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showingAddStep) {
            MagickAddStepView(existingSteps: existingSteps) { step in
                addStep(step)
            }
        }
        .navigationDestination(isPresented: $showingPractice) {
            MagickPracticeRunnerView(items: items, onReturnHome: onReturnHome)
        }
    }

    private func iconName(for step: MagickPracticeStep) -> String {
        switch step {
        case .openAltar:
            return "sparkles"
        case .fourElements:
            return "circle.grid.cross"
        case .meditate:
            return "brain.head.profile"
        case .tarot:
            return "rectangle.stack"
        case .magickDiary:
            return "book.closed"
        case .fireSigil:
            return "flame"
        case .traditionalSymbol:
            return "seal"
        case .closeAltar:
            return "lock"
        }
    }

    private func addStep(_ step: MagickPracticeStep) {
        guard !existingSteps.contains(step) else { return }

        let newItem = MagickPracticeItem(step: step)
        if let closingIndex = items.firstIndex(where: { $0.step == .closeAltar }) {
            items.insert(newItem, at: closingIndex)
        } else {
            items.append(newItem)
            items.append(MagickPracticeItem(step: .closeAltar))
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        keepClosingStepLast()
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            guard items.indices.contains(index),
                  !items[index].step.isRequiredCustomStep else {
                continue
            }
            items.remove(at: index)
        }
        keepClosingStepLast()
    }

    private func keepClosingStepLast() {
        guard let closingIndex = items.firstIndex(where: { $0.step == .closeAltar }) else {
            items.append(MagickPracticeItem(step: .closeAltar))
            return
        }

        let closingItem = items.remove(at: closingIndex)
        items.append(closingItem)
    }
}

private struct MagickBuilderBackground: View {
    var body: some View {
        ZStack {
            Color(red: 24.0 / 255.0, green: 29.0 / 255.0, blue: 44.0 / 255.0)

            RadialGradient(
                colors: [
                    Color(red: 85.0 / 255.0, green: 34.0 / 255.0, blue: 93.0 / 255.0).opacity(0.62),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 430
            )

            RadialGradient(
                colors: [
                    Color(red: 0.0, green: 151.0 / 255.0, blue: 178.0 / 255.0).opacity(0.22),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 0,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

private struct MagickAddStepView: View {
    let existingSteps: Set<MagickPracticeStep>
    let onAdd: (MagickPracticeStep) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(MagickPracticeStep.addableSteps) { step in
                Button {
                    makeMagickHaptic()
                    onAdd(step)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(step.title)
                            .foregroundStyle(.primary)

                        Spacer()

                        if existingSteps.contains(step) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .disabled(existingSteps.contains(step))
            }
            .navigationTitle("Add to Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Practice runner

private struct MagickPracticeRunnerView: View {
    let items: [MagickPracticeItem]
    let onReturnHome: () -> Void

    @State private var currentIndex = 0
    @State private var symbolSelections: [UUID: TraditionalSymbol]
    @State private var revealedSymbolSteps: Set<UUID> = []

    init(items: [MagickPracticeItem], onReturnHome: @escaping () -> Void) {
        self.items = items
        self.onReturnHome = onReturnHome

        let randomSymbols: [UUID: TraditionalSymbol] = Dictionary(
            uniqueKeysWithValues: items.compactMap { item -> (UUID, TraditionalSymbol)? in
                guard item.step == .traditionalSymbol else { return nil }
                return (item.id, TraditionalSymbol.allCases.randomElement() ?? .glyph1)
            }
        )
        _symbolSelections = State(initialValue: randomSymbols)
    }

    private var currentItem: MagickPracticeItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let currentItem {
                    practiceContent(for: currentItem, in: geometry)
                        .id(currentItem.id)
                        .transition(.opacity)
                } else {
                    Color(red: 33.0 / 255.0, green: 40.0 / 255.0, blue: 58.0 / 255.0)
                        .ignoresSafeArea()
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        if shouldShowHomeButton {
                            Button {
                                makeMagickHaptic()
                                onReturnHome()
                            } label: {
                                Image("homeButton")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 82)
                            }
                            .accessibilityLabel("Return home")
                        } else if shouldShowNextButton {
                            Button {
                                advancePractice()
                            } label: {
                                Image("nextButton")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 82)
                            }
                            .accessibilityLabel("Next practice step")
                            .transition(
                                .scale(scale: 0.65)
                                .combined(with: .opacity)
                            )
                        }
                    }
                    .buttonStyle(MagickPressStyle())
                    .padding(.trailing, 22)
                    .padding(.bottom, max(18, geometry.safeAreaInsets.bottom + 6))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func practiceContent(
        for item: MagickPracticeItem,
        in geometry: GeometryProxy
    ) -> some View {
        if item.step == .traditionalSymbol {
            let symbol = symbolSelections[item.id] ?? .glyph1

            TraditionalSymbolPracticeView(
                symbol: symbol,
                geometry: geometry
            ) {
                guard !revealedSymbolSteps.contains(item.id) else { return }

                makeMagickHaptic()

                withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) {
                    revealedSymbolSteps.insert(item.id)
                }
            }
        } else if let assetName = item.step.assetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .ignoresSafeArea()
        }
    }

    private var shouldShowHomeButton: Bool {
        guard let currentItem else { return true }
        return currentItem.step == .closeAltar || currentIndex == items.count - 1
    }

    private var shouldShowNextButton: Bool {
        guard let currentItem else { return false }

        if currentItem.step == .traditionalSymbol {
            return revealedSymbolSteps.contains(currentItem.id)
        }

        return true
    }

    private func advancePractice() {
        guard currentIndex < items.count - 1 else {
            onReturnHome()
            return
        }

        makeMagickHaptic()

        withAnimation(.easeInOut(duration: 0.28)) {
            currentIndex += 1
        }
    }
}

private struct TraditionalSymbolPracticeView: View {
    let symbol: TraditionalSymbol
    let geometry: GeometryProxy
    let onSymbolTapped: () -> Void

    var body: some View {
        ZStack {
            symbol.backgroundColor
                .ignoresSafeArea()

            Button(action: onSymbolTapped) {
                Image(symbol.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: min(geometry.size.width * 0.86, 460),
                        maxHeight: geometry.size.height * 0.72
                    )
                    .padding(.horizontal, 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(MagickSymbolPressStyle())
            .accessibilityLabel("Traditional magickal symbol")
            .accessibilityHint("Tap to reveal the next button")
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
}


// MARK: - Shared interaction styling

private struct MagickSymbolPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .brightness(configuration.isPressed ? 0.12 : 0)
            .animation(
                .spring(response: 0.22, dampingFraction: 0.55),
                value: configuration.isPressed
            )
    }
}

private struct MagickPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private func makeMagickHaptic() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
}
