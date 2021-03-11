// Kevin Li - 10:53 PM - 6/6/20

import SwiftUI

struct MonthView: View, MonthlyCalendarManagerDirectAccess {

    @Environment(\.calendarTheme) var theme: CalendarTheme
    @Environment(\.editMode) var editMode

    @ObservedObject var calendarManager: MonthlyCalendarManager

    let month: Date

    private var weeks: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        return calendar.generateDates(
            inside: monthInterval,
            matching: calendar.firstDayOfEveryWeek)
    }

    private var isWithinSameMonthAndYearAsToday: Bool {
        calendar.isDate(month, equalTo: Date(), toGranularities: [.month, .year])
    }

    var body: some View {
        VStack(spacing: 40) {
            HStack{
            monthYearHeader
                .padding(.leading, CalendarConstants.Monthly.outerHorizontalPadding)
                .onTapGesture { self.communicator?.showYearlyView() }
                /*
                 case 1.심심기간 설정
                 - 기간 설정하기: editmode가 true > 완료 editmode가 false
                 case 2.심심기간 수정
                 - 기간 수정하기: edit_boring_period가 true..컨텍스트 메뉴에서 true로 변경 > 완료 edit_boring_period가 false
                 */
                
                //기간 설정 모드일 경우
                if (.active == self.editMode?.wrappedValue){
                    
                    Button(action: {
                        
                        print("완료 버튼 클릭함.")
                        self.editMode?.wrappedValue = .active == self.editMode?.wrappedValue ? .inactive : .active
                        print("전 에딧 모드 값: \(calendarManager.is_edit_mode)")
                        
                        calendarManager.is_edit_mode = false
                    print("후 에딧 모드 값: \(calendarManager.is_edit_mode)")
                    //proco main calendarview에 커스텀한 메소드 실행.
                        //첫번째 값: 심심기간 설정된 날짜 모두, 두번째 값: 
                        delegate?.calendar(didEditBoringPeriod: self.selections, end: true)
                        
                    }){
                        Text( "완료")
                            .font(.callout)
                    }
                //기간 수정 모드일 경우
                }else if calendarManager.edit_boring_period{
                    
                    Button(action: {
                        print("수정 완료 클릭")
                        calendarManager.edit_boring_period = false
                        
                        //proco main calendarview에 커스텀한 메소드 실행.
                            delegate?.calendar(didEditBoringPeriod: self.selections, end: true)
                        
                    }){
                        Text("수정 완료")
                    }
                }else {
                    
                    Button(action: {
                        print("추가하기 버튼 클릭함.")
                        self.editMode?.wrappedValue = .active == self.editMode?.wrappedValue ? .inactive : .active
                    
                            print("전 에딧 모드 값: \(calendarManager.is_edit_mode)")
                            calendarManager.is_edit_mode = true
                        print("후 에딧 모드 값: \(calendarManager.is_edit_mode)")

                    }){
                        Text( "기간 설정하기")
                            .font(.callout)
                    }
                }
            }
            weeksViewWithDaysOfWeekHeader
        //일정 리스트 뷰 보여주는 것 예외처리 부분
        //edit mode가 아니고 selectedDate가 존재하면 정보 리스트뷰를 보여준다.
        if (.inactive == self.editMode?.wrappedValue) && selectedDate != nil{
            
            calenderAccessoryView
                .padding(.leading, CalendarConstants.Monthly.outerHorizontalPadding)
                .id(selectedDate!)
        }
            Spacer()
        }
        .padding(.top, CalendarConstants.Monthly.topPadding)
        .frame(width: CalendarConstants.Monthly.cellWidth, height: CalendarConstants.cellHeight)
    }

}

private extension MonthView {

    var monthYearHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                monthText
                yearText
            }
            Spacer()
        }
    }

    var monthText: some View {
        Text(month.fullMonth.uppercased())
            .font(.system(size: 26))
            .bold()
            .tracking(7)
            .foregroundColor(isWithinSameMonthAndYearAsToday ? Color.black : Color.black)
    }

    var yearText: some View {
        Text(month.year)
            .font(.system(size: 12))
            .tracking(2)
            .foregroundColor(isWithinSameMonthAndYearAsToday ? Color.black : Color.gray)
            .opacity(0.95)
    }

}

private extension MonthView {

    var weeksViewWithDaysOfWeekHeader: some View {
        VStack(spacing: 32) {
            daysOfWeekHeader
            weeksViewStack
        }
        //캘린더가 너무 꽉차 보여서 패딩 추가
        .padding((.leading),UIScreen.main.bounds.width/20)
        .padding((.trailing),UIScreen.main.bounds.width/20)

    }

