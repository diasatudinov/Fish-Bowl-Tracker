//
//  FoodCategory.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

// MARK: - Models

enum FoodCategory: String, CaseIterable, Codable, Identifiable {
    case redFish = "Red Fish"
    case whiteFish = "White Fish"
    case crustaceans = "Crustaceans"
    case mollusks = "Mollusks"
    case seaweed = "Seaweed"
    case canned = "Canned"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .redFish: return "🐟"
        case .whiteFish: return "🐠"
        case .crustaceans: return "🦐"
        case .mollusks: return "🐚"
        case .seaweed: return "🌿"
        case .canned: return "🥫"
        }
    }
}

enum CookingMethod: String, CaseIterable, Codable, Identifiable {
    case raw = "Raw"
    case steamed = "Steamed"
    case grilled = "Grilled"
    case fried = "Fried"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .raw: return "🥩"
        case .steamed: return "♨️"
        case .grilled: return "🔥"
        case .fried: return "🍳"
        }
    }

    var omegaVitaminMultiplier: Double {
        switch self {
        case .fried:
            return 0.85
        default:
            return 1.0
        }
    }
}

enum HealthZone: String, CaseIterable, Codable, Identifiable {
    case heart = "Heart & Vessels"
    case brain = "Brain & Nerves"
    case thyroid = "Thyroid"
    case muscles = "Muscles & Recovery"
    case skin = "Skin, Hair & Nails"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .heart: return "❤️"
        case .brain: return "🧠"
        case .thyroid: return "🦋"
        case .muscles: return "💪"
        case .skin: return "✨"
        }
    }
}

struct Nutrients: Codable, Equatable {
    var protein: Double
    var omega3: Double
    var iodine: Double
    var zinc: Double
    var vitaminD: Double

    static let zero = Nutrients(
        protein: 0,
        omega3: 0,
        iodine: 0,
        zinc: 0,
        vitaminD: 0
    )

    func scaled(weightGrams: Double, method: CookingMethod) -> Nutrients {
        let factor = weightGrams / 100.0
        let omegaVitaminFactor = factor * method.omegaVitaminMultiplier

        return Nutrients(
            protein: protein * factor,
            omega3: omega3 * omegaVitaminFactor,
            iodine: iodine * factor,
            zinc: zinc * factor,
            vitaminD: vitaminD * omegaVitaminFactor
        )
    }

    static func + (lhs: Nutrients, rhs: Nutrients) -> Nutrients {
        Nutrients(
            protein: lhs.protein + rhs.protein,
            omega3: lhs.omega3 + rhs.omega3,
            iodine: lhs.iodine + rhs.iodine,
            zinc: lhs.zinc + rhs.zinc,
            vitaminD: lhs.vitaminD + rhs.vitaminD
        )
    }
}

struct SeaProduct: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let icon: String
    let category: FoodCategory
    let nutrientsPer100: Nutrients
    let insight: String
    let zones: [HealthZone]

    init(
        name: String,
        icon: String,
        category: FoodCategory,
        nutrientsPer100: Nutrients,
        insight: String,
        zones: [HealthZone]
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.category = category
        self.nutrientsPer100 = nutrientsPer100
        self.insight = insight
        self.zones = zones
    }
}

struct MealEntry: Identifiable, Codable {
    let id: UUID
    let product: SeaProduct
    let weight: Double
    let method: CookingMethod
    let date: Date
    let nutrients: Nutrients
    let fact: String

    init(
        product: SeaProduct,
        weight: Double,
        method: CookingMethod,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.product = product
        self.weight = weight
        self.method = method
        self.date = date
        self.nutrients = product.nutrientsPer100.scaled(weightGrams: weight, method: method)
        self.fact = MicroFactFactory.makeFact(
            product: product,
            nutrients: nutrients,
            method: method
        )
    }
}



// MARK: - Micro Facts

enum MicroFactFactory {
    static func makeFact(product: SeaProduct, nutrients: Nutrients, method: CookingMethod) -> String {
        if method == .fried {
            return "Frying kept protein, but reduced Omega-3 and vitamins. Try grill next time."
        }

        if nutrients.omega3 >= 2 {
            return "You closed the Omega-3 goal. Your vessels are under protection!"
        }

        if nutrients.iodine >= 150 {
            return "Thyroid received a full iodine charge."
        }

        if nutrients.vitaminD >= 800 {
            return "Sunshine on your plate! Vitamin D goal is activated."
        }

        if nutrients.zinc >= 8 {
            return "Powerful zinc portion. Hair and nails get building material."
        }

        if product.zones.contains(.heart) {
            return "Heart and vessels got useful marine nutrients."
        }

        if product.zones.contains(.thyroid) {
            return "Thyroid support from iodine-rich seafood."
        }

        return product.insight
    }
}
