//
//  AsyncWebSocketClientProtocol.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

public protocol AsyncWebSocketClientProtocol {
    func connect() async throws
    func disconnect() async throws
    func send(_ data: AsyncWebSocketData) async throws
    func listenStream() async -> AsyncStream<AsyncWebSocketEvent>
}
