import SwiftUI

// MARK: - App

@main
struct FishBowlTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

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

struct Nutrients: Codable {
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

// MARK: - Store

final class FishBowlViewModel: ObservableObject {
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
            name: "Wakame / Nori",
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

// MARK: - Root

struct ContentView: View {
    @StateObject private var viewModel = FishBowlViewModel()

    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("My Bowl", systemImage: "fish")
                }

            SeaPharmacyView()
                .tabItem {
                    Label("Pharmacy", systemImage: "cross.case")
                }

            StatisticsView(viewModel: viewModel)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
        .tint(.red)
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @ObservedObject var viewModel: FishBowlViewModel
    @State private var isAddPresented = false

    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SUN, MAY 24")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))

                            Text("Ocean Health")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        healthRings

                        ZincProgressView(
                            value: viewModel.todayTotals.zinc,
                            goal: viewModel.zincGoal
                        )

                        todayCatch
                    }
                    .padding()
                    .padding(.bottom, 90)
                }

                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Button {
                            isAddPresented = true
                        } label: {
                            Image(systemName: "fish.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(radius: 8)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Fish Bowl Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAddPresented) {
                AddPortionView(viewModel: viewModel)
            }
        }
    }

    private var healthRings: some View {
        let totals = viewModel.todayTotals

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
            HealthRingView(
                title: "Protein",
                icon: "🥇",
                value: totals.protein,
                goal: viewModel.proteinGoal,
                unit: "g"
            )

            HealthRingView(
                title: "Omega-3",
                icon: "🐟",
                value: totals.omega3,
                goal: viewModel.omegaGoal,
                unit: "g"
            )

            HealthRingView(
                title: "Iodine",
                icon: "🌊",
                value: totals.iodine,
                goal: viewModel.iodineGoal,
                unit: "mcg"
            )

            HealthRingView(
                title: "Vitamin D",
                icon: "☀️",
                value: totals.vitaminD,
                goal: viewModel.vitaminDGoal,
                unit: "IU"
            )
        }
    }

    private var todayCatch: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Catch")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(viewModel.todayEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            if viewModel.todayEntries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "plus.circle")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.5))

                    Text("Tap the + button to log your first catch of the day")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(viewModel.todayEntries.reversed()) { entry in
                    CatchCardView(entry: entry) {
                        viewModel.deleteEntry(entry)
                    }
                }
            }
        }
    }
}

struct HealthRingView: View {
    let title: String
    let icon: String
    let value: Double
    let goal: Double
    let unit: String

    private var progress: Double {
        min(value / goal, 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: progress)

                VStack(spacing: 2) {
                    Text(icon)

                    Text(formatted(value))
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
            .frame(height: 70)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(18)
    }

    private func formatted(_ number: Double) -> String {
        if unit == "g" {
            return String(format: "%.1f", number)
        } else {
            return String(format: "%.0f", number)
        }
    }
}

struct ZincProgressView: View {
    let value: Double
    let goal: Double

    private var progress: Double {
        min(value / goal, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🦀 Zinc")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Spacer()

                Text("\(String(format: "%.1f", value)) / \(String(format: "%.1f", goal)) mg")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))

                    Capsule()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

struct CatchCardView: View {
    let entry: MealEntry
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.product.icon)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.product.name) \(Int(entry.weight)) g")
                    .font(.headline)
                    .foregroundColor(.white)

                Text("+\(String(format: "%.1f", entry.nutrients.protein)) g protein • +\(String(format: "%.1f", entry.nutrients.omega3)) g omega")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text(entry.fact)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
    }
}

// MARK: - Add Portion

struct AddPortionView: View {
    @ObservedObject var viewModel: FishBowlViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: FoodCategory = .redFish
    @State private var selectedProduct: SeaProduct = FishBowlData.products[0]
    @State private var weight: Double = 150
    @State private var method: CookingMethod = .grilled
    @State private var saved = false

    private var filteredProducts: [SeaProduct] {
        FishBowlData.products.filter { $0.category == selectedCategory }
    }

    private var previewNutrients: Nutrients {
        selectedProduct.nutrientsPer100.scaled(weightGrams: weight, method: method)
    }

    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        categoryGrid

                        selectedProductCard

                        weightBlock

                        methodPicker

