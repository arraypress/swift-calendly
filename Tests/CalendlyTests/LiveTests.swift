//
//  LiveTests.swift
//  CalendlyTests
//
//  Created by David Sherlock on 2026.
//
//  Live checks against a real account. Skipped unless CALENDLY_TOKEN is set,
//  so CI and an ordinary `swift test` stay offline.
//
//      CALENDLY_TOKEN=… swift test --filter LiveTests
//
//  READ ONLY. Nothing here creates, cancels or modifies anything.
//

import Foundation
import XCTest
@testable import Calendly

final class LiveTests: XCTestCase {

    private var token: String? { ProcessInfo.processInfo.environment["CALENDLY_TOKEN"] }

    func testTheWholeReadPathAgainstARealAccount() async throws {
        try XCTSkipUnless(token != nil, "set CALENDLY_TOKEN to run")
        let token = token!
        let calendly = Calendly(token: token)

        // 1. Identity — the prerequisite for everything else.
        let user = try await calendly.me()
        XCTAssertTrue(user.uri.hasPrefix("https://api.calendly.com/users/"),
                      "everything is addressed by URI, not by id")
        XCTAssertNotNil(user.schedulingURL)
        XCTAssertNotNil(user.timezone)
        XCTAssertNotNil(user.organization)
        XCTAssertNotNil(user.createdAt, "microsecond timestamps must parse")

        // 2. Event types.
        let types = try await calendly.eventTypes()
        XCTAssertFalse(types.isEmpty, "a new account still has a default 30-minute type")
        let first = try XCTUnwrap(types.first)
        XCTAssertFalse(first.name.isEmpty)
        XCTAssertGreaterThan(first.duration, 0)
        XCTAssertTrue(first.active, "inactive types are filtered out by default")
        XCTAssertTrue(first.uri.hasPrefix("https://api.calendly.com/event_types/"))

        // 3. Availability for that type.
        let slots = try await calendly.availableTimes(for: first.uri)
        XCTAssertFalse(slots.isEmpty, "a default schedule has open weekday slots")
        let slot = try XCTUnwrap(slots.first)
        XCTAssertGreaterThan(slot.startTime, Date(), "an open slot is in the future")
        XCTAssertEqual(slot.status, "available")
        XCTAssertNotNil(slot.schedulingURL, "each slot carries the link that books it")

        // 4. The weekly pattern behind them.
        let schedules = try await calendly.availabilitySchedules()
        XCTAssertFalse(schedules.isEmpty)
        let schedule = try XCTUnwrap(schedules.first)
        XCTAssertEqual(schedule.rules.count, 7, "one rule per weekday")
        XCTAssertFalse(schedule.workingDays.isEmpty, "some days must be bookable")
        XCTAssertLessThan(schedule.workingDays.count, 7,
                          "an empty interval list is a DAY OFF, not missing data")

        // 5. Bookings — a new account has none, and that is not an error.
        let events = try await calendly.scheduledEvents()
        XCTAssertTrue(events.isEmpty || events.allSatisfy { !$0.uri.isEmpty })
    }

    /// Calendly answers a past start with a bare "The supplied parameters are
    /// invalid.", which names no cause. This refuses locally instead.
    func testAPastWindowIsRefusedWithoutSpendingACall() async throws {
        try XCTSkipUnless(token != nil, "set CALENDLY_TOKEN to run")
        let token = token!
        let calendly = Calendly(token: token)
        let types = try await calendly.eventTypes()
        let first = try XCTUnwrap(types.first)

        do {
            _ = try await calendly.availableTimes(for: first.uri,
                                                  from: Date().addingTimeInterval(-86_400))
            XCTFail("a past window must be refused")
        } catch let error as CalendlyError {
            XCTAssertEqual(error, .startTimeInPast)
        }
    }

    func testABadTokenIsUnauthorized() async {
        let calendly = Calendly(token: "not-a-real-token")
        do {
            _ = try await calendly.me()
            XCTFail("that token is not valid")
        } catch let error as CalendlyError {
            guard case .unauthorized = error else { return XCTFail("got \(error)") }
        } catch { XCTFail("unexpected \(error)") }
    }
}
