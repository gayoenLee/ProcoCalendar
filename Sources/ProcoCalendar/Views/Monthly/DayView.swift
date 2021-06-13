import SwiftUI

struct DayView: View, MonthlyCalendarManagerDirectAccess {
    
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
    
    //내 일정이 있을 경우 날짜 한 칸에 이미지로 표시하기 위해 내 일정이 있는지 체크하는 메소드.
    private var my_schedule_exist: Bool{
        datasource?.calendar(myScheduleDate: day) ?? true
    }
    
    //맨 처음에 달력 보여줄 때 심심기간이면 다르게 표시해주기 위해 심심기간인지 아닌지 판별하는 것.
    private func is_in_range() ->Bool{
        //심심기간으로 저장된 날짜와 캘린더 date만들어질 때 예외처리를 하는데
        //이때 심심기간에 속한 날짜의 경우 same_day_array에 저장.
        var same_day_arry  : [Date] = []
        if calendarManager.selections.count > 0{
            
            //TODO 기간 수정시 선택한 날짜 포함돼 있는 연속된 날짜에만 예외처리 해줘야 함
                for selection_day in selections{
                    if calendar.isDate(day, equalTo: selection_day, toGranularity: Calendar.Component.day){
                        same_day_arry.append(selection_day)
                    }
                }
            if same_day_arry.count > 0{
            return true
            }else{
                return false
            }
        }else{
            return false
        }
    }
    
