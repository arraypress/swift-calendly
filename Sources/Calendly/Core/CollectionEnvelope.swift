//
//  CollectionEnvelope.swift
//  Calendly
//
//  Created by David Sherlock on 2026.
//

import Foundation

struct CollectionEnvelope<Item: Decodable>: Decodable { let collection: [Item]? }
