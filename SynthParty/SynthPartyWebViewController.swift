import UIKit
import WebKit
import Combine

public class SynthPartyWebViewController: WebViewController {
    
    public weak var delegate: SynthPartyWebViewControllerDelegate?
    
    private let webMidi = WebMIDI()
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var sizeConstraints: [NSLayoutConstraint] = []
    
    public override init() {
        super.init()        
        webMidi.setup(webView: webView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        self.view = UIView(frame: .zero)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        updateSizeConstraints(multiplier: 1)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        $url.compactMap({$0}).sink() { [weak self] (url) in
//            if self?.webView.isLoading == false {
//                self?.didChangeUrl(url)
//            }
        }.store(in: &cancellables)
        
        webView.navigationDelegate = self
        
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    public override func viewWillLayoutSubviews() {
        let multiplier = max(1.0, 1092.0 / view.bounds.width)
        updateSizeConstraints(multiplier: multiplier)
        webView.transform = CGAffineTransform(scaleX: 1.0 / multiplier, y: 1.0 / multiplier)
    }
    
    private func updateSizeConstraints(multiplier: CGFloat) {
        NSLayoutConstraint.deactivate(sizeConstraints)
        self.sizeConstraints = [
            webView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: multiplier),
            webView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: multiplier),
        ]
        NSLayoutConstraint.activate(sizeConstraints)
    }
}

extension SynthPartyWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        webMidi.reset()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        if let url = webView.url {
//            didChangeUrl(url)
//        }
    }
    
//    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        delegate?.synthPartyWebViewController(self, didFail: error)
//    }
//    
//    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        delegate?.synthPartyWebViewController(self, didFail: error)
//    }
}

public protocol SynthPartyWebViewControllerDelegate: AnyObject {}
