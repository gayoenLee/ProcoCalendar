// Kevin Li - 5:19 PM - 6/14/20

import SwiftUI

public protocol ElegantCalendarDataSource: MonthlyCalendarDataSource, YearlyCalendarDataSource { }

public protocol MonthlyCalendarDataSource {

    func calendar(backgroundColorOpacityForDate date: Date) -> Double
    func calendar(canSelectDate date: Date) -> Bool
    //내 일정이 등록된 날짜인지 체크하기 위한 메소드
    func calendar(myScheduleDate date: Date) -> Bool
    func calendar(viewForSelectedDate date: Date, dimensions size: CGSize) -> AnyView
    func calendar(viewForScheduleDate date: Date, dimensions size: CGSize) -> AnyView
    //일별 상세 페이지 관심있어요 뷰
    func calendar(viewForInterest date: Date, dimensions size: CGSize) -> AnyView
    //날짜 한 칸 관심있어요 버튼 뷰
    func calendar(viewForSmallInterest date: Date, dimensions size: CGSize)
    -> AnyView
    
}



public extension MonthlyCalendarDataSource {

    func calendar(backgroundColorOpacityForDate date: Date) -> Double { 1 }

    func calendar(canSelectDate date: Date) -> Bool { true }
    //내 일정이 등록된 날짜인지 체크하기 위한 메소드
    func calendar(myScheduleDate date: Date) -> Bool{ false }
    func calendar(viewForSelectedDate date: Date, dimensions size: CGSize) -> AnyView {
        EmptyView().erased
    }
    //상세 페이지 일정 리스트 뷰
    func calendar(viewForScheduleDate date: Date, dimensions size: CGSize) -> AnyView {
        EmptyView().erased
    }
    
    //상세페이지 관심있어요 버튼 뷰
    func calendar(viewForInterest date: Date, dimensions size: CGSize) -> AnyView {
        EmptyView().erased
    }
    //날짜 한 칸 관심있어요 버튼 뷰
    func calendar(viewForSmallInterest date: Date, dimension size: CGSize) -> AnyView{
        EmptyView().erased
    }

}

// TODO: Depending on future design choices, this may need some functions and properties
public protocol YearlyCalendarDataSource { }
