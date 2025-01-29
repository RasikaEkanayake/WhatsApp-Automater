//
//  ContentView.swift
//  WhatsApp Automater
//
//  Created by Rasika Ekanayaka on 2025-01-29.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var messageViewModel = MessageViewModel()
    @State private var selectedTab = 0
    @State private var showNewMessageSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Messages List View
            NavigationView {
                MessagesList(viewModel: messageViewModel)
                    .navigationTitle("Scheduled Messages")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showNewMessageSheet = true
                            }) {
                                Image(systemName: "square.and.pencil")
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "message.fill")
                Text("Messages")
            }
            .tag(0)
            
            // Settings View
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(1)
        }
        .sheet(isPresented: $showNewMessageSheet) {
            NewMessageView(viewModel: messageViewModel)
        }
    }
}

struct MessagesList: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        List {
            Section(header: Text("Upcoming")) {
                if viewModel.scheduledMessages.isEmpty {
                    Text("No scheduled messages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.scheduledMessages) { message in
                        ScheduledMessageRow(recipient: message.recipient,
                                         message: message.messageText,
                                         time: formatDate(message.scheduledDate),
                                         platform: message.platform)
                            .swipeActions {
                                Button(role: .destructive) {
                                    viewModel.deleteMessage(message)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    viewModel.markMessageAsSent(message)
                                } label: {
                                    Label("Mark as Sent", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
            
            Section(header: Text("Sent")) {
                if viewModel.sentMessages.isEmpty {
                    Text("No sent messages")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.sentMessages) { message in
                        MessageHistoryRow(recipient: message.recipient,
                                        message: message.messageText,
                                        sentTime: formatDate(message.sentDate ?? message.scheduledDate),
                                        platform: message.platform)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ScheduledMessageRow: View {
    let recipient: String
    let message: String
    let time: String
    let platform: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recipient)
                    .font(.headline)
                Spacer()
                Image(systemName: platform == "WhatsApp" ? "phone.circle.fill" : "message.fill")
                    .foregroundColor(platform == "WhatsApp" ? .green : .blue)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MessageHistoryRow: View {
    let recipient: String
    let message: String
    let sentTime: String
    let platform: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipient)
                    .font(.headline)
                Spacer()
                Image(systemName: platform == "WhatsApp" ? "phone.circle.fill" : "message.fill")
                    .foregroundColor(platform == "WhatsApp" ? .green : .blue)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(sentTime)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text("Accounts")) {
                NavigationLink(destination: Text("WhatsApp Settings")) {
                    Label("WhatsApp", systemImage: "phone.circle.fill")
                        .foregroundColor(.green)
                }
                
                NavigationLink(destination: Text("iMessage Settings")) {
                    Label("iMessage", systemImage: "message.fill")
                        .foregroundColor(.blue)
                }
            }
            
            Section(header: Text("Preferences")) {
                NavigationLink(destination: Text("Notifications")) {
                    Label("Notifications", systemImage: "bell.fill")
                }
                
                NavigationLink(destination: Text("Default Settings")) {
                    Label("Default Settings", systemImage: "gearshape.fill")
                }
            }
        }
    }
}

struct NewMessageView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: MessageViewModel
    @State private var recipient = ""
    @State private var messageText = ""
    @State private var scheduledDate = Date()
    @State private var selectedPlatform = "WhatsApp"
    @State private var showContactPicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case recipient, message
    }
    
    let platforms = ["WhatsApp", "iMessage"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Message Details")) {
                    HStack {
                        TextField("Recipient", text: $recipient)
                            .focused($focusedField, equals: .recipient)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .onChange(of: recipient) { newValue in
                                // Format the phone number as the user types
                                let filtered = newValue.filter { $0.isNumber || $0 == "+" }
                                if filtered != newValue {
                                    recipient = filtered
                                }
                                
                                // Automatically add + if user starts typing numbers
                                if !filtered.isEmpty && !filtered.hasPrefix("+") {
                                    recipient = "+\(filtered)"
                                }
                            }
                            .overlay(
                                Group {
                                    if recipient.isEmpty {
                                        HStack {
                                            Text("+1")
                                                .foregroundColor(.gray)
                                                .padding(.leading, 4)
                                            Spacer()
                                        }
                                    }
                                }
                            )
                        
                        Button(action: {
                            focusedField = nil
                            showContactPicker = true
                        }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 4)
                    }
                    
                    Picker("Platform", selection: $selectedPlatform) {
                        ForEach(platforms, id: \.self) { platform in
                            Text(platform)
                                .tag(platform)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        if messageText.isEmpty {
                            Text("Type your message...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $messageText)
                            .focused($focusedField, equals: .message)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Send Time",
                              selection: $scheduledDate,
                              displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Button(action: {
                        focusedField = nil // Dismiss keyboard
                        sendMessage()
                    }) {
                        Text("Send Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .disabled(recipient.isEmpty || messageText.isEmpty)
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        focusedField = nil // Dismiss keyboard
                        let newMessage = Message(
                            recipient: recipient,
                            messageText: messageText,
                            platform: selectedPlatform,
                            scheduledDate: scheduledDate
                        )
                        viewModel.scheduleMessage(newMessage)
                        dismiss()
                    }
                    .disabled(recipient.isEmpty || messageText.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showContactPicker, onDismiss: nil) {
                ContactPickerView(contact: $recipient)
                    .ignoresSafeArea()
            }
            .alert("Message Status", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func sendMessage() {
        var success = false
        if selectedPlatform == "WhatsApp" {
            success = viewModel.sendWhatsAppMessage(recipient: recipient, message: messageText)
        } else {
            success = viewModel.sendiMessage(recipient: recipient, message: messageText)
        }
        
        showAlert = true
        alertMessage = success ? "Message opened in \(selectedPlatform)" : "Failed to open \(selectedPlatform)"
    }
}

#Preview {
    ContentView()
}
