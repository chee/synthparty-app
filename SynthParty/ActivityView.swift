import SwiftUI
import SFUserFriendlySymbols

struct ActivityView: UIViewControllerRepresentable {
    
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: [HomeActivity() ,BrowserActivity()])
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

class HomeActivity: UIActivity {
    
    var url: URL? = nil
 
    
    override var activityTitle: String? {
        return NSLocalizedString("Set as Home", comment: "Set as Home")
    }
    
    override var activityImage: UIImage? {
        return UIImage(symbol: .house)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let _ = item as? URL {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                self.url = url
                break
            }
        }
    }
    
    override func perform() {
        Task { @MainActor in
            activityDidFinish(true)
        }
    }
}

class BrowserActivity: UIActivity {
    
    var url: URL? = nil
    
    override var activityTitle: String? {
        return NSLocalizedString("Open in Browser", comment: "Open in Browser")
    }
    
    override var activityImage: UIImage? {
        return UIImage(symbol: .safari)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for item in activityItems {
            if let url = item as? URL, UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        for item in activityItems {
            if let url = item as? URL {
                self.url = url
                break
            }
        }
    }
    
    override func perform() {
        if let url = url {
            UIApplication.shared.open(url)
        }
        activityDidFinish(true)
    }
}
