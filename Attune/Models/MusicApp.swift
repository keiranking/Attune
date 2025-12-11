import ScriptingBridge

final class MusicApp {
    static let shared = MusicApp()

    private var proxy: MusicApplication?

    private init() {}

    var app: MusicApplication? {
        validateProxy()
        return proxy
    }

    private func validateProxy() {
        if proxy == nil {
            proxy = createProxy()
            return
        }

        if proxy?.isRunning == false {
            print("MusicApp: Detected stale proxy. Reconnecting.")
            proxy = createProxy()
        }
    }

    private func createProxy() -> MusicApplication? {
        guard let base = SBApplication(bundleIdentifier: "com.apple.Music") else {
            print("MusicApp: SBApplication returned nil.")
            return nil
        }

        return unsafeBitCast(base, to: MusicApplication.self)
    }
}
