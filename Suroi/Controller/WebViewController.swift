// Credit: Dmitry Yastrebov

import UIKit
import WebKit

final class WebViewController: UIViewController {

    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        return webView
    }()

    private let router: ExternalLinkRouting

    init(router: ExternalLinkRouting = SuroiExternalLinkRouter()) {
        self.router = router
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.router = SuroiExternalLinkRouter()
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        loadInitialURL()
    }

    private func setupLayout() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func loadInitialURL() {
        guard let url = URL(string: "https://suroi.io") else { return }
        webView.load(URLRequest(url: url))
    }

    private func openExternally(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        switch router.destination(for: url) {
        case .inWebView:
            decisionHandler(.allow)
        case .externalBrowser:
            openExternally(url)
            decisionHandler(.cancel)
        }
    }
}

// MARK: - WKUIDelegate (handles target=_blank / window.open)

extension WebViewController: WKUIDelegate {

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {

        // Links opened in a new window should still follow the same routing rules.
        if let url = navigationAction.request.url, router.destination(for: url) == .externalBrowser {
            openExternally(url)
        } else if let url = navigationAction.request.url {
            // If it's allowed in-webview, load it in the current webview.
            webView.load(URLRequest(url: url))
        }

        return nil
    }
}

// MARK: - Routing Abstractions (SOLID-friendly)

enum LinkDestination {
    case inWebView
    case externalBrowser
}

protocol ExternalLinkRouting {
    func destination(for url: URL) -> LinkDestination
}

struct SuroiExternalLinkRouter: ExternalLinkRouting {

    private let allowedRootDomain = "suroi.io"

    // Any match here must open in Safari
    private let redirectRules: [RedirectRule] = [
        .host("discord.suroi.io"),
        .hostPathPrefix("suroi.io/privacy"),
        .hostPathPrefix("suroi.io/rules"),
        .hostPathPrefix("suroi.io/changelog"),
        .hostPathPrefix("suroi.io/news")
    ]

    func destination(for url: URL) -> LinkDestination {
        guard let host = url.host?.lowercased() else { return .inWebView }

        // Rule 1: Anything outside suroi.io (and subdomains) => Safari
        if !isAllowedDomain(host: host) {
            return .externalBrowser
        }

        // Rule 2: Anything matching redirect rules => Safari
        if matchesRedirectRules(url: url, host: host) {
            return .externalBrowser
        }

        return .inWebView
    }

    private func isAllowedDomain(host: String) -> Bool {
        host == allowedRootDomain || host.hasSuffix("." + allowedRootDomain)
    }

    private func matchesRedirectRules(url: URL, host: String) -> Bool {
        let path = url.path.lowercased()
        let fullHostPath = host + path // e.g. "suroi.io/privacy"

        return redirectRules.contains { rule in
            switch rule {
            case .host(let exactHost):
                return host == exactHost.lowercased()
            case .hostPathPrefix(let prefix):
                return fullHostPath.hasPrefix(prefix.lowercased())
            }
        }
    }
}

// MARK: - Redirect Rule Model

enum RedirectRule: Equatable {
    case host(String)              // exact host match, e.g. "discord.suroi.io"
    case hostPathPrefix(String)    // host+path prefix, e.g. "suroi.io/privacy"
}
