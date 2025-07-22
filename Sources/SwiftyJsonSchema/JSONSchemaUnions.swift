//
//  JSONSchemaUnions.swift
//  SwiftyJsonSchema
//
//  Created by Peter Liddle on 6/19/25.
//

/// This is used when you have a type that wraps other concrete types that in JSON would be a union. I.e. a role key that can have Admin, User, etc role objects
public protocol JSONSchemaAnyOfDiscriminatedUnion: JSONSchemaGeneratable {
    var allowedTypes: [any ProducesJSONSchema.Type] { get }
}

public protocol JSONSchemaOneOfDiscriminatedUnion: JSONSchemaGeneratable {
    var allowedTypes: [any ProducesJSONSchema.Type] { get }
}
