import SwiftUI
import UIKit

struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        ViewController()   // ← あなたが作ったUIKitのVC
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 画面更新が必要な時だけ使う。今回は空でOK
    }
}

struct ContentView: View {
    var body: some View {
        ViewControllerWrapper()
    }
}

#Preview {
    ContentView()
}
