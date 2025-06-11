//
//  SchemaInfo.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//

public protocol ProducesJSONSchema: Codable, Sendable {
    associatedtype SchemaType: Codable = Self
    static var exampleValue: SchemaType { get }
}