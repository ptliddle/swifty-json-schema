//
//  JSONSchemaEmptyCollectionTests.swift
//  SwiftyJsonSchema
//
//  Created on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

// Test structs for empty collections
struct EmptyArrayContainer: CaseIterable, Codable {
    static var allCases: [EmptyArrayContainer] = [EmptyArrayContainer()]
    let emptyArray: [String] = []
}

struct EmptyDictionaryContainer: CaseIterable, Codable {
    static var allCases: [EmptyDictionaryContainer] = [EmptyDictionaryContainer()]
    let emptyDict: [String: Int] = [:]
}

struct NestedEmptyCollections: CaseIterable, Codable {
    static var allCases: [NestedEmptyCollections] = [NestedEmptyCollections()]
    let emptyArrayOfArrays: [[String]] = []
    let emptyArrayOfDicts: [[String: Int]] = []
    let emptyDictOfArrays: [String: [Int]] = [:]
    let emptyDictOfDicts: [String: [String: Bool]] = [:]
}

// Test struct with nil optional collections
struct NilOptionalCollections: Codable {
    var nilArray: [String]?
    var nilDict: [String: Int]?
    var id: String

    init(id: String) {
        self.id = id
        self.nilArray = nil
        self.nilDict = nil
    }
}

final class JSONSchemaEmptyCollectionTests: XCTestCase {
    
    // MARK: - Empty Array Tests
    
    func testEmptyArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyArray: [String] = []
        
        let schema = try generator.generateSchema(for: emptyArray)
        
        // Should be a valid array schema
        XCTAssertEqual(schema.type, .array)
        
        // Empty arrays should now determine the item type from the static type
        XCTAssertEqual(schema.items?.content?.type, .string)
    }
    
    func testWrappedEmptyArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = EmptyArrayContainer()
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // Should have the emptyArray property
        XCTAssertNotNil(schema.properties?["emptyArray"])
        
        // The emptyArray property should be an array
        XCTAssertEqual(schema.properties?["emptyArray"]?.type, .array)
        
        // Empty arrays should now determine the item type from the static type
        XCTAssertEqual(schema.properties?["emptyArray"]?.items?.content?.type, .string)
    }
    
    // MARK: - Empty Dictionary Tests
    
    func testEmptyDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyDict: [String: Int] = [:]
        
        let schema = try generator.generateSchema(for: emptyDict)
        
        // Should be a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // Empty dictionaries should now determine the value type from the static type
        if case .schema(let valueSchema) = schema.additionalProperties {
            XCTAssertEqual(valueSchema.type, .integer)
        } else {
            XCTFail("Expected additionalProperties to be a schema with integer type")
        }
    }
    
    func testWrappedEmptyDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = EmptyDictionaryContainer()
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // Should have the emptyDict property
        XCTAssertNotNil(schema.properties?["emptyDict"])
        
        // The emptyDict property should be an object
        XCTAssertEqual(schema.properties?["emptyDict"]?.type, .object)
        
        // Empty dictionaries should now determine the value type from the static type
        if case .schema(let valueSchema) = schema.properties?["emptyDict"]?.additionalProperties {
            XCTAssertEqual(valueSchema.type, .integer)
        } else {
            XCTFail("Expected additionalProperties to be a schema with integer type")
        }
    }
    
    // MARK: - Nested Empty Collections Tests
    
    func testNestedEmptyCollectionsSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = NestedEmptyCollections()
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // Check emptyArrayOfArrays - should be array of arrays of strings
        XCTAssertEqual(schema.properties?["emptyArrayOfArrays"]?.type, .array)
        XCTAssertEqual(schema.properties?["emptyArrayOfArrays"]?.items?.content?.type, .array)
        XCTAssertEqual(schema.properties?["emptyArrayOfArrays"]?.items?.content?.items?.content?.type, .string)
        
        // Check emptyArrayOfDicts - should be array of objects with integer values
        XCTAssertEqual(schema.properties?["emptyArrayOfDicts"]?.type, .array)
        XCTAssertEqual(schema.properties?["emptyArrayOfDicts"]?.items?.content?.type, .object)
        
        // Check emptyDictOfArrays - should be object with array values
        XCTAssertEqual(schema.properties?["emptyDictOfArrays"]?.type, .object)
        if case .schema(let valueSchema) = schema.properties?["emptyDictOfArrays"]?.additionalProperties {
            XCTAssertEqual(valueSchema.type, .array)
            XCTAssertEqual(valueSchema.items?.content?.type, .integer)
        } else {
            XCTFail("Expected additionalProperties to be a schema")
        }
        
        // Check emptyDictOfDicts - should be object with object values
        XCTAssertEqual(schema.properties?["emptyDictOfDicts"]?.type, .object)
        if case .schema(let valueSchema) = schema.properties?["emptyDictOfDicts"]?.additionalProperties {
            XCTAssertEqual(valueSchema.type, .object)
        } else {
            XCTFail("Expected additionalProperties to be a schema")
        }
    }
    
    // MARK: - Nil Optional Collection Tests
    
    func testNilOptionalArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = NilOptionalCollections(id: "test")
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // nilArray should be an array with string items
        XCTAssertEqual(schema.properties?["nilArray"]?.type, .array)
        XCTAssertEqual(schema.properties?["nilArray"]?.items?.content?.type, .string)
        
        // nilArray should NOT be in required (it's optional)
        XCTAssertFalse(schema.required?.contains("nilArray") ?? true)
    }
    
    func testNilOptionalDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = NilOptionalCollections(id: "test")
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // nilDict should be an object with integer additionalProperties
        XCTAssertEqual(schema.properties?["nilDict"]?.type, .object)
        if case .schema(let valueSchema) = schema.properties?["nilDict"]?.additionalProperties {
            XCTAssertEqual(valueSchema.type, .integer)
        } else {
            XCTFail("Expected additionalProperties to be a schema with integer type")
        }
        
        // nilDict should NOT be in required (it's optional)
        XCTAssertFalse(schema.required?.contains("nilDict") ?? true)
    }
}
