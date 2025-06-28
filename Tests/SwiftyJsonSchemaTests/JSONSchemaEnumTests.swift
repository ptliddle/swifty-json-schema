//
//  JSONSchemaEnumTests.swift
//  
//
//  Created on 6/26/25.
//

import XCTest
@testable import SwiftyJsonSchema

final class JSONSchemaEnumTests: XCTestCase {
    
    // Simple string-based enum
    enum UserRole: String, Codable, CaseIterable {
        case admin
        case editor
        case viewer
    }
    
    // Int-based enum
    enum Priority: Int, Codable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
    }
    
    // Enum with associated values
    enum ContentType: Codable, CaseIterable {
        static var allCases: [Self] = [.text("Test Text"),
                                       .image(url: "http://example.com/image1.png", width: 120, height: 200),
                                       .video(url: "http://example.com/video1.mp4", duration: 576)]
        
        case text(String)
        case image(url: String, width: Int, height: Int)
        case video(url: String, duration: Double)
    }
    
    // Test structure with enums
    struct ContentItem: Codable {
        var id: String
        var role: UserRole
        var priority: Priority
        var content: ContentType
    }
    
    func testSimpleEnumSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test structure with a simple enum
        struct UserWithRole: Codable {
            var id: String
            var name: String
            var role: UserRole
        }
        
        let user = UserWithRole(id: "user-1", name: "Admin User", role: .admin)
        
        // Generate schema
        let schema = try generator.generateSchema(for: user)
        
        TestLog.debug(schema.debugDescription)
        
        // Verify schema
        XCTAssertEqual(schema.type, .object)
        
        // Check role property
        guard let roleSchema = schema.properties?["role"] else {
            XCTFail("Missing role property in schema")
            return
        }
        
        // Role should be a string with enum values
        XCTAssertEqual(roleSchema.type, .string)
        XCTAssertEqual(Set(roleSchema.enumValues ?? []), Set(["admin", "editor", "viewer"]))
    }
    
    func testIntEnumSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create a test structure with an int enum
        struct Task: Codable {
            var id: String
            var description: String
            var priority: Priority
        }
        
        let task = Task(id: "task-1", description: "Important task", priority: .high)
        
        // Generate schema
        let schema = try generator.generateSchema(for: task)
        
        TestLog.debug(schema.debugDescription)
        
        // Verify schema
        XCTAssertEqual(schema.type, .object)
        
        // Check priority property
        guard let prioritySchema = schema.properties?["priority"] else {
            XCTFail("Missing priority property in schema")
            return
        }
        
        // Priority should be an integer with enum values
        XCTAssertEqual(prioritySchema.type, .integer)
        
        // The enum values should be the raw integer values
        let expectedEnumValues: [Int] = [0, 1, 2, 3]
        let outputEnumValues: [Int] = (prioritySchema.enumValues ?? []).compactMap { $0.intValue ?? nil }
        XCTAssertEqual(Set(outputEnumValues), Set(expectedEnumValues))
    }
    
    func testComplexEnumSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create test items with different content types
        let textItem = ContentItem(
            id: "item-1",
            role: .editor,
            priority: .medium,
            content: .text("This is a text content")
        )
        
        let imageItem = ContentItem(
            id: "item-2",
            role: .admin,
            priority: .high,
            content: .image(url: "https://example.com/image.jpg", width: 800, height: 600)
        )
        
        // Generate schema for the ContentItem
        let schema = try generator.generateSchema(for: textItem)
        
        // Verify the overall structure
        XCTAssertEqual(schema.type, .object)
        XCTAssertNotNil(schema.properties?["id"])
        XCTAssertNotNil(schema.properties?["role"])
        XCTAssertNotNil(schema.properties?["priority"])
        XCTAssertNotNil(schema.properties?["content"])
        
        // Verify role enum schema
        let roleSchema = schema.properties?["role"]
        XCTAssertEqual(roleSchema?.type, .string)
        XCTAssertEqual(Set(roleSchema?.enumValues?.compactMap { $0.stringValue } ?? []), 
                       Set(["admin", "editor", "viewer"]))
        
        // Verify priority enum schema
        let prioritySchema = schema.properties?["priority"]
        XCTAssertEqual(prioritySchema?.type, .integer)
        let expectedEnumValues: [Int] = [0, 1, 2, 3]
        let outputEnumValues: [Int] = (prioritySchema?.enumValues ?? []).compactMap { $0.intValue }
        XCTAssertEqual(Set(outputEnumValues), Set(expectedEnumValues))
        
        // Verify content schema
        let contentSchema = schema.properties?["content"]
        
        // Content should use oneOf for the different cases
        XCTAssertNotNil(contentSchema?.oneOf)
        XCTAssertGreaterThanOrEqual(contentSchema?.oneOf?.count ?? 0, 3) // Should have at least 3 cases
        
        // Find the schema for each case
        let textCaseSchema = contentSchema?.oneOf?.first { $0.properties?["text"] != nil }
        
        let imageCaseSchema = contentSchema?.oneOf?.first { $0.properties?["image"] != nil }
        
        let videoCaseSchema = contentSchema?.oneOf?.first { $0.properties?["video"] != nil }
        
        // Verify text case schema
        XCTAssertNotNil(textCaseSchema, "Schema should include a case for text")
        XCTAssertEqual(textCaseSchema!.type, .object)
        XCTAssertEqual(textCaseSchema!.properties!["text"]!.type, .string)
        
        // Verify image case schema
        XCTAssertNotNil(imageCaseSchema, "Schema should include a case for image")
        XCTAssertEqual(imageCaseSchema!.type, .object)
        let imageObjectSchema = imageCaseSchema!.properties!["image"]!
        XCTAssertEqual(imageObjectSchema.type, .object)
        
        // Check Image object props
        XCTAssertEqual(imageObjectSchema.properties!["url"]?.type, .string)
        XCTAssertEqual(imageObjectSchema.properties!["width"]?.type, .integer)
        XCTAssertEqual(imageObjectSchema.properties!["height"]?.type, .integer)
        
        // Verify video case schema
        XCTAssertNotNil(videoCaseSchema, "Schema should include a case for video")
        XCTAssertEqual(videoCaseSchema?.type, .object)
        
        let videoObjectSchema = videoCaseSchema!.properties!["video"]!
        XCTAssertEqual(videoObjectSchema.type, .object)
        XCTAssertEqual(videoObjectSchema.properties!["url"]!.type, .string)
        XCTAssertEqual(videoObjectSchema.properties!["duration"]!.type, .number)
        
        // Generate schema for the image item to verify consistency
        let imageItemSchema = try generator.generateSchema(for: imageItem)
        XCTAssertEqual(imageItemSchema.type, .object)
        XCTAssertNotNil(imageItemSchema.properties?["content"])
        
        // Both items should generate the same schema structure
        XCTAssertEqual(schema.properties?["content"]?.oneOf?.count, 
                       imageItemSchema.properties?["content"]?.oneOf?.count)
    }
}
