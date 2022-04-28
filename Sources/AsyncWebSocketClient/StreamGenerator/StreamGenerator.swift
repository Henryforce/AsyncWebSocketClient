//
//  StreamGenerator.swift
//
//
//  Created by Henry Javier Serrano Echeverria on 13/1/22.
//

import Foundation

// OPTIONAL TODO: move to a different package

actor StreamGenerator<T> {
  var subscribers = [UUID: AsyncStream<T>.Continuation]()

  var value: T { _value }
  var _value: T {
    didSet {
      subscribers.values.forEach { $0.yield(value) }
    }
  }

  init(value: T) {
    self._value = value
  }

  func updateValue(_ value: T) {
    self._value = value
  }

  func subscribe() -> AsyncStream<T> {
    return AsyncStream { continuation in
      let uuid = UUID()
      subscribers[uuid] = continuation

      continuation.onTermination = { @Sendable _ in
        Task { [weak self] in
          await self?.removeSubscriber(with: uuid)
        }
      }
    }
  }

  private func removeSubscriber(with uuid: UUID) {
    subscribers.removeValue(forKey: uuid)
  }

  deinit {
    for key in subscribers.keys {
      guard let subscriber = subscribers[key] else { continue }
      subscriber.finish()
      removeSubscriber(with: key)
    }
  }
}

//public protocol WriteStreamGenerator: Actor {
//    associatedtype Value
//    func updateValue(_ value: Value)
//}
//
//public protocol ReadStreamGenerator: Actor {
//    associatedtype Value
//    var value: Value { get }
//    func subscribe() -> AsyncStream<Value>
//}
