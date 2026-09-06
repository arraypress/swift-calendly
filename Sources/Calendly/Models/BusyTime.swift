//
//  BusyTime.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A block of time that is already taken.
///
/// The closest Calendly gets to reading a calendar: it includes events from
/// CONNECTED calendars, not just Calendly's own bookings — so this answers
/// "am I actually free" where ``AvailabilitySchedule`` only answers "would I
/// in principle be working".
public struct BusyTime: Sendable, Codable, Equatable {
    /// `calendly` for a booking made here, `external` for one from a
    /// connected Google or Outlook calendar.
    public let type: String?
    /// When the busy period begins, in UTC.
    public let startTime: Date?
    /// When it ends, in UTC.
    public let endTime: Date?
    /// The booking, when this came from Calendly.
    public let event: String?

    private enum CodingKeys: String, CodingKey {
        case type, event
        case startTime = "start_time", endTime = "end_time"
    }
    private enum EventKeys: String, CodingKey { case uri }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = Decode.string(container, .type)
        self.startTime = Timestamps.parse(Decode.string(container, .startTime))
        self.endTime = Timestamps.parse(Decode.string(container, .endTime))
        self.event = Decode.string(Decode.nested(container, .event, keyedBy: EventKeys.self), .uri)
    }

    public init(type: String?, startTime: Date?, endTime: Date?, event: String? = nil) {
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.event = event
    }

    /// Whether the block came from a calendar outside Calendly.
    public var isExternal: Bool { type == "external" }
}
