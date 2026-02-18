//
//  JSONSchemaGenerator.swift
//
//
//  Created on 6/26/25.
//

import Foundation

public enum JSONSchemaGenerationError: Error {
    case notACodableType(String)
    case notCaseIterableEnum(String)
    case notCaseIterableOrCodable(String)
    case noEnumCases
    case unknownBaseType
    case invalidCollection(String)
    case invalidOptional(String)
    case noExampleItemForArray(String)
    case noExampleItemForDictionary(String)
}

public struct Path: CustomStringConvertible {
    
    static let Root = Self.init(pathComps: [])
    
    private let pathComps: [String]
    
    private init(pathComps: [String]) {
        self.pathComps = pathComps
    }
    
    public func appending(path: String) -> Self {
        let newPath = self.pathComps + [path]
        return Self.init(pathComps: newPath)
    }
    
    public var description: String {
        return pathComps.joined(separator: ".")
    }
}

/// A class that generates JSON Schema from Swift Codable types
public class JSONSchemaGenerator {
    
    /// Configuration options for JSON Schema generation
    public struct Configuration {
        
        public static let defaultJsonSchemaVersion = "http://json-schema.org/draft-07/schema#"
        
        /// The JSON Schema version to use
        public let schemaVersion: String
        
        /// The schema ID to use
        public let schemaId: String?
        
        /// Whether to include descriptions from property wrappers
        public let includeDescriptions: Bool
        
        /// Initialize with default values
        public init(schemaVersion: String = Self.defaultJsonSchemaVersion, schemaId: String? = nil, includeDescriptions: Bool = true) {
            self.schemaVersion = schemaVersion
            self.schemaId = schemaId
            self.includeDescriptions = includeDescriptions
        }
    }
    
    /// The configuration for this generator
    private let configuration: Configuration
    
    private lazy var baseSchema: JSONSchema = {
        return JSONSchema(id: configuration.schemaId, schema: configuration.schemaVersion, type: .object)
    }()
    
    /// Initialize with the given configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    func handleEnums<E>(enumObject: E, path: Path) throws -> JSONSchema where E: CaseIterable, E: Codable {
        
        var schemaDescriptions: [String: String]?
        
        // Check json schema descriptions
        if let EX = E.self as? HasCustomJSONSchemaDescriptions.Type {
            schemaDescriptions = EX.schemaDescriptions
        }
        
        func getRawValueType<T: RawRepresentable>(for enumType: T.Type) -> String {
            return "\(T.RawValue.self)"
        }
            
        var schema = JSONSchema()
        
        // get all the types
        var basicEnums = [E]()
        var associatedTypeEnums = [E]()
        
        E.allCases.forEach { enumObj in
            
            let mirror = Mirror(reflecting: enumObj)
            if mirror.children.isEmpty {
                basicEnums.append(enumObj)
            }
            else {
                associatedTypeEnums.append(enumObj)
            }
        }
        
        if !basicEnums.isEmpty {
            // There are 2 types of basic enums those that are `default` and RawRepresentables. Defaults are always strings in jsonschema
            var schemaType: JSONSchemaType = try {
                
                if let rawEnumObject = enumObject as? (any RawRepresentable & Codable) {
                    let type = type(of: rawEnumObject)
                    let rawTypeString = getRawValueType(for: type)
                    let jsonType = try JSONSchemaType(withRawEnumType: rawTypeString)
                    return jsonType
                }
                else {
                    return .string
                }
            }()
                
            let caseLabels = E.allCases.compactMap({ enumObject in
                if let rawEnumObject = enumObject as? (any RawRepresentable & Codable) {
                    return Value(from: rawEnumObject.rawValue as? Codable)
                } 
                else {
                    // For non-RawRepresentable enums, use the string representation
                    return Value.string("\(enumObject)")
                }
            })
            
            schema.enumValues = caseLabels
            schema.type = schemaType
        }
        
        
        if !associatedTypeEnums.isEmpty {
            let allSchemas = try associatedTypeEnums.map { caseValue in
                let label = "\(caseValue.self)"
                
                var schema = try _generateSchema(for: caseValue, bypassEnumDetection: true, path: path)
                
                schema.id = label
                return schema
            }
            
            schema.type = .object
            schema.oneOf = allSchemas
        }
        
