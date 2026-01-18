import SwiftUI

struct AboutView: View {
    var body: some View {
        HStack(alignment: .top) {
            AppIconView(size: 128)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text(appName)
                        .font(.system(size: 40, weight: .light))
                        .fontWeight(.semibold)

                    Text("v\(appVersion)")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 5)

                Text("AboutView.appDescription")

                Text("AboutView.callsToAction")

                Spacer()

                (Text(copyright) + Text("AboutView.legalRights"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
        }
        .padding([.horizontal, .bottom])
        .frame(width: 480, height: 240)
        .appearOnTop()
    }

    private var bundle: Bundle { .main }

    private var appName: String {
        bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "App"
    }

    private var appVersion: String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var copyright: String {
        bundle.object(forInfoDictionaryKey: "NSHumanReadableCopyright") as? String
        ?? "© \(Calendar.current.component(.year, from: .now))"
    }
}

struct AppIconView: View {
    let size: CGFloat

    var bundle: Bundle { .main }

    var body: some View {
        Image(nsImage: icnsIcon() ?? NSApp.applicationIconImage)
            .resizable()
            .frame(width: size, height: size)
    }

    private func icnsIcon() -> NSImage? {
        guard
            let url = bundle.url(forResource: "AppIcon", withExtension: "icns"),
            let image = NSImage(contentsOf: url)
        else { return nil }

        return image
    }
}

#Preview {
    AboutView()
}
