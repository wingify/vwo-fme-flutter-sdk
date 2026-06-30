/**
 * Copyright 2024-2026 Wingify Software Pvt. Ltd.
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

#if WINGIFY_FME_FLUTTER_SDK
import Wingify_FME
#elseif VWO_FME_FLUTTER_SDK
import VWO_FME
#else
#error("Build with vwo_fme_flutter_sdk or wingify_fme_flutter_sdk podspec so the correct native FME module is linked.")
#endif

//Constants
private let SDK_NAME = "vwo-fme-flutter-sdk"
private let WINGIFY_SDK_NAME = "wingify-fme-flutter-sdk"

// Plugin constants
private let INITIALIZE_VWO = "init"
private let IOS_GET_FLAG = "getFlag" // Use IOS_ prefix for iOS-specific constants
private let IOS_TRACK_EVENT = "trackEvent" // Use IOS_ prefix for iOS-specific constants
private let IOS_SET_ATTRIBUTE = "setAttribute"
private let IOS_SET_ALIAS = "setAlias"
private let IOS_CLEAR_INSTANCE = "clearInstance"
private let IOS_SET_SESSION = "setSessionData"
private let IOS_SEND_SDK_INIT_EVENT = "sendSdkInitEvent"

/// The FME Flutter SDK plugin for iOS.
///
/// This plugin bridges the Flutter framework and the native FME SDK for iOS. The linked native pod
/// depends on the published Flutter package (`VWO-FME` for `vwo_fme_flutter_sdk`, `Wingify-FME`
/// for `wingify_fme_flutter_sdk`). Both native modules expose the legacy `VWOFme` and `WingifyFme`
/// APIs. Every call carries a `useWingifyApi` flag from Flutter: `true` routes through the Wingify
/// API, `false` through the legacy VWO API.
public class VwoFmeFlutterSdkPlugin: NSObject, FlutterPlugin, IntegrationCallback, LogTransport {

    /// The Flutter method channel used to communicate with the Flutter framework.
    private var methodChannel: FlutterMethodChannel?

    private var logTransport: LogTransport?

    private func getVWOInstance(accountId: Int?, sdkKey: String?) -> VWOFme? {
        guard let accountId = accountId,
              let sdkKey = sdkKey,
              !sdkKey.isEmpty else {
            return nil
        }
        return VWOFme.getInstance(accountId: accountId, sdkKey: sdkKey)
    }

    private func getWingifyInstance(accountId: Int?, sdkKey: String?) -> WingifyFme? {
        guard let accountId = accountId,
              let sdkKey = sdkKey,
              !sdkKey.isEmpty else {
            return nil
        }
        return WingifyFme.getInstance(accountId: accountId, sdkKey: sdkKey)
    }

    private func vwoContext(_ dict: [String: Any]) -> VWOUserContext {
        return VWOUserContext(id: dict["id"] as? String,
                              shouldUseDeviceIdAsUserId: dict["shouldUseDeviceIdAsUserId"] as? Bool ?? false,
                              customVariables: dict["customVariables"] as? [String: Any] ?? [:])
    }

    private func wingifyContext(_ dict: [String: Any]) -> WingifyUserContext {
        return WingifyUserContext(id: dict["id"] as? String,
                                  shouldUseDeviceIdAsUserId: dict["shouldUseDeviceIdAsUserId"] as? Bool ?? false,
                                  customVariables: dict["customVariables"] as? [String: Any] ?? [:])
    }

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
        case IOS_SET_ALIAS:
            setAlias(call, result: result)
        case IOS_CLEAR_INSTANCE:
            clearInstance(call, result: result)
        case IOS_SET_SESSION:
            setSessionData(call, result: result)
        case IOS_SEND_SDK_INIT_EVENT:
            sendSdkInitEvent(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Initializes the SDK, routing through the Wingify or legacy VWO API.
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
        let isAliasingEnabled = args["isAliasingEnabled"] as? Bool ?? false
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        var batchUploadTimeInterval: Int64 = -1
        if let batchUploadTimeIntervalString = args["batchUploadTimeInterval"] as? String {
            batchUploadTimeInterval = Int64(batchUploadTimeIntervalString) ?? -1
        }

        var logLevel: LogLevelEnum = .error
        if let loggerLevel = logger?["level"] as? String {
            let normalizedLevel = loggerLevel.lowercased()
            if let level = LogLevelEnum(rawValue: normalizedLevel) {
                logLevel = level
            } else {
                print("FME Flutter Plugin: Invalid log level received: \(loggerLevel). Falling back to .error")
            }
        }

        // Initialize the logger
        if let logger = logger, let transports = logger["transports"] as? [[String: Any]], !transports.isEmpty {
            self.logTransport = self
        }

        let logPrefix = logger?["prefix"] as? String ?? ""
        let integrations: IntegrationCallback? = hasIntegrations ? self : nil
        let resolvedBatchMinSize = batchMinSize == -1 ? nil : batchMinSize
        let resolvedBatchInterval: Int64? = batchUploadTimeInterval == -1 ? nil : batchUploadTimeInterval

        let completion: WingifyInitCompletionHandler = { initResult in
            switch initResult {
            case .success(let message):
                result(message)
            case .failure(let error):
                result(FlutterError(code: "INIT_ERROR", message: error.localizedDescription, details: nil))
            }
        }

        if useWingifyApi {
            let options = WingifyInitOptions(sdkKey: sdkKey,
                                             accountId: accountId,
                                             logLevel: logLevel,
                                             logPrefix: logPrefix,
                                             integrations: integrations,
                                             gatewayService: gatewayService ?? [:],
                                             cachedSettingsExpiryTime: cachedSettingsExpiryTime,
                                             pollInterval: pollInterval,
                                             batchMinSize: resolvedBatchMinSize,
                                             batchUploadTimeInterval: resolvedBatchInterval,
                                             sdkName: WINGIFY_SDK_NAME,
                                             sdkVersion: sdkVersion,
                                             logTransport: self.logTransport,
                                             isUsageStatsDisabled: isUsageStatsDisabled,
                                             vwoMeta: vwoMeta,
                                             storage: nil,
                                             isAliasingEnabled: isAliasingEnabled)
            WingifyFme.initialize(options: options, completion: completion)
        } else {
            let options = VWOInitOptions(sdkKey: sdkKey,
                                         accountId: accountId,
                                         logLevel: logLevel,
                                         logPrefix: logPrefix,
                                         integrations: integrations,
                                         gatewayService: gatewayService ?? [:],
                                         cachedSettingsExpiryTime: cachedSettingsExpiryTime,
                                         pollInterval: pollInterval,
                                         batchMinSize: resolvedBatchMinSize,
                                         batchUploadTimeInterval: resolvedBatchInterval,
                                         sdkName: SDK_NAME,
                                         sdkVersion: sdkVersion,
                                         logTransport: self.logTransport,
                                         isUsageStatsDisabled: isUsageStatsDisabled,
                                         vwoMeta: vwoMeta,
                                         storage: nil,
                                         isAliasingEnabled: isAliasingEnabled)
            VWOFme.initialize(options: options, completion: completion)
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

        let accountId = args["accountId"] as? Int
        let sdkKey = args["sdkKey"] as? String
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        let handler: (GetFlag) -> Void = { flag in
            result([
                "isEnabled": flag.isEnabled(),
                "variables": flag.getVariables(),
            ])
        }

        if useWingifyApi {
            let userContext = wingifyContext(usrContext)
            if let instance = getWingifyInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.getFlag(featureKey: flagName, context: userContext, completion: handler)
            } else {
                WingifyFme.getFlag(featureKey: flagName, context: userContext, completion: handler)
            }
        } else {
            let userContext = vwoContext(usrContext)
            if let instance = getVWOInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.getFlag(featureKey: flagName, context: userContext, completion: handler)
            } else {
                VWOFme.getFlag(featureKey: flagName, context: userContext, completion: handler)
            }
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

        let accountId = args["accountId"] as? Int
        let sdkKey = args["sdkKey"] as? String
        let eventProperties = args["eventProperties"] as? [String: Any]
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        if useWingifyApi {
            let userContext = wingifyContext(context)
            if let instance = getWingifyInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.trackEvent(eventName: eventName, context: userContext, eventProperties: eventProperties)
            } else {
                WingifyFme.trackEvent(eventName: eventName, context: userContext, eventProperties: eventProperties)
            }
        } else {
            let userContext = vwoContext(context)
            if let instance = getVWOInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.trackEvent(eventName: eventName, context: userContext, eventProperties: eventProperties)
            } else {
                VWOFme.trackEvent(eventName: eventName, context: userContext, eventProperties: eventProperties)
            }
        }
        result(["success": true])
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

        let accountId = args["accountId"] as? Int
        let sdkKey = args["sdkKey"] as? String
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        if useWingifyApi {
            let userContext = wingifyContext(context)
            if let instance = getWingifyInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.setAttribute(attributes: attributes, context: userContext)
            } else {
                WingifyFme.setAttribute(attributes: attributes, context: userContext)
            }
        } else {
            let userContext = vwoContext(context)
            if let instance = getVWOInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.setAttribute(attributes: attributes, context: userContext)
            } else {
                VWOFme.setAttribute(attributes: attributes, context: userContext)
            }
        }
        result(true)
    }

    /// Sets an alias for a user (links temporary user ID to original user ID).
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func setAlias(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let userContextDict = args["userContext"] as? [String: Any],
              let alias = args["alias"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "userContext and alias are required", details: nil))
            return
        }

        let accountId = args["accountId"] as? Int
        let sdkKey = args["sdkKey"] as? String
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        if useWingifyApi {
            let userContext = wingifyContext(userContextDict)
            if let instance = getWingifyInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.setAlias(from: userContext, to: alias)
            } else {
                WingifyFme.setAlias(from: userContext, to: alias)
            }
        } else {
            let userContext = vwoContext(userContextDict)
            if let instance = getVWOInstance(accountId: accountId, sdkKey: sdkKey) {
                instance.setAlias(from: userContext, to: alias)
            } else {
                VWOFme.setAlias(from: userContext, to: alias)
            }
        }
        result(true)
    }

    /// Clears a specific instance from the shared native cache.
    ///
    /// - Parameters:
    ///   - call: The method call.
    ///   - result: The result callback.
    private func clearInstance(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let accountId = args["accountId"] as? Int,
              let sdkKey = args["sdkKey"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "accountId and sdkKey are required", details: nil))
            return
        }

        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false
        if useWingifyApi {
            WingifyFme.clearInstance(accountId: accountId, sdkKey: sdkKey)
        } else {
            VWOFme.clearInstance(accountId: accountId, sdkKey: sdkKey)
        }
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

        let accountId = args["accountId"] as? Int
        let sdkKey = args["sdkKey"] as? String
        let useWingifyApi = args["useWingifyApi"] as? Bool ?? false

        if useWingifyApi {
            getWingifyInstance(accountId: accountId, sdkKey: sdkKey)?.sendSdkInitEvent(sdkInitTime: sdkInitTime)
        } else {
            getVWOInstance(accountId: accountId, sdkKey: sdkKey)?.sendSdkInitEvent(sdkInitTime: sdkInitTime)
        }

        result(true)
    }
}
