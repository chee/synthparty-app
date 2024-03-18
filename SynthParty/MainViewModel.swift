import Foundation
import Combine


@dynamicMemberLookup
@MainActor
class MainViewModel: ObservableObject {
    
    @Published var isShowingPreferences = false
    @Published var isShowingActivityView = false
    
    let webViewModel = WebViewModel()
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        webViewModel.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<WebViewModel, T>) -> T {
        webViewModel[keyPath: keyPath]
    }
    
    var home = URL(string: "https://synth.party/cc/")
    
    func goHome() throws {
        webViewModel.url = home
        webViewModel.apply(input: .load)
    }
    
    func load() {
        webViewModel.apply(input: .load)
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