                        nutrientPreview

                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                if let first = FishBowlData.products.first(where: { $0.category == newCategory }) {
                    selectedProduct = first
                }
            }
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
            ForEach(FoodCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    VStack(spacing: 8) {
                        Text(category.icon)
                            .font(.title2)

                        Text(category.rawValue)
                            .font(.caption.bold())
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 82)
                    .background(
                        selectedCategory == category
                        ? Color.green.opacity(0.35)
                        : Color.white.opacity(0.12)
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.25))
                    )
                }
            }
        }
    }

    private var selectedProductCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose product")
                .font(.headline)
                .foregroundColor(.white)

            ForEach(filteredProducts) { product in
                Button {
                    selectedProduct = product
                } label: {
                    HStack {
                        Text(product.icon)
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(product.name)
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(product.insight)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }

                        Spacer()

                        if selectedProduct.id == product.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        selectedProduct.id == product.id
                        ? Color.green.opacity(0.25)
                        : Color.white.opacity(0.1)
                    )
                    .cornerRadius(16)
                }
            }
        }
    }

    private var weightBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight (g)")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(Int(weight))")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
            }

            Slider(value: $weight, in: 0...500, step: 10)
                .tint(.red)
        }
    }

    private var methodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cooking method")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(CookingMethod.allCases) { item in
                    Button {
                        method = item
                    } label: {
                        VStack(spacing: 6) {
                            Text(item.icon)
                            Text(item.rawValue)
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(
                            method == item
                            ? Color.red.opacity(0.45)
                            : Color.white.opacity(0.12)
                        )
                        .cornerRadius(14)
                    }
                }
            }

            if method == .fried {
                Text("Fried applies ×0.85 to Omega-3 and Vitamin D.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var nutrientPreview: some View {
        HStack {
            NutrientPreviewItem(
                title: "protein",
                value: "+\(String(format: "%.1f", previewNutrients.protein))g"
            )

            Divider()
                .background(Color.white.opacity(0.3))

            NutrientPreviewItem(
                title: "Omega",
                value: "+\(String(format: "%.1f", previewNutrients.omega3))g"
            )

            Divider()
                .background(Color.white.opacity(0.3))

            NutrientPreviewItem(
                title: "Iodine",
                value: "+\(String(format: "%.0f", previewNutrients.iodine))mcg"
            )
        }
        .padding()
        .background(Color.blue.opacity(0.35))
        .cornerRadius(16)
    }

    private var saveButton: some View {
        Button {
            viewModel.addEntry(
                product: selectedProduct,
                weight: weight,
                method: method
            )

            saved = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                dismiss()
            }
        } label: {
            Text(saved ? "🐟 Saved to Bowl!" : "🐟 Save to Bowl")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(saved ? Color.green : Color.red)
                .cornerRadius(16)
                .shadow(radius: 8)
        }
    }
}

struct NutrientPreviewItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundColor(.red)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pharmacy

struct SeaPharmacyView: View {
    @State private var selectedZone: HealthZone?

