// Kevin Li - 2:26 PM - 6/14/20

import ElegantPages
import SwiftUI

public struct MonthlyCalendarView: View, MonthlyCalendarManagerDirectAccess {

    public var axis: Axis = .vertical

    @ObservedObject public var calendarManager: MonthlyCalendarManager

    private var isTodayWithinDateRange: Bool {
        Date() >= calendar.startOfDay(for: startDate) &&
            calendar.startOfDay(for: Date()) <= endDate
    }

    private var isCurrentMonthYearSameAsTodayMonthYear: Bool {
        calendar.isDate(currentMonth, equalTo: Date(), toGranularities: [.month, .year])
    }

    public init(calendarManager: MonthlyCalendarManager) {
        self.calendarManager = calendarManager
    }

    public var body: some View {
        GeometryReader { geometry in
            self.content(geometry: geometry)
                //.padding(.all)

        }
        .onAppear{
            print("먼슬리 캘린더뷰 나타남.")
        }
    }

    private func content(geometry: GeometryProxy) -> some View {
        CalendarConstants.Monthly.cellWidth = geometry.size.width

        return ZStack(alignment: .top) {
            monthsList
        }
        .frame(height: CalendarConstants.cellHeight*0.8)
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .onAppear{
            print("먼슬리 캘린더뷰  content 나타남.")
        }
    }

    private var monthsList: some View {
        Group {
            //새로운 달로 스크롤 할 때 불려지는 것. - onpagechanged
            if axis == .vertical {
                ElegantVList(manager: listManager,
                             pageTurnType: .monthlyEarlyCutoff,
                             viewForPage: monthView)
                    .onPageChanged(configureNewMonth)
                    .frame(width: CalendarConstants.Monthly.cellWidth)
            } else {
                ElegantHList(manager: listManager,
                             pageTurnType: .monthlyEarlyCutoff,
                             viewForPage: monthView)
                    .onPageChanged(configureNewMonth)
                    .frame(width: CalendarConstants.Monthly.cellWidth)
            }
        }
    }

    private func monthView(for page: Int) -> AnyView {
        MonthView(calendarManager: calendarManager, month: months[page])
            .erased
    }

}


private extension PageTurnType {

    static var monthlyEarlyCutoff: PageTurnType = .earlyCutoff(config: .monthlyConfig)
}

public extension EarlyCutOffConfiguration {

    static let monthlyConfig = EarlyCutOffConfiguration(
        scrollResistanceCutOff: 40,
        pageTurnCutOff: 80,
        pageTurnAnimation: .spring(response: 0.3, dampingFraction: 0.95))

}
