import SwiftUI

struct WorkMorningRoutineView: View {
    @EnvironmentObject private var router: AppRouter

    private let playX: CGFloat = 0.40
    private let playY: CGFloat = 0.60
    private let playWidth: CGFloat = 60

    private let nextX: CGFloat = 0.86
    private let nextY: CGFloat = 0.90
    private let nextWidth: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("take_care")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Button {
                    router.path.append(.morningMeditation)
                } label: {
                    Image("playButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: playWidth)
                }
                .buttonStyle(AssetButtonPressStyle())
                .position(
                    x: geo.size.width * playX,
                    y: geo.size.height * playY
                )

                Button {
                    router.path.append(.setIntention)
                } label: {
                    Image("nextButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: nextWidth)
                }
                .buttonStyle(AssetButtonPressStyle())
                .position(
                    x: geo.size.width * nextX,
                    y: geo.size.height * nextY
                )
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
