//
//  Models.swift
//  Test
//
//  Created by Kawaji Mizuki on 2026/01/28.
//

import Foundation

struct HotPepperResponse: Codable {
    let results: Results
}

struct Results: Codable {
    let shop: [Shop]?
    let error: String?
}

struct error: Codable {
    let code: String?
    let message: String?
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
