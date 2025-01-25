//
//  URLSessionWebSocketTaskWrapper.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 12/1/22.
//

import Foundation

protocol URLSessionWebSocketTaskWrapper {
  func wrappedResume()
  func wrappedCancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
  func wrappedSend(
    _ message: URLSessionWebSocketTask.Message,
    completionHandler: @Sendable @escaping (Error?) -> Void
  )
  func wrappedReceive(
    completionHandler: @Sendable @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
  func wrappedSendPing(pongReceiveHandler: @Sendable @escaping (Error?) -> Void)
}

extension URLSessionWebSocketTask: URLSessionWebSocketTaskWrapper {
  func wrappedResume() {
    resume()
  }

  func wrappedCancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    cancel(with: closeCode, reason: reason)
  }

  func wrappedSend(_ message: Message, completionHandler: @Sendable @escaping (Error?) -> Void) {
    send(message, completionHandler: completionHandler)
  }

  func wrappedReceive(completionHandler: @Sendable @escaping (Result<Message, Error>) -> Void) {
    receive(completionHandler: completionHandler)
  }

  func wrappedSendPing(pongReceiveHandler: @Sendable @escaping (Error?) -> Void) {
    sendPing { error in
      pongReceiveHandler(error)
    }
  }
}
