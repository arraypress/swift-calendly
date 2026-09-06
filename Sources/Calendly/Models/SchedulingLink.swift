//
//  SchedulingLink.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A booking link that can be used a set number of times.
public struct SchedulingLink: Sendable, Codable, Equatable {
    /// The link to send someone.
    public let url: String
    /// What it books.
    public let owner: String?
    /// What the link books — `EventType` is the only value Calendly returns.
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
