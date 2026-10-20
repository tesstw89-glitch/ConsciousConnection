import SwiftUI

// Swift Package targets don't always expose Xcode's auto-generated colour
// asset accessors. Load StrengthLab's original colours from its own bundle.
extension Color {
    static var purpleStart: Color { Color("PurpleStart", bundle: .module) }
    static var purpleEnd: Color { Color("PurpleEnd", bundle: .module) }
    static var blueStart: Color { Color("BlueStart", bundle: .module) }
    static var blueEnd: Color { Color("BlueEnd", bundle: .module) }
    static var orangeStart: Color { Color("OrangeStart", bundle: .module) }
    static var orangeEnd: Color { Color("OrangeEnd", bundle: .module) }
    static var greenStart: Color { Color("GreenStart", bundle: .module) }
    static var greenEnd: Color { Color("GreenEnd", bundle: .module) }
}
