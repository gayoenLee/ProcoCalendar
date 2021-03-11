// Kevin Li - 5:25 PM - 6/10/20

import Combine
import ElegantPages
import SwiftUI

public class ElegantCalendarManager: ObservableObject {

    public var currentMonth: Date {
        monthlyManager.currentMonth
    }

    public var selectedDate: Date? {
        monthlyManager.selectedDate
    }
    
    //3.02추가 심심기간 선택한 배열을 내가 수정해서 넣어주기 위해 추가.
    public var selections: [Date]{
        monthlyManager.selections
    }

    public var isShowingYearView: Bool {
        pagesManager.currentPage == 0
    }

    @Published public var datasource: ElegantCalendarDataSource?
    @Published public var delegate: ElegantCalendarDelegate?

    public let configuration: CalendarConfiguration

    @Published public var yearlyManager: YearlyCalendarManager
    @Published public var monthlyManager: MonthlyCalendarManager
    
    let pagesManager: ElegantPagesManager

    private var anyCancellable = Set<AnyCancellable>()

    //3.02 selections를 추가해서 받을 수 있도록 함.
    public init(configuration: CalendarConfiguration, initialMonth: Date? = nil, selections: [Date]) {
        print("엘레강트 매니저 init 안")
        self.configuration = configuration
        yearlyManager = YearlyCalendarManager(configuration: configuration,
                                              initialYear: initialMonth)
       
        monthlyManager = MonthlyCalendarManager(configuration: configuration,
                                                initialMonth: initialMonth, selections: selections)
        

        pagesManager = ElegantPagesManager(startingPage: 1,
                                           pageTurnType: .calendarEarlySwipe)

        yearlyManager.communicator = self
        monthlyManager.communicator = self

        $datasource
            .sink {
                self.monthlyManager.datasource = $0
                self.yearlyManager.datasource = $0
            }
            .store(in: &anyCancellable)

        $delegate
            .sink {
                self.monthlyManager.delegate = $0
                self.yearlyManager.delegate = $0
            }
            .store(in: &anyCancellable)

        Publishers.CombineLatest(yearlyManager.objectWillChange, monthlyManager.objectWillChange)
            .sink { _ in self.objectWillChange.send()
            }
            .store(in: &anyCancellable)
    }
    //현재 달이 아닌 다른 달을 yearly view에서 선택해서 이동할 때 호출됨.
    public func scrollToMonth(_ month: Date, animated: Bool = true) {
        print("엘레강트 매니저에서 스크롤투 먼스 메소드 안")
        monthlyManager.scrollToMonth(month, animated: animated)
    }

    public func scrollBackToToday(animated: Bool = true) {
        print("엘레강트 캘린더 매니저에서 scrollBackToToday 메소드 안")

        scrollToDay(Date(), animated: animated)
    }

    public func scrollToDay(_ day: Date, animated: Bool = true) {
        print("엘레강트 캘린더 매니저에서 scroll to day메소드 안")
        monthlyManager.scrollToDay(day, animated: animated)
    }
}

extension ElegantCalendarManager {

    // accounts for both when the user scrolls to the yearly calendar view and the
    // user presses the month text to scroll to the yearly calendar view
    func scrollToYearIfOnYearlyView(_ page: Int) {
        if page == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                self.yearlyManager.scrollToYear(self.currentMonth)
            }
        }
    }
}

extension ElegantCalendarManager: ElegantCalendarCommunicator {
    //현재 달이 아닌 다른 달을 yearly view에서 선택해서 이동할 때 호출됨.
    public func scrollToMonthAndShowMonthlyView(_ month: Date) {
        print("엘레강트 캘린더 매니저에서 scrollToMonthAndShowMonthlyView")
        pagesManager.scroll(to: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            self.scrollToMonth(month)
        }
    }

    public func showYearlyView() {
        pagesManager.scroll(to: 0)
    }

}

protocol ElegantCalendarDirectAccess {

    var parent: ElegantCalendarManager? { get }

}

extension ElegantCalendarDirectAccess {

    var datasource: ElegantCalendarDataSource? {
        parent?.datasource
    }

    var delegate: ElegantCalendarDelegate? {
        parent?.delegate
    }

}

private extension PageTurnType {

    static let calendarEarlySwipe: PageTurnType = .earlyCutoff(
        
        config: .init(scrollResistanceCutOff: 40,
                      pageTurnCutOff: 90,
                      pageTurnAnimation: .interactiveSpring(response: 0.35, dampingFraction: 0.86, blendDuration: 0.25)))

}
