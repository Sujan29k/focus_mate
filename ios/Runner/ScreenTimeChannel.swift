import Flutter
import UIKit
import FamilyControls

@available(iOS 15.0, *)
class ScreenTimeChannel: NSObject, FlutterPlugin {
    static let channelName = "com.focusmate.screentime"
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = ScreenTimeChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuthorization(result: result)
            
        case "checkAuthorizationStatus":
            checkAuthorizationStatus(result: result)
            
        case "getScreenTimeData":
            getScreenTimeData(result: result)
            
        case "startMonitoring":
            startMonitoring(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func requestAuthorization(result: @escaping FlutterResult) {
        ScreenTimeManager.shared.requestAuthorization { success, error in
            if success {
                result(["success": true, "message": "Authorization granted"])
            } else {
                result(["success": false, "error": error ?? "Unknown error"])
            }
        }
    }
    
    private func checkAuthorizationStatus(result: @escaping FlutterResult) {
        let status = ScreenTimeManager.shared.checkAuthorizationStatus()
        result(["status": status, "authorized": status == "approved"])
    }
    
    private func getScreenTimeData(result: @escaping FlutterResult) {
        // Check if we should return mock data or real data
        let useMockData = true // Set to false when real monitoring is implemented
        
        if useMockData {
            let mockData = ScreenTimeManager.shared.getMockScreenTimeData()
            result([
                "success": true,
                "apps": mockData,
                "isMockData": true,
                "message": "Mock data for demonstration. Real data requires DeviceActivityReport extension."
            ])
        } else {
            ScreenTimeManager.shared.getScreenTimeData { data in
                result(data)
            }
        }
    }
    
    private func startMonitoring(result: @escaping FlutterResult) {
        let success = ScreenTimeManager.shared.startMonitoring()
        result(["success": success, "message": success ? "Monitoring started" : "Authorization required"])
    }
}