    //심심기간 추가시에 기존에 있던 심심기간 + 추가시에 새로 선택하는 날짜들 표시 x
    //추가하려는 날짜들만 표시하도록 하기 위해 is in range메소드 쓰지 않고 새로 만듬.
    private var is_in_temp_selections: Bool{
        if calendarManager.is_edit_mode{
        print("기간 추가시 temp selections 체크하는 메소드 안")
            
        var same_day_arry  : [Date] = []
        if calendarManager.temp_selections.count > 0{
            
            for selection_day in calendarManager.temp_selections{
                    if calendar.isDate(day, equalTo: selection_day, toGranularity: Calendar.Component.day){
                        same_day_arry.append(selection_day)
                    }
                }
            if same_day_arry.count > 0{
            return true
            }else{
                return false
            }
        }else{
            return false
        }
        }else{
            return false
        }
    }
    //심심기간 수정시 선택한 날짜가 포함된 기간인지 확인하는 메소드
    private var is_in_edit_period: Bool{
        var same_day_arry  : [Date] = []
        if calendarManager.edit_period.count > 0{
            
            for selection_day in calendarManager.edit_period{
                    if calendar.isDate(day, equalTo: selection_day, toGranularity: Calendar.Component.day){
                        same_day_arry.append(selection_day)
                    }
                }
            if same_day_arry.count > 0{
            return true
            }else{
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
        VStack(alignment: .leading){
            HStack{
                Text(numericDay)
                    .font(.custom("NanumSquareB", size: selectedDate != nil ? 13 : 13))
                    
                    .foregroundColor(selected_color)
                    //.background(selectedDate != nil ? Color.gray : nil)
                    .clipShape(Rectangle())
                    .opacity(opacity)
                    //그냥 날짜 한 개 클릭했을 때 나타나는 뷰
                    .overlay( isSelected ? CircularSelectionView() : nil)
                    //기간 수정시 오버레이됨.
                    .overlay(calendarManager.edit_boring_period == true && is_in_edit_period || calendarManager.is_edit_mode == true && is_in_temp_selections ? BoringSelectedView() : nil )
                    //기간 추가할 때 오버레이되는 뷰
//                    .overlay(calendarManager.is_edit_mode == true && is_in_temp_selections ? AddBoringSelectedView() : nil)
                    .onTapGesture(perform: notifyManager)
                    .contextMenu {
                        //TODO 심심기간인지를 구별하기 위한 변수 필요함.
                        Button("♥️ - 좋아요", action: calendarManager.selectHearts)
                        if is_in_range(){
                            
                            Button(action: {
                                
                                //selectEditPeriod: 수정 모드임을 toggle, 수정하려는 선택한 날짜가 포함된 연속된 기간을 구함.
                                calendarManager.selectEditPeriod(day: day)
                                print("기간 수정 선택한 날짜: \(day)")
                                print("현재 에딧모드 변경됐는지 확인: \(calendarManager.edit_boring_period)")
                        
                            }){
                                Text("♣️ - 심심 기간 수정")
                            }
                            Button(action: {
                                //삭제 하시겠습니까 알림 창 한 개 더 띄운 후 삭제하는 통신 진행함. 따라서 여기서는 알림창만 띄움.
                                print("기간 삭제하기 클릭: \(day)")
                                self.check_delete_alert.toggle()
                                
                            }){
                                Text("♣️ - 심심기간 삭제")
                            }
                        }
                        Button("♠️ - 내 일정 추가", action: calendarManager.selectSpades)
                        Button("♦️ - 관심있어요", action: calendarManager.selectDiamonds)
                    }
                //Spacer()
                //내 일정이 등록된 날짜일 경우 보여주는 이미지
                if my_schedule_exist && calendarManager.date_info_appear == false{
                    Image("my_schedule_icon")
                        .resizable()
                        .frame(width: 9.5, height: 8)
                }
            }
            HStack{
            if selectedDate == nil && !is_edit_mode && !is_in_range(){
               // GeometryReader{geometry in
                
                calendarManager.datasource?.calendar(viewForSelectedDate: day, dimensions: UIScreen.main.bounds.size)
               // }
                //.aspectRatio(contentMode: .fill)
            }
            }
            Spacer()
            HStack{
            /*
             심심기간인 경우 나타나는 뷰
                 - 심심기간 수정하는 경우 관심있어요 뷰는 나타나지 않는다.
             */
                if calendarManager.edit_boring_period{
                }else{
                    if is_in_range() && calendarManager.date_info_appear == false{
                    GeometryReader{ geometry in

                        calendarManager.datasource?.calendar(viewForSmallInterest: day, dimensions: geometry.size)
                    }
                   // .aspectRatio(contentMode: .fill)
                 }
                }
            }
        }
        .onTapGesture(perform: notifyManager)
//        .onTapGesture {
//            print("날짜 한 개 클릭; \(numericDay)")
//        }
        .frame(width: selectedDate != nil ? CalendarConstants.Monthly.dayWidth*0.7 : CalendarConstants.Monthly.dayWidth, height: selectedDate != nil ? CalendarConstants.Monthly.dayWidth*0.9 : CalendarConstants.Monthly.dayWidth*1.8)
        .background(is_in_range() ? Color.boring_period_color : nil)
        .alert(isPresented: self.$check_delete_alert, content: {
            Alert(title: Text("심심기간 삭제"), message: Text("해당 기간을 삭제하시겠습니까?"), primaryButton: Alert.Button.default(Text("확인"), action: {
                print("심심 기간 삭제 클릭")
                //확인 눌렀을 때 삭제, 연속된 기간 구함.
                calendarManager.get_period_for_delete(selected_day: day)
                
                //심심기간 생성.수정.삭제 통신 진행.
                calendarManager.delegate?.calendar(didEditBoringPeriod: selections, end: true)
           
            }), secondaryButton: Alert.Button.default(Text("취소"), action: {
                
            }))
        })
    }
    
    private var numericDay: String {
        String(calendar.component(.day, from: day))
    }
    
    private var foregroundColor: Color {
        if isDayToday {
            return Color.blue
        } else {
            return Color.black
            
        }
    }
    
    private var opacity: Double {
        guard !isDayToday else { return 1 }
        return isDaySelectableAndInRange ? 1 : 0.15
    }
    //내가 만든 것
    private var selected_color: Color{
        if calendarManager.edit_boring_period{
           return  is_in_edit_period ? Color.green.opacity(0.3) : Color.gray
        }else{
        return is_in_range() ? Color.green.opacity(0.55) : Color.black
        }
    }
    private func notifyManager() {
        guard isDayWithinDateRange && canSelectDay else { return }
        print("현재 저장된 selections: \(selections)")
        print("노티파이 매니저에서 받은 날짜: \(day)")
        if isDayToday || isDayWithinWeekMonthAndYear {
            calendarManager.dayTapped(day: day, withHaptic: true)
        }
    }
}

private struct BoringSelectedView: View{
    
    @State private var startBounce = false
    
    var body: some View{
        
        Rectangle()
            .stroke(Color.orange, lineWidth: 2)
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

private struct AddBoringSelectedView: View{
    
    @State private var startBounce = false
    
    var body: some View{
        
        Rectangle()
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: radius, height: radius)
            .opacity(startBounce ? 1 : 0)
            .animation(.interpolatingSpring(stiffness: 150, damping: 10))
            .onAppear(perform: startBounceAnimation)
    }
    
    private var radius: CGFloat {
        startBounce ? CalendarConstants.Monthly.dayWidth*0.7: CalendarConstants.Monthly.dayWidth*0.9
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
        startBounce ? CalendarConstants.Monthly.dayWidth : CalendarConstants.Monthly.dayWidth + 25
    }
    
    private func startBounceAnimation() {
        startBounce = true
    }
    
}

