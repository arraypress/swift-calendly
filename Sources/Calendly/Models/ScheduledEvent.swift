//
//  ScheduledEvent.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A booking.
public struct ScheduledEvent: Sendable, Codable, Equatable, Identifiable {
    /// The URI. Every other endpoint wants this, never a bare id.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// The event type's name at the time of booking.
    public let name: String?
    /// `active` or `canceled`.
    public let status: String?
    /// When it starts, in UTC.
    public let startTime: Date?
    /// When it ends, in UTC.
    public let endTime: Date?
    /// The URI of the ``EventType`` this was booked from.
    public let eventType: String?
    /// Where it happens, as Calendly describes it — a URL for video calls.
    public let location: String?
    /// How many have booked, and the cap.
    public let inviteesActive: Int?
    /// The cap, for a group event.
    public let inviteesLimit: Int?
    /// Why it was called off, when it was.
    public let cancelReason: String?

    /// Whether the booking still stands.
    public var isActive: Bool { status == "active" }

    private enum CodingKeys: String, CodingKey {
        case uri, name, status, location
        case startTime = "start_time", endTime = "end_time"
        case eventType = "event_type"
        case inviteesCounter = "invitees_counter"
        case cancellation
    }
    private enum CounterKeys: String, CodingKey { case active, limit, total }
    private enum LocationKeys: String, CodingKey { case location, type, join_url }
    private enum CancelKeys: String, CodingKey { case reason }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name)
        self.status = Decode.string(container, .status)
        self.startTime = Timestamps.parse(Decode.string(container, .startTime))
        self.endTime = Timestamps.parse(Decode.string(container, .endTime))
        self.eventType = Decode.string(container, .eventType)

        // Location is an object whose useful field depends on its type: a
        // join URL for a video call, a plain string for an address.
        let place = Decode.nested(container, .location, keyedBy: LocationKeys.self)
        self.location = Decode.string(place, .location)
            ?? Decode.string(place, .join_url)
            ?? Decode.string(place, .type)

        let counter = Decode.nested(container, .inviteesCounter, keyedBy: CounterKeys.self)
        self.inviteesActive = Decode.int(counter, .active)
        self.inviteesLimit = Decode.int(counter, .limit)
        self.cancelReason = Decode.string(
            Decode.nested(container, .cancellation, keyedBy: CancelKeys.self), .reason
        )
    }

    public init(uri: String, name: String?, status: String? = nil,
                startTime: Date? = nil, endTime: Date? = nil, eventType: String? = nil,
                location: String? = nil, inviteesActive: Int? = nil,
                inviteesLimit: Int? = nil, cancelReason: String? = nil) {
        self.uri = uri
        self.name = name
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.eventType = eventType
        self.location = location
        self.inviteesActive = inviteesActive
        self.inviteesLimit = inviteesLimit
        self.cancelReason = cancelReason
    }
}
