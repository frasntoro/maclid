import Foundation

enum AppInfo {
    static let name = "MacLid"
    static let tagline = "The blur follows your lid."
    static let author = "frasntoro"
    static let releasesURL = URL(string: "https://github.com/frasntoro/maclid/releases")!

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "development"
    }
}
