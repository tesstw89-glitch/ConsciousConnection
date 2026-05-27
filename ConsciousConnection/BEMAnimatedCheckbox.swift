import SwiftUI
import UIKit
import BEMCheckBox

struct BEMAnimatedCheckbox: UIViewRepresentable {
    @Binding var isOn: Bool

    var size: CGFloat = 28
    var onTintColor: UIColor = .white
    var onFillColor: UIColor = .white
    var onCheckColor: UIColor = .black
    var offTintColor: UIColor = UIColor.white.withAlphaComponent(0.55)

    func makeCoordinator() -> Coordinator {
        Coordinator(isOn: $isOn)
    }

    func makeUIView(context: Context) -> BEMCheckBox {
        let checkbox = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: size, height: size))

        checkbox.delegate = context.coordinator
        checkbox.on = isOn
        checkbox.boxType = .circle
        checkbox.lineWidth = 2
        checkbox.cornerRadius = 6
        checkbox.animationDuration = 0.55
        checkbox.onAnimationType = .bounce
        checkbox.offAnimationType = .bounce

        checkbox.tintColor = offTintColor
        checkbox.onTintColor = onTintColor
        checkbox.onFillColor = onFillColor
        checkbox.offFillColor = .clear
        checkbox.onCheckColor = onCheckColor
        checkbox.backgroundColor = .clear

        return checkbox
    }

    func updateUIView(_ uiView: BEMCheckBox, context: Context) {
        if uiView.on != isOn {
            uiView.setOn(isOn, animated: true)
        }

        uiView.tintColor = offTintColor
        uiView.onTintColor = onTintColor
        uiView.onFillColor = onFillColor
        uiView.onCheckColor = onCheckColor
    }

    final class Coordinator: NSObject, BEMCheckBoxDelegate {
        @Binding var isOn: Bool

        init(isOn: Binding<Bool>) {
            self._isOn = isOn
        }

        func didTap(_ checkBox: BEMCheckBox) {
            isOn = checkBox.on
        }
    }
}
