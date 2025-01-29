import Foundation

struct Message: Identifiable, Codable, Equatable {
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
    
    // Implement Equatable
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.recipient == rhs.recipient &&
        lhs.messageText == rhs.messageText &&
        lhs.platform == rhs.platform &&
        lhs.scheduledDate == rhs.scheduledDate &&
        lhs.isSent == rhs.isSent &&
        lhs.sentDate == rhs.sentDate
    }
} 