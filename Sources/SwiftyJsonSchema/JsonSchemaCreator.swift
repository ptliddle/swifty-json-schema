//
//  JsonSchemaCreator.swift
//
//
//  Created by Peter Liddle on 9/17/24.
//
import Foundation

enum JSONSchemaError: Error {
    case typeWasNotCodable(String)
    case unrecognizedType
    case doesNotConformToProducesUnionJSONSchema(String)
    case hasNoIterableCases(String)
}

public class JsonSchemaCreator {
        
    @available(*, deprecated, message: "Use JSONSchemaGenerator.generateSchema(from:) instead")
    public static func createJSONSchema<T: Codable>(from type: T.Type, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil ) -> JSONSchema where T: ProducesUnionJSONSchema {
        return (try? JSONSchemaGenerator().generateSchema(from: type)) ?? JSONSchema()
    }
    
    @available(*, deprecated, message: "Use JSONSchemaGenerator.generateSchema(from:) instead")
    public static func createJSONSchema<T: Codable>(from type: T.Type, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil )  -> JSONSchema where T: ProducesJSONSchema {
        return (try? JSONSchemaGenerator().generateSchema(from: type)) ?? JSONSchema()
    }
    
    // Function to convert a Codable object to JSONSchema
    @available(*, deprecated, message: "Use JSONSchemaGenerator.generateSchema(for:) instead")
    public static func createJSONSchema<T: Codable>(for object: T, id: String? = nil, schema: String? = "http://json-schema.org/draft-07/schema#", propertyDescriptions: [String: String]? = nil )  -> JSONSchema {
        return (try? JSONSchemaGenerator().generateSchema(for: object)) ?? JSONSchema()
    }
}
