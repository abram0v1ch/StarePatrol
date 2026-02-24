import XCTest
@testable import StarePatrolCore

// MARK: - TimerManager Tests

final class TimerManagerTests: XCTestCase {

    var manager: TimerManager!

    override func setUp() {
        super.setUp()
        manager = TimerManager()
        // Ensure clean slate by resetting to work mode
        manager.pauseTimer()    // stop any auto-started timer
        manager.isBreaking = false
        manager.isPaused = false
        manager.timeRemaining = manager.workInterval
    }

    override func tearDown() {
        manager.pauseTimer()
        manager = nil
        super.tearDown()
    }

    // MARK: Initial State

    func testInitialState_isNotBreaking() {
        XCTAssertFalse(manager.isBreaking)
    }

    func testInitialState_isNotPaused() {
        XCTAssertFalse(manager.isPaused)
    }

    func testInitialState_timeRemainingEqualsWorkInterval() {
        XCTAssertEqual(manager.timeRemaining, manager.workInterval)
    }

    func testInitialState_workIntervalDefault() {
        // Default is 20 minutes = 1200 seconds
        XCTAssertEqual(manager.workInterval, 1200, accuracy: 1)
    }

    func testInitialState_breakIntervalDefault() {
        // Default is 20 seconds
        XCTAssertEqual(manager.breakInterval, 20, accuracy: 1)
    }

    // MARK: timeString

    func testTimeString_twentyMinutes() {
        manager.timeRemaining = 1200
        XCTAssertEqual(manager.timeString, "20:00")
    }

    func testTimeString_oneMinuteFiveSeconds() {
        manager.timeRemaining = 65
        XCTAssertEqual(manager.timeString, "01:05")
    }

    func testTimeString_zeroSeconds() {
        manager.timeRemaining = 0
        XCTAssertEqual(manager.timeString, "00:00")
    }

    func testTimeString_fiftyNineSeconds() {
        manager.timeRemaining = 59
        XCTAssertEqual(manager.timeString, "00:59")
    }

    func testTimeString_over60Minutes() {
        manager.timeRemaining = 3661   // 61 min 1 sec
        XCTAssertEqual(manager.timeString, "61:01")
    }

    // MARK: resetTimer

    func testResetTimer_clearsPaused() {
        manager.isPaused = true
        manager.resetTimer()
        XCTAssertFalse(manager.isPaused)
    }

    func testResetTimer_clearsBreaking() {
        manager.isBreaking = true
        manager.resetTimer()
        XCTAssertFalse(manager.isBreaking)
    }

    func testResetTimer_setsWorkInterval() {
        manager.timeRemaining = 42
        manager.resetTimer()
        XCTAssertEqual(manager.timeRemaining, manager.workInterval)
    }

    func testResetTimer_startsTimer() {
        manager.pauseTimer()
        manager.resetTimer()
        XCTAssertTrue(manager.isTimerRunning)
    }

    // MARK: pauseApp

    func testPauseApp_setsPaused() {
        manager.pauseApp(minutes: 10)
        XCTAssertTrue(manager.isPaused)
    }

    func testPauseApp_clearsBreaking() {
        manager.isBreaking = true
        manager.pauseApp(minutes: 5)
        XCTAssertFalse(manager.isBreaking)
    }

    func testPauseApp_setsTimeRemaining() {
        manager.pauseApp(minutes: 15)
        XCTAssertEqual(manager.timeRemaining, 15 * 60, accuracy: 1)
    }

    func testPauseApp_timerContinuesRunning() {
        // pauseApp starts a countdown timer so the timer IS running
        manager.pauseApp(minutes: 5)
        XCTAssertTrue(manager.isTimerRunning)
    }

    // MARK: pauseIndefinitely

    func testPauseIndefinitely_setsPaused() {
        manager.pauseIndefinitely()
        XCTAssertTrue(manager.isPaused)
    }

    func testPauseIndefinitely_stopsTimer() {
        manager.startTimer()
        manager.pauseIndefinitely()
        XCTAssertFalse(manager.isTimerRunning)
    }

    func testPauseIndefinitely_clearsBreaking() {
        manager.isBreaking = true
        manager.pauseIndefinitely()
        XCTAssertFalse(manager.isBreaking)
    }

    // MARK: resumeTimer

    func testResumeTimer_clearsPaused() {
        manager.isPaused = true
        manager.resumeTimer()
        XCTAssertFalse(manager.isPaused)
    }

    func testResumeTimer_startsTimer() {
        manager.pauseTimer()
        manager.isPaused = true
        manager.resumeTimer()
        XCTAssertTrue(manager.isTimerRunning)
    }