    private var filteredProducts: [SeaProduct] {
        guard let selectedZone else {
            return FishBowlData.products
        }

        return FishBowlData.products.filter {
            $0.zones.contains(selectedZone)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()

                VStack(spacing: 12) {
                    zoneFilter

                    List {
                        ForEach(filteredProducts) { product in
                            NavigationLink {
                                ProductDetailView(product: product)
                            } label: {
                                PharmacyRow(product: product)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
                .padding(.top)
            }
            .navigationTitle("Sea Pharmacy")
        }
    }

    private var zoneFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button {
                    selectedZone = nil
                } label: {
                    Text("All")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedZone == nil ? Color.green : Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                ForEach(HealthZone.allCases) { zone in
                    Button {
                        selectedZone = zone
                    } label: {
                        Text("\(zone.icon) \(zone.rawValue)")
                            .font(.caption.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedZone == zone ? Color.green : Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct PharmacyRow: View {
    let product: SeaProduct

    var body: some View {
        HStack(spacing: 12) {
            Text(product.icon)
                .font(.title)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text("Omega-3: \(String(format: "%.1f", product.nutrientsPer100.omega3)) g")
                    .font(.caption)
                    .foregroundColor(.orange)

                Text(product.insight)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

struct ProductDetailView: View {
    let product: SeaProduct

    var body: some View {
        ZStack {
            OceanBackground()

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Text(product.icon)
                            .font(.system(size: 72))

                        Text(product.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text(product.insight)
                            .font(.body.italic())
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.35))
                    .cornerRadius(24)

                    VStack(spacing: 0) {
                        NutrientRow(title: "Protein", value: "\(product.nutrientsPer100.protein) g", icon: "🥇")
                        NutrientRow(title: "Omega-3", value: "\(product.nutrientsPer100.omega3) g", icon: "🐟")
                        NutrientRow(title: "Iodine", value: "\(Int(product.nutrientsPer100.iodine)) mcg", icon: "🌊")
                        NutrientRow(title: "Vitamin D", value: "\(Int(product.nutrientsPer100.vitaminD)) IU", icon: "☀️")
                        NutrientRow(title: "Zinc", value: "\(product.nutrientsPer100.zinc) mg", icon: "🦀")
                    }
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(18)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Health Benefits")
                            .font(.headline)
                            .foregroundColor(.white)

                        ForEach(product.zones) { zone in
                            Text("\(zone.icon) \(zone.rawValue)")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NutrientRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Text(icon)
            Text(title)
                .foregroundColor(.white)

            Spacer()

            Text(value)
                .foregroundColor(.white)
                .font(.body.monospacedDigit())
        }
        .padding()
    }
}

// MARK: - Statistics

struct StatisticsView: View {
    @ObservedObject var viewModel: FishBowlViewModel

    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        HealthWaveChartView(
                            days: viewModel.entriesForLastSevenDays(),
                            omegaGoal: viewModel.omegaGoal,
                            vitaminDGoal: viewModel.vitaminDGoal
                        )

                        metrics

                        topProducts

                        MicroFactCard(text: randomFact)
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
        }
    }

    private var metrics: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Fish Days",
                value: "\(viewModel.fishDaysThisWeek) of 7",
                subtitle: viewModel.fishDaysThisWeek >= 2 ? "WHO goal ok" : "Add more seafood"
            )

            StatCard(
                title: "Day Streak",
                value: "\(viewModel.fishDaysThisWeek) 🎣",
                subtitle: "This week"
            )
        }
    }

    private var topProducts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Products")
                .font(.headline)
                .foregroundColor(.white)

            if viewModel.topProductsThisWeek.isEmpty {
                Text("No data for selected period. Add entries on the main screen.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(viewModel.topProductsThisWeek.prefix(5), id: \.name) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.name)
                                .foregroundColor(.white)

                            Spacer()

                            Text("\(Int(item.percent * 100))%")
                                .foregroundColor(.white.opacity(0.8))
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))

                                Capsule()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * item.percent)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
    }

    private var randomFact: String {
        let facts = [
            "Omega-3 fatty acids support heart and vessel health.",
            "Iodine helps thyroid function.",
            "Vitamin D supports immune system activity.",
            "Zinc is important for skin, hair and nails."
        ]

        return facts.randomElement() ?? facts[0]
    }
}

struct HealthWaveChartView: View {
    let days: [(date: Date, nutrients: Nutrients)]
    let omegaGoal: Double
    let vitaminDGoal: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Wave")
                .font(.headline)
                .foregroundColor(.white)

            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.blue.opacity(0.35))

                    chartLine(
                        values: days.map { min($0.nutrients.omega3 / omegaGoal, 1.5) },
                        size: geometry.size
                    )
                    .stroke(Color.orange, lineWidth: 3)

                    chartLine(
                        values: days.map { min($0.nutrients.vitaminD / vitaminDGoal, 1.5) },
                        size: geometry.size
                    )
                    .stroke(Color.yellow, lineWidth: 3)
                }
            }
            .frame(height: 200)

            HStack {
                Label("Omega-3", systemImage: "minus")
                    .foregroundColor(.orange)

                Label("Vitamin D", systemImage: "minus")
                    .foregroundColor(.yellow)
            }
            .font(.caption)
        }
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
    }

    private func chartLine(values: [Double], size: CGSize) -> Path {
        var path = Path()

        guard values.count > 1 else {
            return path
        }

        let maxValue: Double = 1.5
        let stepX = size.width / CGFloat(values.count - 1)

        for index in values.indices {
            let x = CGFloat(index) * stepX
            let normalized = values[index] / maxValue
            let y = size.height - CGFloat(normalized) * size.height

            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.title3.bold())
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
    }
}

struct MicroFactCard: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Text("〰️")
                .font(.largeTitle)

            Text(text)
                .font(.subheadline.italic())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.25))
        .cornerRadius(18)
    }
}

// MARK: - UI Helpers

struct OceanBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.15, blue: 0.27),
                Color(red: 0.08, green: 0.33, blue: 0.48),
                Color(red: 0.5, green: 0.82, blue: 0.78)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        .ignoresSafeArea()
    }
}