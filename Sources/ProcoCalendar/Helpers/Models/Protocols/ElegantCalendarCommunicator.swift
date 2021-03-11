// Kevin Li - 2:42 PM - 7/12/20

import Foundation

public protocol ElegantCalendarCommunicator {

    func scrollToMonthAndShowMonthlyView(_ month: Date)
    func showYearlyView()

}

public extension ElegantCalendarCommunicator {

    func scrollToMonthAndShowMonthlyView(_ month: Date) {
        print("ElegantCalendarCommunicator에서 scrollToMonthAndShowMonthlyView안 메소드")
    }
    func showYearlyView() { }

}
