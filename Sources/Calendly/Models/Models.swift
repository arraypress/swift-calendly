//
//  Models.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//
//  Shapes verified against the live API on 2026-09-05.
//
//  The organising idea of this API is that EVERYTHING IS ADDRESSED BY URI —
//  a full `https://api.calendly.com/...` URL, never a bare id. Listing your
//  own event types means passing your own user URI as a query parameter, so
//  `/users/me` is a mandatory first call before almost anything else.
//

import Foundation

/// Whoever the token belongs to.
public struct User: Sendable, Codable, Equatable, Identifiable {
    /// The URI. This is the id every other endpoint wants.
    public let uri: String
    public var id: String { uri }
    public let name: String?
    public let slug: String?
    public let email: String?
    /// The public booking page.
    public let schedulingURL: String?
    /// IANA, e.g. `Asia/Bangkok`.
    public let timezone: String?
    /// The organisation URI, needed for org-wide queries.
    public let organization: String?
    public let avatarURL: String?
    public let createdAt: Date?

    private enum CodingKeys: String, CodingKey {
        case uri, name, slug, email, timezone
        case schedulingURL = "scheduling_url"
        case organization = "current_organization"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name)
        self.slug = Decode.string(container, .slug)
        self.email = Decode.string(container, .email)
        self.schedulingURL = Decode.string(container, .schedulingURL)
        self.timezone = Decode.string(container, .timezone)
        self.organization = Decode.string(container, .organization)
        self.avatarURL = Decode.string(container, .avatarURL)
        self.createdAt = Timestamps.parse(Decode.string(container, .createdAt))
    }

    public init(uri: String, name: String?, slug: String? = nil, email: String? = nil,
                schedulingURL: String? = nil, timezone: String? = nil,
                organization: String? = nil, avatarURL: String? = nil, createdAt: Date? = nil) {
        self.uri = uri
        self.name = name
        self.slug = slug
        self.email = email
        self.schedulingURL = schedulingURL
        self.timezone = timezone
        self.organization = organization
        self.avatarURL = avatarURL
        self.createdAt = createdAt
    }
}

/// A kind of meeting people can book.
public struct EventType: Sendable, Codable, Equatable, Identifiable {
    public let uri: String
    public var id: String { uri }
    public let name: String
    public let slug: String?
    /// Minutes.
    public let duration: Int
    public let active: Bool
    /// `solo`, `group`.
    public let kind: String?
    /// The link to send someone.
    public let schedulingURL: String?
    public let description: String?
    public let color: String?
    /// A secret type is not listed on the public booking page.
    public let secret: Bool
    /// Where it happens, as Calendly describes it.
    public let locations: [String]

    private enum CodingKeys: String, CodingKey {
        case uri, name, slug, duration, active, kind, color, secret, locations
        case schedulingURL = "scheduling_url"
        case description = "description_plain"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name) ?? ""
        self.slug = Decode.string(container, .slug)
        self.duration = Decode.int(container, .duration) ?? 0
        self.active = Decode.bool(container, .active) ?? true
        self.kind = Decode.string(container, .kind)
        self.schedulingURL = Decode.string(container, .schedulingURL)
        self.description = Decode.string(container, .description)
        self.color = Decode.string(container, .color)
        self.secret = Decode.bool(container, .secret) ?? false
        // `locations` is null on a type with none, and an array of typed
        // objects otherwise.
        self.locations = (Decode.value([JSONValue].self, container, .locations) ?? [])
            .compactMap { $0["location"]?.string ?? $0["kind"]?.string ?? $0["type"]?.string }
    }

    public init(uri: String, name: String, slug: String? = nil, duration: Int,
                active: Bool = true, kind: String? = nil, schedulingURL: String? = nil,
                description: String? = nil, color: String? = nil,
                secret: Bool = false, locations: [String] = []) {
        self.uri = uri
        self.name = name
        self.slug = slug
        self.duration = duration
        self.active = active
        self.kind = kind
        self.schedulingURL = schedulingURL
        self.description = description
        self.color = color
        self.secret = secret
        self.locations = locations
    }
}

