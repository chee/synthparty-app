import UIKit
import WebKit
import Combine

public class SynthPartyWebViewController: WebViewController {
    
    public weak var delegate: SynthPartyWebViewControllerDelegate?
    
    private let webMidi = WebMIDI()
    
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
        webView.navigationDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
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

extension SynthPartyWebViewController: WKNavigationDelegate {}

public protocol SynthPartyWebViewControllerDelegate: AnyObject {}
