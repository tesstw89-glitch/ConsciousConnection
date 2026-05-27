import SwiftUI

struct WorkMorningIntroView: View {
    @EnvironmentObject private var router: AppRouter

    private let nextX: CGFloat = 0.86
    private let nextY: CGFloat = 0.90
    private let nextWidth: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LoopingVideoBackgroundView(
                    resourceName: "work_morning1",
                    fileExtension: "mp4"
                )
                .ignoresSafeArea()

                Button {
                    router.path.append(.workMorningRoutine)
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
