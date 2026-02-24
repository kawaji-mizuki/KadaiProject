import SwiftUI

struct NewView: View {
    
    private let items = [
        "店舗 1",
        "店舗 2",
        "店舗 3",
        "店舗 1",
        "店舗 2",
        "店舗 3",
        "店舗 1",
        "店舗 2",
        "店舗 3",
        "店舗 1",
        "店舗 2",
        "店舗 3",
    ]
    
    @StateObject private var vm = ViewModel()
    var body: some View {
        NavigationStack {
            VStack(spacing:30) {
                
                List(items, id: \.self) { name in
                    Text(name)
                }
                .navigationTitle("店舗一覧")
                
                NavigationLink("ContentViewへ遷移") {
                    DetailView()
                }
            }
            .padding()
            .onAppear {
                vm.fetch()
            }
        }
    }
}

#Preview {
    NewView()
}
