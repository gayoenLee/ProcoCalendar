// Kevin Li - 5:20 PM - 6/14/20

import Combine
import ElegantPages
import SwiftUI

extension Notification.Name {
    static let calendar_owner_click = Notification.Name("calendar_owner_click")
}
public class MonthlyCalendarManager: ObservableObject, ConfigurationDirectAccess {
    
    @Published public private(set) var currentMonth: Date
    
    @Published public var previous_month: Date? = Date()
    
    //선택한 날짜(클릭한)
    @Published public var selectedDate: Date? = nil{
        didSet{
            objectWillChange.send()
        }
    }
    
    //심심기간 추가 모드일 경우 구분 위해 추가
    @Published public var is_edit_mode: Bool = false{
        didSet{
            objectWillChange.send()
        }
    }
    //마이페이지 이동 구분값
    @Published public var go_mypage: Bool = false{
        didSet{
            objectWillChange.send()
            print("주인 프로필 클릭해서 마이 페이지 이동값 변경됨: \(self.go_mypage)")
            NotificationCenter.default.post(name: Notification.Name.calendar_owner_click, object: nil, userInfo: ["calendar_owner_click" : "ok"])
        }
    }
    
    public let objectWillChange = ObservableObjectPublisher()
    let listManager: ElegantListManager
    
    @Published public var datasource: MonthlyCalendarDataSource?
    @Published public var delegate: MonthlyCalendarDelegate?
    
    //*************선택한 날짜들 담는 곳 기간 선택 때문에 추가한 것.
    @Published public var selections = [Date](){
        willSet{
            objectWillChange.send()
        }
    }
    
    //selections와 구분하기 위해 심심기간을 추가하려 할 때 이곳에 임시로 배열 담아놓는 공간.
    @Published public var temp_selections : [Date] = []{
        didSet{
            objectWillChange.send()
        }
    }
    
    //심심기간 수정시 선택한 날짜가 포함된 기간들을 담아놓기 위한 공간
    @Published public var edit_period : [Date] = []{
        didSet{
            objectWillChange.send()
        }
    }
    
    //***********기간 선택시 선택한 날들을 담을 것. ClosedRange : 시작과 끝 범위가 명확할 때 사용.
    @Published var dateRangeWrapper: ClosedRange<Date>? = nil
    
    //심심기간 수정시 수정모드임을 알릴 수 있는 변수.
    @Published var edit_boring_period: Bool = false{
        didSet{
            objectWillChange.send()
        }
    }
    
    //날짜 칸안의 관심있어요 버튼 뷰를 상세페이지가 나타날 경우 안보이게 하기 위해 구분하는데 사용.
    @Published var date_info_appear : Bool = false{
        didSet{
            objectWillChange.send()
        }
    }
    
    //캘린더 주인 프로필 보여주기 위해 추가
    @Published var owner_idx: Int = -1{
        didSet{
            objectWillChange.send()
        }
    }
    
    @Published var owner_photo_path: String = ""{
        didSet{
            objectWillChange.send()
        }
    }
    @Published var owner_name: String = ""{
        didSet{
            objectWillChange.send()
        }
    }
    @Published var watch_user_idx: Int = -1{
        didSet{
            objectWillChange.send()
        }
    }
    
    public var communicator: ElegantCalendarCommunicator?
    //달력 날짜들 세팅 관련 파일
    public let configuration: CalendarConfiguration
    public let months: [Date]
    
    //진동 이벤트 관련 변수들
    var allowsHaptics: Bool = true
    private var isHapticActive: Bool = true
    
    private var anyCancellable: AnyCancellable?
    
    public init(configuration: CalendarConfiguration, initialMonth: Date? = nil, selections: [Date]? = nil, owner_idx: Int? = nil, owner_photo_path: String? = "", owner_name: String? = "", watch_user_idx: Int? = nil, go_mypage: Bool?, previousMonth: Date) {
        print("순서4. 먼슬리캘린더매니저 init안에 들어온 initialmonth: \(initialMonth), previous month: \(previousMonth)")
        
        self.configuration = configuration
        
        let months = configuration.calendar.generateDates(
            inside: DateInterval(start: configuration.startDate,
                                 end: configuration.calendar.endOfDay(for: configuration.endDate)),
            matching: .firstDayOfEveryMonth)
        
        self.months = configuration.ascending ? months : months.reversed()
        
        //3.02추가
        self.selections = selections ?? [Date()]
        
        var startingPage: Int = 1
        if let initialMonth = initialMonth {
            startingPage = configuration.calendar.monthsBetween(configuration.referenceDate, and: initialMonth)
        }
        //ahems zhemrk ehfaustj init되기 때문에 널일 수도 있고, 초기값을 설정해줘야 함.
        self.owner_idx = owner_idx ?? -1
        self.owner_photo_path = owner_photo_path ?? ""
        self.owner_name = owner_name ?? ""
        self.watch_user_idx = watch_user_idx ?? -1
        
        self.go_mypage = go_mypage ?? false
       
        self.previous_month = previousMonth
        
        currentMonth = months[startingPage]
   
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "LLLL"
       
        listManager = .init(startingPage: startingPage,
                            pageCount: months.count)
        
        //실행됨. 달에 대한 정보
        anyCancellable = $delegate.sink {
            //여기 previousmonth가 오류
            print("delegate sink에서 will display month 실행: \(self.currentMonth),\(self.previous_month) ")
            $0?.calendar(willDisplayMonth: self.currentMonth, previousMonth: previousMonth)
        }
    }
}