/// A booking.
public struct ScheduledEvent: Sendable, Codable, Equatable, Identifiable {
    public let uri: String
    public var id: String { uri }
    public let name: String?
    /// `active` or `canceled`.
    public let status: String?
    public let startTime: Date?
    public let endTime: Date?
    public let eventType: String?
    public let location: String?
    /// How many have booked, and the cap.
    public let inviteesActive: Int?
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

/// One bookable slot.
public struct Slot: Sendable, Codable, Equatable {
    public let startTime: Date
    /// `available`.
    public let status: String?
    /// The link that books this exact slot.
    public let schedulingURL: String?
    public let inviteesRemaining: Int?

    private enum CodingKeys: String, CodingKey {
        case status
        case startTime = "start_time"
        case schedulingURL = "scheduling_url"
        case inviteesRemaining = "invitees_remaining"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let start = Timestamps.parse(Decode.string(container, .startTime)) else {
            throw CalendlyError.malformed("a slot with no start time")
        }
        self.startTime = start
        self.status = Decode.string(container, .status)
        self.schedulingURL = Decode.string(container, .schedulingURL)
        self.inviteesRemaining = Decode.int(container, .inviteesRemaining)
    }

    public init(startTime: Date, status: String? = "available",
                schedulingURL: String? = nil, inviteesRemaining: Int? = nil) {
        self.startTime = startTime
        self.status = status
        self.schedulingURL = schedulingURL
        self.inviteesRemaining = inviteesRemaining
    }
}

/// A weekly availability pattern.
public struct AvailabilitySchedule: Sendable, Codable, Equatable, Identifiable {
    public let uri: String
    public var id: String { uri }
    public let name: String?
    public let timezone: String?
    /// Whether this is the schedule used by default.
    public let isDefault: Bool
    public let rules: [Rule]

    /// One day's hours.
    public struct Rule: Sendable, Codable, Equatable {
        /// `wday` for a weekday pattern, `date` for a one-off override.
        public let type: String?
        /// `monday`… when `type` is `wday`.
        public let weekday: String?
        /// `yyyy-MM-dd` when `type` is `date`.
        public let date: String?
        /// The open windows. **Empty means a day off** — not missing data.
        public let intervals: [Interval]

        /// Whether anything can be booked on this day.
        public var isAvailable: Bool { !intervals.isEmpty }

        private enum CodingKeys: String, CodingKey { case type, wday, date, intervals }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = Decode.string(container, .type)
            self.weekday = Decode.string(container, .wday)
            self.date = Decode.string(container, .date)
            self.intervals = Decode.value([Interval].self, container, .intervals) ?? []
        }

        public init(type: String?, weekday: String?, date: String? = nil, intervals: [Interval]) {
            self.type = type
            self.weekday = weekday
            self.date = date
            self.intervals = intervals
        }
    }

    /// An open window, local to the schedule's timezone.
    public struct Interval: Sendable, Codable, Equatable {
        /// `09:00`.
        public let from: String
        /// `17:00`.
        public let to: String

        public init(from: String, to: String) {
            self.from = from
            self.to = to
        }
    }

    private enum CodingKeys: String, CodingKey { case uri, name, timezone, rules, `default` }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name)
        self.timezone = Decode.string(container, .timezone)
        self.isDefault = Decode.bool(container, .default) ?? false
        self.rules = Decode.value([Rule].self, container, .rules) ?? []
    }

    public init(uri: String, name: String?, timezone: String? = nil,
                isDefault: Bool = false, rules: [Rule] = []) {
        self.uri = uri
        self.name = name
        self.timezone = timezone
        self.isDefault = isDefault
        self.rules = rules
    }

    /// The days something can actually be booked.
    public var workingDays: [Rule] { rules.filter(\.isAvailable) }
}
