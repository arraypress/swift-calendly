//
//  Extended.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//
//  The rest of the surface: who booked, when you are actually busy, who is on
//  the team, and the two things worth writing.
//

import Foundation

/// Someone who booked.
public struct Invitee: Sendable, Codable, Equatable, Identifiable {
    public let uri: String
    public var id: String { uri }
    public let name: String?
    public let email: String?
    /// `active` or `canceled`.
    public let status: String?
    public let timezone: String?
    /// Their answers to the booking form's questions.
    public let answers: [Answer]
    /// The link they can use to move the booking. Rescheduling is THEIR
    /// action, not something the API can do on their behalf.
    public let rescheduleURL: String?
    public let cancelURL: String?
    public let createdAt: Date?

    /// One question and its answer.
    public struct Answer: Sendable, Codable, Equatable {
        public let question: String
        public let answer: String

        private enum CodingKeys: String, CodingKey { case question, answer }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.question = Decode.string(container, .question) ?? ""
            self.answer = Decode.string(container, .answer) ?? ""
        }

        public init(question: String, answer: String) {
            self.question = question
            self.answer = answer
        }
    }

    private enum CodingKeys: String, CodingKey {
        case uri, name, email, status, timezone
        case questionsAndAnswers = "questions_and_answers"
        case rescheduleURL = "reschedule_url"
        case cancelURL = "cancel_url"
        case createdAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name)
        self.email = Decode.string(container, .email)
        self.status = Decode.string(container, .status)
        self.timezone = Decode.string(container, .timezone)
        self.answers = Decode.value([Answer].self, container, .questionsAndAnswers) ?? []
        self.rescheduleURL = Decode.string(container, .rescheduleURL)
        self.cancelURL = Decode.string(container, .cancelURL)
        self.createdAt = Timestamps.parse(Decode.string(container, .createdAt))
    }

    public init(uri: String, name: String?, email: String? = nil, status: String? = nil,
                timezone: String? = nil, answers: [Answer] = [],
                rescheduleURL: String? = nil, cancelURL: String? = nil, createdAt: Date? = nil) {
        self.uri = uri
        self.name = name
        self.email = email
        self.status = status
        self.timezone = timezone
        self.answers = answers
        self.rescheduleURL = rescheduleURL
        self.cancelURL = cancelURL
        self.createdAt = createdAt
    }
}

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
    public let startTime: Date?
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

/// Somebody on the organisation.
public struct Member: Sendable, Codable, Equatable, Identifiable {
    public let uri: String
    public var id: String { uri }
    /// `owner`, `admin`, `user`.
    public let role: String?
    public let user: User?
    public let organization: String?

    private enum CodingKeys: String, CodingKey { case uri, role, user, organization }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.role = Decode.string(container, .role)
        self.user = Decode.value(User.self, container, .user)
        self.organization = Decode.string(container, .organization)
    }

    public init(uri: String, role: String?, user: User? = nil, organization: String? = nil) {
        self.uri = uri
        self.role = role
        self.user = user
        self.organization = organization
    }
}

/// A booking link that can be used a set number of times.
public struct SchedulingLink: Sendable, Codable, Equatable {
    /// The link to send someone.
    public let url: String
    /// What it books.
    public let owner: String?
    public let ownerType: String?

    private enum CodingKeys: String, CodingKey {
        case url = "booking_url"
        case owner
        case ownerType = "owner_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.url = (try? container.decode(String.self, forKey: .url)) ?? ""
        self.owner = Decode.string(container, .owner)
        self.ownerType = Decode.string(container, .ownerType)
    }

    public init(url: String, owner: String? = nil, ownerType: String? = nil) {
        self.url = url
        self.owner = owner
        self.ownerType = ownerType
    }
}

/// The outcome of calling a booking off.
public struct Cancellation: Sendable, Codable, Equatable {
    public let reason: String?
    public let cancelledBy: String?
    public let cancelledAt: Date?

    private enum CodingKeys: String, CodingKey {
        case reason
        case cancelledBy = "canceled_by"
        case cancelledAt = "created_at"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.reason = Decode.string(container, .reason)
        self.cancelledBy = Decode.string(container, .cancelledBy)
        self.cancelledAt = Timestamps.parse(Decode.string(container, .cancelledAt))
    }

    public init(reason: String?, cancelledBy: String? = nil, cancelledAt: Date? = nil) {
        self.reason = reason
        self.cancelledBy = cancelledBy
        self.cancelledAt = cancelledAt
    }
}
