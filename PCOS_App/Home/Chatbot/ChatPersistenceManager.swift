import Foundation
import CoreData
import UIKit

final class ChatPersistenceManager {

    static let shared = ChatPersistenceManager()
    private init() {}

    private var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }

    func loadTodaysMessages() -> [ChatMessage] {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let request = NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]

        let results = (try? context.fetch(request)) ?? []
        return results.map { $0.toChatMessage() }
    }

    func saveMessage(text: String, sender: MessageSender) {

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<CDChatMessage>(entityName: "CDChatMessage")
        request.predicate = NSPredicate(format: "timestamp >= %@", startOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        request.fetchLimit = 1

        let lastOrder = (try? context.fetch(request))?.first?.sortOrder ?? -1

        let cdMessage = CDChatMessage(context: context)
        cdMessage.id = UUID()
        cdMessage.text = text
        cdMessage.senderRaw = sender == .user ? "user" : "ai"
        cdMessage.timestamp = Date()
        cdMessage.sortOrder = lastOrder + 1

        save()
    }

    func buildChatSummary() -> String {
        let todaysMessages = loadTodaysMessages()

        guard todaysMessages.count > 1 else { return "" }

        let recentMessages = todaysMessages.suffix(10)

        var lines: [String] = []
        for msg in recentMessages {
            let role = msg.sender == .user ? "User" : "Cyster"

            let content = msg.sender == .ai
                ? String(msg.text.prefix(100)) + (msg.text.count > 100 ? "..." : "")
                : msg.text
            lines.append("\(role): \(content)")
        }

        return """
        [EARLIER TODAY — conversation summary for continuity:]
        \(lines.joined(separator: "\n"))
        [END SUMMARY]
        """
    }

    func clearAllMessages() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDChatMessage")
        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(batchDelete)
            try context.save()

            context.reset()
        } catch {
            print("ERROR: Failed to clear chat messages: \(error)")
        }
    }

    func deleteOldMessages() {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDChatMessage")
        request.predicate = NSPredicate(format: "timestamp < %@", startOfDay as NSDate)

        let batchDelete = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(batchDelete)
            try context.save()
        } catch {
            print("ERROR: Failed to delete old messages: \(error)")
        }
    }

    private func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("ERROR: ChatPersistenceManager save failed: \(error)")
        }
    }
}
