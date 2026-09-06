//
//  CalendlyError.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// What can go wrong talking to Calendly.
public enum CalendlyError: Error, LocalizedError, Sendable, Equatable {
    case unauthorized(String)
    /// The token is valid but lacks the scope for this call.
    case forbidden(String)
    case notFound(String)
    case rateLimited(retryAfter: Int?)
    /// Calendly rejected the parameters. Its own message is carried, because
    /// the API's "The supplied parameters are invalid." says nothing on its
    /// own — see ``Calendly/availableTimes(for:from:to:)`` for the usual cause.
    case invalidParameters(String)
    case http(Int)
    case malformed(String)
    /// A window whose start is in the past, which Calendly always refuses.
    case startTimeInPast

    /// A one-line reason, for a CLI or a log.
    public var errorDescription: String? {
        switch self {
        case .unauthorized(let detail): return detail
        case .forbidden(let detail): return "\(detail) — the token may lack the scope"
        case .notFound(let what): return "no such \(what)"
        case .rateLimited(let after):
            return "Calendly is rate-limiting" + (after.map { " (retry after \($0)s)" } ?? "")
        case .invalidParameters(let why): return "Calendly rejected the request: \(why)"
        case .http(let code): return "Calendly answered HTTP \(code)"
        case .malformed(let what): return "unexpected response shape: \(what)"
        case .startTimeInPast: return "the window must start in the future"
        }
    }
}
