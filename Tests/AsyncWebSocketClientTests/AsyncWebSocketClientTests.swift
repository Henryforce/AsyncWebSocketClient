import XCTest
@testable import AsyncWebSocketClient

final class AsyncWebSocketClientTests: XCTestCase {
    
    var mockSocketTask: MockURLSessionWebSocketTaskWrapper!
    var client: AsyncWebSocketClient!
    
    override func setUp() {
        super.setUp()
        mockSocketTask = MockURLSessionWebSocketTaskWrapper()
        client = AsyncWebSocketClient(webSocketTask: mockSocketTask)
    }
    
    override func tearDown() {
        super.tearDown()
        mockSocketTask = nil
        client = nil
    }
    
    func testConnectionOpened() async throws {
        // Given
        
        // When
        mockSocketTask.waitForResume { // Whenever resume is called, let's emulate a succesfull connection response
            await self.client.socketWasOpened() // Simulate the call from the URLSession delegate
        }
        
        var iterator = await client.listenStream().makeAsyncIterator()
        
        try await client.connect() // Block until the client is connected
        
        let event = await iterator.next()
        
        // Then
        XCTAssertEqual(mockSocketTask.resumeWasCalledCount, 1)
        guard case .socketOpened = event else {
            XCTFail("Invalid event received")
            return
        }
    }
    
    func testConnectionFailedToOpenThrowsAnError() async {
        // Given
        var expectedError: Error?
        
        // When
        mockSocketTask.waitForResume { // Whenever resume is called, let's emulate a succesfull connection response
            await self.client.socketFailedToOpen() // Simulate the call from the URLSession delegate
        }
        do {
            try await client.connect() // Block until the client throws an exception
            XCTFail("An error should have been thrown")
        } catch (let error) {
            expectedError = error
        }
        
        // Then
        XCTAssertEqual(mockSocketTask.resumeWasCalledCount, 1)
        guard case .failedToConnect = expectedError as? AsyncWebSocketError else {
            XCTFail("Invalid error received")
            return
        }
    }
    
    // TODO: remove temp tests
//    func testExample() async throws {
//        let client = AsyncWebSocketClient(url: URL(string: "ws://localhost:8765/")!)
//
//        Task {
//            do {
//                try await client.connect()
//
//                for index in 0..<10 {
//                    try await client.send(.string("Hello \(index)"))
//                    try await Task.sleep(nanoseconds: 1000000000)
//                }
//            } catch (let error) {
//                print("\(error)")
//            }
//        }
//
//        let stream = await client.listenStream()
//        let sequence = stream.map { event -> String in
//            return "Event: \(event)"
//        }
//
//        for await event in sequence {
//            print(event)
//        }
//    }
    
}

// Python script for running echo websocket server. Install websockets before trying...
/*
 
 #!/usr/bin/env python

 import asyncio
 import websockets

 async def echo(websocket):
     async for message in websocket:
         await websocket.send(message)

 async def main():
     async with websockets.serve(echo, "localhost", 8765):
         await asyncio.Future()  # run forever

 asyncio.run(main())
 
 */
