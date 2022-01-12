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
    func wrappedSend(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
    func wrappedReceive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
}

extension URLSessionWebSocketTask: URLSessionWebSocketTaskWrapper {
    func wrappedResume() {
        resume()
    }
    
    func wrappedCancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        cancel(with: closeCode, reason: reason)
    }
    
    func wrappedSend(_ message: Message, completionHandler: @escaping (Error?) -> Void) {
        send(message, completionHandler: completionHandler)
    }
    
    func wrappedReceive(completionHandler: @escaping (Result<Message, Error>) -> Void) {
        receive(completionHandler: completionHandler)
    }
}
