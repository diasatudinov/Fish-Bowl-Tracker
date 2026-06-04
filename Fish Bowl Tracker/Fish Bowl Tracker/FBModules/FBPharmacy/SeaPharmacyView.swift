//
//  SeaPharmacyView.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

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
        ZStack {
            Color.clear
            
            VStack(spacing: 12) {
                Text("Sea Pharmacy")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
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
            Image("\(product.name)Icon")
                .resizable()
                .scaledToFit()
                .frame(height: 40)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.vertical, 6)
        .background(
            Image(.cellBgFB)
                .resizable()
        )
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
                        Image("\(product.name)Icon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 72)

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
