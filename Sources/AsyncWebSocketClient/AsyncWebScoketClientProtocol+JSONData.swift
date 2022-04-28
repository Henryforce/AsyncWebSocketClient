//
//  AsyncWebSocketClientProtocol+JSONData.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

extension AsyncWebSocketClientProtocol {
  public func sendJSONData<T: Encodable>(
    _ data: T,
    encoder: JSONEncoder = JSONEncoder()
  ) async throws {
    let encodedData = try encoder.encode(data)
    try await send(.data(encodedData))
  }
}
