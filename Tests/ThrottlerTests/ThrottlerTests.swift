import XCTest
@testable import Throttler

final class ThrottlerTests: XCTestCase {
    
    func testThrottlerShouldStartImmediately() {
        let interval: TimeInterval = 5.0
        let exp = expectation(description: "exp")
        
        var sum = 0
        let count = 1000
        for i in 0...count {
            // note: shouldStartImmediately is true by default.
            Throttler.throttle(queue: .global(), delay:.seconds(3)) {
                print("throttle executed: sum : \(sum)!")
                
                sum += 1
                print("sum being added!! : \(sum)")
            }
            
            if i == count {
                print("fulfilled: sum : \(sum)!")
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: interval)
        XCTAssertNotEqual(sum, count + 1)
            
        var sum2 = 0
        Throttler.throttle {
            sum2 += 1
            
        }
        XCTAssertNotEqual(sum2, 1)
        
        let exp3 = expectation(description: "exp3")
        var sum3 = 0

        for i in 0...10 {
            Throttler.throttle(delay: .seconds(2.0), shouldRunLatest: true) {
                sum3 = i
                
                if i == 10 {
                    exp3.fulfill()
                }
                
            }
        }

        waitForExpectations(timeout: interval)
        XCTAssertEqual(sum3, 10)
        
        
        let exp4 = expectation(description: "exp4")
        let count4 = 10000
        var sum4 = 0

        for i in 0...count4 {
            Throttler.throttle(delay: .seconds(5.0), shouldRunLatest: false) {
                print("sum4 : \(i)")
                sum4 = i
            }
            
            if i == count4 {
                exp4.fulfill()
            }
        }

        waitForExpectations(timeout: 100.0)
        XCTAssertNotEqual(sum4, count4)
    }
}

// MARK: - Debouncer
extension ThrottlerTests {
    func testDebouncerShouldStartImmediately() {
        let interval: TimeInterval = 10.0
        let exp = expectation(description: "")
        
        var sum = 0
        var sum2 = 0
        
        for i in 0...1000 {
            print("for loop : \(i)")
            
            // note: shouldStartImmediately is true by default.
            Throttler.debounce {
                sum += 1
                print("Debouncer.debounce1 executed: sum : \(sum)!")
            }
            
            Throttler.debounce(queue: .global(), delay:2.0, shouldStartImmediately: false) {
                sum2 += 1
                print("Debouncer.debounce2 executed: sum : \(sum)!")
                
                if sum == 2 && sum2 == 1 {
                    print("fulfilled: sum : \(sum2)!")
                    exp.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: interval)
        XCTAssertEqual(sum, 2)
        XCTAssertEqual(sum2, 1)
    }
}
