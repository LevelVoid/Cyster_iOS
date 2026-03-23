//
//  ChatMessage.swift
//  PCOS_App
//
//  Created by SDC-USER on 23/03/26.
//
import Foundation

enum MessageSender {
    case user
    case ai
}

struct ChatMessage: Identifiable {
    let id: UUID = UUID()
    let text: String
    let sender: MessageSender
    let timestamp: Date
    
    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: timestamp)
    }
    
    init(text: String, sender: MessageSender, timestamp: Date = Date()) {
        self.text = text
        self.sender = sender
        self.timestamp = timestamp
    }
}
