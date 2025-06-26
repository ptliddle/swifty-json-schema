//
//  SchemaInfo.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//

public protocol JSONSchemaGeneratable: Codable, Sendable {}

public protocol ProducesJSONSchema: JSONSchemaGeneratable {
    associatedtype SchemaType: Codable = Self
    static var exampleValue: SchemaType { get }
}

public protocol ProducesUnionJSONSchema: JSONSchemaGeneratable, CaseIterable where Self.AllCases.Element: JSONSchemaGeneratable { }

