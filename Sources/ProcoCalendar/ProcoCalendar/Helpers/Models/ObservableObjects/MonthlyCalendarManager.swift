// Kevin Li - 5:20 PM - 6/14/20

import Combine
import ElegantPages
import SwiftUI

public class MonthlyCalendarManager: ObservableObject, ConfigurationDirectAccess {

    @Published public private(set) var currentMonth: Date
    //선택한 날짜(클릭한)
    @Published public var selectedDate: Date? = nil{
        willSet{
            objectWillChange.send()
        }
    }

    //심심기간 추가 모드일 경우 구분 위해 추가
    @Published public var is_edit_mode: Bool = false{
        willSet{
            objectWillChange.send()
        }
    }
    public let objectWillChange = ObservableObjectPublisher()
    let listManager: ElegantListManager

    @Published public var datasource: MonthlyCalendarDataSource?
    @Published public var delegate: MonthlyCalendarDelegate?

    //*************선택한 날짜들 담는 곳 기간 선택 때문에 추가한 것.
    @Published var selections = [Date](){
        willSet{
            objectWillChange.send()
        }
    }
    //***********기간 선택시 선택한 날들을 담을 것. ClosedRange : 시작과 끝 범위가 명확할 때 사용.
    @Published var dateRangeWrapper: ClosedRange<Date>? = nil

    //심심기간 수정시 추가로 구분할 필요가 있어서 사용.
    @Published var edit_boring_period: Bool = false{
        willSet{
            objectWillChange.send()
        }
    }
    
    //내가 좋아요 또는 심심기간 클릭시 사용..클릭했을 경우 true->통신시 프로젝트에서 사용
    @Published var cliked_like: Bool = false{
        willSet{
            objectWillChange.send()
        }
    }
    
    public var communicator: ElegantCalendarCommunicator?

    public let configuration: CalendarConfiguration
    public let months: [Date]

    var allowsHaptics: Bool = true
    private var isHapticActive: Bool = true

    private var anyCancellable: AnyCancellable?

    public init(configuration: CalendarConfiguration, initialMonth: Date? = nil) {
        self.configuration = configuration

        let months = configuration.calendar.generateDates(
            inside: DateInterval(start: configuration.startDate,
                                 end: configuration.calendar.endOfDay(for: configuration.endDate)),
            matching: .firstDayOfEveryMonth)

        self.months = configuration.ascending ? months : months.reversed()

        var startingPage: Int = 0
        if let initialMonth = initialMonth {
            startingPage = configuration.calendar.monthsBetween(configuration.referenceDate, and: initialMonth)
        }

        currentMonth = months[startingPage]

        listManager = .init(startingPage: startingPage,
                             pageCount: months.count)

        anyCancellable = $delegate.sink {
            $0?.calendar(willDisplayMonth: self.currentMonth)
        }
    }

}

extension MonthlyCalendarManager {

    func configureNewMonth(at page: Int) {
        if months[page] != currentMonth {
            currentMonth = months[page]
            selectedDate = nil

            delegate?.calendar(willDisplayMonth: currentMonth)

            if allowsHaptics && isHapticActive {
                UIImpactFeedbackGenerator.generateSelectionHaptic()
            } else {
                isHapticActive = true
            }
        }
    }
    
    //추가한 것
     func date_loop(from fromDate: Date, to toDate: Date) {
        selections = []
            var date = fromDate
        
            while date <= toDate {
                
                print("선택한 날짜들 포문: \(date)")
                selections.append(date)
                guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
                date = newDate
            }
        print("선택한 날짜들 확인 \(selections)")
        }
    
    //심심기간 삭제 위해 만든 것
    func get_period_for_delete(selected_day: Date){
        print("삭제하려고 선택한 날짜:\(selected_day)")
        print("기간 삭제 위해 만든 메소드 안 기존 selections: \(selections)")

        //비교할 값
        var upper_day = selected_day
        //가장 큰 날짜 값보다 적게 +1 시키기 위함.
        while upper_day <= selections.reversed()[0]{
            print("뒤집은 배열 마지막 값: \(selections.reversed()[0])")
            print("비교하려는 값: \(upper_day)")
            
            if selections.contains(upper_day){
                
                let index = selections.firstIndex(of: upper_day)
                 selections.remove(at: index!)
                print("포함해서 삭제하려는 값: \(upper_day)")
                upper_day = Calendar.current.date(byAdding: .day, value: 1, to: upper_day)!
            }
            //배열에 값이 없을 경우 예외처리 해줘야 index out of range error 발생 안함.
            if selections.isEmpty{
                break
            }
        }
        print("***************큰 날짜 삭제 후 배열: \(selections)")
        var lower_day = selected_day
        
        while lower_day >= selections[0]{
            print("배열중 가장 작은 값: \(selections[0])")
            print("비교하려는 값: \(lower_day)")
            
            if selections.contains(lower_day){
                
                let index = selections.firstIndex(of: lower_day)
                selections.remove(at: index!)
                
                print("포함해서 삭제하려는 값: \(lower_day)")
                lower_day = Calendar.current.date(byAdding: .day, value: -1, to: lower_day)!
                
            }else if !selections.contains(lower_day){
                
                print("선택 날짜 -1")
                lower_day = Calendar.current.date(byAdding: .day, value: -1, to: lower_day)!
            }
            
            if selections.isEmpty{
                break
            }
        }
    print("최종 배열값: \(selections)")
    }

}

extension MonthlyCalendarManager {

    @discardableResult
    public func scrollBackToToday() -> Bool {
        scrollToDay(Date())
    }

