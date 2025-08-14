/**
 * Copyright 2024-2025 Wingify Software Pvt. Ltd.
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
private let SDK_NAME = "vwo-fme-flutter-sdk"

// Plugin constants
private let INITIALIZE_VWO = "init"
private let IOS_GET_FLAG = "getFlag" // Use IOS_ prefix for iOS-specific constants
private let IOS_TRACK_EVENT = "trackEvent" // Use IOS_ prefix for iOS-specific constants
private let IOS_SET_ATTRIBUTE = "setAttribute"
private let IOS_SET_SESSION = "setSessionData"
private let IOS_SEND_SDK_INIT_EVENT = "sendSdkInitEvent"

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
public class VwoFmeFlutterSdkPlugin: NSObject, FlutterPlugin, IntegrationCallback, LogTransport {

    /// The Flutter method channel used to communicate with the Flutter framework.
    private var methodChannel: FlutterMethodChannel?

    private var logTransport: LogTransport?

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
        case IOS_SET_SESSION:
            setSessionData(call, result: result)
        case IOS_SEND_SDK_INIT_EVENT:
            sendSdkInitEvent(call, result: result)

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
        let batchMinSize = args["batchMinSize"] as? Int ?? nil
        let sdkVersion = args["sdkVersion"] as? String ?? ""
        let isUsageStatsDisabled = args["isUsageStatsDisabled"] as? Bool ?? false
        let vwoMeta = args["_vwo_meta"] as? [String: Any] ?? [:]
        let hasIntegrations = args["hasIntegrations"] as? Bool ?? false

        var batchUploadTimeInterval: Int64 = -1
        if let batchUploadTimeIntervalString = args["batchUploadTimeInterval"] as? String {
            batchUploadTimeInterval = Int64(batchUploadTimeIntervalString) ?? -1
        }

        var logLevel: LogLevelEnum = .error
        if let loggerLevel = logger?["level"] as? String,
           let level = LogLevelEnum(rawValue: loggerLevel.uppercased()) {
            logLevel = level
        }
        
        // Initialize the logger
        if let logger = logger, let transports = logger["transports"] as? [[String: Any]], !transports.isEmpty {
            self.logTransport = self
        }

        let logPrefix = logger?["prefix"] as? String ?? ""

        let vwoOptions = VWOInitOptions(sdkKey: sdkKey,
                                        accountId: accountId,
                                        logLevel: logLevel,
                                        logPrefix: logPrefix,
                                        integrations: hasIntegrations ? self : nil,
                                        gatewayService: gatewayService ?? [:],
                                        cachedSettingsExpiryTime: cachedSettingsExpiryTime,
                                        pollInterval: pollInterval,
                                        batchMinSize: batchMinSize == -1 ? nil : batchMinSize,
                                        batchUploadTimeInterval: batchUploadTimeInterval == -1 ? nil : batchUploadTimeInterval,
                                        sdkName: SDK_NAME,
                                        sdkVersion: sdkVersion,
                                        logTransport: self.logTransport,
                                        isUsageStatsDisabled: isUsageStatsDisabled,
                                        vwoMeta: vwoMeta)

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
    
    /// LogTransport implementation
    public func log(logType: String, message: String) {
        let properties = [
            "level": logType,
            "message": message
        ]
        methodChannel?.invokeMethod("onLoggerCallback", arguments: properties)
    }

    /// Gets the value of a feature flag.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func getFlag(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let flagName = args["flagName"] as? String,
              let usrContext = args["userContext"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "flagName and userContext are required", details: nil))
            return
        }

        // Initialize VWOUserContext with id, customVariables
        let userContext = VWOUserContext(id: usrContext["id"] as? String,
                                    customVariables: usrContext["customVariables"] as? [String: Any] ?? [:])

        // Call VWOFme.getFlag with the initialized VWOUserContext
        VWOFme.getFlag(featureKey: flagName, context: userContext) { flag in
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

        let userContext = VWOUserContext(id: context["id"] as? String,
                                    customVariables: context["customVariables"] as? [String: Any] ?? [:])

        // Call the VWO SDK's trackEvent method
        if let properties = eventProperties {
            VWOFme.trackEvent(eventName: eventName, context: userContext, eventProperties: properties)
        } else {
            VWOFme.trackEvent(eventName: eventName, context: userContext)
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
              let attributes = args["attributes"] as? [String: Any],
              let context = args["context"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "attributeKey, attributeValue, and context are required", details: nil))
            return
        }

        let userContext = VWOUserContext(id: context["id"] as? String,
                                    customVariables: context["customVariables"] as? [String: Any] ?? [:])
        VWOFme.setAttribute(attributes: attributes, context: userContext)
        result(true)
    }

    /// Function to set the session data.
    ///
    /// - Parameters:
    /// - call: The method call.
    /// - result: The result callback.
    private func setSessionData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let sessionData = call.arguments as? [String: Any] {
            FmeConfig.setSessionData(sessionData)
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_ARGUMENT",
            message: "Session data is null",
            details: nil))
        }
    }

    /// Sends SDK initialization event with timing information.
    ///
    /// - Parameters:
    /// - call: The method call.
    /// - result: The result callback.
    private func sendSdkInitEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sdkInitTimeStr = args["sdkInitTime"] as? String,
              let sdkInitTime = Int64(sdkInitTimeStr) else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "sdkInitTime is required and must be a valid number", details: nil))
            return
        }

        // Call the native VWO SDK's sendSdkInitEvent method
        VWOFme.sendSdkInitEvent(sdkInitTime: sdkInitTime)
        result(true)
    }
}
