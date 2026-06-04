//
//  DashboardView.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

// MARK: - Dashboard

struct DashboardView: View {
    @ObservedObject var viewModel: FishBowlViewModel
    @State private var isAddPresented = false

    var body: some View {
            ZStack {
                Color.clear

                VStack {
                    
                    Text("Fish Bowl Tracker")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                        .padding(.bottom, 90)
                    }
                }.padding()

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
            .sheet(isPresented: $isAddPresented) {
                AddPortionView(viewModel: viewModel)
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
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.product.name) \(Int(entry.weight)) g")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white)

                Text("+\(String(format: "%.1f", entry.nutrients.protein)) g protein • +\(String(format: "%.1f", entry.nutrients.omega3)) g omega")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))

                Text(entry.fact)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            Image(.cellBgFB)
                .resizable()
        )
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
        ZStack {
            OceanBackground()
            
            ScrollView {
                VStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            
                            Image(systemName: "arrow.backward")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("Add Portion")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    VStack(spacing: 20) {
                        categoryGrid
                        
                        selectedProductCard
                        
                        weightBlock
                        
                        methodPicker
                        
                        nutrientPreview
                        
                        saveButton
                    }
                }
                .padding()
            }
        }
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
