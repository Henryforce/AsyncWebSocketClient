//
//  MockURLSessionWebSocketTaskWrapper.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 12/1/22.
//

import Foundation
@testable import AsyncWebSocketClient

final class MockURLSessionWebSocketTaskWrapper: URLSessionWebSocketTaskWrapper {
    init() { }
    
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
    
    typealias SendData = (URLSessionWebSocketTask.Message, (Error?) -> Void)
    var sendWasCalledStack = [SendData]()
    func wrappedSend(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void) {
        sendWasCalledStack.append((message, completionHandler))
    }
    
    typealias ReceiveData = (Result<URLSessionWebSocketTask.Message, Error>) -> Void
    var receiveWasCalledStack = [ReceiveData]()
    func wrappedReceive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
        receiveWasCalledStack.append(completionHandler)
    }
}
