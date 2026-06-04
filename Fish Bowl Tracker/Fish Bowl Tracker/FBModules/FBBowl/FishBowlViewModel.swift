//
//  FishBowlViewModel.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

// MARK: - Store

final class FishBowlViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .bowl
    @Published var entries: [MealEntry] = [] {
        didSet {
            save()
        }
    }

    let proteinGoal: Double = 80
    let omegaGoal: Double = 2
    let iodineGoal: Double = 150
    let vitaminDGoal: Double = 800
    let zincGoal: Double = 11

    private let saveKey = "fish_bowl_entries"

    init() {
        load()
    }

    var todayEntries: [MealEntry] {
        entries.filter {
            Calendar.current.isDateInToday($0.date)
        }
    }

    var todayTotals: Nutrients {
        todayEntries.reduce(.zero) { $0 + $1.nutrients }
    }

    var weekEntries: [MealEntry] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: Date()) else {
            return entries
        }

        return entries.filter { $0.date >= calendar.startOfDay(for: weekAgo) }
    }

    var fishDaysThisWeek: Int {
        let days = Set(
            weekEntries.map {
                Calendar.current.startOfDay(for: $0.date)
            }
        )

        return days.count
    }

    var topProductsThisWeek: [(name: String, percent: Double)] {
        let grouped = Dictionary(grouping: weekEntries, by: { $0.product.name })
        let totals = grouped.mapValues { items in
            items.reduce(0) { $0 + $1.weight }
        }

        let totalWeight = totals.values.reduce(0, +)

        guard totalWeight > 0 else {
            return []
        }

        return totals
            .map { key, value in
                (name: key, percent: value / totalWeight)
            }
            .sorted { $0.percent > $1.percent }
    }

    func addEntry(product: SeaProduct, weight: Double, method: CookingMethod) {
        let entry = MealEntry(product: product, weight: weight, method: method)

        withAnimation(.spring()) {
            entries.append(entry)
        }
    }

    func deleteEntry(_ entry: MealEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    func entriesForLastSevenDays() -> [(date: Date, nutrients: Nutrients)] {
        let calendar = Calendar.current

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else {
                return nil
            }

            let start = calendar.startOfDay(for: date)

            let dayEntries = entries.filter {
                calendar.isDate($0.date, inSameDayAs: start)
            }

            let total = dayEntries.reduce(.zero) { $0 + $1.nutrients }

            return (date: start, nutrients: total)
        }
        .reversed()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Save error:", error)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return
        }

        do {
            entries = try JSONDecoder().decode([MealEntry].self, from: data)
        } catch {
            print("Load error:", error)
        }
    }
}

// MARK: - Data

