//
//  EventType.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A kind of meeting people can book.
public struct EventType: Sendable, Codable, Equatable, Identifiable {
    /// The URI. Every other endpoint wants this, never a bare id.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// What the meeting is called on the booking page.
    public let name: String
    /// The last path component of its booking link.
    public let slug: String?
    /// Minutes.
    public let duration: Int
    /// Whether it can currently be booked.
    public let active: Bool
    /// `solo`, `group`.
    public let kind: String?
    /// The link to send someone.
    public let schedulingURL: String?
    /// The blurb shown to whoever is booking, as plain text.
    public let description: String?
    /// The hex colour Calendly shows it in.
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
