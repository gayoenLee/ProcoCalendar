// Kevin Li - 11:30 PM - 6/6/20

import SwiftUI

struct DayView: View, MonthlyCalendarManagerDirectAccess {

    @Environment(\.calendarTheme) var theme: CalendarTheme
    //심심 기간 추가시 사용.
    @Environment(\.editMode) var editMode

    @ObservedObject var calendarManager: MonthlyCalendarManager

    let week: Date
    let day: Date
    //심심기간 삭제시 alert창 띄우기 위함.
    @State private var check_delete_alert: Bool = false
    
    private var isDayWithinDateRange: Bool {
        day >= calendar.startOfDay(for: startDate) && day <= endDate
    }
    //심심기간 선택 -> 선택한 날짜들
    private func is_in_range() ->Bool{

        if calendarManager.selections.count > 0{
            
            //TODO 심심기간 수정시 선택한 날짜 포함돼 있는 연속된 날짜에만 예외처리 해줘야 함
            if calendarManager.selections.contains(day){
                
                return true
            }else{
                print("데이뷰에서 is in rangae")

                return false
            }
        }else{
            return false
        }
    }
    
    private var isDayWithinWeekMonthAndYear: Bool {
        calendar.isDate(week, equalTo: day, toGranularities: [.month, .year])
    }

    private var canSelectDay: Bool {
        datasource?.calendar(canSelectDate: day) ?? true
    }

    private var isDaySelectableAndInRange: Bool {
        isDayWithinDateRange && isDayWithinWeekMonthAndYear && canSelectDay
    }

    private var isDayToday: Bool {
        calendar.isDateInToday(day)
    }

    private var isSelected: Bool {
        guard let selectedDate = calendarManager.selectedDate else { return false }
        print("선택했을 때 is selected안에서 selectedDate값 : \(selectedDate)")
        if calendarManager.is_edit_mode{
            
            if calendarManager.selections.count == 0 {

                return false
            }
            else if calendarManager.selections.count == 1 {
                
            } else {

                let range = calendarManager.selections[0]...calendarManager.selections[1]
                print("데이뷰에서 범위 확인: \(range)")
                print("데이뷰에서 selectedDate 확인: \(selectedDate)")
                return calendar.isDate(selectedDate, equalTo: day, toGranularities: [.day, .month, .year])
            }
        }
        return calendar.isDate(selectedDate, equalTo: day, toGranularities: [.day, .month, .year])
    }

    var body: some View {
        VStack{
            HStack{
        Text(numericDay)
            .font(.footnote)
            .foregroundColor(selected_color)
            .frame(width: selectedDate != nil ? CalendarConstants.Monthly.dayWidth : UIScreen.main.bounds.width/20, height: selectedDate != nil ? CalendarConstants.Monthly.dayWidth : UIScreen.main.bounds.width/20)
            .background(selectedDate != nil ? backgroundColor : nil)
            .clipShape(Rectangle())
            .opacity(opacity)
           // .overlay(isSelected && (editMode != nil) ? CircularSelectionView() : nil)
            .overlay(calendarManager.edit_boring_period == true && is_in_range() || isSelected ? CircularSelectionView() : nil)
            .onTapGesture(perform: notifyManager)
            .contextMenu {
                //TODO 심심기간인지를 구별하기 위한 변수 필요함.
                Button("♥️ - 좋아요", action: calendarManager.selectHearts)
                if is_in_range(){
                    
                    Button(action: {
                        
                        calendarManager.selectEditPeriod(day: day)
                        print("기간 수정 선택한 날짜: \(day)")
                        print("현재 에딧모드 변경됐는지 확인: \(calendarManager.edit_boring_period)")
                    }){
                        Text("♣️ - 심심 기간 수정")
                    }
                    
                    Button(action: {
                        print("기간 삭제하기 클릭: \(day)")
                        self.check_delete_alert.toggle()
                    }){
                        Text("♣️ - 심심기간 삭제")
                    }
                }

                Button("♠️ - 내 일정 추가", action: calendarManager.selectSpades)
                Button("♦️ - 관심있어요", action: calendarManager.selectDiamonds)
                }
                Spacer()
            }
            if selectedDate == nil && is_edit_mode == false {
                
                GeometryReader{geometry in
                    
                    calendarManager.datasource?.calendar(viewForSelectedDate: day, dimensions: geometry.size)
                    }
            }
        }
        .alert(isPresented: self.$check_delete_alert, content: {
            Alert(title: Text("심심기간 삭제"), message: Text("해당 기간을 삭제하시겠습니까?"), primaryButton: Alert.Button.default(Text("확인"), action: {
                //확인 눌렀을 때 삭제
                //TODO 알림창에서 기간 삭제 메소드 구현할 것.
                calendarManager.get_period_for_delete(selected_day: day)
                //후에 통신이 끝났을 때 다시 alert창 띄우기
                
            }), secondaryButton: Alert.Button.default(Text("취소"), action: {
                
            }))
        })
    }

    private var numericDay: String {
        String(calendar.component(.day, from: day))
    }

    private var foregroundColor: Color {
        if isDayToday {
            return theme.primary
        } else {
            return .primary
        }
    }

    private var backgroundColor: some View {
        Group {
            if isDayToday {
                Color.primary
            } else if isDaySelectableAndInRange {
                theme.primary
                    .opacity(datasource?.calendar(backgroundColorOpacityForDate: day) ?? 1)
            } else {
                Color.clear
            }
        }
    }

    private var opacity: Double {
        guard !isDayToday else { return 1 }
        return isDaySelectableAndInRange ? 1 : 0.15
    }

    private func notifyManager() {
        guard isDayWithinDateRange && canSelectDay else { return }

        if isDayToday || isDayWithinWeekMonthAndYear {
            calendarManager.dayTapped(day: day, withHaptic: true)
        }
    }

}

private struct BoringSelectedView: View{
    
    @State private var startBounce = false

    var body: some View{
        
        Rectangle()
            .stroke(Color.primary, lineWidth: 2)
            .frame(width: radius, height: radius)
            .opacity(startBounce ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 150, damping: 10))
            .onAppear(perform: startBounceAnimation)
    }
    
    private var radius: CGFloat {
        startBounce ? CalendarConstants.Monthly.dayWidth + 6 : CalendarConstants.Monthly.dayWidth + 25
    }
    
    private func startBounceAnimation() {
        startBounce = true
    }
}

private struct CircularSelectionView: View {

    @State private var startBounce = false

    var body: some View {
        Circle()
            .stroke(Color.primary, lineWidth: 2)
            .frame(width: radius, height: radius)
            .opacity(startBounce ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 150, damping: 10))
            .onAppear(perform: startBounceAnimation)
    }

    private var radius: CGFloat {
        startBounce ? CalendarConstants.Monthly.dayWidth + 6 : CalendarConstants.Monthly.dayWidth + 25
    }

    private func startBounceAnimation() {
        startBounce = true
    }

}

struct DayView_Previews: PreviewProvider {
    static var previews: some View {
        LightDarkThemePreview {
            DayView(calendarManager: .mock, week: Date(), day: Date())

            DayView(calendarManager: .mock, week: Date(), day: .daysFromToday(3))
        }
    }
}
