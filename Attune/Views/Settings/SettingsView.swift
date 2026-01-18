import SwiftUI

extension SettingsView {
    enum Tab {
        case general
        case whitelist
    }
}

extension SettingsView {
    @Observable
    final class ViewModel {
        var selection: Tab = .general

        var generalSettingsIcon: String {
            Icon.generalSettings.name + (selection == .general ? ".fill" : "")
        }

        var whitelistSettingsIcon: String {
            Icon.whitelistSettings.name + (selection == .whitelist ? ".fill" : "")
        }
    }
}

struct SettingsView: View {
    @Environment(AppSettings.self) var settings

    @Bindable private var viewModel = ViewModel()

    let generalSettingsViewModel: GeneralSettingsView.ViewModel
    let whitelistSettingsViewModel: WhitelistSettingsView.ViewModel

    var body: some View {
        TabView(selection: $viewModel.selection) {
            GeneralSettingsView(viewModel: generalSettingsViewModel)
                .tabItem {
                    Label(
                        "SettingsView.generalSettingsTabLabel",
                        systemImage: viewModel.generalSettingsIcon
                    )
                }
                .tag(Tab.general)

            WhitelistSettingsView(viewModel: whitelistSettingsViewModel)
                .tabItem {
                    Label(
                        "SettingsView.whitelistSettingsTabLabel",
                        systemImage: viewModel.whitelistSettingsIcon
                    )
                }
                .tag(Tab.whitelist)
        }
        .frame(width: 400)
        .fixedSize(horizontal: true, vertical: false)
        .appearOnTop()
    }
}
