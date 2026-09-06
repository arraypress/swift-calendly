//
//  Cancellation.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The outcome of calling a booking off.
public struct Cancellation: Sendable, Codable, Equatable {
    /// Why it was called off, if a reason was given.
    public let reason: String?
    /// The name of whoever called it off.
    public let cancelledBy: String?
    /// When they did.
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
