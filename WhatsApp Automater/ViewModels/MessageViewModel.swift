import Foundation
import UserNotifications
import UIKit

class MessageViewModel: ObservableObject {
    @Published var scheduledMessages: [Message] = []
    @Published var sentMessages: [Message] = []
    
    init() {
        loadMessages()
        requestNotificationPermission()
    }
    
    private func loadMessages() {
        // Load saved messages from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "scheduledMessages"),
           let decoded = try? JSONDecoder().decode([Message].self, from: data) {
            scheduledMessages = decoded.filter { !$0.isSent }
            sentMessages = decoded.filter { $0.isSent }
        }
    }
    
    private func saveMessages() {
        let allMessages = scheduledMessages + sentMessages
        if let encoded = try? JSONEncoder().encode(allMessages) {
            UserDefaults.standard.set(encoded, forKey: "scheduledMessages")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleMessage(_ message: Message) {
        scheduledMessages.append(message)
        scheduleNotification(for: message)
        saveMessages()
    }
    
    private func scheduleNotification(for message: Message) {
        let content = UNMutableNotificationContent()
        content.title = "Scheduled Message"
        content.body = "Time to send message to \(message.recipient) on \(message.platform)"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: message.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: message.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func markMessageAsSent(_ message: Message) {
        if let index = scheduledMessages.firstIndex(where: { $0.id == message.id }) {
            var updatedMessage = scheduledMessages[index]
            updatedMessage.isSent = true
            updatedMessage.sentDate = Date()
            
            scheduledMessages.remove(at: index)
            sentMessages.append(updatedMessage)
            saveMessages()
        }
    }
    
    func deleteMessage(_ message: Message) {
        if let index = scheduledMessages.firstIndex(where: { $0.id == message.id }) {
            scheduledMessages.remove(at: index)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [message.id.uuidString])
            saveMessages()
        }
    }
    
    private func validatePhoneNumber(_ number: String) -> String? {
        // Remove any non-numeric characters except +
        var cleaned = number.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // Ensure it starts with + and has at least 10 digits
        if !cleaned.hasPrefix("+") {
            cleaned = "+\(cleaned)"
        }
        
        let digitCount = cleaned.filter { $0.isNumber }.count
        guard digitCount >= 10 else { return nil }
        
        return cleaned
    }
    
    func sendWhatsAppMessage(recipient: String, message: String) -> Bool {
        guard let validNumber = validatePhoneNumber(recipient) else {
            print("Invalid phone number format")
            return false
        }
        
        // Pre-format the message with any templates or custom formatting
        let formattedMessage = formatMessage(message)
        
        // Use the API URL format
        let urlString = "https://api.whatsapp.com/send?phone=\(validNumber.dropFirst())&text=\(formattedMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return false
        }
        
        // Check if WhatsApp is installed
        if UIApplication.shared.canOpenURL(url) {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:]) { success in
                    if success {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
            return true
        }
        
        return false
    }
    
    private func formatMessage(_ message: String) -> String {
        // Add any custom formatting, templates, or smart text replacement
        var formattedMessage = message
        
        // Example: Add signature if needed
        if !message.contains("Sent via") {
            formattedMessage += "\n\nSent via WhatsApp Automater"
        }
        
        return formattedMessage
    }
    
    func sendiMessage(recipient: String, message: String) -> Bool {
        let smsUrl = "sms:\(recipient)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let url = URL(string: smsUrl) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
                return true
            }
        }
        return false
    }
} 