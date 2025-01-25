# AsyncWebSocketClient

![badge-platforms][] [![badge-spm][]][spm]

This is a package that contains a client behaving as an async wrapper for the URLSessionWebSocketTask provided by Apple.

## Usage

```swift
let client = AsyncWebSocketClient(url: URL(string: "ws://localhost:8765/")!)

try await client.connect()

try await client.send(.string("Hello world!")) // Either raw data or strings can be sent

let stream = await client.listenStream() // Returns an AsyncStream of events

for await event in stream {
  print(event) // Print events such as data received, connection opened, connection closed
}
```

## Advanced usage

You can also send encodable objects to the client:

```swift
struct MyEncodableObject: Encodable, Sendable {
  let title: String
}

let objectToEncode = MyEncodableObject(title: "Title")

try await client.sendJSONData(objectToEncode)
```

## How to test

AsyncWebSocketClient conforms to AsyncWebSocketClientProtocol and it is recommended to use dependency injection to make testing easier. For convenience, this library also includes a mock target `AsyncWebSocketClientMocks` which you can use if you just need a simple mock. You could optionally add your own mock class conforming to AsyncWebSocketClientProtocol.

## Installation

### Swift Package Manager

In Xcode, select File --> Swift Packages --> Add Package Dependency and then add the following url:

```swift
https://github.com/Henryforce/AsyncWebSocketClient
```

[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg

[badge-spm]: https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg

[spm]: https://github.com/apple/swift-package-manager
