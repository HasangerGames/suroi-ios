import UIKit
import Foundation
@preconcurrency import WebKit

struct ServerResponse: Decodable {
    let mode: String
}

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var offlineImageView: UIImageView!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        offlineImageView.isHidden = true
        modeFetcher()
        loadInitialURL()
    }

    
    // WebView logic
    func loadInitialURL() {
        if let url = URL(string: "https://suroi.io") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlModel = URLModel()
        if urlModel.isInternalURL(url) {
            decisionHandler(.allow)
        } else if urlModel.isExternalURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    
    // Background logic
    let backgroundManager = BackgroundManager()

    func updateBackground(forGameMode mode: String) {
        backgroundManager.updateBackground(forGameMode: mode, in: backgroundImageView)
    }

    func modeFetcher() {
        guard let url = URL(string: "https://na.suroi.io/api/serverInfo") else {
            print("Invalid URL")
            showOfflineScreen()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Failed to fetch server info: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showOfflineScreen()
                }
                return
            }
            guard let data = data else {
                print("No data received from server")
                DispatchQueue.main.async {
                    self?.showOfflineScreen()
                }
                return
            }

            do {
                let serverInfo = try JSONDecoder().decode(ServerResponse.self, from: data)
                print("Fetched mode from server: \(serverInfo.mode)")

                DispatchQueue.main.async {
                    self?.hideOfflineScreen()
                    self?.updateBackground(forGameMode: serverInfo.mode)
                }
            } catch {
                print("Failed to decode server info: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showOfflineScreen()
                }
            }
        }
        task.resume()
    }

    
    // Offline screen logic
    func showOfflineScreen() {
        offlineImageView.isHidden = false
        webView.isHidden = true
        backgroundImageView.isHidden = true
    }

    func hideOfflineScreen() {
        offlineImageView.isHidden = true
        webView.isHidden = false
        backgroundImageView.isHidden = false
    }

    
    // JavaScript dialogs handling
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "Confirm", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(false)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler(true)
        }))
        present(alert, animated: true, completion: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "Prompt", message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            completionHandler(nil)
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            let userInput = alert.textFields?.first?.text
            completionHandler(userInput)
        }))
        present(alert, animated: true, completion: nil)
    }
}
//test
