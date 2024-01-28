//
//  AsyncWebSocketClientMock.swift
//
//
//  Created by Henry Javier Serrano Echeverria on 27/1/24.
//

import AsyncWebSocketClient
import Foundation

open class AsyncWebSocketClientMock: AsyncWebSocketClientProtocol {
  public var connectWasCalledCount = 0
  public func connect() async throws {
    connectWasCalledCount += 1
  }

  public var disconnectWasCalledCount = 0
  public func disconnect() async throws {
    disconnectWasCalledCount += 1
  }

  public var sendWasCalledStack = [AsyncWebSocketData]()
  public func send(_ data: AsyncWebSocketData) async throws {
    sendWasCalledStack.append(data)
  }

  @Published public var streamSocketEvent = AsyncWebSocketEvent.socketOpened
  public var listenStreamWasCalledCount = 0
  public func listenStream() async -> AsyncStream<AsyncWebSocketEvent> {
    listenStreamWasCalledCount += 1

    let stream = $streamSocketEvent.values
    return AsyncStream { continuation in
      let cancellableTask = Task {
        for await event in stream {
          try Task.checkCancellation()
          continuation.yield(event)
        }
      }
      // Cancel the task that is listening to the stream socket event.
      continuation.onTermination = { _ in
        cancellableTask.cancel()
      }
    }
  }

  public init() {

  }

}
