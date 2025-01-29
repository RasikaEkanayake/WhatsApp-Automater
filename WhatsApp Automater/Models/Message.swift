import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let recipient: String
    let messageText: String
    let platform: String
    let scheduledDate: Date
    var isSent: Bool
    var sentDate: Date?
    
    init(recipient: String, messageText: String, platform: String, scheduledDate: Date) {
        self.id = UUID()
        self.recipient = recipient
        self.messageText = messageText
        self.platform = platform
        self.scheduledDate = scheduledDate
        self.isSent = false
        self.sentDate = nil
    }
} 