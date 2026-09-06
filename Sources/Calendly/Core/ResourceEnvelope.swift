//
//  ResourceEnvelope.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The two wrappers every Calendly response uses: one resource, or a
/// collection with paging beside it.
struct ResourceEnvelope<Item: Decodable>: Decodable { let resource: Item }
