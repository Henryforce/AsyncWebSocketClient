//
//  AsyncWebSocketData.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

public enum AsyncWebSocketData {
    case data(Data)
    case string(String)
}

extension AsyncWebSocketData {
   
    var message: URLSessionWebSocketTask.Message {
        switch self {
        case .data(let data):
            return .data(data)
        case .string(let string):
            return .string(string)
        }
    }
    
    var event: AsyncWebSocketEvent {
        return .dataReceived(self)
    }
    
}