    // MARK: isTimerRunning

    func testIsTimerRunning_falseAfterPauseTimer() {
        manager.startTimer()
        manager.pauseTimer()
        XCTAssertFalse(manager.isTimerRunning)
    }

    func testIsTimerRunning_trueAfterStartTimer() {
        manager.pauseTimer()
        manager.startTimer()
        XCTAssertTrue(manager.isTimerRunning)
    }

    // MARK: skipBreak

    func testSkipBreak_whenNotBreaking_doesNothing() {
        manager.isBreaking = false
        let before = manager.totalBreaksSkipped
        manager.skipBreak()
        XCTAssertEqual(manager.totalBreaksSkipped, before)
    }

    func testSkipBreak_whenBreaking_incrementsSkipped() {
        manager.isBreaking = true
        let before = manager.totalBreaksSkipped
        manager.skipBreak()
        XCTAssertEqual(manager.totalBreaksSkipped, before + 1)
    }

    func testSkipBreak_whenBreaking_clearsBreaking() {
        manager.isBreaking = true
        manager.skipBreak()
        XCTAssertFalse(manager.isBreaking)
    }

    func testSkipBreak_whenBreaking_resetsPaused() {
        manager.isBreaking = true
        manager.isPaused = false
        manager.skipBreak()
        XCTAssertFalse(manager.isPaused)
    }

    // MARK: completeBreak

    func testCompleteBreak_whenNotBreaking_doesNothing() {
        manager.isBreaking = false
        let before = manager.totalBreaksTaken
        manager.completeBreak()
        XCTAssertEqual(manager.totalBreaksTaken, before)
    }

    func testCompleteBreak_whenBreaking_incrementsTaken() {
        manager.isBreaking = true
        let before = manager.totalBreaksTaken
        manager.completeBreak()
        XCTAssertEqual(manager.totalBreaksTaken, before + 1)
    }

    func testCompleteBreak_whenBreaking_clearsBreaking() {
        manager.isBreaking = true
        manager.completeBreak()
        XCTAssertFalse(manager.isBreaking)
    }

    // MARK: tick – auto-expiry counts as a break taken (regression test)

    func testTick_breakExpiry_incrementsTaken() {
        // Put manager into break mode with 1 second remaining
        manager.isBreaking = true
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        let before = manager.totalBreaksTaken

        // First tick: decrements timeRemaining to 0
        manager.tick()
        // Second tick: timeRemaining == 0, fires break→work transition
        manager.tick()

        XCTAssertEqual(manager.totalBreaksTaken, before + 1,
            "Auto-expired break should increment totalBreaksTaken")
    }

    // MARK: Injectable closure hooks

    func testTick_workToBreak_callsOnShowReminder() {
        UserDefaults.standard.set("fullscreen", forKey: "notificationMode")
        var showCalled = false
        manager.onShowReminder = { _ in showCalled = true }
        // Simulate work expiry → break starts
        manager.isBreaking = false
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick() // → 0
        manager.tick() // transition: work → break
        XCTAssertTrue(showCalled, "onShowReminder must be called when break starts")
    }

    func testTick_breakToWork_callsOnHideReminder() {
        var hideCalled = false
        manager.onHideReminder = { hideCalled = true }
        manager.isBreaking = true
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick() // → 0
        manager.tick() // transition: break → work
        XCTAssertTrue(hideCalled, "onHideReminder must be called when break ends")
    }

    func testTick_workToBreak_callsOnHaptic() {
        var hapticCalled = false
        manager.onHaptic = { hapticCalled = true }
        manager.isBreaking = false
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick()
        manager.tick()
        XCTAssertTrue(hapticCalled, "onHaptic must be called on work→break transition")
    }

    func testTick_breakToWork_callsOnHaptic() {
        var hapticCalled = false
        manager.onHaptic = { hapticCalled = true }
        manager.isBreaking = true
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick()
        manager.tick()
        XCTAssertTrue(hapticCalled, "onHaptic must be called on break→work transition")
    }

    func testTick_workToBreak_callsOnPlaySound_whenEnabled() {
        UserDefaults.standard.set(true, forKey: "breakStartSoundEnabled")
        var playedSound: String?
        manager.onPlaySound = { name in playedSound = name }
        manager.isBreaking = false
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick()
        manager.tick()
        XCTAssertNotNil(playedSound, "onPlaySound must be called for break-start sound")
    }

