//
//  UIViewController.swift
//  Test
//
//  Created by Kawaji Mizuki on 2026/01/22.
//

import UIKit

final class ViewController: UIViewController {

    // 表示用のUI部品
    private let logoImageView = UIImageView()
    private let loadedImageView = UIImageView()
    private let shopname = UILabel()

    // 状態
    private var logoImage: UIImage?
    private var loadImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupUI()
        fetchAndShow() // ← onAppear の中身をここへ
    }

    private func setupUI() {

        // image views
        logoImageView.contentMode = .scaleAspectFit
        loadedImageView.contentMode = .scaleAspectFit

        let stack = UIStackView(arrangedSubviews: [
            logoImageView,
            loadedImageView,
            shopname

        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
    }
    
    //Modelを用意する
    struct HotPepperResponse: Codable {
        let results: Results
    }

    struct Results: Codable {
        let shop: [Shop]
    }

    struct Shop: Codable {
        let name: String?
        let address: String?
        let logoImage: String?

        enum CodingKeys: String, CodingKey {
            case name
            case address
            case logoImage = "logo_image"
        }
    }
    
    //通信処理
    private func fetchAndShow() {
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

            UserDefaults.standard.set(jsonString, forKey: "hotpepper_json")

            if UserDefaults.standard.string(forKey: "hotpepper_json") == nil {
                print("UserDefaults に JSON が保存されていません")
            }

            do {
                let decoded = try JSONDecoder().decode(HotPepperResponse.self, from: data)

                guard let firstShop = decoded.results.shop.first else {
                    print("shop取得失敗")
                    return
                }

                let name = firstShop.name ?? "不明"
                let address = firstShop.address ?? "不明"
                let logo_image = firstShop.logoImage ?? "不明"

                print("店舗名 =", name)
                print("住所 =", address)
                print("お店のロゴ =", logo_image)
                
                //以下の処理はメインスレッドで実行
                DispatchQueue.main.async {
                    self.shopname.text = name
                }

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

                        // SwiftUIの self.logoImage = image の代わりに
                        // UIKitでは imageView.image に代入する
                        DispatchQueue.main.async {
                            self.logoImage = image
                            self.logoImageView.image = image
                            self.logoImageView.isHidden = false
                        }

                        self.saveLogoToTemp(image)

                        // ここはUI更新もあるのでmainに寄せるのが安全
                        DispatchQueue.main.async {
                            self.loadImage = self.loadImagefromtemp(fileName: "logo.jpg")
                            self.loadedImageView.image = self.loadImage


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
