//
//  Decode.swift
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
