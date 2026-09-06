//
//  Timestamps.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Timestamp handling.
///
/// Calendly stamps everything in UTC with microsecond precision
/// (`2026-09-05T14:16:45.503059Z`), which the plain ISO 8601 style refuses —
/// it must be parsed as fractional. Measured 2026-09-05.
enum Timestamps {
    private static let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let plain = Date.ISO8601FormatStyle(includingFractionalSeconds: false)

    static func parse(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else { return nil }
        return (try? fractional.parse(text)) ?? (try? plain.parse(text))
    }

    /// The form Calendly's query parameters take.
    static func format(_ date: Date) -> String {
        plain.format(date)
    }
}
