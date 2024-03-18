import SwiftUI

struct MainView: View {
    
    @SceneStorage("lastUrl") private var lastUrl: URL?
    
    @StateObject private var viewModel = MainViewModel()

    
    @State private var eventTask: Task<(), Never>?
    
    var body: some View {
        HStack(spacing: 0) {
            WebView(viewModel: viewModel.webViewModel)
                .edgesIgnoringSafeArea([.bottom, .horizontal])
        }
        .onAppear {
            
            eventTask = Task {
                for await event in viewModel.eventChannel {

                }
            }
            
            try? viewModel.initialLoad(lastUrl: lastUrl)
        }
        .onDisappear {
            eventTask?.cancel()
        }
        .onChange(of: viewModel.url) { newValue in
            if let url = newValue {
                lastUrl = url
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
