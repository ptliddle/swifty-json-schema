//
//  JSONSchemaComplexTypeTests.swift
//  
//
//  Created on 6/26/25.
//

import XCTest
import Foundation
@testable import SwiftyJsonSchema

final class JSONSchemaComplexTypeTests: XCTestCase {
    
    // Test structure with dictionary properties
    struct ConfigWithDictionaries: Codable {
        var name: String
        var settings: [String: String]
        var numericSettings: [String: Int]
        var nestedSettings: [String: [String: Bool]]
    }
    
    func testDictionarySchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test config with dictionaries
        let config = ConfigWithDictionaries(
            name: "AppConfig",
            settings: ["theme": "dark", "language": "en-US"],
            numericSettings: ["timeout": 30, "maxRetries": 5],
            nestedSettings: [
                "features": ["darkMode": true, "notifications": false],
                "permissions": ["camera": true, "location": true]
            ]
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: config)
        
        // Verify schema
        XCTAssertEqual(schema.type, .object)
        
        // Check properties
        guard let properties = schema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check dictionary properties
        XCTAssertEqual(properties["settings"]?.type, .object)
        XCTAssertEqual(properties["numericSettings"]?.type, .object)
        XCTAssertEqual(properties["nestedSettings"]?.type, .object)
        
        // Check that all properties are required
        XCTAssertEqual(Set(schema.required ?? []), Set(["name", "settings", "numericSettings", "nestedSettings"]))
    }
    
    // Test structure with common Foundation types
    struct EntityWithFoundationTypes: Codable {
        var id: String
        var createdAt: Date
        var updatedAt: Date?
        var websiteURL: URL
        var imageURL: URL?
    }
    
    func testFoundationTypesSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test entity with Foundation types
        let entity = EntityWithFoundationTypes(
            id: "entity-123",
            createdAt: Date(),
            updatedAt: Date().addingTimeInterval(3600), // 1 hour later
            websiteURL: URL(string: "https://example.com")!,
            imageURL: URL(string: "https://example.com/image.jpg")
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: entity)
        
        // Verify schema
        XCTAssertEqual(schema.type, .object)
        
        // Check properties
        guard let properties = schema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check Date properties - should be strings with format "date-time"
        XCTAssertEqual(properties["createdAt"]?.type, .string)
        XCTAssertEqual(properties["createdAt"]?.format, "date-time")
        
        XCTAssertEqual(properties["updatedAt"]?.type, .string)
        XCTAssertEqual(properties["updatedAt"]?.format, "date-time")
        
        // Check URL properties - should be strings with format "uri"
        XCTAssertEqual(properties["websiteURL"]?.type, .string)
        XCTAssertEqual(properties["websiteURL"]?.format, "uri")
        
        XCTAssertEqual(properties["imageURL"]?.type, .string)
        XCTAssertEqual(properties["imageURL"]?.format, "uri")
        
        // Check required fields - optional properties should not be required
        XCTAssertEqual(Set(schema.required ?? []), Set(["id", "createdAt", "websiteURL"]))
    }
    
    // Test structure with deeply nested objects
    struct GrandchildObject: Codable {
        var id: String
        var name: String
        var value: Int
    }
    
    struct ChildObject: Codable {
        var id: String
        var grandchildren: [GrandchildObject]
        var metadata: [String: String]
    }
    
    struct ParentObject: Codable {
        var id: String
        var children: [ChildObject]
        var favoriteChild: ChildObject?
    }
    
    func testDeeplyNestedObjectsSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test object with deep nesting
        let parent = ParentObject(
            id: "parent-1",
            children: [
                ChildObject(
                    id: "child-1",
                    grandchildren: [
                        GrandchildObject(id: "gc-1", name: "First", value: 1),
                        GrandchildObject(id: "gc-2", name: "Second", value: 2)
                    ],
                    metadata: ["type": "primary"]
                ),
                ChildObject(
                    id: "child-2",
                    grandchildren: [
                        GrandchildObject(id: "gc-3", name: "Third", value: 3)
                    ],
                    metadata: ["type": "secondary"]
                )
            ],
            favoriteChild: ChildObject(
                id: "favorite-child",
                grandchildren: [
                    GrandchildObject(id: "gc-fav", name: "Favorite", value: 100)
                ],
                metadata: ["type": "favorite"]
            )
        )
        
        // Generate schema
        let schema = try generator.generateSchema(for: parent)
        
        // Verify schema
        XCTAssertEqual(schema.type, .object)
        
        // Check properties
        guard let properties = schema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check children array
        XCTAssertEqual(properties["children"]?.type, .array)
        
        // Navigate to child object schema
        guard let childSchema = properties["children"]?.items?.items else {
            XCTFail("Missing child schema")
            return
        }
        
        // Check child properties
        XCTAssertEqual(childSchema.type, .object)
        XCTAssertNotNil(childSchema.properties?["id"])
        XCTAssertNotNil(childSchema.properties?["grandchildren"])
        XCTAssertNotNil(childSchema.properties?["metadata"])
        
        // Navigate to grandchild object schema
        guard let grandchildSchema = childSchema.properties?["grandchildren"]?.items?.items else {
            XCTFail("Missing grandchild schema")
            return
        }
        
        // Check grandchild properties
        XCTAssertEqual(grandchildSchema.type, .object)
        XCTAssertNotNil(grandchildSchema.properties?["id"])
        XCTAssertNotNil(grandchildSchema.properties?["name"])
        XCTAssertNotNil(grandchildSchema.properties?["value"])
        
        // Check favoriteChild (optional nested object)
        XCTAssertEqual(properties["favoriteChild"]?.type, .object)
        XCTAssertNotNil(properties["favoriteChild"]?.properties?["id"])
        XCTAssertNotNil(properties["favoriteChild"]?.properties?["grandchildren"])
        XCTAssertNotNil(properties["favoriteChild"]?.properties?["metadata"])
    }
}