extension MonthlyCalendarManager {
    
    //2. direct access에서 메소드 호출하고 이 메소드 다시 불려짐. 새로운 달로 넘어갈 떄 실행돼서 로그 나옴.
    //만약 새로운 달로 스크롤시 새로운 달 정보는 months[page] 이전 달 정보는 currentMonth
    func configureNewMonth(at page: Int) {
        
        print("**********************먼슬리캘린더 매니저에서configure new month 메소드 들어옴.****************************")
        print("순서5. 먼슬리캘린더 매니저에서 컨피규어 메소드 ")
     
//        if months[page] != currentMonth {
//            print("configure new month의 page: \(page), current_month: \(currentMonth) months[page]: \( months[page])")
//
//            previous_month = self.previous_month
//            currentMonth = months[page]
//
//            print("configure new month 이전 달: \(previous_month)")
//            print("configure new month의 currentMonth: \(currentMonth)")
//
//            selectedDate = nil
//            print("셀렉션즈 확인: \(selections)")
//
//            //프로코메인캘린뷰에서 실행됨. 달에 대한 정보
//            delegate?.calendar(willDisplayMonth: currentMonth, previousMonth: previous_month!)
//            print("delegate이후 실행")
//
//            if allowsHaptics && isHapticActive {
//                UIImpactFeedbackGenerator.generateSelectionHaptic()
//            } else {
//                isHapticActive = true
//            }
//
//        }else{
//            print("configure new month else구문: months[page] :\(months[page]), current month: \(currentMonth)")
//        }
        
    }
    
