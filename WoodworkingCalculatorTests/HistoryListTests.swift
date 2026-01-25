import Testing
import Foundation
@testable import Wood_Calc

extension Date: @retroactive Timestamped {
    public var timestamp: Date { self }
}

@Suite
struct HistoryListTests {
    @Test
    func emptyItems() {
        let result = groupByTimeIntervals(items: [Date]())
        #expect(result.isEmpty)
    }
    
    @Test
    func singleItemToday() throws {
        let now = Date()
        
        let result = groupByTimeIntervals(items: [now])
        
        try #require(result.count == 1)
        #expect(result[0] == (.today, [now]))
    }
    
    @Test
    func itemsOnlyInOldestInterval() throws {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        let veryOld = try #require(calendar.date(byAdding: .day, value: -365, to: midnight))
        
        let items = [
            veryOld,
            try #require(calendar.date(byAdding: .second, value: -1000, to: veryOld))
        ]
        
        let result = groupByTimeIntervals(items: items)
        
        try #require(result.count == 1)
        #expect(result[0] == (.older, items))
    }
    
    @Test
    func itemsAtTodayYesterdayBoundary() throws {
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        
        let item1 = midnight
        let item2 = try #require(calendar.date(byAdding: .second, value: -1, to: midnight))
        
        let result = groupByTimeIntervals(items: [item1, item2])
        
        try #require(result.count == 2)
        #expect(result[0] == (.today, [item1]))
        #expect(result[1] == (.yesterday, [item2]))
    }
    
    @Test
    func allTimeIntervals() throws {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        
        let item1 = now
        let item2 = try #require(calendar.date(byAdding: .minute, value: -30, to: now))
        let item3 = try #require(calendar.date(byAdding: .hour, value: -1, to: midnight))
        let item4 = try #require(calendar.date(byAdding: .day, value: -5, to: midnight))
        let item5 = try #require(calendar.date(byAdding: .day, value: -15, to: midnight))
        let item6 = try #require(calendar.date(byAdding: .day, value: -20, to: midnight))
        let item7 = try #require(calendar.date(byAdding: .day, value: -60, to: midnight))
        
        let result = groupByTimeIntervals(items: [item1, item2, item3, item4, item5, item6, item7])
        
        try #require(result.count == 5)
        #expect(result[0] == (.today, [item1, item2]))
        #expect(result[1] == (.yesterday, [item3]))
        #expect(result[2] == (.pastWeek, [item4]))
        #expect(result[3] == (.pastMonth, [item5, item6]))
        #expect(result[4] == (.older, [item7]))
    }
    
    @Test
    func reversedInputReturnsNonsensicalResult() throws {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        
        let item1 = now
        let item2 = try #require(calendar.date(byAdding: .minute, value: -30, to: now))
        let item3 = try #require(calendar.date(byAdding: .hour, value: -1, to: midnight))
        
        let result = groupByTimeIntervals(items: [item3, item2, item1])
        
        try #require(result.count == 1)
        // Semantically wrong, but we don't guarantee any better!
        #expect(result[0] == (.yesterday, [item3, item2, item1]))
    }
    
    @Test
    func outOfOrderInputReturnsNonsensicalResult() throws {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: now)
        
        let item1 = now
        let item2 = try #require(calendar.date(byAdding: .minute, value: -30, to: now))
        let oldItem = try #require(calendar.date(byAdding: .day, value: -60, to: midnight))
        let item3 = try #require(calendar.date(byAdding: .minute, value: -60, to: now))
        
        let result = groupByTimeIntervals(items: [item1, item2, oldItem, item3])
        
        try #require(result.count == 2)
        #expect(result[0] == (.today, [item1, item2]))
        // Semantically wrong, but we don't guarantee any better!
        #expect(result[1] == (.older, [oldItem, item3]))
    }
}
