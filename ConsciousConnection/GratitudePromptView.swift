import SwiftUI

struct GratitudePromptView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            Image("gratitudePromptBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // NEXT -> Checklist (router controlled)
            NavigationLink(value: Route.checklist) {
                Image("nextButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    NavigationStack {
        GratitudePromptView()
    }
}
