//
//  ProducesJSONSchema.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//  Updated on 6/26/25.
//

public protocol JSONSchemaGeneratable: Codable, Sendable {}

public protocol ProducesJSONSchema: JSONSchemaGeneratable {
    associatedtype SchemaType: Codable = Self
    static var exampleValue: SchemaType { get }
}

public protocol ProducesUnionJSONSchema: ProducesJSONSchema, CaseIterable where Self.AllCases.Element: JSONSchemaGeneratable { }

public extension ProducesUnionJSONSchema {
    public typealias SchemaType = Self
    public static var exampleValue: SchemaType {
        Self.allCases.first!
    }
}
