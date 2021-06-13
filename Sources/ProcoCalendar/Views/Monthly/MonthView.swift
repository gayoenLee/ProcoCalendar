import SwiftUI

struct MonthView: View, MonthlyCalendarManagerDirectAccess {

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
        VStack{
            HStack{
            monthYearHeader
                .padding(.leading, CalendarConstants.Monthly.outerHorizontalPadding*0.5)
//                .padding( .top, CalendarConstants.Monthly.outerHorizontalPadding*6)
                .onTapGesture { self.communicator?.showYearlyView() }
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
        .navigationBarHidden(true)
        .navigationBarTitle("", displayMode: .inline)
        //.padding(.top, CalendarConstants.Monthly.topPadding)
        .frame(width: CalendarConstants.Monthly.cellWidth, height: CalendarConstants.cellHeight)
    }

}

private extension MonthView {

    var monthYearHeader: some View {
        HStack {

                yearText
                monthText
                    .padding(.trailing)
           
            simsim_set_btn
            Spacer()
            if calendarManager.watch_user_idx == calendarManager.owner_idx{
            owner_profile
            }
        }
       // .frame(width: UIScreen.main.bounds.width*0.05)
    }

    var monthText: some View {
        Text(month.fullMonth.uppercased())
            .font(.system(size: 22))
            .bold()
            .tracking(3)
            .foregroundColor(isWithinSameMonthAndYearAsToday ? Color.black : Color.black)
    }

    var yearText: some View {
        Text(month.year)
            .font(.system(size: 22))
            .bold()
            .tracking(4)
            .foregroundColor(isWithinSameMonthAndYearAsToday ? Color.black : Color.black)
    }
    
    var owner_profile: some View{
        //캘린더 주인의 닉네임, 프로필 사진.
        Button(action: {
            
            self.calendarManager.go_mypage = true
            print("캘린더 주인 클릭: \( self.calendarManager.go_mypage)")
        
          
        }){
        HStack{
        Text("\(calendarManager.owner_name)")
            .font(.custom("NanumSquareB", size: 15))
            .foregroundColor(Color.black)
        
        Image(calendarManager.owner_photo_path == "" ? "main_profile_img" : calendarManager.owner_photo_path)
            .resizable()
            .frame(width: 28.93, height: 28.93)
        }
        .padding(.trailing)
        }
    }
    
    var simsim_set_btn: some View{
        HStack{
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
                HStack{
                Image("boring_set_btn")
                .resizable()
                .frame(width: 26.26, height: 28.67)
                
                Image("boring_set_end_btn")
                    .resizable()
                    .frame(width: 35, height:23)
                }
            }
        //기간 수정 모드일 경우
        }else if calendarManager.edit_boring_period{
            
            Button(action: {
                print("수정 완료 클릭")
                calendarManager.edit_boring_period = false
                
                //proco main calendarview에 커스텀한 메소드 실행.
                    delegate?.calendar(didEditBoringPeriod: self.selections, end: true)
                
            }){
                HStack{
                Image("boring_set_btn")
                .resizable()
                .frame(width: 26.26, height: 28.67)
                
                Image("boring_set_end_btn")
                    .resizable()
                    .frame(width: 35, height:23)
                }
            }
        }
        else {
            
            Button(action: {
                print("추가하기 버튼 클릭함.")
                self.editMode?.wrappedValue = .active == self.editMode?.wrappedValue ? .inactive : .active
            
                    print("전 에딧 모드 값: \(calendarManager.is_edit_mode)")
                    calendarManager.is_edit_mode = true
                print("후 에딧 모드 값: \(calendarManager.is_edit_mode)")

            }){
               
                Image("not_boring_set_btn")
                .resizable()
                .frame(width: 26.26, height: 28.67)
            }
        }
    }
    }
}

private extension MonthView {

    var weeksViewWithDaysOfWeekHeader: some View {
       // VStack(spacing: 32){
        VStack{
            daysOfWeekHeader
                //.padding(.trailing, UIScreen.main.bounds.width/10)
      
            weeksViewStack
        }
        //캘린더가 너무 꽉차 보여서 패딩 추가
        //.padding((.leading),UIScreen.main.bounds.width/30)
        .padding(([.trailing]),UIScreen.main.bounds.width/30)

    }

    var daysOfWeekHeader: some View {
        //이전에 hstack에 (spacing: CalendarConstants.Monthly.gridSpacing)있었음.
        HStack {
            ForEach(calendar.generate_week_name(), id: \.self) { dayOfWeek in
        
                Text(dayOfWeek)
                    .font(.custom("NanumSquareB", size: selectedDate != nil ? 13 : 13))
                    .frame(width: selectedDate != nil ? CalendarConstants.Monthly.dayWidth*0.3 : CalendarConstants.Monthly.dayWidth*0.6, height: selectedDate != nil ? CalendarConstants.Monthly.dayWidth*0.8 : CalendarConstants.Monthly.dayWidth*0.8)
                    .foregroundColor(dayOfWeek == "일" ? Color.red.opacity(0.5) : Color.gray)
                    .padding([.leading, .trailing], UIScreen.main.bounds.width/60)
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
                print("상세 페이지뷰 나타남.selectedDate: \(String(describing: selectedDate))")
                calendarManager.date_info_appear = true
            }
            .onDisappear{
              
                    print("상세 페이지뷰 사라짐. selectedDate: \(String(describing: selectedDate))")
                    
                    calendarManager.date_info_appear = false
                
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
            }
            //안한게 이쁨..
//            .background(calendarManager.selections.contains(selectedDate!) ? Color.boring_period_color : nil)
            
            HStack{
                
                if calendarManager.selections.contains(selectedDate!){
                    //심심기간일 경우 관심있어요 버튼 보이게 하는 것.
                   // GeometryReader{geometry in
                        
                    calendarManager.datasource?.calendar(viewForInterest: selectedDate!, dimensions: UIScreen.main.bounds.size)
                   // }
                }
            }
            
            //좋아요 + 일정 리스트 뷰
            self.datasource?.calendar(viewForScheduleDate: calendarManager.selectedDate!, dimensions: UIScreen.main.bounds.size)
                .padding(.top)
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
            monthDayText = "\(selectedDate!.dayOfWeekWithMonthAndDay)일"
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

