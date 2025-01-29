import Foundation

class BackendService {
    private let baseURL = "http://www.devlk.com/whatsapp_server.php"
    
    func scheduleMessage(recipient: String, message: String, scheduledTime: Date) async throws {
        // Check if the scheduled time is in the future
        guard scheduledTime > Date() else {
            throw URLError(.badServerResponse)
        }
        
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "recipient": recipient,
            "message": message,
            "scheduledTime": ISO8601DateFormatter().string(from: scheduledTime)
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool,
                  success else {
                throw URLError(.badServerResponse)
            }
        } catch {
            print("Network error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func checkMessageStatus() async throws -> [Message] {
        guard let url = URL(string: "\(baseURL)/check_status.php") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool,
                  success,
                  let messages = json["messages"] as? [[String: Any]] else {
                throw URLError(.badServerResponse)
            }
            
            return messages.compactMap { messageData in
                guard let id = messageData["id"] as? String,
                      let recipient = messageData["recipient"] as? String,
                      let messageText = messageData["message"] as? String,
                      let scheduledTimeString = messageData["scheduledTime"] as? String,
                      let scheduledTime = ISO8601DateFormatter().date(from: scheduledTimeString) else {
                    return nil
                }
                
                return Message(
                    recipient: recipient,
                    messageText: messageText,
                    platform: "WhatsApp",
                    scheduledDate: scheduledTime
                )
            }
        } catch {
            print("Network error: \(error.localizedDescription)")
            throw error
        }
    }
} 
