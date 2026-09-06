//
//  AvailabilitySchedule.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A weekly availability pattern.
public struct AvailabilitySchedule: Sendable, Codable, Equatable, Identifiable {
    /// The URI. Every other endpoint wants this, never a bare id.
    public let uri: String
    /// The URI again, so this is `Identifiable`.
    public var id: String { uri }
    /// What the schedule is called — "Working hours".
    public let name: String?
    /// IANA, e.g. `Asia/Bangkok`. The rules below are in this zone.
    public let timezone: String?
    /// Whether this is the schedule used by default.
    public let isDefault: Bool
    /// One rule per weekday or specific date.
    public let rules: [Rule]

    /// One day's hours.
    public struct Rule: Sendable, Codable, Equatable {
        /// `wday` for a weekday pattern, `date` for a one-off override.
        public let type: String?
        /// `monday`… when `type` is `wday`.
        public let weekday: String?
        /// `yyyy-MM-dd` when `type` is `date`.
        public let date: String?
        /// The open windows. **Empty means a day off** — not missing data.
        public let intervals: [Interval]

        /// Whether anything can be booked on this day.
        public var isAvailable: Bool { !intervals.isEmpty }

        private enum CodingKeys: String, CodingKey { case type, wday, date, intervals }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = Decode.string(container, .type)
            self.weekday = Decode.string(container, .wday)
            self.date = Decode.string(container, .date)
            self.intervals = Decode.value([Interval].self, container, .intervals) ?? []
        }

        public init(type: String?, weekday: String?, date: String? = nil, intervals: [Interval]) {
            self.type = type
            self.weekday = weekday
            self.date = date
            self.intervals = intervals
        }
    }

    /// An open window, local to the schedule's timezone.
    public struct Interval: Sendable, Codable, Equatable {
        /// `09:00`.
        public let from: String
        /// `17:00`.
        public let to: String

        public init(from: String, to: String) {
            self.from = from
            self.to = to
        }
    }

    private enum CodingKeys: String, CodingKey { case uri, name, timezone, rules, `default` }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uri = (try? container.decode(String.self, forKey: .uri)) ?? ""
        self.name = Decode.string(container, .name)
        self.timezone = Decode.string(container, .timezone)
        self.isDefault = Decode.bool(container, .default) ?? false
        self.rules = Decode.value([Rule].self, container, .rules) ?? []
    }

    public init(uri: String, name: String?, timezone: String? = nil,
                isDefault: Bool = false, rules: [Rule] = []) {
        self.uri = uri
        self.name = name
        self.timezone = timezone
        self.isDefault = isDefault
        self.rules = rules
    }

    /// The days something can actually be booked.
    public var workingDays: [Rule] { rules.filter(\.isAvailable) }
}
