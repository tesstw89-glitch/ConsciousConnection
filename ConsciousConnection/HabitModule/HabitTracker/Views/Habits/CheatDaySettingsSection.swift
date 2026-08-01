import SwiftUI

struct CheatDaySettingsSection: View {
    @Binding var allowance: Int
    @Binding var period: CheatDayPeriod

    let accentColor: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(accentColor)

                    Text("Add a cheat day")
                        .font(.headline)
                        .foregroundStyle(primaryText)
                }

                Text("Use one when you need a day off without breaking your streak.")
                    .font(.caption)
                    .foregroundStyle(secondaryText)
            }

            HStack(spacing: 18) {
                Button {
                    if allowance > 0 {
                        allowance -= 1
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(allowance > 0 ? accentColor : tertiaryText)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle()
                                .fill(accentColor.opacity(allowance > 0 ? 0.15 : 0.07))
                        )
                }
                .buttonStyle(.plain)
                .disabled(allowance == 0)
                .accessibilityLabel("Remove a cheat day")

                VStack(spacing: 2) {
                    Text("\(allowance)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(primaryText)
                        .contentTransition(.numericText())

                    Text(allowance == 1 ? "cheat day" : "cheat days")
                        .font(.caption)
                        .foregroundStyle(secondaryText)
                }
                .frame(minWidth: 86)

                Button {
                    allowance += 1
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(accentColor))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a cheat day")
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                ForEach(CheatDayPeriod.allCases) { option in
                    Button {
                        period = option
                    } label: {
                        Text(option.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(period == option ? .white : secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(period == option ? accentColor : accentColor.opacity(0.14))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if allowance > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)

                    Text("You can use \(allowance) cheat day\(allowance == 1 ? "" : "s") per \(period.unitName).")
                        .font(.caption)
                }
                .foregroundStyle(accentColor)
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 20)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: allowance)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: period)
    }
}
