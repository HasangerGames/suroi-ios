import Foundation

class URLModel {

    let internalHost: String = "suroi.io"

    let externalHosts: [String] = [
        "wiki.suroi.io",
        "discord.suroi.io",
        "reddit.com",
        "youtube.com",
        "github.com",
        "bluesky.com",
        "instagram.com",
        "ko-fi.com"
    ]

    func isInternalURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host == internalHost
    }

    func isExternalURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return externalHosts.contains(host) || host != internalHost
    }
}
