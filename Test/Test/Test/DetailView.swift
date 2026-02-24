import SwiftUI
import UIKit

struct DetailView: View {
    @StateObject private var vm = ViewModel()
    
    var body: some View {
        VStack {
            //店名表示
            if vm.shopName.isEmpty {
                Text("No image")
            } else {
                Text(vm.shopName)
                
            }
            //店画像表示
            if let tempimage = vm.loadImage {
                Image(uiImage: tempimage)
            } else {
                Text("No Image")
            }
        }
        .padding()
        //VM実行
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
    DetailView()
}
