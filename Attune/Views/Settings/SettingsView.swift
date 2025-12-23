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
            selection == .general
            ? "gearshape.fill"
            : "gearshape"
        }

        var whitelistSettingsIcon: String {
            selection == .whitelist
            ? "checkmark.seal.fill"
            : "checkmark.seal"
        }
    }
}

struct SettingsView: View {
    @Environment(AppSettings.self) var settings

    @Bindable private var viewModel = ViewModel()

    let whitelistSettingsViewModel: WhitelistSettingsView.ViewModel

    var body: some View {
        TabView(selection: $viewModel.selection) {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: viewModel.generalSettingsIcon) }
                .tag(Tab.general)

            WhitelistSettingsView(viewModel: whitelistSettingsViewModel)
                .tabItem { Label("Whitelist", systemImage: viewModel.whitelistSettingsIcon) }
                .tag(Tab.whitelist)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
