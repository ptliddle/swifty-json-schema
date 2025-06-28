//
//  SchemaProducerTests.swift
//  
//
//  Created by Peter Liddle on 8/27/24.
//

import XCTest
@testable import SwiftyJsonSchema

enum Generic: Error {
    case error(String)
}

extension Data {
    var string: String {
        get throws {
            guard let string = String(data: self, encoding: .utf8) else {
                throw Generic.error("Could not convert data to string")
            }
            return string
        }
    }
}

#if DEBUG
func log(_ items: Any...) {
    print(items)
}
#else
func log(_ items: Any...) {
    // Do Nothing
}
#endif


//MARK: - Test Structures
struct PersonInfo: ProducesJSONSchema {
    static var exampleValue: PersonInfo = PersonInfo(name: "Bob", age: 115, hobbies: ["3D Printing", "Space Exploration", "Classical Music", "Star Trek", "Talking to Guppie", "Drinking Coffee"])
    
    var name: String
    var age: Int
    var hobbies: [String]
}

struct MootInfo: ProducesJSONSchema {
    static var exampleValue = MootInfo(name: "Moot 5", date: .now, location: "Vert", attendees: [
        PersonInfo.exampleValue,
        PersonInfo(name: "Ricker", age: 68, hobbies: ["Military Strategy", "Combat Tactics", "Weapons Systems", "Interstellar Warfare"]),
        PersonInfo(name: "Garth", age: 65, hobbies: ["Engineering", "Terraforming", "Asteroid Mining", "Colony Development"]),
    ])
    
    
    var name: String
    var date: Date
    var location: String
    var attendees: [PersonInfo]
}

// MARK: Tests
final class SchemaProducerTests: XCTestCase {
    
    func testSimpleStructToJSONSchema() throws {
        // Create a schema from PersonInfo
        let schema = JsonSchemaCreator.createJSONSchema(from: PersonInfo.self)
        log(schema)
        
        // Define the expected schema
        let expectedSchema = JSONSchema(
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "age": JSONSchema(type: .integer, additionalProperties: .bool(false)),
                "hobbies": JSONSchema(
                    type: .array,
                    items: JSONSchema(type: .string, additionalProperties: .bool(false)),
                    additionalProperties: .bool(false)
                )
            ],
            required: ["name", "age", "hobbies"]
        )
        
