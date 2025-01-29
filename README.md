# WhatsApp Automater

WhatsApp Automater is a tool designed to automate interactions with WhatsApp, providing a seamless experience for scheduling and sending messages.

## Development Status

**Note:** Development of this project is currently paused. Future updates and enhancements are on hold until further notice.

## Features

- Schedule messages to be sent at a specific time.
- Automate repetitive tasks on WhatsApp.
- Easy-to-use interface for managing automated tasks.

## Requirements

- iOS 13.0 or later
- Xcode 12.0 or later
- Swift 5.0 or later

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/whatsapp-automater.git
   ```
2. Open the project in Xcode:
   ```bash
   cd whatsapp-automater
   open WhatsApp\ Automater.xcodeproj
   ```
3. Build and run the project on your simulator or device.

## Configuration

To allow HTTP connections during development, ensure your `Info.plist` is configured as follows:
xml
<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
<key>NSExceptionDomains</key>
<dict>
<key>devlk.com</key>
<dict>
<key>NSExceptionAllowsInsecureHTTPLoads</key>
<true/>
<key>NSIncludesSubdomains</key>
<true/>
</dict>
</dict>
</dict>

## Usage

1. Launch the app on your device.
2. Navigate to the scheduling section.
3. Set up your message and schedule it for a specific time.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any enhancements or bug fixes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

For any inquiries or support, please contact [rasika@devlk.com](mailto:rasika@devlk.com).
