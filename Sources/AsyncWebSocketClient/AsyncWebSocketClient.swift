//
//  AsyncWebSocketClient.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import AsyncTimeSequences
import Foundation

public actor AsyncWebSocketClient: NSObject, AsyncWebSocketClientProtocol {

  private var webSocketTask: URLSessionWebSocketTaskWrapper?
  private var urlSession: URLSession!
  private var connectContinuation: CheckedContinuation<Void, Error>?
  private var streamContinuation: AsyncStream<AsyncWebSocketEvent>.Continuation?
  private let streamGenerator = StreamGenerator(value: Int.zero)
  private let scheduler: AsyncScheduler

  enum Constants {
    static let debounceTime: TimeInterval = 20.0
  }

  // TODO: add a dequeue to keep track of events that could be missed by a subscriber if the stream is not requested

  public init(url: URL, scheduler: AsyncScheduler = MainAsyncScheduler.default) {
    self.scheduler = scheduler
    super.init()
    self.urlSession = URLSession(
      configuration: .default,
      delegate: self,
      delegateQueue: nil
    )
    webSocketTask = urlSession.webSocketTask(with: url)
  }

  init(webSocketTask: URLSessionWebSocketTaskWrapper, scheduler: AsyncScheduler) {
    self.webSocketTask = webSocketTask
    self.scheduler = scheduler
    super.init()
  }

  public func connect() async throws {
    guard let webSocketTask = webSocketTask else { throw AsyncWebSocketError.invalidSocket }
    return try await withCheckedThrowingContinuation { continuation in
      connectContinuation = continuation
      webSocketTask.wrappedResume()
    }
  }

  /// Disconnects but keeps the stream open
  public func disconnect() async throws {
    guard let webSocketTask = webSocketTask else { throw AsyncWebSocketError.invalidSocket }
    webSocketTask.wrappedCancel(with: .goingAway, reason: nil)
    self.webSocketTask = nil
  }

  /// Disconnects and closes the stream
  public func close() async throws {
    try await disconnect()
    finishStream()
  }

  public func send(_ data: AsyncWebSocketData) async throws {
    guard let webSocketTask = webSocketTask else { throw AsyncWebSocketError.invalidSocket }

    try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
      webSocketTask.wrappedSend(data.message) { error in
        if let error = error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume()
      }
    })
  }

  /// Starts to listen to events. Only one active stream is allowed at all times.
  public func listenStream() async -> AsyncStream<AsyncWebSocketEvent> {
    return AsyncStream { continuation in
      if let savedContinuation = streamContinuation {  // If there is an open stream, close it
        savedContinuation.finish()
        streamContinuation = nil
      }
      streamContinuation = continuation
    }
  }

  func processReceivedResult(_ result: Result<URLSessionWebSocketTask.Message, Error>) {
    switch result {
    case .failure(let error):
      updateStream(with: error)
    case .success(let message):
      let socketData: AsyncWebSocketData

      switch message {
      case .string(let text):
        socketData = .string(text)
      case .data(let data):
        socketData = .data(data)
      @unknown default:
        fatalError()
      }

      resetPingPong()
      updateStream(with: socketData)
      listen()
    }
  }

  func socketWasOpened() {
    if let connectContinuation = connectContinuation {
      connectContinuation.resume()
      self.connectContinuation = nil
    }
    startPingPongHandler()
    updateStream(with: .socketOpened)
    listen()
  }

  func socketFailedToOpen() {
    guard let connectContinuation = connectContinuation else { return }
    connectContinuation.resume(throwing: AsyncWebSocketError.failedToConnect)
    self.connectContinuation = nil
  }

  func listen() {
    webSocketTask?.wrappedReceive { result in
      Task { [weak self] in
        await self?.processReceivedResult(result)
      }
    }
  }

  /// A debouncing behavior is implemented to send a ping-pong every time after 20 seconds
  /// have elapsed since the last time an event happened or this function was initially called.
  func startPingPongHandler() {
    Task { [weak self, streamGenerator, scheduler] in
      let stream = await streamGenerator.subscribe()

      let debouncedStream = stream.debounce(for: Constants.debounceTime, scheduler: scheduler)

      // Start debouncing now
      await streamGenerator.updateValue(.zero)

      for await _ in debouncedStream {
        guard let self = self else { break }
        await self.performPingPong()
      }
    }
  }

  func updateStream(with event: AsyncWebSocketEvent) {
    streamContinuation?.yield(event)
  }

  private func updateStream(with data: AsyncWebSocketData) {
    streamContinuation?.yield(data.event)
  }

  private func updateStream(with error: Error) {
    streamContinuation?.yield(.socketClosed(error))
  }

  private func performPingPong() {
    webSocketTask?.wrappedSendPing(pongReceiveHandler: { error in
      guard let error = error else { return }
      Task { [weak self] in
        await self?.terminate(with: error)
      }
    })
  }

  private func resetPingPong() {
    Task {
      await streamGenerator.updateValue(.zero)
    }
  }

  private func terminate(with error: Error) {
    webSocketTask?.wrappedCancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    updateStream(with: .socketClosed(error))
  }

  private func finishStream() {
    streamContinuation?.finish()
    streamContinuation = nil
  }

}
