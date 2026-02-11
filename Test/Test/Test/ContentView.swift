import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var vm = ViewModel()

    var body: some View {
        VStack {
            
            if vm.shopName.isEmpty {
                Text("No image")
            } else {
                Text(vm.shopName)

            }

            if let tempimage = vm.loadImage {
                Image(uiImage: tempimage)
            } else {
                Text("No Image")
            }
        }
        .padding()
        .onAppear {
            vm.fetch()
        }
        .alert("エラー", isPresented: $vm.ErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.ErrorMessage)
        }
    }
}

#Preview {
    ContentView()
}
