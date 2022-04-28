//
//  MockURLSessionWebSocketTaskWrapper.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 12/1/22.
//

import Foundation

@testable import AsyncWebSocketClient

final class MockURLSessionWebSocketTaskWrapper: URLSessionWebSocketTaskWrapper {
  init() {}

  var resumeWasCalledCount = 0
  func wrappedResume() {
    resumeWasCalledCount += 1

    if let savedHandler = savedHandler {
      Task {
        await savedHandler()
        self.savedHandler = nil
      }
    }
  }

  typealias ResumeHandler = () async -> Void
  var savedHandler: ResumeHandler?
  func waitForResume(_ handler: @escaping ResumeHandler) {
    savedHandler = handler
  }

  typealias CancelData = (URLSessionWebSocketTask.CloseCode, Data?)
  var cancelWasCalledStack = [CancelData]()
  func wrappedCancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    cancelWasCalledStack.append((closeCode, reason))
  }

  var sendWasCalledStack = [URLSessionWebSocketTask.Message]()
  var sendError: Error?
  func wrappedSend(
    _ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void
  ) {
    sendWasCalledStack.append(message)
    completionHandler(sendError)
  }

  typealias ReceiveHandler = (Result<URLSessionWebSocketTask.Message, Error>) -> Void
  var receiveWasCalledCount = 0
  var receiveValues = [Result<URLSessionWebSocketTask.Message, Error>]()
  var receiveHandler: ReceiveHandler?
  func wrappedReceive(
    completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void
  ) {
    receiveWasCalledCount += 1

    guard !receiveValues.isEmpty else {
      receiveHandler = completionHandler
      return
    }
    let firstValue = receiveValues.removeFirst()
    completionHandler(firstValue)
  }

  var sendPingWasCalledCount = 0
  var sendPingErrors = [Error]()
  func wrappedSendPing(pongReceiveHandler: @escaping (Error?) -> Void) {
    sendPingWasCalledCount += 1

    guard !sendPingErrors.isEmpty else { return }
    let firstError = sendPingErrors.removeFirst()
    pongReceiveHandler(firstError)
  }

  func cleanup() {
    guard let receiveHandler = receiveHandler else { return }
    receiveHandler(.failure(AsyncWebSocketError.unknownError(nil)))
  }
}