    @discardableResult
    public func scrollToDay(_ day: Date, animated: Bool = true) -> Bool {
        let didScrollToMonth = scrollToMonth(day, animated: animated)
        let canSelectDay = datasource?.calendar(canSelectDate: day) ?? true

        if canSelectDay {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.15) {
                self.dayTapped(day: day, withHaptic: !didScrollToMonth)
            }
        }

        return canSelectDay
    }
    
    func selectHearts() {
      // Act on hearts selection.
      print("selectHearts 클릭")
  }

//심심기간 수정하기 - 기간 추가시 editmode와 구분 위해서 boolean값으로 구분할 변수 추가
func selectEditPeriod(day: Date){
    
    print("심심 기간 수정하려는 날짜: \(day)")
    self.edit_boring_period.toggle()
    
  }
  func selectSpades() { print("selectSpades 클릭") }
  func selectDiamonds() { print("selectDiamonds 클릭") }


//여기에서 날짜 한 개를 클릭하면 notify manager가 실행되고
//아래 메소드가 실행됨. 이때 selectedDay에 해당 날짜를 넣음.
//->selectedDay에 값이 있으므로 일정 리스트뷰가 나타남.
    func dayTapped(day: Date, withHaptic: Bool) {
        print("데이탭드 실행, selected date 확인: \(selectedDate)")
        
        if allowsHaptics && withHaptic {
            UIImpactFeedbackGenerator.generateSelectionHaptic()
        }
        

        if self.is_edit_mode || self.edit_boring_period{
            print("편집 모드일 때")
            
            if selectedDate == day {
                print("이미 선택한 날짜와 같았음.")
                selectedDate = nil
                
            } else{
                print("이전에 선택했던 날짜와 다름.")
                let calculate_number = selections.count % 2
                
                if calculate_number == 0{
                
                    print("짝수인 경우")
                    
                }else{
                    print("홀수인 경우")
                    
                }
                if selections.count != 1 {
                        
                        selections = [day]
                        print("셀렉트데이의 selections: \(selections)")
                        
                    } else {
                        print("셀렉트데이의 selections 넣은 것: \(selections)")
                        selections.append(day)
                    }
                
                    selections.sort()
                    print("셀렉트데이의 selections 2: \(selections)")
                    
                    if selections.count == 2 {
                        //dateRangeWrapper?.wrappedValue =
                            //0번째: 시작 날짜, 1번째 마지막 날짜
                          //  selections[0]...selections[1]
                        print("셀렉트데이의 selections3: \(selections)")
                                                    
                        //setSelection(selections[0]...selections[1])
                        //TODO 일단 뺌
                        date_loop(from: selections[0], to: selections[1])

                    } else {
                       // dateRangeWrapper?.wrappedValue = nil
                    }
            }
        }else{
            print("기간 설정 편집모드 아닐 때")
            
            //예외처리 추가한 것.
            //selections배열 갯수가 이미 2개로 선택 완료된 상태에서 또 날짜 한 개를 눌렀을 때
            if selectedDate == day {
                print("이미 선택한 날짜와 같았음.")
                selectedDate = nil

            }
            else{
                print("에딧 모드 아닐 때 케이스 마지막")
                selectedDate = day
                delegate?.calendar(didSelectDay: day)
            }
        }
    }

    @discardableResult
    public func scrollToMonth(_ month: Date, animated: Bool = true) -> Bool {
        isHapticActive = animated

        let needsToScroll = !calendar.isDate(currentMonth, equalTo: month, toGranularities: [.month, .year])

        if needsToScroll {
            let page = calendar.monthsBetween(referenceDate, and: month)
            listManager.scroll(to: page, animated: animated)
        } else {
            isHapticActive = true
        }

        return needsToScroll
    }

}

extension MonthlyCalendarManager {

    static let mock = MonthlyCalendarManager(configuration: .mock)
    static let mockWithInitialMonth = MonthlyCalendarManager(configuration: .mock, initialMonth: .daysFromToday(60))

}

protocol MonthlyCalendarManagerDirectAccess: ConfigurationDirectAccess {

    var calendarManager: MonthlyCalendarManager { get }
    var configuration: CalendarConfiguration { get }

}

extension MonthlyCalendarManagerDirectAccess {

    var configuration: CalendarConfiguration {
        calendarManager.configuration
    }

    var listManager: ElegantListManager {
        calendarManager.listManager
    }

    var months: [Date] {
        calendarManager.months
    }

    var communicator: ElegantCalendarCommunicator? {
        calendarManager.communicator
    }

    var datasource: MonthlyCalendarDataSource? {
        calendarManager.datasource
    }

    var delegate: MonthlyCalendarDelegate? {
        calendarManager.delegate
    }

    var currentMonth: Date {
        calendarManager.currentMonth
    }

    var selectedDate: Date? {
        calendarManager.selectedDate
    }
    //추가
    var selectedDate: Date? {
        calendarManager.selectedDate
    }
    //추가
    var is_edit_mode: Bool {
        calendarManager.is_edit_mode
    }

    func configureNewMonth(at page: Int) {
        calendarManager.configureNewMonth(at: page)
    }

    func scrollBackToToday() {
        calendarManager.scrollBackToToday()
    }

}

private extension Calendar {

    func monthsBetween(_ date1: Date, and date2: Date) -> Int {
        let startOfMonthForDate1 = startOfMonth(for: date1)
        let startOfMonthForDate2 = startOfMonth(for: date2)
        return abs(dateComponents([.month],
                              from: startOfMonthForDate1,
                              to: startOfMonthForDate2).month!)
    }

}
