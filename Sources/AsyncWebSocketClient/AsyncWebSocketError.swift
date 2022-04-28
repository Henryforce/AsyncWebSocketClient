//
//  AsyncWebSocketError.swift
//  AsyncWebSocketClient
//
//  Created by Henry Javier Serrano Echeverria on 11/1/22.
//

import Foundation

enum AsyncWebSocketError: Error {
  case invalidSocket
  case failedToConnect
  case unknownError(Error?)
}