        // Assert that the schema matches our expected schema
        XCTAssertEqual(schema.type, expectedSchema.type)
        XCTAssertEqual(schema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(schema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check individual properties
        guard let schemaProperties = schema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(schemaProperties["name"]?.type, expectedProperties["name"]?.type)
        
        // Check age property
        XCTAssertEqual(schemaProperties["age"]?.type, expectedProperties["age"]?.type)
        
        // Check hobbies property
        XCTAssertEqual(schemaProperties["hobbies"]?.type, expectedProperties["hobbies"]?.type)
        
        // Check hobbies items
        XCTAssertEqual(schemaProperties["hobbies"]?.items?.content?.type, expectedProperties["hobbies"]?.items?.content?.type)
        
        // Convert schema to JSON string
        let jsonData = try JSONEncoder().encode(schema)
        
        // Define expected JSON string
        let expectedJsonString = """
        {
          "$schema": "http://json-schema.org/draft-07/schema#",
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
            },
            "age": {
              "type": "integer",
            },
            "hobbies": {
              "type": "array",
              "items": {
                "type": "string"
              }
            }
          },
          "required": ["name", "age", "hobbies"],
        }
        """
        
        // Parse both JSON strings to compare them as objects (to avoid formatting differences)
        let actualJson = try JSONSerialization.jsonObject(with: jsonData, options: [])
        let expectedJson = try JSONSerialization.jsonObject(with: expectedJsonString.data(using: .utf8)!, options: [])
        
        // Convert both back to data with consistent formatting
        let normalizedActualData = try JSONSerialization.data(withJSONObject: actualJson, options: .sortedKeys)
        let normalizedExpectedData = try JSONSerialization.data(withJSONObject: expectedJson, options: .sortedKeys)
        
        // Compare the normalized JSON strings
        XCTAssertEqual(try normalizedActualData.asPrettyJson, try normalizedExpectedData.asPrettyJson)
    }
    
    func testMoreComplexStructToStrictJSONSchema() throws {
        // Create a schema from MootInfo
        let schema = JsonSchemaCreator.createJSONSchema(from: MootInfo.self)
        log(schema)
        
        // Define the expected schema for MootInfo using the proper initializer
        let expectedSchema = JSONSchema(
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "location": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "date": JSONSchema(
                    type: .object,
                    properties: [
                        "timeIntervalSinceReferenceDate": JSONSchema(type: .number, additionalProperties: .bool(false))
                    ],
                    required: ["timeIntervalSinceReferenceDate"],
                    additionalProperties: .bool(false)
                ),
                "attendees": JSONSchema(
                    type: .array,
                    items: JSONSchema(
                        type: .object,
                        properties: [
                            "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                            "age": JSONSchema(type: .integer, additionalProperties: .bool(false)),
                            "hobbies": JSONSchema(
                                type: .array,
                                items: JSONSchema(type: .string, additionalProperties: .bool(false)),
                                additionalProperties: .bool(false)
                            )
                        ],
                        required: ["name", "age", "hobbies"],
                        additionalProperties: .bool(false)
                    ),
                    additionalProperties: .bool(false)
                )
            ],
            required: ["name", "date", "location", "attendees"],
            additionalProperties: .bool(false)
        )
        
        // Assert that the schema matches our expected schema
        XCTAssertEqual(schema.type, expectedSchema.type)
        XCTAssertEqual(schema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(schema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check additionalProperties
        if let schemaAdditionalProps = schema.additionalProperties, let expectedAdditionalProps = expectedSchema.additionalProperties {
            switch (schemaAdditionalProps, expectedAdditionalProps) {
            case (.bool(let a), .bool(let b)):
                XCTAssertEqual(a, b)
            case (.schema(let a), .schema(let b)):
                XCTAssertEqual(a.type, b.type)
            default:
                XCTFail("additionalProperties types don't match")
            }
        } else {
            XCTAssertEqual(schema.additionalProperties == nil, expectedSchema.additionalProperties == nil)
        }
        
        // Check individual properties
        guard let schemaProperties = schema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(schemaProperties["name"]?.type, expectedProperties["name"]?.type)
        
        // Check location property
        XCTAssertEqual(schemaProperties["location"]?.type, expectedProperties["location"]?.type)
        
        // Check date property
        XCTAssertEqual(schemaProperties["date"]?.type, expectedProperties["date"]?.type)
        
        // Check attendees property
        XCTAssertEqual(schemaProperties["attendees"]?.type, expectedProperties["attendees"]?.type)
        
        // Convert schema to JSON string
        let jsonData = try JSONEncoder().encode(schema)
        
        // Define expected JSON string - this is a simplified version that matches the essential structure
        let expectedJsonString = """
        {"properties":{"name":{"items":{},"additionalProperties":false,"type":"string"},"date":{"additionalProperties":false,"items":{},"type":"object","properties":{"timeIntervalSinceReferenceDate":{"type":"number","additionalProperties":false,"items":{}}},"required":["timeIntervalSinceReferenceDate"]},"location":{"items":{},"type":"string","additionalProperties":false},"attendees":{"items":{"items":{"type":"object","additionalProperties":false,"properties":{"age":{"items":{},"type":"integer","additionalProperties":false},"name":{"items":{},"type":"string","additionalProperties":false},"hobbies":{"items":{"items":{"type":"string","additionalProperties":false,"items":{}}},"type":"array","additionalProperties":false}},"items":{},"required":["name","age","hobbies"]}},"type":"array","additionalProperties":false}},"additionalProperties":false,"required":["name","date","location","attendees"],"type":"object","items":{},"$schema":"http://json-schema.org/draft-07/schema#"}
        """.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse both JSON strings to compare them as objects (to avoid formatting differences)
        let actualJson = try JSONSerialization.jsonObject(with: jsonData, options: [])
        let expectedJson = try JSONSerialization.jsonObject(with: expectedJsonString.data(using: .utf8)!, options: [])
        
        // Convert both back to data with consistent formatting
        let normalizedActualData = try JSONSerialization.data(withJSONObject: actualJson, options: .sortedKeys)
        let normalizedExpectedData = try JSONSerialization.data(withJSONObject: expectedJson, options: .sortedKeys)
        
        // Compare the normalized JSON strings
        XCTAssertEqual(try normalizedActualData.string, try normalizedExpectedData.string)
    }

    
    func testPersonSchemaFromJSON() throws {
        
        let personSchemaInputJson = """
        {"properties":{"name":{"items":{},"additionalProperties":false,"type":"string"},"age":{"items":{},"additionalProperties":false,"type":"integer"},"hobbies":{"items":{"items":{"type":"string","items":{},"additionalProperties":false}},"additionalProperties":false,"type":"array"}},"additionalProperties":false,"required":["name","age","hobbies"],"type":"object","items":{},"$schema":"http://json-schema.org/draft-07/schema#"}
        """
        
        // Decode the JSON schema
        let decodedSchema = try JSONDecoder().decode(JSONSchema.self, from: personSchemaInputJson.data(using: .utf8)!)
        log(decodedSchema)

        // Create the expected schema for PersonInfo using the proper initializer
        let expectedSchema = JSONSchema(
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "age": JSONSchema(type: .integer, additionalProperties: .bool(false)),
                "hobbies": JSONSchema(
                    type: .array,
                    items: JSONSchema(type: .string, additionalProperties: .bool(false)),
                    additionalProperties: .bool(false)
                )
            ],
            required: ["name", "age", "hobbies"],
            additionalProperties: .bool(false)
        )
        
        // Assert that the decoded schema matches our expected schema
        XCTAssertEqual(decodedSchema.type, expectedSchema.type)
        XCTAssertEqual(decodedSchema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(decodedSchema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check additionalProperties
        XCTAssertEqual(decodedSchema.additionalProperties, expectedSchema.additionalProperties)
        
        // Check individual properties
        guard let decodedProperties = decodedSchema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(decodedProperties["name"]?.type, expectedProperties["name"]?.type)
        XCTAssertEqual(decodedProperties["name"]?.additionalProperties, expectedProperties["name"]?.additionalProperties)
        
        // Check age property
        XCTAssertEqual(decodedProperties["age"]?.type, expectedProperties["age"]?.type)
        XCTAssertEqual(decodedProperties["age"]?.additionalProperties, expectedProperties["age"]?.additionalProperties)
        
        // Check hobbies property
        XCTAssertEqual(decodedProperties["hobbies"]?.type, expectedProperties["hobbies"]?.type)
        XCTAssertEqual(decodedProperties["hobbies"]?.additionalProperties, expectedProperties["hobbies"]?.additionalProperties)
        
        // Check hobbies items
        XCTAssertEqual(decodedProperties["hobbies"]?.items?.content?.type, expectedProperties["hobbies"]?.items?.content?.type)
        
        // Also verify that this schema matches what would be created by the JsonSchemaCreator
        let generatedSchema = JsonSchemaCreator.createJSONSchema(from: PersonInfo.self)
        
        // Compare the key aspects of the schemas
        XCTAssertEqual(decodedSchema.type, generatedSchema.type)
        XCTAssertEqual(Set(decodedSchema.required ?? []), Set(generatedSchema.required ?? []))
        
        // Verify that the properties have the same types
        guard let generatedProperties = generatedSchema.properties else {
            XCTFail("Missing properties in generated schema")
            return
        }
        
        XCTAssertEqual(decodedProperties["name"]?.type, generatedProperties["name"]?.type)
        XCTAssertEqual(decodedProperties["age"]?.type, generatedProperties["age"]?.type)
        XCTAssertEqual(decodedProperties["hobbies"]?.type, generatedProperties["hobbies"]?.type)
    }
    
    func testMootSchemaFromJSON() throws {
        
        let mootSchemaInputJson = """
        {"items":{},"type":"object","additionalProperties":false,"$schema":"http://json-schema.org/draft-07/schema#","required":["name","date","location","attendees"],"properties":{"name":{"items":{},"type":"string","additionalProperties":false},"date":{"additionalProperties":false,"items":{},"type":"object","properties":{"timeIntervalSinceReferenceDate":{"type":"number","additionalProperties":false,"items":{}}},"required":["timeIntervalSinceReferenceDate"]},"location":{"items":{},"type":"string","additionalProperties":false},"attendees":{"items":{"items":{"type":"object","additionalProperties":false,"properties":{"age":{"items":{},"type":"integer","additionalProperties":false},"name":{"items":{},"type":"string","additionalProperties":false},"hobbies":{"items":{"items":{"type":"string","additionalProperties":false,"items":{}}},"type":"array","additionalProperties":false}},"items":{},"required":["name","age","hobbies"]}},"type":"array","additionalProperties":false}}}
        """
        
        // Decode the JSON schema
        let decodedSchema = try JSONDecoder().decode(JSONSchema.self, from: mootSchemaInputJson.data(using: .utf8)!)
        log(decodedSchema)
        
        // Create the expected schema for MootInfo using the proper initializer
        let expectedSchema = JSONSchema(
            schema: "http://json-schema.org/draft-07/schema#",
            type: .object,
            properties: [
                "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "location": JSONSchema(type: .string, additionalProperties: .bool(false)),
                "date": JSONSchema(
                    type: .object,
                    properties: [
                        "timeIntervalSinceReferenceDate": JSONSchema(type: .number, additionalProperties: .bool(false))
                    ],
                    required: ["timeIntervalSinceReferenceDate"],
                    additionalProperties: .bool(false)
                ),
                "attendees": JSONSchema(
                    type: .array,
                    items: JSONSchema(
                        type: .object,
                        properties: [
                            "name": JSONSchema(type: .string, additionalProperties: .bool(false)),
                            "age": JSONSchema(type: .integer, additionalProperties: .bool(false)),
                            "hobbies": JSONSchema(
                                type: .array,
                                items: JSONSchema(type: .string, additionalProperties: .bool(false)),
                                additionalProperties: .bool(false)
                            )
                        ],
                        required: ["name", "age", "hobbies"],
                        additionalProperties: .bool(false)
                    ),
                    additionalProperties: .bool(false)
                )
            ],
            required: ["name", "date", "location", "attendees"],
            additionalProperties: .bool(false)
        )
        
        // Assert that the decoded schema matches our expected schema
        XCTAssertEqual(decodedSchema.type, expectedSchema.type)
        XCTAssertEqual(decodedSchema.schema, expectedSchema.schema)
        
        // Check required properties
        XCTAssertEqual(Set(decodedSchema.required ?? []), Set(expectedSchema.required ?? []))
        
        // Check additionalProperties
        XCTAssertEqual(decodedSchema.additionalProperties, expectedSchema.additionalProperties)
        
        // Check individual properties
        guard let decodedProperties = decodedSchema.properties,
              let expectedProperties = expectedSchema.properties else {
            XCTFail("Missing properties in schema")
            return
        }
        
        // Check name property
        XCTAssertEqual(decodedProperties["name"]?.type, expectedProperties["name"]?.type)
        
        // Check location property
        XCTAssertEqual(decodedProperties["location"]?.type, expectedProperties["location"]?.type)
        
        // Check date property
        XCTAssertEqual(decodedProperties["date"]?.type, expectedProperties["date"]?.type)
        guard let decodedDateProps = decodedProperties["date"]?.properties,
              let expectedDateProps = expectedProperties["date"]?.properties else {
            XCTFail("Missing date properties")
            return
        }
        XCTAssertEqual(decodedDateProps["timeIntervalSinceReferenceDate"]?.type, expectedDateProps["timeIntervalSinceReferenceDate"]?.type)
        
        // Check attendees property
        XCTAssertEqual(decodedProperties["attendees"]?.type, expectedProperties["attendees"]?.type)
        
        // Check attendees items (PersonInfo schema)
        guard let decodedAttendeeItems = decodedProperties["attendees"]?.items?.content,
              let expectedAttendeeItems = expectedProperties["attendees"]?.items?.content else {
            XCTFail("Missing attendees items")
            return
        }
        
        // Check PersonInfo properties in attendees
        guard let decodedPersonProps = decodedAttendeeItems.properties,
              let expectedPersonProps = expectedAttendeeItems.properties else {
            XCTFail("Missing person properties in attendees")
            return
        }
        
        // Check person name property
        XCTAssertEqual(decodedPersonProps["name"]?.type, expectedPersonProps["name"]?.type)
        
        // Check person age property
        XCTAssertEqual(decodedPersonProps["age"]?.type, expectedPersonProps["age"]?.type)
        
        // Check person hobbies property
        XCTAssertEqual(decodedPersonProps["hobbies"]?.type, expectedPersonProps["hobbies"]?.type)
        
        // Check hobbies items
        XCTAssertEqual(decodedPersonProps["hobbies"]?.items?.content?.type, expectedPersonProps["hobbies"]?.items?.content?.type)
        
        // Also verify that this schema matches what would be created by the JsonSchemaCreator
        let generatedSchema = JsonSchemaCreator.createJSONSchema(from: MootInfo.self)
        
        // Compare the key aspects of the schemas
        XCTAssertEqual(decodedSchema.type, generatedSchema.type)
        XCTAssertEqual(Set(decodedSchema.required ?? []), Set(generatedSchema.required ?? []))
    }
    
    func testArbitrarySchemaFromJSON() throws {
        
        let testSchema = """
             {
              "$id": "https://example.com/property-descriptors.schema.json",
              "$schema": "http://json-schema.org/draft-07/schema#",
              "title": "PropertyDescriptors",
               "type": "object",
               "properties": {
                  "identifiedComponents": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "properties": {
                        "id": {
                          "type": "string"
                        },
                        "context": {
                          "type": "string"
                        }
                      },
                      "additionalProperties": false
                    }
                  }
                },
                "additionalProperties": false
              }
        """
        
        let data = testSchema.data(using: .utf8)!
        let object = try JSONDecoder().decode(JSONSchema.self, from: data)
        
        let jsonData = try JSONEncoder().encode(object)
        
        let jsonForPrint = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
        let prettyPrintData = try JSONSerialization.data(withJSONObject: jsonForPrint, options: .prettyPrinted)
        
        log(String(data: prettyPrintData, encoding: .utf8)!)
        
    }
}
