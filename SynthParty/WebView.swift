import SwiftUI
import AsyncAlgorithms

struct WebView: UIViewControllerRepresentable {
    
    @ObservedObject var viewModel: WebViewModel
    
    func makeCoordinator() -> WebView.Coordinator {
        return Coordinator()
    }
    
    func makeUIViewController(context: Context) -> SynthPartyWebViewController {
        let viewController = SynthPartyWebViewController()
        viewController.delegate = context.coordinator
        
        context.coordinator.bind(viewModel: viewModel, viewController: viewController)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: SynthPartyWebViewController, context: Context) {
    }
}

extension WebView {
    
    @MainActor
    class Coordinator: NSObject, SynthPartyWebViewControllerDelegate {
        
        private var eventChannel: AsyncChannel<WebViewModel.Event>?
        
        func bind(viewModel: WebViewModel, viewController: SynthPartyWebViewController) {
            viewController.$url.receive(on: DispatchQueue.main).assign(to: &viewModel.$url)
            viewController.$isLoading.receive(on: DispatchQueue.main).assign(to: &viewModel.$isLoading)
            viewController.$estimatedProgress.receive(on: DispatchQueue.main).assign(to: &viewModel.$estimatedProgress)
            viewController.$canGoBack.receive(on: DispatchQueue.main).assign(to: &viewModel.$canGoBack)
            viewController.$canGoForward.receive(on: DispatchQueue.main).assign(to: &viewModel.$canGoForward)
            
            let inputChannel = viewModel.inputChannel
            Task {
                for await input in inputChannel {
                    switch input {
                    case .load(url: let url):
                        viewController.load(url: url)
                    case .goBack:
                        viewController.goBack()
                    case .goForward:
                        viewController.goForward()
                    case .reload:
                        viewController.reload()
                    case .stopLoading:
                        viewController.stopLoading()
                    }
                }
            }
            
            self.eventChannel = viewModel.eventChannel
        }
        
        
        nonisolated func synthPartyWebViewController(_ viewController: SynthPartyWebViewController, didDownloadFileAt url: URL) {
            Task { @MainActor in
                let vc = UIDocumentPickerViewController(forExporting: [url])
                vc.shouldShowFileExtensions = true
                viewController.present(vc, animated: true)
            }
        }
    }
}