        return schema
    }
   
    
    /// Generate a JSON Schema for the given Codable object
    /// - Parameters:
    ///   - object: The object to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T>(for object: T) throws -> JSONSchema where T: Codable {
        // Create a base schema with the configuration values
        let schema = JSONSchema(id: configuration.schemaId, schema: configuration.schemaVersion, type: .object)
        return try _generateSchema(for: object, schema: baseSchema, path: .Root.appending(path: "\(T.self)"))
    }
    
    public func generateSchema<T>(for object: T) throws -> JSONSchema where T: CaseIterable {
        // Create a base schema with the configuration values
        return try _generateSchema(for: object, schema: baseSchema, path: Path.Root)
    }
    
    // Helper function
    private func isEnum(_ value: Any, mirror: Mirror) -> Bool {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .enum {
            return true
        }
        
        // Additional checks for RawRepresentable, etc.
        return value is (any CaseIterable & Codable)
    }
     
    // bypassEnumDetection is mainly used when calling from handleEnum to deal with associatedTypes so we don't end up in a loop
    private func _generateSchema<T>(for object: T, schema: JSONSchema? = nil, bypassEnumDetection: Bool = false, path: Path) throws -> JSONSchema where T: Any {
        
        // Handle decorated types first. We unwrap them and send them on
        if let metadataSchema = object as? (any BaseJSONSchemaMetadataProtocol) {
            // Extract out wrappedValue
            var schema = try _generateSchema(for: metadataSchema.subjectValue, path: path)
            schema.description = metadataSchema.schemaDescription
            schema.additionalProperties = metadataSchema.additionalProperties
            return schema
        }
        

        
        // Create dictionaries to store properties and required fields
        var properties: [String: JSONSchema] = [:]
        var required: [String] = []
        
        // Use Mirror to reflect on the object's properties
        let mirror = Mirror(reflecting: object)
        let typeHint = mirror.displayStyle
        
        // First things first, check if it's a primitive type and we can handle based on the information we already have without needing reflection and return schema
        if var schema = try generateSchemaForBaseTypes(object, typeHint: typeHint, path: path) {
            // Check for type level metdata
            if let metadata = object as? GeneratesJSONSchemaMetadata {
                schema.additionalProperties = metadata.additionalProperties
                schema.description = metadata.schemaDescription
            }
            
            return schema // We have a base type so return it
        }
        
        //MARK: - Advanced types
        // When we get here we're dealing with complex types, either structs, classes, etc or special types like enums or Decorated types
        
        //Check if it's an enum. Enum's need special handling
        if isEnum(object) && !bypassEnumDetection {
            guard let enumObject = object as? (any CaseIterable & Codable) else {
                throw JSONSchemaGenerationError.notCaseIterableEnum("For \(object.self), it needs to conform to CaseIterable")
            }
            let enumSchema = try handleEnums(enumObject: enumObject, path: path)
            return enumSchema
        }

        
        // First we check if we're at the base, i.e. a basic type. It should have no children
        // Dictionaries and Arrays are considered base types
        guard !mirror.children.isEmpty else {
            
            // If we got here it's not a Primitive or Foundation type, but it has no children, theres only a few edge cases that meet that so let's deal with them
            
            // empty classes, structs
            if typeHint == .class || typeHint == .struct {
                return JSONSchema(type: .object, properties: [:]) // We return an empty object for these types, along with empty properties as this is required by some validators
            }
            return JSONSchema()
        }

        var schema = schema ?? JSONSchema(type: .object) // ?? generateSchemaForProperty(object)
        
        // Handle each of the types children
        try handleChildren()
        
        func handleChildren() throws {
            // Process each child in the mirror
            for child in mirror.children {
                
                let value = child.value
                
                // Guard it's not a ignored property and skip if it is
                if value is JSONSchemaIgnorable { continue }
                
                // Skip if the property has no label
                guard let propertyName = child.label else { continue }
                
                // Clean the property name (remove underscore prefix for property wrappers)
                let cleanPropertyName = cleanPropertyName(propertyName)
                
                // Generate schema for this property
                let propertySchema = try _generateSchema(for: value, path: path.appending(path: propertyName))
                properties[cleanPropertyName] = propertySchema
                
                if !(isOptional(value)) {
                    required.append(cleanPropertyName)
                }
            }
            
            // Add properties and required fields to the schema
            schema.properties = properties
            schema.required = required
        }
        
        return schema
    }
    
    /// Generate a JSON Schema for the given Codable type
    /// - Parameters:
    ///   - type: The type to generate a schema for
    /// - Returns: A JSONSchema object representing the schema
    public func generateSchema<T: ProducesJSONSchema>(from type: T.Type, strict: Bool = false) throws -> JSONSchema {
        let instance = T.exampleValue
        return try _generateSchema(for: instance, schema: baseSchema, path: .Root)
    }
    
