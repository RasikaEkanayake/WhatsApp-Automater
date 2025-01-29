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
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Messages List View
                MessagesList(viewModel: messageViewModel)
                    .navigationTitle("Scheduled Messages")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showNewMessageSheet = true
                            }) {
                                Label("New Message", systemImage: "square.and.pencil")
                            }
                            .accessibilityLabel("Create new message")
                        }
                    }
                    .tabItem {
                        Label("Messages", systemImage: "message.fill")
                    }
                    .tag(0)
                
                // Settings View
                SettingsView()
                    .navigationTitle("Settings")
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(1)
            }
        }
        .sheet(isPresented: $showNewMessageSheet) {
            NewMessageView(viewModel: messageViewModel)
        }
        .tint(.green) // WhatsApp brand color
    }
}

struct MessagesList: View {
    @ObservedObject var viewModel: MessageViewModel
    
    var body: some View {
        List {
            Section {
                if viewModel.scheduledMessages.isEmpty {
                    ContentUnavailableView(
                        "No Scheduled Messages",
                        systemImage: "clock",
                        description: Text("Messages you schedule will appear here")
                    )
                } else {
                    ForEach(viewModel.scheduledMessages) { message in
                        ScheduledMessageRow(message: message)
                            .swipeActions(allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        viewModel.deleteMessage(message)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    withAnimation {
                                        viewModel.markMessageAsSent(message)
                                    }
                                } label: {
                                    Label("Mark as Sent", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            } header: {
                Text("Upcoming")
            }
            
            Section {
                if viewModel.sentMessages.isEmpty {
                    ContentUnavailableView(
                        "No Sent Messages",
                        systemImage: "checkmark.circle",
                        description: Text("Messages you've sent will appear here")
                    )
                } else {
                    ForEach(viewModel.sentMessages) { message in
                        MessageHistoryRow(message: message)
                    }
                }
            } header: {
                Text("Sent")
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: viewModel.scheduledMessages)
        .animation(.default, value: viewModel.sentMessages)
    }
}

struct ScheduledMessageRow: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(message.recipient)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                PlatformBadge(platform: message.platform)
            }
            
            Text(message.messageText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Label {
                Text(formatDate(message.scheduledDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scheduled message to \(message.recipient)")
        .accessibilityHint("Scheduled for \(formatDate(message.scheduledDate))")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct MessageHistoryRow: View {
    let message: Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(message.recipient)
                    .font(.headline)
                Spacer()
                PlatformBadge(platform: message.platform)
            }
            
            Text(message.messageText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(formatDate(message.sentDate ?? message.scheduledDate))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
                Section {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Recipient", text: $recipient)
                                .focused($focusedField, equals: .recipient)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: recipient) { newValue in
                                    let filtered = newValue.filter { $0.isNumber || $0 == "+" }
                                    if filtered != newValue {
                                        recipient = filtered
                                    }
                                    if !filtered.isEmpty && !filtered.hasPrefix("+") {
                                        recipient = "+\(filtered)"
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            
                            Button {
                                focusedField = nil
                                showContactPicker = true
                            } label: {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .imageScale(.large)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        Picker("Platform", selection: $selectedPlatform) {
                            ForEach(platforms, id: \.self) { platform in
                                Text(platform).tag(platform)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .topLeading) {
                                if messageText.isEmpty {
                                    Text("Type your message...")
                                        .foregroundColor(.gray.opacity(0.8))
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                
                                TextEditor(text: $messageText)
                                    .focused($focusedField, equals: .message)
                                    .frame(minHeight: 100, maxHeight: 200)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Message Details")
                }
                
                Section {
                    DatePicker("Send Time",
                              selection: $scheduledDate,
                              displayedComponents: [.date, .hourAndMinute])
                } header: {
                    Text("Schedule")
                }
                
                Section {
                    Button {
                        focusedField = nil
                        sendMessage()
                    } label: {
                        Text("Send Now")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(recipient.isEmpty || messageText.isEmpty ? Color.gray.opacity(0.2) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(recipient.isEmpty || messageText.isEmpty)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        focusedField = nil
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
        }
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView(contact: $recipient)
                .ignoresSafeArea()
        }
        .alert("Message Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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

struct PlatformBadge: View {
    let platform: String
    
    var body: some View {
        Label(platform, systemImage: platform == "WhatsApp" ? "phone.circle.fill" : "message.fill")
            .font(.caption.bold())
            .foregroundStyle(platform == "WhatsApp" ? .green : .blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
