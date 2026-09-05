//
//  Calendly.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//
//  Calendly on a personal access token, not OAuth.
//
//  A PAT is scoped and made in the web UI in a minute, which is what lets a
//  scheduling tool exist as a CLI. OAuth is only needed when each user
//  connects their own account without pasting anything.
//
//  THE ORGANISING IDEA: everything is addressed by URI — a full
//  `https://api.calendly.com/...` URL, never a bare id — and listing your own
//  event types means passing your own user URI as a query parameter. So
//  `/users/me` is a MANDATORY first call before almost anything else. This
//  client caches it for the lifetime of the instance rather than making every
//  caller thread it through.
//
//  Verified against the live API on 2026-09-05.
//

import Foundation

/// A client for the Calendly API.
public actor Calendly {

    /// How requests are performed — injectable so tests run on recordings.
    public typealias Transport = @Sendable (URLRequest) async throws -> (Data, HTTPURLResponse)

    public static let defaultHost = "api.calendly.com"
    /// The most rows Calendly returns in one page.
    public static let maximumCount = 100

    private let token: String
    private let host: String
    private let transport: Transport
    /// `/users/me`, remembered — every other call needs it.
    private var cachedUser: User?

    /// A client.
    ///
    /// - Parameter token: A personal access token, or an OAuth access token.
    ///   Both are bearer tokens; this does not care which.
    public init(token: String, host: String = Calendly.defaultHost, transport: Transport? = nil) {
        self.token = token
        self.host = host
        self.transport = transport ?? { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw CalendlyError.malformed("not an HTTP response")
            }
            return (data, http)
        }
    }

    // MARK: - Identity

    /// Whoever the token belongs to.
    ///
    /// Fetched once and remembered: it is the prerequisite for nearly every
    /// other call, and re-fetching it per request would double the traffic.
    public func me() async throws -> User {
        if let cachedUser { return cachedUser }
        let data = try await get("/users/me")
        let user = try decodeResource(User.self, from: data)
        cachedUser = user
        return user
    }

    // MARK: - Event types

    /// The kinds of meeting that can be booked.
    ///
    /// - Parameters:
    ///   - user: Whose. Defaults to the token's owner.
    ///   - includeInactive: Turned-off types are hidden by default, because
    ///     the usual question is "what can someone book".
    public func eventTypes(user: String? = nil, includeInactive: Bool = false,
                           limit: Int = 25) async throws -> [EventType] {
        let uri: String
        if let user { uri = user } else { uri = try await me().uri }
        let data = try await get("/event_types", query: [
            "user": uri,
            "count": String(min(max(limit, 1), Calendly.maximumCount)),
        ])
        let all = try decodeCollection(EventType.self, from: data)
        return includeInactive ? all : all.filter(\.active)
    }

    // MARK: - Bookings

    /// Bookings, soonest first.
    ///
    /// - Parameters:
    ///   - status: `active` or `canceled`. Both when nil.
    ///   - from: Only bookings starting at or after this moment.
    public func scheduledEvents(user: String? = nil, status: String? = nil,
                                from: Date? = nil, to: Date? = nil,
                                limit: Int = 25) async throws -> [ScheduledEvent] {
        let uri: String
        if let user { uri = user } else { uri = try await me().uri }
        var query: [String: String] = [
            "user": uri,
            "count": String(min(max(limit, 1), Calendly.maximumCount)),
            "sort": "start_time:asc",
        ]
        if let status { query["status"] = status }
        if let from { query["min_start_time"] = Timestamps.format(from) }
        if let to { query["max_start_time"] = Timestamps.format(to) }

        let data = try await get("/scheduled_events", query: query)
        return try decodeCollection(ScheduledEvent.self, from: data)
    }

    /// Bookings still to come.
    public func upcoming(user: String? = nil, limit: Int = 25) async throws -> [ScheduledEvent] {
        try await scheduledEvents(user: user, status: "active", from: Date(), limit: limit)
    }

    // MARK: - Availability

    /// Open slots for an event type.
    ///
    /// - Parameters:
    ///   - eventType: The type's URI.
    ///   - from: When to start looking. **Must be in the future** — Calendly
    ///     rejects a past start with a bare "The supplied parameters are
    ///     invalid.", which says nothing about the cause. Measured
    ///     2026-09-05; this refuses locally instead, before spending a call.
    ///   - to: When to stop. A fortnight was accepted in testing.
    public func availableTimes(for eventType: String,
                               from: Date = Date().addingTimeInterval(3_600),
                               to: Date? = nil) async throws -> [Slot] {
        guard from > Date() else { throw CalendlyError.startTimeInPast }
        let end = to ?? from.addingTimeInterval(7 * 24 * 3_600)
        guard end > from else {
            throw CalendlyError.invalidParameters("the window ends before it starts")
        }
        let data = try await get("/event_type_available_times", query: [
            "event_type": eventType,
            "start_time": Timestamps.format(from),
            "end_time": Timestamps.format(end),
        ])
        return try decodeCollection(Slot.self, from: data)
    }

    /// The weekly patterns behind those slots.
    public func availabilitySchedules(user: String? = nil) async throws -> [AvailabilitySchedule] {
        let uri: String
        if let user { uri = user } else { uri = try await me().uri }
        let data = try await get("/user_availability_schedules", query: ["user": uri])
        return try decodeCollection(AvailabilitySchedule.self, from: data)
    }

    // MARK: - Booking links

    /// The public page where anything of yours can be booked.
    public func schedulingURL() async throws -> String? {
        try await me().schedulingURL
    }

    // MARK: - Transport

    private func get(_ path: String, query: [String: String] = [:]) async throws -> Data {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        if !query.isEmpty {
            components.queryItems = query
                .map { URLQueryItem(name: $0.key, value: $0.value) }
                .sorted { $0.name < $1.name }
        }
        guard let url = components.url else {
            throw CalendlyError.malformed("could not build a URL for \(path)")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await transport(request)
        switch response.statusCode {
        case 200...299:
            return data
        case 401:
            throw CalendlyError.unauthorized(Calendly.message(in: data) ?? "Calendly rejected the token")
        case 403:
            throw CalendlyError.forbidden(Calendly.message(in: data) ?? "forbidden")
        case 404:
            throw CalendlyError.notFound(path)
        case 429:
            let after = response.value(forHTTPHeaderField: "Retry-After").flatMap { Int(Double($0) ?? 0) }
            throw CalendlyError.rateLimited(retryAfter: after)
        case 400, 422:
            throw CalendlyError.invalidParameters(Calendly.message(in: data) ?? "bad request")
        default:
            throw CalendlyError.http(response.statusCode)
        }
    }

    /// Calendly's own message, which is the only useful part of a 4xx body.
    private static func message(in data: Data) -> String? {
        guard let value = try? JSONDecoder().decode(JSONValue.self, from: data) else { return nil }
        return value["message"]?.string ?? value["title"]?.string
    }

    /// A single resource arrives wrapped in `{"resource": …}`.
    private func decodeResource<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(ResourceEnvelope<T>.self, from: data).resource
        } catch {
            throw CalendlyError.malformed(error.localizedDescription)
        }
    }

    /// A list arrives wrapped in `{"collection": [...], "pagination": {...}}`.
    private func decodeCollection<T: Decodable>(_ type: T.Type, from data: Data) throws -> [T] {
        do {
            return try JSONDecoder().decode(CollectionEnvelope<T>.self, from: data).collection ?? []
        } catch {
            throw CalendlyError.malformed(error.localizedDescription)
        }
    }
}

// MARK: - Envelopes

/// The two wrappers every Calendly response uses: one resource, or a
/// collection with paging beside it.
struct ResourceEnvelope<Item: Decodable>: Decodable { let resource: Item }
struct CollectionEnvelope<Item: Decodable>: Decodable { let collection: [Item]? }