//    /// Generate a JSON Schema for the given CaseIterable type
//    /// - Parameters:
//    ///   - type: The type to generate a schema for
//    /// - Returns: A JSONSchema object representing the schema
//    public func generateSchema<T>(from type: T.Type, srict: Bool = false) throws -> JSONSchema where T: CaseIterable {
//        guard let instance = T.allCases.first else {
//            throw JSONSchemaGenerationError.noEnumCases
//        }
//        return try _generateSchema(for: instance, schema: baseSchema)
//    }
    
    
    // MARK: - Private Methods
    
    /// Cleans a property name by removing any leading underscore
    /// - Parameter propertyName: The raw property name
    /// - Returns: The cleaned property name
    private func cleanPropertyName(_ propertyName: String) -> String {
        
        // Cleans up property names to work with JSON
        if propertyName.hasPrefix("_") {
            return String(propertyName.dropFirst())
        }
        else if propertyName.hasPrefix(".") {
            // Handles tuple elements where you have .0, .1, etc and converts them to a more JSON friendly format
            return "_" + String(propertyName.dropFirst())
        }
    
        return propertyName
    }
    
    /// Determines if a value is an Optional type
    /// - Parameter value: The value to check
    /// - Returns: True if the value is an Optional, false otherwise
    private func isOptional(_ value: Any) -> Bool {
        let displayOptional = Mirror(reflecting: value).displayStyle == .optional
        let optionalDecorated = value is (any OptionalJSONSchemaMetadataProtocol)
        return displayOptional || optionalDecorated
    }
    
    
    private func isEnum(_ value: Any) -> Bool {
        return Mirror(reflecting: value).displayStyle == .enum
    }
    
    /// Generate a JSON Schema for a property value
    /// - Parameter value: The property value to generate a schema for
    /// - Returns: A JSONSchema object representing the property
    private func generateSchemaForBaseTypes<T>(_ value: T, typeHint: Mirror.DisplayStyle?, path: Path) throws -> JSONSchema? where T: Any {
        
        // Handle basic primitive types
        switch value {
        case is String:
            return JSONSchema(type: .string)
            
        case is Int, is Int8, is Int16, is Int32, is Int64, is UInt, is UInt8, is UInt16, is UInt32, is UInt64:
            return JSONSchema(type: .integer)
            
        case is Float, is Double, is Decimal:
            return JSONSchema(type: .number)
            
        case is Bool:
            return JSONSchema(type: .boolean)
            
        // Foundation types with special handling
        case is URL:
            var schema = JSONSchema(type: .string)
            schema.format = "uri"
            return schema
            
        case is UUID:
            var schema = JSONSchema(type: .string)
            schema.format = "uuid"
            return schema
            
        case is Date:
            var schema = JSONSchema(type: .string)
            schema.format = "date-time"
            return schema
            
        case is Data:
            var schema = JSONSchema(type: .string)
            schema.contentEncoding = "base64"
            return schema
            
        // Handle arrays (even empty ones)
        case let array as [Any]:
            var schema = JSONSchema(type: .array)
            if !array.isEmpty, let firstItem = array.first {
                let itemSchema = try _generateSchema(for: firstItem, path: path)
                schema.items = PassthroughContainer(itemSchema)
            }
            else {
                throw JSONSchemaGenerationError.noExampleItemForArray("\(path)")
            }
            return schema
            
        // Handle dictionaries (even empty ones)
        case let dict as [String: Any]:
            var schema = JSONSchema(type: .object)
            schema.additionalProperties = .bool(true)
            
            if !dict.isEmpty {
                var properties = [String: JSONSchema]()
                for (key, value) in dict {
                    properties[key] = try _generateSchema(for: value, path: path)
                }
                schema.properties = properties
            }
            else {
                throw JSONSchemaGenerationError.noExampleItemForDictionary("\(path)")
            }
            return schema
            
        // Put this last as some types like [Any] can get seen as Optional<Any>.
        // Although the hints from mirror largely help with this
        case let optValue as Optional<Any> where typeHint == .optional:
            guard let realValue = optValue else {
                return JSONSchema(type: .null)
            }
            return try _generateSchema(for: realValue, path: path)
            
        default:
            // If it's not a Foundation or Primitive Swift type return nil
            return nil
        }
    }
}
