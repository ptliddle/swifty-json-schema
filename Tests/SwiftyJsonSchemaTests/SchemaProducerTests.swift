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


final class SchemaProducerTests: XCTestCase {

    //MARK: - Test Structures
    struct PersonInfo: ProducesJSONSchema {
        static var exampleValue: PersonInfo = PersonInfo(name: "Bob", age: 115, hobbies: ["3D Printing", "Space Exploration", "Classical Music", "Star Trek", "Talking to Guppie", "Drinking Coffee"])
        
        var name: String
        var age: Int
        var hobbies: [String]
    }
    
    struct MootInfo: ProducesJSONSchema {
        static var exampleValue = SchemaProducerTests.MootInfo(name: "Moot 5", date: .now, location: "Vert", attendees: [
            PersonInfo.exampleValue,
            PersonInfo(name: "Ricker", age: 68, hobbies: ["Military Strategy", "Combat Tactics", "Weapons Systems", "Interstellar Warfare"]),
            PersonInfo(name: "Garth", age: 65, hobbies: ["Engineering", "Terraforming", "Asteroid Mining", "Colony Development"]),
        ])
        
        
        var name: String
        var date: Date
        var location: String
        var attendees: [PersonInfo]
    }
    
    func testSimpleStructToJSONSchema() throws {
        
        let schema = JsonSchemaCreator.createJSONSchema(from: PersonInfo.self)
        log(schema)
        
        let jsonData = try JSONEncoder().encode(schema).string
        
        log(jsonData)
    }
    
    func testMoreComplexStructToJSONSchema() throws {
        
        let expectedSchema = """
        {
          "$schema" : "http://json-schema.org/draft-07/schema#",
          "properties" : {
            "attendees" : {
              "type" : "array",
              "items" : {
                "items" : {
                  "properties" : {
                    "hobbies" : {
                      "items" : {
                        "items" : {
                          "type" : "string",
                          "items" : {

                          },
                          "additionalProperties" : false
                        }
                      },
                      "type" : "array",
                      "additionalProperties" : false
                    },
                    "age" : {
                      "type" : "integer",
                      "items" : {

                      },
                      "additionalProperties" : false
                    },
                    "name" : {
                      "type" : "string",
                      "items" : {

                      },
                      "additionalProperties" : false
                    }
                  },
                  "items" : {

                  },
                  "type" : "object",
                  "required" : [
                    "name",
                    "age",
                    "hobbies"
                  ],
                  "additionalProperties" : false
                }
              },
              "additionalProperties" : false
            },
            "name" : {
              "items" : {

              },
              "type" : "string",
              "additionalProperties" : false
            },
            "location" : {
              "items" : {

              },
              "type" : "string",
              "additionalProperties" : false
            },
            "date" : {
              "properties" : {
                "timeIntervalSinceReferenceDate" : {
                  "items" : {

                  },
                  "type" : "number",
                  "additionalProperties" : false
                }
              },
              "items" : {

              },
              "type" : "object",
              "required" : [
                "timeIntervalSinceReferenceDate"
              ],
              "additionalProperties" : false
            }
          },
          "items" : {

          },
          "type" : "object",
          "required" : [
            "name",
            "date",
            "location",
            "attendees"
          ],
          "additionalProperties" : false
        }
        """
        
        let schema = JsonSchemaCreator.createJSONSchema(from: MootInfo.self)
        log(schema)
//        XCTAssertEqual(expectedSchema, schema.debugDescription)
        
        let jsonData = try JSONEncoder().encode(schema).string
        
        log(jsonData)
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
                "name": JSONSchema(type: .string, additionalProperties: false),
                "age": JSONSchema(type: .integer, additionalProperties: false),
                "hobbies": JSONSchema(
                    type: .array,
                    items: JSONSchema(type: .string, additionalProperties: false),
                    additionalProperties: false
                )
            ],
            required: ["name", "age", "hobbies"],
            additionalProperties: false
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
        XCTAssertEqual(decodedProperties["hobbies"]?.items?.items?.type, expectedProperties["hobbies"]?.items?.items?.type)
        
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
                "name": JSONSchema(type: .string, additionalProperties: false),
                "location": JSONSchema(type: .string, additionalProperties: false),
                "date": JSONSchema(
                    type: .object,
                    properties: [
                        "timeIntervalSinceReferenceDate": JSONSchema(type: .number, additionalProperties: false)
                    ],
                    required: ["timeIntervalSinceReferenceDate"],
                    additionalProperties: false
                ),
                "attendees": JSONSchema(
                    type: .array,
                    items: JSONSchema(
                        type: .object,
                        properties: [
                            "name": JSONSchema(type: .string, additionalProperties: false),
                            "age": JSONSchema(type: .integer, additionalProperties: false),
                            "hobbies": JSONSchema(
                                type: .array,
                                items: JSONSchema(type: .string, additionalProperties: false),
                                additionalProperties: false
                            )
                        ],
                        required: ["name", "age", "hobbies"],
                        additionalProperties: false
                    ),
                    additionalProperties: false
                )
            ],
            required: ["name", "date", "location", "attendees"],
            additionalProperties: false
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
        guard let decodedAttendeeItems = decodedProperties["attendees"]?.items?.items,
              let expectedAttendeeItems = expectedProperties["attendees"]?.items?.items else {
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
        XCTAssertEqual(decodedPersonProps["hobbies"]?.items?.items?.type, expectedPersonProps["hobbies"]?.items?.items?.type)
        
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
