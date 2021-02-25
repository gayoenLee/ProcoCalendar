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
                        
                    }){
                        Text( "완료")
                            .font(.callout)
                    }
                    
                //기간 수정 모드일 경우
                }else if calendarManager.edit_boring_period{
                    
                    Button(action: {
                        
                        print("수정 완료 클릭")
                        calendarManager.edit_boring_period = false

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
                
            }
            weeksViewWithDaysOfWeekHeader
        //일정 리스트 뷰 보여주는 것 예외처리 부분
        //selectedDate가 존재하면 정보 리스트뷰를 보여준다.
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
            .foregroundColor(isWithinSameMonthAndYearAsToday ? theme.primary : .primary)
    }

    var yearText: some View {
        Text(month.year)
            .font(.system(size: 12))
            .tracking(2)
            .foregroundColor(isWithinSameMonthAndYearAsToday ? theme.primary : .gray)
            .opacity(0.95)
    }

}

private extension MonthView {

    var weeksViewWithDaysOfWeekHeader: some View {
        VStack(spacing: 32) {
            daysOfWeekHeader
            weeksViewStack
        }
    }

    var daysOfWeekHeader: some View {
        HStack(spacing: CalendarConstants.Monthly.gridSpacing) {
            ForEach(calendar.dayOfWeekInitials, id: \.self) { dayOfWeek in
                Text(dayOfWeek)
                    .font(.caption)
                    .frame(width: CalendarConstants.Monthly.dayWidth)
                    .foregroundColor(.gray)
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
                    Button(action: {
                        print("관심있어요 버튼 클릭")
                        
                    }){
                        Image(systemName: "star")
                            .resizable()
                            .frame(width: UIScreen.main.bounds.width/15, height: UIScreen.main.bounds.width/15)
                            .foregroundColor(Color.yellow)
                        
                    }
                        
                        Button(action: {
                            print("관심있어요 갯수 클릭")
                        }){
                            Text("관심있어요")
                                .font(.footnote)
                        }
                        Spacer()
                }else{
            Button(action: {
                print("좋아요 버튼 클릭")
                
            }){
                Image(systemName: "heart")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width/15, height: UIScreen.main.bounds.width/15)
                    .foregroundColor(Color.red)
                
            }
                
                Button(action: {
                    print("좋아요 갯수 클릭")
                }){
                    Text("좋아요")
                        .font(.footnote)
                }
                Spacer()
                }
            }
           // GeometryReader { geometry in
                //2.23변경.
//                self.datasource?.calendar(viewForSelectedDate: calendarManager.selectedDate!,
//                                          dimensions: UIScreen.main.bounds.size)
            //}
            
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
            .foregroundColor(.gray)
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
