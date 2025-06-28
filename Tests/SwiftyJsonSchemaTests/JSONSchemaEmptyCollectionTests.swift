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

final class JSONSchemaEmptyCollectionTests: XCTestCase {
    
    // MARK: - Empty Array Tests
    
    func testEmptyArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyArray: [String] = []
        
        let schema = try generator.generateSchema(for: emptyArray)
        
        // Should be a valid array schema
        XCTAssertEqual(schema.type, .array)
        
        // For empty arrays, we can't determine the item type through reflection
        // We can only verify that the schema is correctly identified as an array
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
        
        // For empty arrays, we can't determine the item type through reflection
        // We can only verify that the schema is correctly identified as an array
    }
    
    // MARK: - Empty Dictionary Tests
    
    func testEmptyDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let emptyDict: [String: Int] = [:]
        
        let schema = try generator.generateSchema(for: emptyDict)
        
        // Should be a valid object schema
        XCTAssertEqual(schema.type, .object)
        
        // For empty dictionaries, additionalProperties should be set but we can't determine value type
        XCTAssertNotNil(schema.additionalProperties)
        // We can only check that additionalProperties is present, not its specific type
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
        
        // For empty dictionaries, additionalProperties should be set but we can't determine value type
        XCTAssertNotNil(schema.properties?["emptyDict"]?.additionalProperties)
        // We can only check that additionalProperties is present, not its specific type
    }
    
    // MARK: - Nested Empty Collections Tests
    
    func testNestedEmptyCollectionsSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let container = NestedEmptyCollections()
        
        let schema = try generator.generateSchema(for: container)
        
        // Container should be an object
        XCTAssertEqual(schema.type, .object)
        
        // Check emptyArrayOfArrays
        XCTAssertEqual(schema.properties?["emptyArrayOfArrays"]?.type, .array)
        // For empty arrays, we can't determine the item type through reflection
        
        // Check emptyArrayOfDicts
        XCTAssertEqual(schema.properties?["emptyArrayOfDicts"]?.type, .array)
        // For empty arrays, we can't determine the item type through reflection
        
        // Check emptyDictOfArrays
        XCTAssertEqual(schema.properties?["emptyDictOfArrays"]?.type, .object)
        XCTAssertNotNil(schema.properties?["emptyDictOfArrays"]?.additionalProperties)
        // For empty dictionaries, we can't determine the value type through reflection
        
        // Check emptyDictOfDicts
        XCTAssertEqual(schema.properties?["emptyDictOfDicts"]?.type, .object)
        XCTAssertNotNil(schema.properties?["emptyDictOfDicts"]?.additionalProperties)
        // For empty dictionaries, we can't determine the value type through reflection
    }
}
