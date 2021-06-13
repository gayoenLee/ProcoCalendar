// Kevin Li - 5:19 PM - 6/14/20

import SwiftUI

public protocol ElegantCalendarDelegate: MonthlyCalendarDelegate, YearlyCalendarDelegate { }

public protocol MonthlyCalendarDelegate {

    func calendar(didSelectDay date: Date)
    //실행됨. 달에 대한 정보
    func calendar(willDisplayMonth date: Date, previousMonth: Date)
    //심심기간 설정 완료시 실행
    func calendar(didEditBoringPeriod selections: [Date], end: Bool)
}

public extension MonthlyCalendarDelegate {

    func calendar(didSelectDay date: Date) { }
    //이건 로그 안뜸.
    func calendar(willDisplayMonth date: Date, previousMonth: Date) {
        print("먼슬리 캘린더 디릴게이트 익스텐션에서 will display month")
    }
    
    //심심기간 설정 완료시 실행
    func calendar(didEditBoringPeriod selections: [Date], end: Bool){
        print("기간 설정 완료 엘레강트 캘린더 delegate")
    }

}

public protocol YearlyCalendarDelegate {

    func calendar(didSelectMonth date: Date)
    func calendar(willDisplayYear date: Date)

}

public extension YearlyCalendarDelegate {

    func calendar(didSelectMonth date: Date) { }
    func calendar(willDisplayYear date: Date) { }

}
