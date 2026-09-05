//
//  Models+Encoding.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//
//  Canonical encoders. These write the flattened shape — a location as one
//  string where Calendly sends a typed object, an invitee count as two plain
//  numbers where it sends a counter object.
//

import Foundation

extension User {
    private enum OutputKeys: String, CodingKey {
        case uri, name, slug, email, schedulingURL, timezone, organization, avatarURL, createdAt
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(schedulingURL, forKey: .schedulingURL)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        try container.encodeIfPresent(organization, forKey: .organization)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }
}

extension EventType {
    private enum OutputKeys: String, CodingKey {
        case uri, name, slug, duration, active, kind, schedulingURL
        case description, color, secret, locations
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encode(duration, forKey: .duration)
        try container.encode(active, forKey: .active)
        try container.encodeIfPresent(kind, forKey: .kind)
        try container.encodeIfPresent(schedulingURL, forKey: .schedulingURL)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encode(secret, forKey: .secret)
        if !locations.isEmpty { try container.encode(locations, forKey: .locations) }
    }
}

extension ScheduledEvent {
    private enum OutputKeys: String, CodingKey {
        case uri, name, status, startTime, endTime, eventType, location
        case inviteesActive, inviteesLimit, cancelReason, isActive
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encodeIfPresent(eventType, forKey: .eventType)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(inviteesActive, forKey: .inviteesActive)
        try container.encodeIfPresent(inviteesLimit, forKey: .inviteesLimit)
        try container.encodeIfPresent(cancelReason, forKey: .cancelReason)
        try container.encode(isActive, forKey: .isActive)
    }
}

extension Slot {
    private enum OutputKeys: String, CodingKey {
        case startTime, status, schedulingURL, inviteesRemaining
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(schedulingURL, forKey: .schedulingURL)
        try container.encodeIfPresent(inviteesRemaining, forKey: .inviteesRemaining)
    }
}

extension AvailabilitySchedule.Rule {
    private enum OutputKeys: String, CodingKey {
        case type, weekday, date, intervals, isAvailable
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(weekday, forKey: .weekday)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encode(intervals, forKey: .intervals)
        // Stated explicitly: an empty interval list is a DAY OFF, and a
        // consumer should not have to infer that from an absence.
        try container.encode(isAvailable, forKey: .isAvailable)
    }
}

extension AvailabilitySchedule {
    private enum OutputKeys: String, CodingKey { case uri, name, timezone, isDefault, rules }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: OutputKeys.self)
        try container.encode(uri, forKey: .uri)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        try container.encode(isDefault, forKey: .isDefault)
        try container.encode(rules, forKey: .rules)
    }
}