    func testTick_breakToWork_callsOnPlaySound_whenEnabled() {
        UserDefaults.standard.set(true, forKey: "breakEndSoundEnabled")
        var playedSound: String?
        manager.onPlaySound = { name in playedSound = name }
        manager.isBreaking = true
        manager.timeRemaining = 1
        manager.isAppEnabled = true
        manager.tick()
        manager.tick()
        XCTAssertNotNil(playedSound, "onPlaySound must be called for break-end sound")
    }

    func testSkipBreak_callsOnHapticAndHideReminder() {
        var hapticCalled = false
        var hideCalled = false
        manager.onHaptic       = { hapticCalled = true }
        manager.onHideReminder = { hideCalled = true }
        manager.isBreaking = true
        manager.skipBreak()
        XCTAssertTrue(hapticCalled, "onHaptic must fire when skipping a break")
        XCTAssertTrue(hideCalled,   "onHideReminder must fire when skipping a break")
    }

    func testCompleteBreak_callsOnHapticAndHideReminder() {
        var hapticCalled = false
        var hideCalled = false
        manager.onHaptic       = { hapticCalled = true }
        manager.onHideReminder = { hideCalled = true }
        manager.isBreaking = true
        manager.completeBreak()
        XCTAssertTrue(hapticCalled, "onHaptic must fire when completing a break")
        XCTAssertTrue(hideCalled,   "onHideReminder must fire when completing a break")
    }
}


// MARK: - PauseUtils Tests

final class PauseUtilsTests: XCTestCase {

    // MARK: pauseSnapValues

    func testSnapValues_count() {
        XCTAssertEqual(pauseSnapValues.count, 13)
    }

    func testSnapValues_firstIsOne() {
        XCTAssertEqual(pauseSnapValues.first, 1)
    }

    func testSnapValues_lastIsInfinite() {
        XCTAssertEqual(pauseSnapValues.last, 9999)
    }

    func testSnapValues_contains2h() {
        XCTAssertTrue(pauseSnapValues.contains(120))
    }

    func testSnapValues_contains1h() {
        XCTAssertTrue(pauseSnapValues.contains(60))
    }

    func testSnapValues_isAscending() {
        for i in 0..<(pauseSnapValues.count - 1) {
            XCTAssertLessThan(pauseSnapValues[i], pauseSnapValues[i + 1])
        }
    }

    func testSnapValues_defaultIndexInBounds() {
        let idx = Int(defaultPauseIndex)
        XCTAssertTrue(idx >= 0 && idx < pauseSnapValues.count)
    }

    // MARK: formatPause

    func testFormatPause_infinity() {
        XCTAssertEqual(formatPause(9999), "∞")
    }

    func testFormatPause_overInfinityThreshold() {
        XCTAssertEqual(formatPause(10000), "∞")
    }

    func testFormatPause_oneMinute() {
        XCTAssertEqual(formatPause(1), "1m")
    }

    func testFormatPause_fifteenMinutes() {
        XCTAssertEqual(formatPause(15), "15m")
    }

    func testFormatPause_fiftyNineMinutes() {
        XCTAssertEqual(formatPause(59), "59m")
    }

    func testFormatPause_sixtyMinutes() {
        XCTAssertEqual(formatPause(60), "1h")
    }

    func testFormatPause_ninetyMinutes() {
        XCTAssertEqual(formatPause(90), "1h 30m")
    }

    func testFormatPause_twoHours() {
        XCTAssertEqual(formatPause(120), "2h")
    }

    func testFormatPause_twoHoursThirtyMinutes() {
        XCTAssertEqual(formatPause(150), "2h 30m")
    }

    // MARK: snapPause

    func testSnapPause_exactMatch() {
        XCTAssertEqual(snapPause(15), 15)
    }

    func testSnapPause_roundsDown() {
        // 6 is closer to 5 (diff=1) than to 10 (diff=4)
        XCTAssertEqual(snapPause(6), 5)
    }

    func testSnapPause_roundsUp() {
        // 9 is closer to 10 (diff=1) than to 5 (diff=4)
        XCTAssertEqual(snapPause(9), 10)
    }

    func testSnapPause_belowMinimum() {
        // 0 is closest to 1
        XCTAssertEqual(snapPause(0), 1)
    }

    func testSnapPause_aboveMaximum() {
        // Very large number snaps to 9999
        XCTAssertEqual(snapPause(99999), 9999)
    }

    func testSnapPause_midpointFavorsNearest() {
        // 37.5 between 30 and 45: diff=7.5 each → both tied, min(by:) picks first = 30
        XCTAssertEqual(snapPause(37), 30)   // 37 closer to 30
        XCTAssertEqual(snapPause(38), 45)   // 38 closer to 45
    }
}
