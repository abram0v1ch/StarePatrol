import XCTest
@testable import StarePatrolCore

final class TimerManagerTests: XCTestCase {
    
    func testInitialState() {
        let manager = TimerManager()
        XCTAssertEqual(manager.timeRemaining, manager.workInterval)
        XCTAssertFalse(manager.isBreaking)
        XCTAssertEqual(manager.timeString, "20:00") // 1200 seconds / 60 = 20
    }
    
    func testResetTimerWhenWorking() {
        let manager = TimerManager()
        manager.timeRemaining = 100 // Simulate time passed
        manager.resetTimer()
        
        XCTAssertEqual(manager.timeRemaining, manager.workInterval)
        XCTAssertFalse(manager.isBreaking)
    }
    
    func testResetTimerWhenBreaking() {
        let manager = TimerManager()
        manager.isBreaking = true
        manager.resetTimer()
        
        XCTAssertEqual(manager.timeRemaining, manager.breakInterval)
        XCTAssertTrue(manager.isBreaking)
    }
    
    func testTimeStringFormatting() {
        let manager = TimerManager()
        manager.timeRemaining = 65
        XCTAssertEqual(manager.timeString, "1:05")
        
        manager.timeRemaining = 59
        XCTAssertEqual(manager.timeString, "59")
    }
}
