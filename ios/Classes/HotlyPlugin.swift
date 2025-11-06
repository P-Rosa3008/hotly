import Flutter
import UIKit

public class HotlyPlugin: NSObject, FlutterPlugin {
    
    var root: URL?
    lazy var engine = FlutterEngine(name: "hotly", project: nil, allowHeadlessExecution: true)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.szotp.Hotly", binaryMessenger: registrar.messenger())
        let instance = HotlyPlugin()
        //instance.setRoot() // ✅ ensure root is ready
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func setRoot(path: StaticString = #file) {
        var url = URL(fileURLWithPath: "\(path)")
        let fm = FileManager.default

        while !fm.fileExists(atPath: url.appendingPathComponent("pubspec.yaml").path) {
            url = url.deletingLastPathComponent()
            if url.path == "/" { break }
        }

        root = url.appendingPathComponent("test")
        print("[HotlyPlugin] root set to \(root?.path ?? "<nil>")")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            let ok = engine.run(withEntrypoint: "hotly")
            var returns: [String: Any] = ["ok": ok]
            if let root = root {
                returns["root"] = root.path
            }
            result(returns)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
