// Kevin Li - 7:28 PM - 6/10/20

import SwiftUI

extension Calendar {
    
    var dayOfWeekInitials: [String] {
        
        veryShortWeekdaySymbols
    }
    
}

extension Calendar {

    func endOfDay(for date: Date) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return self.date(byAdding: components, to: startOfDay(for: date))!
    }

    func isDate(_ date1: Date, equalTo date2: Date, toGranularities components: Set<Calendar.Component>) -> Bool {
        components.reduce(into: true) { isEqual, component in
            isEqual = isEqual && isDate(date1, equalTo: date2, toGranularity: component)
        }
    }

    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.month, .year], from: date)
        return self.date(from: components)!
    }

    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components)!
    }
    //일,월,화,수...등 요일 이름 가져오는 메소드.
    func generate_week_name() -> [String]{
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        return calendar.dayOfWeekInitials
    }

}

extension Calendar {

    func generateDates(inside interval: DateInterval,
                       matching components: DateComponents) -> [Date] {
       var dates: [Date] = []
       dates.append(interval.start)

       enumerateDates(
           startingAfter: interval.start,
           matching: components,
           matchingPolicy: .nextTime) { date, _, stop in
           if let date = date {
               if date < interval.end {
                   dates.append(date)
               } else {
                   stop = true
               }
           }
       }

       return dates
    }

}
