//
//  SchemaProducerTests.swift
//  
//
//  Created by Peter Liddle on 8/27/24.
//

import XCTest
@testable import App
import OpenAIKit
import SwiftyPrompts

final class SchemaProducerTests: XCTestCase {
    
    func testSchemaProducerB() throws {
        let dummy = NavigationDiscoveryIdentificationLLMResponse(identifiedComponents: [NavigationDiscoverLLMResponse(id: "", context: "")])
        let schema = SwiftyPrompts.JsonSchemaCreator.createJSONSchema(for: dummy)
        print(schema)
    }
    
    func testSchemaProducerProducesSchema() throws {
        
        let a = NavigationDiscoverLLMResponse(id: "One", context: "One A")
        let b = NavigationDiscoverLLMResponse(id: "Two", context: "Two A")
        
        let testObject = NavigationDiscoveryIdentificationLLMResponse(identifiedComponents: [a, b])
        
        let schemaB = try SwiftyPrompts.JsonSchemaCreator.createJSONSchema(for: testObject)
        let json = try JSONEncoder().encode(schemaB)
        
        print(schemaB.debugDescription)
    }
    
    func testCreateOutputJSON() throws {
        
        let testData = NavigationDiscoveryIdentificationLLMResponse(identifiedComponents:
                                                                        [NavigationDiscoverLLMResponse(id: "One", context: "One A"),
                                                                         NavigationDiscoverLLMResponse(id: "Two", context: "Two A")])
        
        let json = try JSONEncoder().encode(testData)
        print(String(data: json, encoding: .utf8))
    }
    
    func testSchemaFromJSON() throws {
        
        
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
        let object = try JSONDecoder().decode(SwiftyPrompts.JSONSchema.self, from: data)
        
        let jsonData = try JSONEncoder().encode(object)
        
        let jsonForPrint = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
        let prettyPrintData = try JSONSerialization.data(withJSONObject: jsonForPrint, options: .prettyPrinted)
        
        print(String(data: prettyPrintData, encoding: .utf8)!)
        
    }
    
    
    func testSchemaBFromJSON() throws {
        
        
        let mockTestSchemaB = """
        {
            "type": "json_schema",
            "json_schema": {
                "name": "MyName",
                "strict": true,
                "schema": {
                    "additionalProperties": false,
                    "properties": {
                        "identifiedComponents": {
                            "items": {
                                "properties": {
                                    "id": {
                                        "additionalProperties": false,
                                        "properties": {
                                            "some": {
                                                "type": "string",
                                                "additionalProperties": false
                                            }
                                        },
                                        "type": "object",
                                        "required": [
                                            "some"
                                        ],
                                        "description": "The identifier of the component in the view hierarchy"
                                    },
                                    "context": {
                                        "additionalProperties": false,
                                        "properties": {
                                            "some": {
                                                "type": "string",
                                                "additionalProperties": false
                                            }
                                        },
                                        "type": "object",
                                        "required": [
                                            "some"
                                        ],
                                        "description": "The full position of the element in the view hierarchy. This should be able to uniquely identifiy the element in the view hierarchy along with id when there are multiple components with the same id. This should not make use of anything that could change in the view hierarchy between runs such as coordinates. For instance this might be the numerical row position of a row in a table or section number of a section in a group"
                                    }
                                },
                                "type": "object",
                                "required": [
                                    "id",
                                    "context"
                                ],
                                "additionalProperties": false
                            },
                            "type": "array",
                            "description": "Components that have been identified to lead to view hierarchy alterations",
                            "additionalProperties": false
                        }
                    },
                    "type": "object",
                    "required": [
                        "identifiedComponents"
                    ],
                    "$schema": "http:\\/\\/json-schema.org\\/draft-07\\/schema#"
                }
            }
        """
        
        let data = mockTestSchemaB.data(using: .utf8)!
        let object = try JSONDecoder().decode(SwiftyPrompts.JSONSchema.self, from: data)
        
        let jsonData = try JSONEncoder().encode(object)
        
        let jsonForPrint = try JSONSerialization.jsonObject(with: jsonData, options: .fragmentsAllowed)
        let prettyPrintData = try JSONSerialization.data(withJSONObject: jsonForPrint, options: .prettyPrinted)
        
        print(String(data: prettyPrintData, encoding: .utf8)!)
        
    }
    
    func testDecoding() throws {
        let mockData = """
        { "identifiedElements": [
                {
                    "elementType": "StaticText",
                    "label": "Home Improvement P...",
                    "isMultipleId": false,
                    "identifier": "Home Improvement P...",
                    "uiTestFunction": "tets func here"
                }]
        }
        """
        
        let newObject = try JSONDecoder().decode(NavigationUITestsLLMResponse.self, from: mockData.data(using: .utf8)!)
        
        print(newObject)
    }
}
