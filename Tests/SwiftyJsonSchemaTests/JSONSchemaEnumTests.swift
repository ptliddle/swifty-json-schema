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
        
        enum CodingKeys: String, CodingKey {
            case type
            case value
            case url
            case width
            case height
            case duration
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .value)
                
            case .image(let url, let width, let height):
                try container.encode("image", forKey: .type)
                try container.encode(url, forKey: .url)
                try container.encode(width, forKey: .width)
                try container.encode(height, forKey: .height)
                
            case .video(let url, let duration):
                try container.encode("video", forKey: .type)
                try container.encode(url, forKey: .url)
                try container.encode(duration, forKey: .duration)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "text":
                let text = try container.decode(String.self, forKey: .value)
                self = .text(text)
                
            case "image":
                let url = try container.decode(String.self, forKey: .url)
                let width = try container.decode(Int.self, forKey: .width)
                let height = try container.decode(Int.self, forKey: .height)
                self = .image(url: url, width: width, height: height)
                
            case "video":
                let url = try container.decode(String.self, forKey: .url)
                let duration = try container.decode(Double.self, forKey: .duration)
                self = .video(url: url, duration: duration)
                
            default:
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: container.codingPath,
                        debugDescription: "Unknown content type: \(type)"
                    )
                )
            }
        }
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
    

    func testContentTypeEnumSchemaGeneration() throws {
        let generator = JSONSchemaGenerator()
        
        // Generate schema for the ContentType enum directly
        let contentTypeSchema = try generator.generateSchema(for: ContentType.text("Sample text"))
        
        // Verify the base schema properties
        XCTAssertEqual(contentTypeSchema.type, .object)
        XCTAssertNotNil(contentTypeSchema.oneOf, "Schema should use oneOf for enum with associated values")
        XCTAssertGreaterThanOrEqual(contentTypeSchema.oneOf?.count ?? 0, 3, "Schema should have at least 3 oneOf schemas for the 3 enum cases")
        
        // Find the schema for the text case
        let textSchema = contentTypeSchema.oneOf?.first { schema in
            let typeValue = schema.properties?["type"]?.enumValues?.first?.stringValue
            return typeValue == "text"
        }
        XCTAssertNotNil(textSchema, "Schema should include a case for text")
        
        // Verify text schema properties
        XCTAssertEqual(textSchema?.type, .object)
        XCTAssertNotNil(textSchema?.properties?["type"], "Text schema should have a type discriminator property")
        XCTAssertEqual(textSchema?.properties?["type"]?.type, .string)
        XCTAssertEqual(textSchema?.properties?["type"]?.enumValues?.first?.stringValue, "text")
        XCTAssertNotNil(textSchema?.properties?["value"], "Text schema should have a value property")
        XCTAssertEqual(textSchema?.properties?["value"]?.type, .string)
        
        // Find the schema for the image case
        let imageSchema = contentTypeSchema.oneOf?.first { schema in
            let typeValue = schema.properties?["type"]?.enumValues?.first?.stringValue
            return typeValue == "image"
        }
        XCTAssertNotNil(imageSchema, "Schema should include a case for image")
        
        // Verify image schema properties
        XCTAssertEqual(imageSchema?.type, .object)
        XCTAssertNotNil(imageSchema?.properties?["type"], "Image schema should have a type discriminator property")
        XCTAssertEqual(imageSchema?.properties?["type"]?.type, .string)
        XCTAssertEqual(imageSchema?.properties?["type"]?.enumValues?.first?.stringValue, "image")
        XCTAssertNotNil(imageSchema?.properties?["url"], "Image schema should have a url property")
        XCTAssertEqual(imageSchema?.properties?["url"]?.type, .string)
        XCTAssertNotNil(imageSchema?.properties?["width"], "Image schema should have a width property")
        XCTAssertEqual(imageSchema?.properties?["width"]?.type, .integer)
        XCTAssertNotNil(imageSchema?.properties?["height"], "Image schema should have a height property")
        XCTAssertEqual(imageSchema?.properties?["height"]?.type, .integer)
        
        // Find the schema for the video case
        let videoSchema = contentTypeSchema.oneOf?.first { schema in
            let typeValue = schema.properties?["type"]?.enumValues?.first?.stringValue
            return typeValue == "video"
        }
        XCTAssertNotNil(videoSchema, "Schema should include a case for video")
        
        // Verify video schema properties
        XCTAssertEqual(videoSchema?.type, .object)
        XCTAssertNotNil(videoSchema?.properties?["type"], "Video schema should have a type discriminator property")
        XCTAssertEqual(videoSchema?.properties?["type"]?.type, .string)
        XCTAssertEqual(videoSchema?.properties?["type"]?.enumValues?.first?.stringValue, "video")
        XCTAssertNotNil(videoSchema?.properties?["url"], "Video schema should have a url property")
        XCTAssertEqual(videoSchema?.properties?["url"]?.type, .string)
        XCTAssertNotNil(videoSchema?.properties?["duration"], "Video schema should have a duration property")
        XCTAssertEqual(videoSchema?.properties?["duration"]?.type, .number)
    }
    
    func testComplexEnumSchemaGeneration() throws {
        // Create an instance of our generator
        let generator = JSONSchemaGenerator()
        
        // Create test items with different content types
        let textItem = ContentItem (
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
        
        // Generate schemas
        let textSchema = try generator.generateSchema(for: textItem)
        let imageSchema = try generator.generateSchema(for: imageItem)
        
        // Verify schemas
        XCTAssertEqual(textSchema.type, .object)
        XCTAssertEqual(imageSchema.type, .object)
        
        // Check content property for text item
        guard let textContentSchema = textSchema.properties?["content"] else {
            XCTFail("Missing content property in text schema")
            return
        }
        
        // Content should be an object with discriminator field "type"
        XCTAssertEqual(textContentSchema.type, .object)
        XCTAssertNotNil(textContentSchema.properties?["type"])
        XCTAssertNotNil(textContentSchema.properties?["value"])
        
        // Check content property for image item
        guard let imageContentSchema = imageSchema.properties?["content"] else {
            XCTFail("Missing content property in image schema")
            return
        }
        
        // Content should be an object with discriminator field "type"
        XCTAssertEqual(imageContentSchema.type, .object)
        XCTAssertNotNil(imageContentSchema.properties?["type"])
        XCTAssertNotNil(imageContentSchema.properties?["url"])
        XCTAssertNotNil(imageContentSchema.properties?["width"])
        XCTAssertNotNil(imageContentSchema.properties?["height"])
    }
}
