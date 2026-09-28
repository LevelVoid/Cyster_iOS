import Foundation
internal import CoreData

@objc(CDChatMessage)
class CDChatMessage: NSManagedObject {

    func toChatMessage() -> ChatMessage {
        return ChatMessage(
            text: text ?? "",
            sender: senderRaw == "user" ? .user : .ai,
            timestamp: timestamp ?? Date()
        )
    }
}
