import CoreLocation
import MessageUI
import SwiftUI
import UIKit

/// Presents the system Messages composer for emergency SMS with a maps link.
struct MessageComposeView: UIViewControllerRepresentable {

    let recipients: [String]
    let body: String
    var onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let cleaned = recipients.map { $0.filter(\.isNumber) }.filter { !$0.isEmpty }
        let vc = MFMessageComposeViewController()
        vc.recipients = cleaned
        vc.body = body
        vc.messageComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true) {
                self.onFinish()
            }
        }
    }
}

enum EmergencySMSBuilder {
    static func body(coordinate: CLLocationCoordinate2D?, userName: String) -> String {
        let name = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        let intro = name.isEmpty
            ? "My SafeWalk safety timer just ended."
            : "This is \(name). My SafeWalk safety timer just ended."
        guard let c = coordinate else {
            return "\(intro) I may need help — please check on me."
        }
        let link = "https://maps.apple.com/?ll=\(c.latitude),\(c.longitude)"
        return "\(intro) Here is my last known location: \(link)"
    }

    static func smsURL(phoneDigits: String, body: String) -> URL? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=?")
        let encoded = body.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
        return URL(string: "sms:\(phoneDigits)&body=\(encoded)")
    }
}