    var daysOfWeekHeader: some View {
        //이전에 hstack에 (spacing: CalendarConstants.Monthly.gridSpacing)있었음.
        HStack {
            ForEach(calendar.dayOfWeekInitials, id: \.self) { dayOfWeek in
                Text(dayOfWeek)
                    .font(.caption)
                    .frame(width: CalendarConstants.Monthly.dayWidth)
                    .foregroundColor(Color.gray)
            }
        }
    }

    var weeksViewStack: some View {
        VStack(spacing: CalendarConstants.Monthly.gridSpacing) {
            ForEach(weeks, id: \.self) { week in
                WeekView(calendarManager: self.calendarManager, week: week)
            }
        }
    }
}

private extension MonthView {

    var calenderAccessoryView: some View {
        CalendarAccessoryView(calendarManager: calendarManager)
            .onAppear{
                print("상세 페이지뷰 나타남.selectedDate: \(selectedDate)")
            }
            .onDisappear{
                print("상세 페이지뷰 사라짐. selectedDate: \(selectedDate)")
            }
    }
}

private struct CalendarAccessoryView: View, MonthlyCalendarManagerDirectAccess {

    let calendarManager: MonthlyCalendarManager

    @State private var isVisible = false

    private var numberOfDaysFromTodayToSelectedDate: Int {
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfSelectedDate = calendar.startOfDay(for: selectedDate!)
        return calendar.dateComponents([.day], from: startOfToday, to: startOfSelectedDate).day!
    }

    private var isNotYesterdayTodayOrTomorrow: Bool {
        abs(numberOfDaysFromTodayToSelectedDate) > 1
    }

    var body: some View {
        VStack {
            HStack{
            selectedDayInformationView
                Spacer()
                Button(action: {
                   print("내 일정 추가하기 버튼 클릭")
                }){
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width/15, height: UIScreen.main.bounds.width/15)
                        .foregroundColor(Color.orange)
                }
                .padding(.trailing, UIScreen.main.bounds.width/20)
            }
            
            HStack{
                
                if calendarManager.selections.contains(selectedDate!){
                    
                    GeometryReader{geometry in
                        
                        calendarManager.datasource?.calendar(viewForInterest: selectedDate!, dimensions: geometry.size)
                    }
                }else{}
//                else{
//
//            Button(action: {
//                print("좋아요 버튼 클릭")
//            }){
//                Image(systemName: "heart")
//                    .resizable()
//                    .frame(width: UIScreen.main.bounds.width/15, height: UIScreen.main.bounds.width/15)
//                    .foregroundColor(Color.red)
//            }
//                Button(action: {
//                    print("좋아요 갯수 클릭")
//                }){
//                    Text("좋아요")
//                        .font(.footnote)
//                }
//                Spacer()
//                }
            }
            self.datasource?.calendar(viewForScheduleDate: calendarManager.selectedDate!, dimensions: UIScreen.main.bounds.size)
        }
        .onAppear(perform: makeVisible)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5))
    }

    private func makeVisible() {
        isVisible = true
    }

    private var selectedDayInformationView: some View {
        HStack {
            VStack(alignment: .leading) {
                dayOfWeekWithMonthAndDayText
                if isNotYesterdayTodayOrTomorrow {
                    daysFromTodayText
                }
            }
            Spacer()
        }
    }

    private var dayOfWeekWithMonthAndDayText: some View {
        let monthDayText: String
        if numberOfDaysFromTodayToSelectedDate == -1 {
            monthDayText = "어제"
        } else if numberOfDaysFromTodayToSelectedDate == 0 {
            monthDayText = "오늘"
        } else if numberOfDaysFromTodayToSelectedDate == 1 {
            monthDayText = "내일"
        } else {
            monthDayText = selectedDate!.dayOfWeekWithMonthAndDay
        }

        return Text(monthDayText.uppercased())
            .font(.subheadline)
            .bold()
    }

    private var daysFromTodayText: some View {
        let isBeforeToday = numberOfDaysFromTodayToSelectedDate < 0
        let daysDescription = isBeforeToday ? "일 전" : "일 후"

        return Text("\(abs(numberOfDaysFromTodayToSelectedDate)) \(daysDescription)")
            .font(.system(size: 10))
            .foregroundColor(Color.gray)
    }
}

struct MonthView_Previews: PreviewProvider {
    static var previews: some View {
        LightDarkThemePreview {
            MonthView(calendarManager: .mock, month: Date())
            MonthView(calendarManager: .mock, month: .daysFromToday(45))
        }
    }
}
