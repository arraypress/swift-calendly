//
//  Invitee.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Someone who booked.
public struct Invitee: Sendable, Codable, Equatable, Identifiable {
    /// The URI. Every other endpoint wants this, never a bare id.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// The name they gave when booking.
    public let name: String?
    /// The address they gave when booking.
    public let email: String?
    /// `active` or `canceled`.
    public let status: String?
    /// IANA, e.g. `Asia/Bangkok` — the zone THEY booked in.
    public let timezone: String?
    /// Their answers to the booking form's questions.
    public let answers: [Answer]
    /// The link they can use to move the booking. Rescheduling is THEIR
    /// action, not something the API can do on their behalf.
    public let rescheduleURL: String?
    /// The link they can use to call it off. Also their action, not the API's.
    public let cancelURL: String?
    /// When they booked.
    public let createdAt: Date?

    /// One question and its answer.
    public struct Answer: Sendable, Codable, Equatable {
        /// The question as it appeared on the booking form.
        public let question: String
        /// What they typed.
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
