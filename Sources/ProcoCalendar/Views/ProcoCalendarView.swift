// Kevin Li - 6:19 PM - 6/6/20

import ElegantPages
import SwiftUI

public struct ProcoCalendarView: View {
    
    public var axis: Axis = .horizontal

    public let calendarManager: ElegantCalendarManager

    public init(calendarManager: ElegantCalendarManager) {
        self.calendarManager = calendarManager
       
    }
    
    public var body: some View {
        
        content
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
    }
    
    private var content: some View {
     Group {
            if axis == .vertical {
                //연도 달력으로 스크롤되는 기능 막아놓음.
               // ElegantVPages(manager: calendarManager.pagesManager) {
                 //   yearlyCalendarView
                    monthlyCalendarView
                //}
                //.onPageChanged(calendarManager.scrollToYearIfOnYearlyView)
                .erased
            }
            else {
               // ElegantHPages(manager: calendarManager.pagesManager) {
                  //  yearlyCalendarView
                    monthlyCalendarView
               // }
               // .onPageChanged(calendarManager.scrollToYearIfOnYearlyView)
               // .erased
            }
        }
    }

    private var yearlyCalendarView: some View {
        YearlyCalendarView(calendarManager: calendarManager.yearlyManager)
            .axis(axis.inverted)
            .onAppear{
                print("yearly calendar view나타남.")
            }
    }

    private var monthlyCalendarView: some View {
        MonthlyCalendarView(calendarManager: calendarManager.monthlyManager)
            .axis(axis.inverted)
    }

}
