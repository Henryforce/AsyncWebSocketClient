//
//  AsyncWebSocketClient+URLSessionWebSocketDelegate.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 13/1/22.
//

import Foundation

extension AsyncWebSocketClient: URLSessionWebSocketDelegate {
  nonisolated public func urlSession(
    _ session: URLSession, webSocketTask: URLSessionWebSocketTask,
    didOpenWithProtocol protocol: String?
  ) {
    Task {
      await socketWasOpened()
    }
  }

  nonisolated public func urlSession(
    _ session: URLSession, webSocketTask: URLSessionWebSocketTask,
    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?
  ) {
    Task {
      await updateStream(with: .socketClosed(nil))
    }
  }

  nonisolated public func urlSession(
    _ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?
  ) {
    Task {
      await socketFailedToOpen()
    }
  }
}
