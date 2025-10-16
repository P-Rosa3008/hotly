import Flutter
import UIKit

#if DEBUG
public class HotlyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.szotp.Hotly", binaryMessenger: registrar.messenger())

        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public static let instance = HotlyPlugin()

    var root: URL?

    public func setRoot(path: StaticString = #file) {
        #if DEBUG
        var url = URL(fileURLWithPath: "\(path)")
        let fm = FileManager.default

        while !fm.fileExists(atPath: url.appendingPathComponent("pubspec.yaml").path) {
            url = url.deletingLastPathComponent()
        }

        root = url.appendingPathComponent("test")

        print(root!)
        #endif
    }

    lazy var engine = FlutterEngine(name: "hotly", project: nil, allowHeadlessExecution: true)

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            let ok = engine.run(withEntrypoint: "hotly")

            var returns: [String: Any] = [:]
            returns["ok"] = ok
            if let root = root {
                returns["root"] = root.path
            }

            result(returns)
        default:
            assertionFailure()
            result(nil)
        }
    }
}
#else
public class HotlyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {}
    public func setRoot(path: StaticString = #file) {}
}
#endif
