//
//  Support.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Flattened, non-throwing reads.
enum Decode {
    static func string<K: CodingKey>(_ container: KeyedDecodingContainer<K>?, _ key: K) -> String? {
        guard let container else { return nil }
        return (try? container.decodeIfPresent(String.self, forKey: key)) ?? nil
    }

    static func int<K: CodingKey>(_ container: KeyedDecodingContainer<K>?, _ key: K) -> Int? {
        guard let container else { return nil }
        return (try? container.decodeIfPresent(Int.self, forKey: key)) ?? nil
    }

    static func bool<K: CodingKey>(_ container: KeyedDecodingContainer<K>?, _ key: K) -> Bool? {
        guard let container else { return nil }
        return (try? container.decodeIfPresent(Bool.self, forKey: key)) ?? nil
    }

    static func value<T: Decodable, K: CodingKey>(
        _ type: T.Type, _ container: KeyedDecodingContainer<K>?, _ key: K
    ) -> T? {
        guard let container else { return nil }
        return (try? container.decodeIfPresent(T.self, forKey: key)) ?? nil
    }

    static func nested<Outer: CodingKey, Inner: CodingKey>(
        _ container: KeyedDecodingContainer<Outer>?, _ key: Outer, keyedBy: Inner.Type
    ) -> KeyedDecodingContainer<Inner>? {
        guard let container else { return nil }
        return try? container.nestedContainer(keyedBy: Inner.self, forKey: key)
    }
}

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
