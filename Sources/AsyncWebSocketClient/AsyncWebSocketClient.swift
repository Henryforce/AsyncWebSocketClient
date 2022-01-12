//
//  AsyncWebSocketClient.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

public actor AsyncWebSocketClient: NSObject, AsyncWebSocketClientProtocol {
    
    private var webSocketTask: URLSessionWebSocketTaskWrapper?
    private var urlSession: URLSession!
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var streamContinuation: AsyncStream<AsyncWebSocketEvent>.Continuation?
    
    // TODO: add a dequeue to keep track of events that could be missed by a subscriber if the stream is not requested
    
    public init(url: URL) {
        super.init()
        self.urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: nil
        )
        webSocketTask = urlSession.webSocketTask(with: url)
    }
    
    init(webSocketTask: URLSessionWebSocketTaskWrapper) {
        super.init()
        self.webSocketTask = webSocketTask
    }
    
    public func connect() async throws {
        guard let webSocketTask = webSocketTask else { throw AsyncWebSocketError.invalidSocket }
        return try await withCheckedThrowingContinuation { continuation in
            connectContinuation = continuation
            webSocketTask.wrappedResume()
        }
    }
    
    public func disconnect() async throws {
        guard let webSocketTask = webSocketTask else { throw AsyncWebSocketError.invalidSocket }
        webSocketTask.wrappedCancel(with: .goingAway, reason: nil)
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
    
    public func listenStream() async -> AsyncStream<AsyncWebSocketEvent> {
        return AsyncStream { continuation in
            if let savedContinuation = streamContinuation { // If there is an open stream, close it
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
            
            updateStream(with: socketData)
            listen()
        }
    }
    
    func socketWasOpened() {
        if let connectContinuation = connectContinuation {
            connectContinuation.resume()
            self.connectContinuation = nil
        }
        updateStream(with: .socketOpened)
        listen()
    }
    
    func socketFailedToOpen() {
        guard let connectContinuation = connectContinuation else { return }
        connectContinuation.resume(throwing: AsyncWebSocketError.failedToConnect)
        self.connectContinuation = nil
    }
    
    private func listen()  {
        webSocketTask?.wrappedReceive { result in
            Task { [weak self] in
                await self?.processReceivedResult(result)
            }
        }
    }
    
    private func updateStream(with data: AsyncWebSocketData) {
        streamContinuation?.yield(data.event)
    }
    
    private func updateStream(with error: Error) {
        streamContinuation?.yield(.socketClosed(error))
    }
    
    private func updateStream(with event: AsyncWebSocketEvent) {
        streamContinuation?.yield(event)
    }
}

extension AsyncWebSocketClient: URLSessionWebSocketDelegate {
    nonisolated public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task {
            await socketWasOpened()
        }
    }
    
    nonisolated public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task {
            await updateStream(with: .socketClosed(nil))
        }
    }
    
    nonisolated public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        Task {
            await socketFailedToOpen()
        }
    }
}