enum FishBowlData {
    static let products: [SeaProduct] = [
        SeaProduct(
            name: "Salmon",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 20, omega3: 2.5, iodine: 40, zinc: 0.4, vitaminD: 400),
            insight: "Heart health leader and skin glow booster.",
            zones: [.heart, .skin]
        ),
        SeaProduct(
            name: "Mackerel",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 19, omega3: 2.6, iodine: 45, zinc: 0.5, vitaminD: 350),
            insight: "Maximum Omega-3 + B12. Supports nervous system.",
            zones: [.heart, .brain]
        ),
        SeaProduct(
            name: "Sardine",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 20.8, omega3: 1.5, iodine: 39, zinc: 1.3, vitaminD: 270),
            insight: "Protein and calcium from tiny bones.",
            zones: [.heart, .muscles]
        ),
        SeaProduct(
            name: "River Trout",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 19.9, omega3: 0.7, iodine: 30, zinc: 0.8, vitaminD: 150),
            insight: "Affordable alternative to red fish.",
            zones: [.heart, .muscles]
        ),
        SeaProduct(
            name: "Atlantic Herring",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 17, omega3: 1.9, iodine: 35, zinc: 0.8, vitaminD: 150),
            insight: "High EPA concentration.",
            zones: [.heart, .brain]
        ),
        SeaProduct(
            name: "Anchovies",
            icon: "🐟",
            category: .redFish,
            nutrientsPer100: Nutrients(protein: 20.4, omega3: 1.5, iodine: 70, zinc: 1.2, vitaminD: 18),
            insight: "Smart snack. Fast Omega-3 refill.",
            zones: [.heart, .brain]
        ),

        SeaProduct(
            name: "Cod",
            icon: "🐠",
            category: .whiteFish,
            nutrientsPer100: Nutrients(protein: 17.7, omega3: 0.2, iodine: 135, zinc: 0.4, vitaminD: 40),
            insight: "Lean protein and powerful iodine boost.",
            zones: [.thyroid, .muscles]
        ),
        SeaProduct(
            name: "Tuna (fresh)",
            icon: "🐠",
            category: .whiteFish,
            nutrientsPer100: Nutrients(protein: 23, omega3: 1.2, iodine: 50, zinc: 0.6, vitaminD: 200),
            insight: "Ideal for athletes.",
            zones: [.muscles, .brain]
        ),
        SeaProduct(
            name: "Halibut",
            icon: "🐠",
            category: .whiteFish,
            nutrientsPer100: Nutrients(protein: 19, omega3: 1.1, iodine: 45, zinc: 0.5, vitaminD: 120),
            insight: "Gentle fatty protein.",
            zones: [.muscles]
        ),

        SeaProduct(
            name: "Shrimp",
            icon: "🦐",
            category: .crustaceans,
            nutrientsPer100: Nutrients(protein: 20, omega3: 0.3, iodine: 40, zinc: 1.5, vitaminD: 60),
            insight: "Low-calorie protein + zinc for hair growth.",
            zones: [.skin, .muscles]
        ),
        SeaProduct(
            name: "Crab (cooked)",
            icon: "🦀",
            category: .crustaceans,
            nutrientsPer100: Nutrients(protein: 18.1, omega3: 0.2, iodine: 45, zinc: 6.2, vitaminD: 2),
            insight: "Zinc champion.",
            zones: [.skin, .muscles]
        ),
        SeaProduct(
            name: "Lobster",
            icon: "🦞",
            category: .crustaceans,
            nutrientsPer100: Nutrients(protein: 20.5, omega3: 0.2, iodine: 35, zinc: 3.2, vitaminD: 5),
            insight: "Premium protein and copper.",
            zones: [.muscles]
        ),

        SeaProduct(
            name: "Mussels",
            icon: "🐚",
            category: .mollusks,
            nutrientsPer100: Nutrients(protein: 11.5, omega3: 0.4, iodine: 120, zinc: 2.6, vitaminD: 10),
            insight: "Record holder for iron and zinc.",
            zones: [.skin, .thyroid]
        ),
        SeaProduct(
            name: "Oysters",
            icon: "🦪",
            category: .mollusks,
            nutrientsPer100: Nutrients(protein: 9, omega3: 0.4, iodine: 55, zinc: 16, vitaminD: 15),
            insight: "Absolute zinc leader.",
            zones: [.skin]
        ),
        SeaProduct(
            name: "Squid",
            icon: "🦑",
            category: .mollusks,
            nutrientsPer100: Nutrients(protein: 18, omega3: 0.5, iodine: 300, zinc: 1.8, vitaminD: 5),
            insight: "Rich in protein and potassium.",
            zones: [.muscles, .thyroid]
        ),
        SeaProduct(
            name: "Octopus",
            icon: "🐙",
            category: .mollusks,
            nutrientsPer100: Nutrients(protein: 18.2, omega3: 0.3, iodine: 50, zinc: 2, vitaminD: 8),
            insight: "Taurine for the heart.",
            zones: [.heart, .muscles]
        ),

        SeaProduct(
            name: "Sea Kelp (Laminaria)",
            icon: "🌿",
            category: .seaweed,
            nutrientsPer100: Nutrients(protein: 1, omega3: 0.1, iodine: 800, zinc: 0.4, vitaminD: 0),
            insight: "Ultimate iodine source.",
            zones: [.thyroid]
        ),
        SeaProduct(
            name: "Wakame  Nori",
            icon: "🌿",
            category: .seaweed,
            nutrientsPer100: Nutrients(protein: 1.5, omega3: 0.2, iodine: 120, zinc: 0.3, vitaminD: 5),
            insight: "Supports gut health and thyroid.",
            zones: [.thyroid]
        ),

        SeaProduct(
            name: "Cod Liver",
            icon: "🥫",
            category: .canned,
            nutrientsPer100: Nutrients(protein: 4.2, omega3: 1.8, iodine: 350, zinc: 0.9, vitaminD: 4000),
            insight: "Natural Vitamin D capsule.",
            zones: [.heart, .thyroid]
        ),
        SeaProduct(
            name: "Pink Salmon (canned)",
            icon: "🥫",
            category: .canned,
            nutrientsPer100: Nutrients(protein: 21, omega3: 1.8, iodine: 60, zinc: 0.7, vitaminD: 280),
            insight: "Affordable Omega-3 and calcium source.",
            zones: [.heart, .muscles]
        )
    ]
}
