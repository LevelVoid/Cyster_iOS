import Foundation
import CoreData

@objc(CDChatMessage)
public class CDChatMessage: NSManagedObject {

    func toChatMessage() -> ChatMessage {
        return ChatMessage(
            text: text ?? "",
            sender: senderRaw == "user" ? .user : .ai,
            timestamp: timestamp ?? Date()
        )
    }
}
