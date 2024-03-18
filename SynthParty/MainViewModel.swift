import Foundation
import Combine


@dynamicMemberLookup
@MainActor
class MainViewModel: ObservableObject {
    
    @Published var isShowingPreferences = false
    @Published var isShowingActivityView = false
    
    let webViewModel = WebViewModel()
    
    
    private var didInitialLoad = false
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        webViewModel.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<WebViewModel, T>) -> T {
        webViewModel[keyPath: keyPath]
    }
    
    var homeUrl: URL? {
        return URL(string: "https://synth.party/cc/")
    }
    
    func initialLoad(lastUrl: URL?) throws {
        if didInitialLoad == false {
            self.didInitialLoad = true
            if let lastUrl = lastUrl, !lastUrl.isFileURL {
                load(url: lastUrl)
            } else if let url = homeUrl {
                load(url: url)
            }
        }
    }
    
    func goHome() throws {
        guard let url = homeUrl else {
            return
        }
        webViewModel.apply(input: .load(url: url))
    }
    
    func load(url: URL) {
        webViewModel.apply(input: .load(url: url))
    }
    
    func goBack() {
        webViewModel.apply(input: .goBack)
    }
    
    func goForward() {
        webViewModel.apply(input: .goForward)
    }
    
    func reload() {
        webViewModel.apply(input: .reload)
    }
    
    func stopLoading() {
        webViewModel.apply(input: .stopLoading)
    }
}
