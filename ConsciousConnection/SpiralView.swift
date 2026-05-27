import SwiftUI

struct SpiralView: View {

    @State private var path: [SpiralRoute] = []

    var body: some View {

        NavigationStack(path: $path) {

            SpiralTriggerView { trigger in
                path.append(.states(trigger))
            }
            .navigationDestination(for: SpiralRoute.self) { route in
                switch route {

                case .states(let trigger):
                    SpiralStatesView(trigger: trigger) { stateIndex in
                        path.append(.detail(trigger, stateIndex))
                    }

                case .detail(let trigger, let index):
                    let rung = SCALE[index]

                    SpiralDetailView(
                        trigger: trigger,
                        rung: rung,
                        onChangeState: { newRung in
                            // keep moving around within detail, as many times as you want
                            path.append(.detail(trigger, newRung.r - 1))
                        },
                        onGoEMT: { currentIndex in
                            // ✅ ALWAYS available from detail, no matter how many moves
                            path.append(.emt(trigger, currentIndex))
                        },
                        onReset: {
                            path = []
                        }
                    )

                case .emt(let trigger, let index):
                    SpiralEMTView(trigger: trigger, index: index) {
                        path.append(.sedona(trigger, index))
                    }

                case .sedona(let trigger, let index):
                    SpiralSedonaView(trigger: trigger, index: index)
                }
            }
        }
    }
}
