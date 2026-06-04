//
//  FishBowlTrackerApp.swift
//  Fish Bowl Tracker
//
//

import SwiftUI

// MARK: - Root

struct ContentView: View {
    @StateObject private var viewModel = FishBowlViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                OceanBackground()
                
                VStack(spacing: 0) {
                    currentScreen
                    
                    BottomTabBar(viewModel: viewModel)
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch viewModel.selectedTab {
        case .bowl:
            DashboardView(viewModel: viewModel)
        case .pharmacy:
            SeaPharmacyView()
        case .statistics:
            StatisticsView(viewModel: viewModel)
        }
    }
}

struct BottomTabBar: View {
    @ObservedObject var viewModel: FishBowlViewModel
    
    var body: some View {
        
            HStack(spacing: 12) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        viewModel.selectedTab = tab
                        
                    } label: {
                        Image(isSelected(tab) ? tab.selectedIcon : tab.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: isSelected(tab) ? 50 : 40)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, isSelected(tab) ? 0 : 10)
                }
                
            }
            .padding(.horizontal, 18)
            .background(Color.tabBg)
        
    }
    
    private func isSelected(_ tab: AppTab) -> Bool {
        viewModel.selectedTab == tab
    }
}

enum AppTab: Int, CaseIterable, Identifiable {
    case bowl
    case pharmacy
    case statistics
    
    var id: Int { rawValue }
    
    var selectedIcon: String {
        switch self {
        case .bowl: return "selectedTab1"
        case .pharmacy: return "selectedTab2"
        case .statistics: return "selectedTab3"
        }
    }
    
    var icon: String {
        switch self {
        case .bowl: return "tab1"
        case .pharmacy: return "tab2"
        case .statistics: return "tab3"
        }
    }
}

// MARK: - UI Helpers

struct OceanBackground: View {
    var body: some View {
        Image(.appBgFB)
            .resizable()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
