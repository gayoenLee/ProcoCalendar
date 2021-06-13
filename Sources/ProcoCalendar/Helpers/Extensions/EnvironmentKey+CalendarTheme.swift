// Kevin Li - 6:10 PM - 7/14/20

import SwiftUI

public struct CalendarTheme: Equatable, Hashable {

    public let primary: Color

    public init(primary: Color) {
        self.primary = primary
    }
}




 extension Color {
    //심심기간인 경우 배경색
    static let boring_period_color = Color("boring_period_color")
}
