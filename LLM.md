# SwiftyJsonSchema Library Guide for LLMs

## Overview

SwiftyJsonSchema is a Swift library that automatically generates JSON Schema definitions from Swift `Codable` objects. This library simplifies the process of creating JSON Schema documentation for your data models by leveraging Swift's reflection capabilities.

## Key Features

- Generate JSON Schema (Draft-07) from any Swift `Codable` object
- Add descriptions to properties using the `@SchemaInfo` property wrapper
- Support for all basic Swift types and their arrays
- Support for nested objects and arrays of objects
- Customizable schema ID and schema URL

## Installation

Add SwiftyJsonSchema to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/ptliddle/swifty-json-schema.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SwiftyJsonSchema"]),
]
```

## Basic Usage

### 1. Import the library

```swift
import SwiftyJsonSchema
```

### 2. Define your Swift model with Codable

```swift
struct Person: Codable {
    var name: String
    var age: Int
    var isActive: Bool
    var height: Double?
}
```

### 3. Generate JSON Schema

```swift
let person = Person(name: "John Doe", age: 30, isActive: true)
let schema = JsonSchemaCreator.createJSONSchema(for: person)

// Print the schema as JSON
print(schema.debugDescription)
```

This will output a JSON Schema like:

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "age": {
      "type": "integer"
    },
    "isActive": {
      "type": "boolean"
    },
    "height": {
      "type": "number"
    }
  },
  "required": ["name", "age", "isActive"]
}
```

## Adding Property Descriptions

Use the `@SchemaInfo` property wrapper to add descriptions to your properties:

```swift
struct Person: Codable {
    @SchemaInfo(description: "The person's full name")
    var name: String
    
    @SchemaInfo(description: "Age in years")
    var age: Int
    
    @SchemaInfo(description: "Whether the person is currently active")
    var isActive: Bool
    
    @SchemaInfo(description: "Height in meters")
    var height: Double?
}
```

The generated schema will include these descriptions:

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "The person's full name"
    },
    "age": {
      "type": "integer",
      "description": "Age in years"
    },
    "isActive": {
      "type": "boolean",
      "description": "Whether the person is currently active"
    },
    "height": {
      "type": "number",
      "description": "Height in meters"
    }
  },
  "required": ["name", "age", "isActive"]
}
```

## Advanced Usage

### Custom Schema ID and Schema URL

You can specify a custom schema ID and schema URL:

```swift
let schema = JsonSchemaCreator.createJSONSchema(
    for: person,
    id: "https://example.com/schemas/person.json",
    schema: "http://json-schema.org/draft-07/schema#"
)
```

### Nested Objects

The library handles nested objects automatically:

```swift
struct Address: Codable {
    var street: String
    var city: String
    var zipCode: String
}

struct Person: Codable {
    var name: String
    var address: Address
}
```

### Arrays of Objects

Arrays of objects are also supported:

```swift
struct Person: Codable {
    var name: String
    var phoneNumbers: [PhoneNumber]
}

struct PhoneNumber: Codable {
    var type: String
    var number: String
}
```

## Supported Types

SwiftyJsonSchema supports the following Swift types:

- String and [String]
- Int, Int8, Int16, Int32, Int64 and their arrays
- Float, Double and their arrays
- Bool and [Bool]
- Optional types
- Nested Codable objects
- Arrays of Codable objects

## Example Implementation

Here's a complete example showing how to use SwiftyJsonSchema:

```swift
import SwiftyJsonSchema

// Define models
struct Address: Codable {
    @SchemaInfo(description: "Street name and number")
    var street: String
    
    @SchemaInfo(description: "City name")
    var city: String
    
    @SchemaInfo(description: "Postal/ZIP code")
    var zipCode: String
}

struct PhoneNumber: Codable {
    @SchemaInfo(description: "Type of phone (home, work, mobile)")
    var type: String
    
    @SchemaInfo(description: "Phone number with country code")
    var number: String
}

struct Person: Codable {
    @SchemaInfo(description: "The person's full name")
    var name: String
    
    @SchemaInfo(description: "Age in years")
    var age: Int
    
    @SchemaInfo(description: "Whether the person is currently active")
    var isActive: Bool
    
    @SchemaInfo(description: "Residential address")
    var address: Address
    
    @SchemaInfo(description: "List of contact phone numbers")
    var phoneNumbers: [PhoneNumber]
}

// Create an instance
let address = Address(street: "123 Main St", city: "Anytown", zipCode: "12345")
let phoneNumbers = [
    PhoneNumber(type: "home", number: "+1-555-123-4567"),
    PhoneNumber(type: "work", number: "+1-555-987-6543")
]
let person = Person(name: "John Doe", age: 30, isActive: true, address: address, phoneNumbers: phoneNumbers)

// Generate JSON Schema
let schema = JsonSchemaCreator.createJSONSchema(
    for: person,
    id: "https://example.com/schemas/person.json",
    schema: "http://json-schema.org/draft-07/schema#"
)

// Print the schema
print(schema.debugDescription)
```

## Best Practices

1. Always use the `@SchemaInfo` property wrapper to add descriptions to your properties for better documentation.
2. For complex models, generate schemas for each component separately if needed.
3. Use meaningful schema IDs that follow your organization's naming conventions.
4. Consider storing generated schemas as part of your API documentation.

## Limitations

- The library currently supports JSON Schema Draft-07.
- Some advanced JSON Schema features like `oneOf`, `anyOf`, `allOf` are not directly supported.
- Custom validation beyond the basic type system requires manual adjustment of the generated schema.
