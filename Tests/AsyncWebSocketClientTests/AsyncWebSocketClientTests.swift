import XCTest
@testable import AsyncWebSocketClient

final class AsyncWebSocketClientTests: XCTestCase {
    
    // TODO: remove temp tests
    func testExample() async throws {
        let client = AsyncWebSocketClient(url: URL(string: "ws://localhost:8765/")!)
        
        Task {
            do {
                try await client.connect()
                
                for index in 0..<10 {
                    try await client.send(.string("Hello \(index)"))
                    try await Task.sleep(nanoseconds: 1000000000)
                }
            } catch (let error) {
                print("\(error)")
            }
        }
        
        let stream = await client.listenStream()
        let sequence = stream.map { event -> String in
            return "Event: \(event)"
        }

        for await event in sequence {
            print(event)
        }
    }
    
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
