import SwiftUI
import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var contact: String
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        
        // Configure picker to show only phone numbers
        picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        picker.predicateForSelectionOfProperty = NSPredicate(
            format: "key == 'phoneNumbers'"
        )
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView
        
        init(_ parent: ContactPickerView) {
            self.parent = parent
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            DispatchQueue.main.async {
                self.parent.dismiss()
            }
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            handleContactSelection(contact)
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
            if let phoneNumber = contactProperty.value as? CNPhoneNumber {
                formatAndSetPhoneNumber(phoneNumber.stringValue)
            }
        }
        
        private func handleContactSelection(_ contact: CNContact) {
            // If contact has multiple numbers, let user pick one
            if contact.phoneNumbers.count > 1 {
                // The picker will call didSelect contactProperty with the selected number
                return
            }
            
            // If contact has only one number, use it directly
            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                formatAndSetPhoneNumber(phoneNumber)
            }
        }
        
        private func formatAndSetPhoneNumber(_ phoneNumber: String) {
            // Remove any non-numeric characters except +
            var formattedNumber = phoneNumber.replacingOccurrences(
                of: "[^0-9+]",
                with: "",
                options: .regularExpression
            )
            
            // Ensure number starts with +
            if !formattedNumber.hasPrefix("+") {
                // Add default country code if none present
                formattedNumber = "+1" + formattedNumber
            }
            
            DispatchQueue.main.async {
                self.parent.contact = formattedNumber
                self.parent.dismiss()
            }
        }
    }
} 