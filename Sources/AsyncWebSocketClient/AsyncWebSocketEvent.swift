//
//  AsyncWebSocketEvent.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

public enum AsyncWebSocketEvent: Sendable {
  case socketOpened
  case socketClosed(Error?)
  case dataReceived(AsyncWebSocketData)
}
