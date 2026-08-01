import SwiftUI

struct GoodMorningView: View {
    var body: some View {

        ZStack {

            Image("goodMorningBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // START -> Fear video first
            NavigationLink(value: Route.fearMorning) {
                Image("startButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
            }
            .buttonStyle(.plain)
            .position(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height * 0.72
            )
        }
    }
}

#Preview {
    NavigationStack {
        GoodMorningView()
    }
}
