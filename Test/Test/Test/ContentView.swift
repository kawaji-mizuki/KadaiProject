// ContentView.swift
// Test
//
// Created by Mizuki Kawaji on 2026/01/15.
//
import SwiftUI
import UIKit


struct ContentView: View {
    @State private var logoImage: UIImage?
    @State private var loadImage: UIImage?
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            if let image = logoImage {
                Image(uiImage: image)
            }else {
                EmptyView()
            }
            if let tempimage = loadImage {
                Image(uiImage: tempimage)
            }else {
                Text("No Image")
            }
        }
        .padding()
        .onAppear {
            let components = URLComponents(string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=6e933c6b4a0b50e7&large_area=Z011&format=json")!
            guard let url = components.url else {
                print("failed to build URL")
                return
            }
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("URLSession error:", error.localizedDescription)
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    print("No HTTPURLResponse")
                    return
                }
                print("URL =", url.absoluteString)
                print("ResponseCode =", http.statusCode)
                guard let data = data,
                      let jsonString = String(data: data, encoding: .utf8) else {
                    print("JSONデータを文字列に変換できませんでした")
                    return
                }
                //print("JSON文字列:")
                //                print(jsonString)
                UserDefaults.standard.set(jsonString, forKey: "hotpepper_json")
                
                if let savedJson = UserDefaults.standard.string(forKey: "hotpepper_json") {
                    //                          print("UserDefaults から取得した JSON:")
                    //                          print(savedJson)
                } else {
                    print("UserDefaults に JSON が保存されていません")
                }
                do {
                    guard let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Dictionary変換失敗")
                        return
                    }
                    // ② results → shop → 1店舗取得
                    guard let results = jsonDict["results"] as? [String: Any],
                          let shops = results["shop"] as? [[String: Any]],
                          let firstShop = shops.first else {
                        print("shop取得失敗")
                        return
                    }
                    // ③ 例：店舗名/住所
                    let name = firstShop["name"] as? String ?? "不明"
                    let address = firstShop["address"] as? String ?? "不明"
                    let logo_image = firstShop["logo_image"] as? String ?? "不明"
                    print("店舗名 =", name)
                    print("住所 =", address)
                    print("お店のロゴ =", logo_image)
                    
                    if let logoURL = URL(string: logo_image) {
                        let imageTask = URLSession.shared.dataTask(with: logoURL) { data, response, error in
                            if let error = error {
                                print("URLSession error:", error.localizedDescription)
                                return
                            }
                            guard let data = data,
                                  let image = UIImage(data: data) else {
                                print("画像取得: decode failed")
                                return
                            }
                            
                            
                            DispatchQueue.main.async {
                                self.logoImage = image
                            }
                            saveLogoToTemp(image)
                            loadImage = loadImagefromtemp(fileName: "logo.jpg")
                            self.loadImage = loadImagefromtemp(fileName: "logo.jpg")
                            
                        }
                        imageTask.resume()
                    }
                    
                } catch {
                    print("JSON Decode失敗:", error)
                }
                
            }
            task.resume()
        }
    }
    
    private let logofilename = "logo.jpg"
    
    private func tempURLget() -> URL {
        FileManager.default.temporaryDirectory
    }
    
    private func tempURLcreate() -> URL {
        tempURLget().appendingPathComponent(logofilename)
    }
    
    private func saveLogoToTemp(_ image: UIImage) {
        let url = tempURLcreate()
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            print("Temp保存失敗: jpeg encode failed")
            return
        }
        do {
            try data.write(to: url)
            print("Tempに保存できた:", url.path)
        } catch {
            print("Temp保存失敗:", error)
        }
    }
    
    private func loadImagefromtemp(fileName: String) -> UIImage? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Tempにファイルがない:", url.path)
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            print("Temp読み込み失敗:", url.path)
            return nil
        }
        guard let image = UIImage(data: data) else {
            print("Temp画像デコード失敗:", url.path)
            return nil
        }
        print("Tempから読み込み成功:", url.path)
        return image
    }
    
}

#Preview {
    ContentView()
}











