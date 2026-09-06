//
//  Slot.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// One bookable slot.
public struct Slot: Sendable, Codable, Equatable {
    /// When the slot begins, in UTC. A slot with no start time is refused at decode.
    public let startTime: Date
    /// `available`.
    public let status: String?
    /// The link that books this exact slot.
    public let schedulingURL: String?
    /// How many more people can still take it, for a group event.
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
