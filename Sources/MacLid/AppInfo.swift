import Foundation

enum AppInfo {
    static let name = "MacLid"
    static let tagline = "The blur follows your lid."
    static let author = "Francesco Santoro"
    static let handle = "frasntoro"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "sviluppo"
    }
}
