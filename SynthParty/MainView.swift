import SwiftUI

struct MainView: View {
    @StateObject private var model = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    model.goBack()
                }) {
                    Label("Back", systemImage: "arrow.left")
                        .foregroundStyle(model.canGoBack ? .blue : .gray)
                        .labelStyle(.iconOnly)
                }.disabled(!model.canGoBack)
                
                Button(action: {
                    model.goForward()
                }) {
                    Label("Forth", systemImage: "arrow.forward")
                        .foregroundStyle(model.canGoForward ? .blue : .gray)
                        .labelStyle(.iconOnly)
                }.disabled(!model.canGoForward)
                
                Button(action: {
                    model.load()
                }) {
                    Label("Reload", systemImage: "arrow.counterclockwise")
                        .foregroundStyle(.blue)
                        .labelStyle(.iconOnly)
                }
                Spacer()
                TextField("url", text: Binding(
                        get: { model.webViewModel.url?.absoluteString ?? "" },
                        set: { model.webViewModel.url = URL(string: $0) }
                    ))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        model.load()
                    }
                    .submitLabel(.go)
            }.padding(10)
            .cornerRadius(30)

            HStack(spacing: 0) {
                WebView(viewModel: model.webViewModel)
                    .edgesIgnoringSafeArea([.bottom, .horizontal])
            }
            .onAppear {
                model.load()
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
