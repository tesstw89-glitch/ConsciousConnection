import SwiftUI

struct NewCustomListSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var name = ""
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("List name") {
                    TextField("For example: Sunday reset", text: $name)
                        .textInputAutocapitalization(.sentences)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("New List") { onCreate(name); dismiss() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CustomListPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 22).padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(configuration.isPressed ? 0.82 : 0.96))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
