import SwiftUI

struct WorkEveningTasksView: View {
    @EnvironmentObject private var router: AppRouter

    @State private var isDone: Bool = false

    private let actionButtonX: CGFloat = 0.86
    private let actionButtonY: CGFloat = 0.90
    private let actionButtonWidth: CGFloat = 95

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("evening_cleaning")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Group {
                    if isDone {
                        Button {
                            router.path = []
                        } label: {
                            Image("homeButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: actionButtonWidth)
                        }
                    } else {
                        Button {
                            isDone = true
                        } label: {
                            Image("done")
                                .resizable()
                                .scaledToFit()
                                .frame(width: actionButtonWidth)
                        }
                    }
                }
                .buttonStyle(AssetButtonPressStyle())
                .position(
                    x: geo.size.width * actionButtonX,
                    y: geo.size.height * actionButtonY
                )
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}
