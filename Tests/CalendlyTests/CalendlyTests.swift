//
//  CalendlyTests.swift
//  CalendlyTests
//
//  Created by David Sherlock on 2026.
//
//  Offline, on bodies recorded from the live API on 2026-09-05.
//

import Foundation
import XCTest
@testable import Calendly

final class CalendlyTests: XCTestCase {

    private final class Recorder: @unchecked Sendable {
        var requests: [URLRequest] = []
        var bodies: [String]
        let status: Int
        init(_ bodies: [String], status: Int = 200) { self.bodies = bodies; self.status = status }
        var transport: Calendly.Transport {
            { [self] request in
                requests.append(request)
                let body = bodies.count > 1 ? bodies.removeFirst() : (bodies.first ?? "{}")
                let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                               httpVersion: nil, headerFields: [:])!
                return (Data(body.utf8), response)
            }
        }
    }

    /// Trimmed verbatim from a real `/users/me`.
    private let userBody = """
    { "resource": { "uri": "https://api.calendly.com/users/74bcca0b",
      "name": "A Person", "slug": "aperson", "email": "a@example.com",
      "scheduling_url": "https://calendly.com/aperson",
      "timezone": "Asia/Bangkok",
      "current_organization": "https://api.calendly.com/organizations/31a2fde3",
      "created_at": "2026-09-05T14:16:45.503059Z" } }
    """

    // MARK: - Envelopes

    /// One resource is wrapped in `resource`, a list in `collection`.
    func testTheTwoResponseEnvelopesAreBothUnwrapped() async throws {
        let recorder = Recorder([userBody])
        let user = try await Calendly(token: "t", transport: recorder.transport).me()
        XCTAssertEqual(user.name, "A Person")
        XCTAssertEqual(user.timezone, "Asia/Bangkok")

        let types = Recorder([userBody, """
        { "collection": [ { "uri": "https://api.calendly.com/event_types/1",
            "name": "30 Minute Meeting", "slug": "30min", "duration": 30,
            "active": true, "kind": "solo",
            "scheduling_url": "https://calendly.com/aperson/30min" } ],
          "pagination": { "count": 1, "next_page": null } }
        """])
        let found = try await Calendly(token: "t", transport: types.transport).eventTypes()
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.duration, 30)
    }

    /// Calendly stamps to microseconds, which the non-fractional style refuses.
    func testMicrosecondTimestampsParse() {
        XCTAssertNotNil(Timestamps.parse("2026-09-05T14:16:45.503059Z"))
        XCTAssertNotNil(Timestamps.parse("2026-09-05T14:16:45Z"), "and the plain form too")
        XCTAssertNil(Timestamps.parse("not a date"))
        XCTAssertNil(Timestamps.parse(nil))
    }

    // MARK: - URI addressing

    /// Everything is keyed by the user's URI, so `/users/me` must come first.
    func testListingRequiresTheUserURIAndFetchesItOnce() async throws {
        let recorder = Recorder([userBody, #"{"collection":[]}"#, #"{"collection":[]}"#])
        let calendly = Calendly(token: "t", transport: recorder.transport)

        _ = try await calendly.eventTypes()
        _ = try await calendly.eventTypes()

        XCTAssertEqual(recorder.requests.count, 3, "one /users/me, then two listings")
        let listing = try XCTUnwrap(recorder.requests.last?.url?.absoluteString.removingPercentEncoding)
        XCTAssertTrue(listing.contains("user=https://api.calendly.com/users/74bcca0b"),
                      "the query takes a full URI, not a bare id: \(listing)")
        XCTAssertEqual(recorder.requests.filter { $0.url?.path == "/users/me" }.count, 1,
                       "the identity is fetched once and remembered")
    }

    func testAnExplicitUserSkipsTheIdentityCall() async throws {
        let recorder = Recorder([#"{"collection":[]}"#])
        _ = try await Calendly(token: "t", transport: recorder.transport)
            .eventTypes(user: "https://api.calendly.com/users/other")
        XCTAssertEqual(recorder.requests.count, 1, "no /users/me when the URI was given")
    }

    // MARK: - Event types

    func testInactiveTypesAreHiddenUnlessAskedFor() async throws {
        let body = """
        { "collection": [
            { "uri": "u1", "name": "Live", "duration": 30, "active": true },
            { "uri": "u2", "name": "Retired", "duration": 15, "active": false } ] }
        """
        let hidden = Recorder([userBody, body])
        let visible = try await Calendly(token: "t", transport: hidden.transport).eventTypes()
        XCTAssertEqual(visible.map(\.name), ["Live"], "the usual question is what CAN be booked")

        let shown = Recorder([userBody, body])
        let all = try await Calendly(token: "t", transport: shown.transport)
            .eventTypes(includeInactive: true)
        XCTAssertEqual(all.count, 2)
    }

    // MARK: - Availability

    /// A past start gets a bare "parameters are invalid" from Calendly, which
    /// names no cause — so it is refused here, before spending a call.
    func testAPastWindowIsRefusedLocally() async {
        let recorder = Recorder(["{}"])
        do {
            _ = try await Calendly(token: "t", transport: recorder.transport)
                .availableTimes(for: "et", from: Date().addingTimeInterval(-3_600))
            XCTFail("a past window must be refused")
        } catch let error as CalendlyError {
            XCTAssertEqual(error, .startTimeInPast)
        } catch { XCTFail("unexpected \(error)") }
        XCTAssertTrue(recorder.requests.isEmpty, "and without a round trip")
    }

    func testABackwardsWindowIsRefusedToo() async {
        let recorder = Recorder(["{}"])
        let start = Date().addingTimeInterval(7_200)
        do {
            _ = try await Calendly(token: "t", transport: recorder.transport)
                .availableTimes(for: "et", from: start, to: start.addingTimeInterval(-60))
            XCTFail("the window ends before it starts")
        } catch { XCTAssertTrue(recorder.requests.isEmpty) }
    }

    func testASlotCarriesTheLinkThatBooksIt() async throws {
        let recorder = Recorder(["""
        { "collection": [ { "start_time": "2026-09-07T02:00:00Z", "status": "available",
            "invitees_remaining": 1,
            "scheduling_url": "https://calendly.com/aperson/30min/2026-09-07T02:00:00Z" } ] }
        """])
        let slots = try await Calendly(token: "t", transport: recorder.transport)
            .availableTimes(for: "et")

        let slot = try XCTUnwrap(slots.first)
        XCTAssertEqual(slot.status, "available")
        XCTAssertEqual(slot.inviteesRemaining, 1)
        XCTAssertTrue(slot.schedulingURL?.contains("2026-09-07") ?? false,
                      "the link books that exact slot")
    }

    /// An empty interval list is a day off, not missing data.
    func testAnEmptyIntervalListMeansADayOff() throws {
        let schedule = try JSONDecoder().decode(AvailabilitySchedule.self, from: Data("""
        { "uri": "s1", "name": "Working hours", "timezone": "Asia/Bangkok", "default": true,
          "rules": [
            { "type": "wday", "wday": "sunday",  "intervals": [] },
            { "type": "wday", "wday": "monday",  "intervals": [{"from":"09:00","to":"17:00"}] },
            { "type": "wday", "wday": "tuesday", "intervals": [{"from":"09:00","to":"12:00"},
                                                               {"from":"13:00","to":"17:00"}] } ] }
        """.utf8))

        XCTAssertTrue(schedule.isDefault)
        XCTAssertEqual(schedule.rules.count, 3)
        XCTAssertFalse(schedule.rules[0].isAvailable, "Sunday is off")
        XCTAssertTrue(schedule.rules[1].isAvailable)
        XCTAssertEqual(schedule.rules[2].intervals.count, 2, "a lunch break is two windows")
        XCTAssertEqual(schedule.workingDays.map(\.weekday), ["monday", "tuesday"])
    }

    // MARK: - Bookings

    func testABookingFlattensItsLocationAndCounter() throws {
        let event = try JSONDecoder().decode(ScheduledEvent.self, from: Data("""
        { "uri": "e1", "name": "30 Minute Meeting", "status": "active",
          "start_time": "2026-09-10T09:00:00.000000Z",
          "end_time": "2026-09-10T09:30:00.000000Z",
          "event_type": "https://api.calendly.com/event_types/1",
          "location": { "type": "google_conference", "join_url": "https://meet.google.com/abc" },
          "invitees_counter": { "active": 1, "limit": 1, "total": 1 } }
        """.utf8))

        XCTAssertTrue(event.isActive)
        XCTAssertEqual(event.location, "https://meet.google.com/abc",
                       "a video call's useful field is its join URL")
        XCTAssertEqual(event.inviteesActive, 1)
        XCTAssertNotNil(event.startTime)
    }

    func testACancelledBookingKeepsItsReason() throws {
        let event = try JSONDecoder().decode(ScheduledEvent.self, from: Data("""
        { "uri": "e1", "status": "canceled",
          "cancellation": { "reason": "Something came up", "canceled_by": "A Person" } }
        """.utf8))
        XCTAssertFalse(event.isActive)
        XCTAssertEqual(event.cancelReason, "Something came up")
    }

    // MARK: - Failures

    func testEachStatusMapsToItsOwnError() async {
        func expect(_ status: Int, _ body: String, _ check: @escaping (CalendlyError) -> Bool) async {
            let recorder = Recorder([body], status: status)
            do {
                _ = try await Calendly(token: "t", transport: recorder.transport).me()
                XCTFail("HTTP \(status) must not pass")
            } catch let error as CalendlyError {
                XCTAssertTrue(check(error), "HTTP \(status) gave \(error)")
            } catch { XCTFail("unexpected \(error)") }
        }
        await expect(401, #"{"message":"Invalid token"}"#) { if case .unauthorized = $0 { return true }; return false }
        await expect(403, #"{"message":"Missing scope"}"#) { if case .forbidden = $0 { return true }; return false }
        await expect(429, "") { $0 == .rateLimited(retryAfter: nil) }
        await expect(400, #"{"message":"The supplied parameters are invalid."}"#) {
            if case .invalidParameters = $0 { return true }; return false
        }
    }

    func testTheTokenTravelsInAHeaderNotAURL() async throws {
        let recorder = Recorder([userBody])
        _ = try await Calendly(token: "secret-token", transport: recorder.transport).me()

        let request = try XCTUnwrap(recorder.requests.first)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer secret-token")
        XCTAssertFalse(request.url!.absoluteString.contains("secret-token"))
    }
}
