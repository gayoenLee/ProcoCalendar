// Kevin Li - 5:19 PM - 6/14/20

import Combine
import SwiftUI

public class YearlyCalendarManager: ObservableObject, ConfigurationDirectAccess {

    enum PageState {
        case scroll
        case completed
    }

    @Published var currentPage: (index: Int, state: PageState) = (0, .completed)

    public var currentYear: Date {
        years[currentPage.index]
    }

    @Published public var datasource: YearlyCalendarDataSource?
    @Published public var delegate: YearlyCalendarDelegate?

    public var communicator: ElegantCalendarCommunicator?

    public var configuration: CalendarConfiguration
    public var years: [Date]

    private var anyCancellable: AnyCancellable?

    public init(configuration: CalendarConfiguration, initialYear: Date? = nil) {
       // print("연도 달력: \(initialYear)")
        self.configuration = configuration

        let years = configuration.calendar.generateDates(
            inside: DateInterval(start: configuration.startDate,
                                 end: configuration.endDate),
            matching: .firstDayOfEveryYear)

        self.years = configuration.ascending ? years : years.reversed()
      //  print("year calendarmanager에서 years확인: \(years)")
        
        
        if let initialYear = initialYear {
//            let page = calendar.yearsBetween(referenceDate, and: initialYear)
//            currentPage = (page, .scroll)
        } else {
            anyCancellable = $delegate.sink {
                $0?.calendar(willDisplayYear: self.currentYear)
            }
        }
    }

}

//extension YearlyCalendarManager {
//
//    public func scrollBackToToday() {
//        scrollToYear(Date())
//    }
//
//    public func scrollToYear(_ year: Date) {
//        print("연도 달력 scroll to year: \(year)")
//        if !calendar.isDate(currentYear, equalTo: year, toGranularity: .year) {
//            print("if문안 currentyear: \(currentYear)")
//
//            let page = calendar.yearsBetween(referenceDate, and: year)
//            print("page: \(page), refrencedate: \(referenceDate)")
//            currentPage = (page, .scroll)
//        }
//    }
//
//    func willDisplay(page: Int) {
//        print("연도 달력 will display: \(page)")
//        if currentPage.index != page || currentPage.state == .scroll {
//            currentPage = (page, .completed)
//            print("if문안 currentPage: \(currentPage)")
//
//            delegate?.calendar(willDisplayYear: currentYear)
//        }
//        if page <= 1{
//
//            print("1보다 작을 때 비포 start date: \(startDate)")
//            configuration.startDate =  Calendar.current.date(byAdding: .month, value: -10, to: startDate)!
//            print("after start date: \(startDate)")
//            configuration.endDate =  Calendar.current.date(byAdding: .month, value: -10, to: endDate)!
//            print("after endDate: \(endDate)")
//
//            let years = configuration.calendar.generateDates(
//                inside: DateInterval(start: Calendar.current.date(byAdding: .month, value: -10, to: startDate)!,
//                                     end: Calendar.current.date(byAdding: .month, value: -10, to: endDate)!),
//                matching: .firstDayOfEveryYear)
//
//            self.years = configuration.ascending ? years : years.reversed()
//            print("1보다 작을 때 years 확인: \(years)")
//            delegate?.calendar(willDisplayYear: currentYear)
//
//        }else if page >= 3{
//            print("3보다 클 때 비포 start date: \(startDate)")
//            configuration.startDate =  Calendar.current.date(byAdding: .month, value: 12, to: startDate)!
//            configuration.endDate = Calendar.current.date(byAdding: .month, value: 12, to: endDate)!
//
//            let years = configuration.calendar.generateDates(
//                inside: DateInterval(start: Calendar.current.date(byAdding: .month, value: -12, to: startDate)!,
//                                     end: Calendar.current.date(byAdding: .month, value: -12, to: endDate)!),
//                matching: .firstDayOfEveryYear)
//
//            self.years = configuration.ascending ? years : years.reversed()
//            print("3보다 클 때 years 확인: \(years)")
//
//            delegate?.calendar(willDisplayYear: currentYear)
//        }
//    }
//
//    func monthTapped(_ month: Date) {
//        delegate?.calendar(didSelectMonth: month)
//        communicator?.scrollToMonthAndShowMonthlyView(month)
//    }
//
//}

extension YearlyCalendarManager {

    static let mock = YearlyCalendarManager(configuration: .mock)
    static let mockWithInitialYear = YearlyCalendarManager(configuration: .mock, initialYear: .daysFromToday(365))

}

protocol YearlyCalendarManagerDirectAccess: ConfigurationDirectAccess {

    var calendarManager: YearlyCalendarManager { get }
    var configuration: CalendarConfiguration { get }

}

extension YearlyCalendarManagerDirectAccess {

    var configuration: CalendarConfiguration {
        calendarManager.configuration
    }

    var communicator: ElegantCalendarCommunicator? {
        calendarManager.communicator
    }

    var datasource: YearlyCalendarDataSource? {
        calendarManager.datasource
    }

    var delegate: YearlyCalendarDelegate? {
        calendarManager.delegate
    }

    var currentYear: Date {
        calendarManager.currentYear
    }

    var years: [Date] {
        calendarManager.years
    }

}

private extension Calendar {

    func yearsBetween(_ date1: Date, and date2: Date) -> Int {
        print("첫번째: \(date1), 두번째: \(date2)")
        let startOfYearForDate1 = startOfYear(for: date1)
        let startOfYearForDate2 = startOfYear(for: date2)
        
        return abs(dateComponents([.year],
                              from: startOfYearForDate1,
                              to: startOfYearForDate2).year!)
    }

}
