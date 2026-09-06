//
//  User.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Whoever the token belongs to.
public struct User: Sendable, Codable, Equatable, Identifiable {
    /// The URI. This is the id every other endpoint wants.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// Their display name.
    public let name: String?
    /// The last path component of their booking page.
    public let slug: String?
    /// The address the account is registered to.
    public let email: String?
    /// The public booking page.
    public let schedulingURL: String?
    /// IANA, e.g. `Asia/Bangkok`.
    public let timezone: String?
    /// The organisation URI, needed for org-wide queries.
    public let organization: String?
    /// Their profile picture, if they set one.
    public let avatarURL: String?
    /// When the account was made.
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
