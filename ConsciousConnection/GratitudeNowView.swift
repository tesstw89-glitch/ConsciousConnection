import SwiftUI

struct GratitudeNowView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("gratitudeNow")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            NavigationLink(value: Route.sedona) {
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
