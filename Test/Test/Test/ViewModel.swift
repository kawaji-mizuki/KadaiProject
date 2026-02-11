
import Foundation
import UIKit
import Combine

class ViewModel: ObservableObject {

    // Viewが参照する状態（@Stateの代わり）
    @Published var loadImage: UIImage?
    @Published var shopName: String = ""
    @Published var ErrorAlert: Bool = false
    @Published var ErrorMessage: String = ""

    func fetch() {
        let components = URLComponents(string: "https://www.google.com/xxxxxx")!
        guard let url = components.url else {
            print("failed to build URL")
            return
        }
        //オリジナル： https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=6e933c6b4a0b50e7&large_area=Z011&format=json
        //APIエラー用： https://webservice.recruit.co.jp/hotpepper/gourmet/v1/?key=sample&large_area=Z011&format=json
        //HTTPエラー用： https://www.google.com/xxxxxx

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: url) { data, response, error in

            // 通信エラー（Wi-Fiオフ/タイムアウト等）
            if let error = error as? URLError {
                let message: String

                switch error.code {
                case .notConnectedToInternet:
                    message = "インターネットに接続されていません（Wi-Fi/通信を確認してください）"
                case .timedOut:
                    message = "通信がタイムアウトしました（時間内に応答がありませんでした）"
                default:
                    message = "その他の通信エラー"
                    print(error.code)
                }

                DispatchQueue.main.async {
                    self.ErrorMessage = message
                    self.ErrorAlert = true
                }
                return
            }
            guard let http = response as? HTTPURLResponse else {
                print("No HTTPURLResponse")
                return
            }
            print("URL =", url.absoluteString)
            print("ResponseCode =", http.statusCode)
            
            //課題２０　HTTPエラーハンドリング
            guard (200...399).contains(http.statusCode) else {
                let message = "HTTPエラー: \(http.statusCode)"
                print(message)

                DispatchQueue.main.async {
                    self.ErrorMessage = message
                    self.ErrorAlert = true
                }
                return
            }
            
            
            guard let data = data,
                  let jsonString = String(data: data, encoding: .utf8) else {
                print("JSONデータを文字列に変換できませんでした")
                return
            }
            UserDefaults.standard.set(jsonString, forKey: "hotpepper_json")

            do {
                let decoded = try JSONDecoder().decode(HotPepperResponse.self, from: data)
                
                //エラーコード表示
                if let errors = decoded.results.error, let first = errors.first {
                    print("=== API Error ===")
                    print("HTTP StatusCode =", http.statusCode)
                    print("API Error Code =", first.code ?? -1)
                    print("API Error Message =", first.message ?? "nil")
                    
                    DispatchQueue.main.async {
                        self.ErrorMessage = "(\(first.code ?? -1)) \(first.message ?? "")"
                        self.ErrorAlert = true
                    }
                    
                    return
                }
                
                let encodedData = try JSONEncoder().encode(decoded)
                UserDefaults.standard.set(encodedData, forKey: "hotpepper_model")
                print("UserDefaultsにモデル保存できた（bytes）:", encodedData.count)
                
                let restored = try JSONDecoder().decode(HotPepperResponse.self, from: encodedData)
                print("デコード（復元）成功")
                
                //オプショナルバインディング
                if let countshops = restored.results.shop{
                    print("復元した店舗数:", countshops.count)
                }
                else {
                    print("復元した店舗数は取得できませんでした")
                }

                
                let shops = decoded.results.shop ?? []  //Nill合体演算▶︎なかった時は空配列に置き換え
                guard let firstShop = shops.first else {
                    print("shop取得失敗")
                    return
                }

                let name = firstShop.name ?? "不明"
                let logo_image = firstShop.logoImage ?? "不明"
                print("店舗名 =", name)
                print("お店のロゴ =", logo_image)


                DispatchQueue.main.async {
                    self.shopName = name
                }

                if let logoURL = URL(string: logo_image) {
                    let imageTask = URLSession.shared.dataTask(with: logoURL) { data, _, error in
                        if let error = error {
                            print("URLSession error:", error.localizedDescription)
                            return
                        }
                        guard let data = data,
                              let image = UIImage(data: data) else {
                            print("画像取得: decode failed")
                            return
                        }

                        self.saveLogoToTemp(image)

                        DispatchQueue.main.async {
                            self.loadImage = self.loadImagefromtemp(fileName: "logo.jpg")
                        }
                    }
                    imageTask.resume()
                }

            } catch {
                print("JSON Decode失敗:", error)
                
            }
        }
        task.resume()
    }

    //Temp 保存 / 読み込み

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
