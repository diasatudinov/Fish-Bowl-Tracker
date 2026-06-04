//
//  StatisticsView.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

// MARK: - Statistics

struct StatisticsView: View {
    @ObservedObject var viewModel: FishBowlViewModel

    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Text("Statistics")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                    
                }
            }.padding()
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
                .clipShape(RoundedRectangle(cornerRadius: 18))
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
        .clipShape(RoundedRectangle(cornerRadius: 18))
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
