//
//  Member.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Somebody on the organisation.
public struct Member: Sendable, Codable, Equatable, Identifiable {
    /// The URI. Every other endpoint wants this, never a bare id.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// `owner`, `admin`, `user`.
    public let role: String?
    /// The person, when the response embedded them.
    public let user: User?
    /// The URI of the organisation they belong to.
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
