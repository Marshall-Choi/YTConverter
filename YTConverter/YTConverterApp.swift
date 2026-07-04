import SwiftUI

@main
struct YTConverterApp: App {
    var body: some Scene {
        WindowGroup("YouTube → Apple Music") {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 680, height: 580)
    }
}
