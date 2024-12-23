/**
 * Copyright 2024 Wingify Software Pvt. Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Flutter
import UIKit
import VWO_FME

//Constants
private let SDK_VERSION = "1.0.0"
private let SDK_NAME = "vwo-fme-flutter-sdk"

// Plugin constants
private let INITIALIZE_VWO = "init"
private let IOS_GET_FLAG = "getFlag" // Use IOS_ prefix for iOS-specific constants
private let IOS_TRACK_EVENT = "trackEvent" // Use IOS_ prefix for iOS-specific constants
private let IOS_SET_ATTRIBUTE = "setAttribute"

/// The VWO FME Flutter SDK plugin for iOS.
///
/// This plugin provides a bridge between the Flutter framework and the VWO FME SDK for iOS.
/// It allows you to integrate VWO FME into your Flutter app and use its features, such as:
///
/// - Initializing the SDK
/// - Getting feature flags
/// - Tracking events
/// - Setting user attributes
///
/// To use this plugin, add `vwo_fme_flutter_sdk` as a dependency in your pubspec.yaml file.
public class VwoFmeFlutterSdkPlugin: NSObject, FlutterPlugin, IntegrationCallback  {

    /// The Flutter method channel used to communicate with the Flutter framework.
    private var methodChannel: FlutterMethodChannel?

    /// Registers the plugin with the Flutter framework.
    /// - Parameter registrar: The Flutter plugin registrar.
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "vwo_fme_flutter_sdk", binaryMessenger: registrar.messenger())
        let instance = VwoFmeFlutterSdkPlugin()
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// Handles method calls from the Flutter framework.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case INITIALIZE_VWO:
            initializeVWO(call, result: result)
        case IOS_GET_FLAG:
            getFlag(call, result: result)
        case IOS_TRACK_EVENT:
            trackEvent(call, result: result)
        case IOS_SET_ATTRIBUTE:
            setAttribute(call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Initializes the VWO SDK.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func initializeVWO(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sdkKey = args["sdkKey"] as? String,
              let accountId = args["accountId"] as? Int else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "sdkKey and accountId are required", details: nil))
            return
        }
        
        let logger = args["logger"] as? [String: Any]
        let gatewayService = args["gatewayService"] as? [String: Any]
        let pollInterval: Int64? = args["pollInterval"] as? Int64 ?? nil
        let cachedSettingsExpiryTime: Int64? = args["cachedSettingsExpiryTime"] as? Int64 ?? nil
        
        var logLevel: LogLevelEnum = .error
        if let loggerLevel = logger?["level"] as? String,
           let level = LogLevelEnum(rawValue: loggerLevel.uppercased()) {
            logLevel = level
        }
        
        let vwoOptions = VWOInitOptions(sdkKey: sdkKey,
                                        accountId: accountId,
                                        logLevel: logLevel,
                                        integrations: self,
                                        gatewayService: gatewayService ?? [:],
                                        cachedSettingsExpiryTime: cachedSettingsExpiryTime,
                                        pollInterval: pollInterval,
                                        sdkName: SDK_VERSION,
                                        sdkVersion: SDK_NAME)
        
        VWOFme.initialize(options: vwoOptions) { initResult in
            switch initResult {
            case .success(let message):
                result(message)
            case .failure(let error):
                result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }

    /// Executes the integration callback with the given properties.
    ///
    /// - Parameter properties: The properties to pass to the callback.
    public func execute(_ properties: [String: Any]) {
            methodChannel?.invokeMethod("onIntegrationCallback", arguments: properties)
    }

    /// Gets the value of a feature flag.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func getFlag(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let flagName = args["flagName"] as? String,
              let userContext = args["userContext"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "flagName and userContext are required", details: nil))
            return
        }

        // Extract ipAddress and userAgent from userContext
        let ipAddress = userContext["ipAddress"] as? String ?? ""
        let userAgent = userContext["userAgent"] as? String ?? ""
        // Initialize VWOContext with id, customVariables, ipAddress, and userAgent
        let vwoContext = VWOContext(id: userContext["id"] as? String,
                                    customVariables: userContext["customVariables"] as? [String: Any] ?? [:],
                                    ipAddress: ipAddress,
                                    userAgent: userAgent)

        // Call VWOFme.getFlag with the initialized VWOContext
        VWOFme.getFlag(featureKey: flagName, context: vwoContext) { flag in
            let flagResult: [String: Any] = [
                "isEnabled": flag.isEnabled(),
                "variables": flag.getVariables(),
            ]
            result(flagResult)
        }
    }

    /// Tracks an event.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func trackEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let eventName = args["eventName"] as? String,
              let context = args["context"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "eventName and context are required", details: nil))
            return
        }
        
        let eventProperties = args["eventProperties"] as? [String: Any]
        
        let vwoContext = VWOContext(id: context["id"] as? String,
                                    customVariables: context["customVariables"] as? [String: Any] ?? [:])
        
        // Call the VWO SDK's trackEvent method
        if let properties = eventProperties {
            VWOFme.trackEvent(eventName: eventName, context: vwoContext, eventProperties: properties)
        } else {
            VWOFme.trackEvent(eventName: eventName, context: vwoContext)
        }
        let response: [String: Bool] = ["success": true]
        result(response)
    }

    /// Sets a user attribute.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func setAttribute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let attributeKey = args["attributeKey"] as? String,
              let attributeValue = args["attributeValue"],
              let context = args["context"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "attributeKey, attributeValue, and context are required", details: nil))
            return
        }
        
        let vwoContext = VWOContext(id: context["id"] as? String,
                                    customVariables: context["customVariables"] as? [String: Any] ?? [:])
        VWOFme.setAttribute(attributeKey: attributeKey, attributeValue: attributeValue, context: vwoContext)
        result(true)
    }
}
