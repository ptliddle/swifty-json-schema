//
//  JSONSchemaCollectionTypeTests.swift
//  SwiftyJsonSchema
//
//  Created on 6/27/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

// Simple test structs that conform to CaseIterable for testing
struct StringArray: CaseIterable, Codable {
    static var allCases: [StringArray] = [StringArray()]
    let items = ["one", "two", "three"]
}

struct IntArray: CaseIterable, Codable {
    static var allCases: [IntArray] = [IntArray()]
    let items = [1, 2, 3]
}

struct StringDict: CaseIterable, Codable {
    static var allCases: [StringDict] = [StringDict()]
    let dict = ["key1": "value1", "key2": "value2"]
}

struct MixedDict: CaseIterable, Codable {
    static var allCases: [MixedDict] = [MixedDict()]
    let stringValue = "string value"
    let intValue = 42
    let boolValue = true
}

final class JSONSchemaCollectionTypeTests: XCTestCase {
    
    // MARK: - Array Tests
    
    func testStringArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let schema = try generator.generateSchema(for:  ["one", "two", "three"])
        
        
        XCTAssertEqual(schema.type, JSONSchemaType.array)
        XCTAssertEqual(schema.items!.items!.type, .string)
    }
    
    func testWrappedStringArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let stringArray = StringArray()
        let schema = try generator.generateSchema(for:  stringArray)
        
        XCTAssertEqual(schema.type, JSONSchemaType.object)
        XCTAssertNotNil(schema.properties)
        
        if let properties = schema.properties, let itemsProp = properties["items"] {
            XCTAssertEqual(itemsProp.type, JSONSchemaType.array)
            if let items = itemsProp.items, let itemSchema = items.items {
                XCTAssertEqual(itemSchema.type, JSONSchemaType.string)
            } else {
                XCTFail("Items schema should not be nil")
            }
        } else {
            XCTFail("Properties should not be nil")
        }
    }
    
    func testIntArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let schema = try generator.generateSchema(for: [1, 2, 3])
        
        XCTAssertEqual(schema.type, JSONSchemaType.array)
        XCTAssertEqual(schema.items!.items!.type, .integer)
    }
    
    func testWrappedIntArraySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = IntArray()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, JSONSchemaType.object)
        XCTAssertNotNil(schema.properties)
        
        if let properties = schema.properties, let itemsProp = properties["items"] {
            XCTAssertEqual(itemsProp.type, JSONSchemaType.array)
            if let items = itemsProp.items, let itemSchema = items.items {
                XCTAssertEqual(itemSchema.type, JSONSchemaType.integer)
            } else {
                XCTFail("Items schema should not be nil")
            }
        } else {
            XCTFail("Properties should not be nil")
        }
    }
    
    // MARK: - Dictionary Tests
    
    func testStringDictionarySchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = StringDict()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, JSONSchemaType.object)
        XCTAssertNotNil(schema.properties)
        
        if let properties = schema.properties, let dictProp = properties["dict"] {
            XCTAssertEqual(dictProp.type, JSONSchemaType.object)
            XCTAssertNotNil(dictProp.properties)
            
            if let dictProperties = dictProp.properties {
                XCTAssertEqual(dictProperties.count, 2)
                XCTAssertEqual(dictProperties["key1"]?.type, JSONSchemaType.string)
                XCTAssertEqual(dictProperties["key2"]?.type, JSONSchemaType.string)
            } else {
                XCTFail("Dict properties should not be nil")
            }
        } else {
            XCTFail("Properties should not be nil")
        }
    }
    
    func testMixedObjectSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        let value = MixedDict()
        let schema = try generator.generateSchema(for: value)
        
        XCTAssertEqual(schema.type, JSONSchemaType.object)
        XCTAssertNotNil(schema.properties)
        
        if let properties = schema.properties {
            XCTAssertEqual(properties.count, 3)
            XCTAssertEqual(properties["stringValue"]?.type, JSONSchemaType.string)
            XCTAssertEqual(properties["intValue"]?.type, JSONSchemaType.integer)
            XCTAssertEqual(properties["boolValue"]?.type, JSONSchemaType.boolean)
        } else {
            XCTFail("Properties should not be nil")
        }
    }
}