    //날짜를 기간의 시작날짜 - 끝날짜 저장하는 것에서 모든 날짜를 저장하는 것으로 이야기가 돼서 변경하기 위해 추가한 메소드.
    func date_loop(from fromDate: Date, to toDate: Date) {

        var date = fromDate
        
        while date <= toDate {
            
            print("선택한 날짜들 포문: \(date)")
            selections.append(date)
            
            if self.edit_boring_period{
                self.edit_period.append(date)
            }else if self.is_edit_mode{
                self.temp_selections.append(date)
            }
            guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
            date = newDate
        }
        print("선택한 날짜들 확인 selections :  \(selections)")
       // temp_selections = []
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
        var lower_day = Calendar.current.date(byAdding: .day, value: -1, to:selected_day)!
        
        while lower_day >= selections.reversed()[0]{
            print("배열중 가장 작은 값: \(selections[0])")
            print("비교하려는 값: \(lower_day)")
            
            if selections.contains(lower_day){
                
                let index = selections.firstIndex(of: lower_day)
                selections.remove(at: index!)
                
                print("포함해서 삭제하려는 값: \(lower_day)")
                lower_day = Calendar.current.date(byAdding: .day, value: -1, to: lower_day)!
                
            }
            else if !selections.contains(lower_day){

              break
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
        print("먼슬리 캘린더 매니저에서 scrolltoday메소드 안")
        let didScrollToMonth = scrollToMonth(day, animated: animated)
        let canSelectDay = datasource?.calendar(canSelectDate: day) ?? true
        
        if canSelectDay {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.15) {
                self.dayTapped(day: day, withHaptic: !didScrollToMonth)
            }
        }
        return canSelectDay
    }
    //날짜 롱클릭시 컨텍스트 메뉴 중 하나
    func selectHearts() {
        // Act on hearts selection.
        print("selectHearts 클릭")
    }
    
    //심심기간 수정하기 - 기간 추가시 editmode와 구분 위해서 boolean값으로 구분할 변수 추가
    func selectEditPeriod(day: Date){
        
        print("심심 기간 수정하려는 날짜: \(day)")
        
        self.get_period_for_edit(selected_day: day)
        
        self.edit_boring_period.toggle()
        
    }
    func selectSpades() { print("selectSpades 클릭") }
    func selectDiamonds() { print("selectDiamonds 클릭") }
    
    //수정하려는 날짜가 포함된 기간의 날짜들을 구하기 위함.
    func get_period_for_edit(selected_day: Date){
        print("수정하려고 선택한 날짜:\(selected_day)")
        print("기간 수정 위해 만든 메소드 안 기존 selections: \(selections)")
        var temp_selection = selections

        //비교할 값
        var upper_day = selected_day
        //가장 큰 날짜 값보다 적게 +1 시키기 위함.
        while upper_day <= temp_selection.reversed()[0]{
            print("뒤집은 배열 마지막 값: \(temp_selection.reversed()[0])")
            print("비교하려는 값: \(upper_day)")
            
            if temp_selection.contains(upper_day){
                
                let index = temp_selection.firstIndex(of: upper_day)
                temp_selection.remove(at: index!)
                self.edit_period.append(upper_day)
                print("포함해서 수정하려는 값: \(upper_day)")
                upper_day = Calendar.current.date(byAdding: .day, value: 1, to: upper_day)!
            }
            //배열에 값이 없을 경우 예외처리 해줘야 index out of range error 발생 안함.
            if temp_selection.isEmpty{
                break
            }
        }
        print("***************큰 날짜 삭제 후 배열: \(temp_selections)")
        var lower_day = selected_day
        
        while lower_day >= temp_selection.reversed()[0]{
            print("배열중 가장 작은 값: \(temp_selection[0])")
            print("비교하려는 값: \(lower_day)")
            
            if temp_selection.contains(lower_day){
                
                let index = temp_selection.firstIndex(of: lower_day)
                temp_selection.remove(at: index!)
                self.edit_period.append(lower_day)

                print("포함해서 수정하려는 값: \(lower_day)")
                lower_day = Calendar.current.date(byAdding: .day, value: -1, to: lower_day)!
            
            //이 부분 오류 없는지 확인하기
            }else if !temp_selection.contains(lower_day){
                
                print("선택 날짜 -1")
                lower_day = Calendar.current.date(byAdding: .day, value: -1, to: lower_day)!
            }
            
            if temp_selection.isEmpty{
                break
            }
        }
        print("최종 temp_selections 배열값: \(temp_selection)")
        print("최종 edit_period 배열값: \(self.edit_period)")

    }
    
    //여기에서 날짜 한 개를 클릭하면 notify manager가 실행되고
    //아래 메소드가 실행됨. 이때 selectedDay에 해당 날짜를 넣음.
    //->selectedDay에 값이 있으므로 일정 리스트뷰가 나타남.
    func dayTapped(day: Date, withHaptic: Bool) {
        //selectedDate: 이전에 클릭해서 여기에 저장됐던 날짜
        //day: 지금 새로 클릭한 날짜
        print("현재 temp_selections")
        if allowsHaptics && withHaptic {
            UIImpactFeedbackGenerator.generateSelectionHaptic()
        }
        //is_edit_mode : 기간 추가할 때, edit_boring_period: 기간 수정할 때
        if self.is_edit_mode{
            print("day tapped에서 편집 모드일 때")
            
            //이렇게 한 이유: 기간 선택시 시작 날짜와 끝날짜 선택하는데 시작 날짜와 끝날 짜가 달라야 기간 선택이 되므로 이렇게 조건을 걸은 것.
            if selectedDate == day || temp_selections.contains(day){
                print("이미 선택한 날짜와 같거나 이미 심심기간인 날짜 선택함.")
                
                //같은 시작 날짜를 선택했으므로 취소한 것으로 간주하고 초기화시키는 것
                self.get_period_for_delete(selected_day: day)

                selectedDate = nil
                self.temp_selections = []
                
            } else{
                print("day tapped에서 이전에 선택했던 날짜와 다름.: 이전 날짜: \(String(describing: selectedDate)) 지금 선택한 날짜: \(day)")
                //이전에 선택했던 날짜가 없을 경우 temp_selections에 지금 선택한 날짜가 시작 날짜.
                if temp_selections.count != 1 {
                    
                    //temp_selections = []
                    temp_selections = [day]
                    print("셀렉트데이의 temp_selections: \(temp_selections)")
                 //이전에 선택했던 날짜가 있을 경우 temp_selections에 현재 날짜가 마지막 날짜로 넣어짐.
                } else {
                    print("넣으려는 날짜 : \(day)")
                    
                    print("셀렉트데이의 temp_selections 넣은 것: \(temp_selections)")
                    temp_selections.append(day)
                }
                
                temp_selections.sort()
                print("셀렉트데이의 selections 2: \(temp_selections)")
                
                if temp_selections.count == 2 {
                    //dateRangeWrapper?.wrappedValue =
                    //0번째: 시작 날짜, 1번째 마지막 날짜
                    //  selections[0]...selections[1]
                    print("셀렉트데이의 temp_selections3: \(temp_selections)")
                    
                    //setSelection(selections[0]...selections[1])
                    date_loop(from: temp_selections[0], to: temp_selections[1])
                } else {
                    // dateRangeWrapper?.wrappedValue = nil
                }
            }
        }else if self.edit_boring_period{
            print("기간 수정 모드일 때")

            if selectedDate == day || edit_period.contains(day){
                print("이미 선택한 날짜와 같거나 이미 심심기간인 날짜 선택함.")
                //같은 시작 날짜를 선택했으므로 취소한 것으로 간주하고 초기화시키기
               //1. 이전에 선택한 날짜 : selectedDate , 2.편집하려는 기간: edit_period
                self.get_period_for_delete(selected_day: day)
                selectedDate = nil
                //edit_period = [day]
                edit_period = []
            }else{
              print("이전에 선택한 날짜와 다를 때, 이전 날짜: \(selectedDate), 지금 선택한 날짜: \(day)")
                //이미 날짜 두개를 선택하고서 또 다른 날짜를 클릭하면 그 날짜를 시작 날짜로 새롭게 인식.
                if temp_selections.count != 1 {
                    
                    temp_selections = [day]
                    edit_period = []
                    edit_period = [day]
                    print("셀렉트데이의 temp_selections: \(temp_selections)")
                 //이전에 선택했던 날짜가 있을 경우 temp_selections에 현재 날짜가 마지막 날짜로 넣어짐.
                } else {
                    print("넣으려는 날짜 : \(day)")
                    
                    print("셀렉트데이의 temp_selections 넣은 것: \(temp_selections)")
                    temp_selections.append(day)
                    edit_period.append(day)
                }
                
                temp_selections.sort()
                edit_period.sort()
                print("셀렉트데이의 selections 2: \(temp_selections)")
                
                //기간을 선택했으면 selections에서 기존 날짜를 삭제하고 새로운 기간을 집어넣기.
                if temp_selections.count == 2 {
                    //0번째: 시작 날짜, 1번째 마지막 날짜
                    print("셀렉트데이의 temp_selections3: \(temp_selections)")
                    date_loop(from: temp_selections[0], to: temp_selections[1])
                } else {
                    // dateRangeWrapper?.wrappedValue = nil
                }
            }
        }
        else{
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
        print("먼슬리 캘린더 매니저에서 scrollToMonth")
        isHapticActive = animated
        
        let needsToScroll = !calendar.isDate(currentMonth, equalTo: month, toGranularities: [.month, .year])
        
        if needsToScroll {
            print("먼슬리 캘린더 매니저에서 needsToScroll")
            
            let page = calendar.monthsBetween(referenceDate, and: month)
            listManager.scroll(to: page, animated: animated)
        } else {
            print("먼슬리 캘린더 매니저에서 needsToScroll의 else문")
            
            isHapticActive = true
        }
        
        return needsToScroll
    }
    
}

extension MonthlyCalendarManager {
    
//    static let mock = MonthlyCalendarManager(configuration: .mock, go_mypage: false)
//
//    static let mockWithInitialMonth = MonthlyCalendarManager(configuration: .mock, initialMonth: .daysFromToday(60), go_mypage: false)
    
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
    
    var previous_month: Date{
        calendarManager.previous_month!
    }
    
    //추가
    var selectedDate: Date? {
        calendarManager.selectedDate
    }
    //추가
    var is_edit_mode: Bool {
        calendarManager.is_edit_mode
    }
    
    var owner_idx : Int{
        calendarManager.owner_idx
    }
    
    var owner_photo_path: String{
        calendarManager.owner_photo_path
    }
    
    //3.02추가
    //새로운 달로 이동시 selections배열에 새로 값을 넣어주는데 편하게 사용하기 위해 추가
    var selections: [Date] {
        calendarManager.selections
    }
    //프로필 클릭시 마이 페이지 이동 구분값
    var go_mypage: Bool{
        calendarManager.go_mypage
    }
    
    //1.새로운 달로 스크롤 - onpagechanged에서 첫번째로 불려지는 것.
    func configureNewMonth(at page: Int) {

        print("먼슬리 캘린더 매니저에서 configureNewMonth direct access: \(page)")
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
