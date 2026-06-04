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
package com.vwo.vwo_fme_flutter_sdk

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.vwo.VWO
import com.vwo.interfaces.IVwoInitCallback
import com.vwo.interfaces.logger.LogTransport
import com.vwo.models.user.FMEConfig
import com.vwo.models.user.VWOInitOptions
import com.vwo.packages.logger.enums.LogLevelEnum
import com.wingify.Wingify
import com.wingify.WingifyClient
import com.wingify.interfaces.IWingifyInitCallback
import com.wingify.interfaces.integration.IntegrationCallback
import com.wingify.models.user.GatewayService
import com.wingify.models.user.WingifyInitOptions
import com.wingify.models.user.WingifyUserContext
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.concurrent.thread
import kotlin.text.toLongOrNull

const val SDK_NAME = "vwo-fme-flutter-sdk"
const val WINGIFY_SDK_NAME = "wingify-fme-flutter-sdk"

/**
 * Bridge between the Flutter method channel and the native FME SDK.
 *
 * The native SDK ships both the legacy `com.vwo` and the `com.wingify` APIs from a single
 * binary, sharing one instance cache. Every call carries a `useWingifyApi` flag from Flutter:
 * `true` routes through the Wingify API, `false` through the legacy VWO API. Since both clients
 * derive from [WingifyClient], all post-init operations run against that common type and only
 * initialization and instance lookup branch on the flag.
 */
@Suppress("DEPRECATION") // Legacy com.vwo.* APIs are used intentionally for backward compatibility.
class VWOBridge(private val context: Context) {

    /**
     * Returns the initialized client for [accountId]/[sdkKey], using the Wingify or VWO lookup
     * based on [useWingifyApi]. Both clients share the same cache but cast to sibling types, so
     * the lookup must match the API used at initialization.
     */
    private fun getClient(
        accountId: Int?,
        sdkKey: String?,
        useWingifyApi: Boolean
    ): WingifyClient? {
        if (accountId == null || sdkKey.isNullOrEmpty()) return null
        return if (useWingifyApi) {
            Wingify.getInstance(accountId, sdkKey)
        } else {
            VWO.getInstance(accountId, sdkKey)
        }
    }

    /**
     * Builds a [WingifyUserContext] from the map sent by Flutter. Accepted by both the Wingify
     * and VWO native APIs.
     */
    private fun buildUserContext(map: Map<*, *>): WingifyUserContext {
        return WingifyUserContext().apply {
            id = map["id"] as? String
            (map["customVariables"] as? Map<String, Any>)?.let { customVariables.putAll(it) }
            (map["variationTargetingVariables"] as? Map<String, Any>)?.let {
                variationTargetingVariables.putAll(it)
            }
            shouldUseDeviceIdAsUserId = map["shouldUseDeviceIdAsUserId"] as? Boolean ?: false
            (map["gatewayService"] as? Map<*, *>)?.let { gateway ->
                vwo = GatewayService().apply {
                    location = gateway["location"] as? Map<String, String>
                }
            }
        }
    }

    /**
     * Initializes the FME SDK, routing through the Wingify or legacy VWO API.
     */
    fun initializeVWO(call: MethodCall, result: Result, channel: MethodChannel) {

        val args = call.arguments as? Map<*, *> ?: run {
            result.error("INVALID_ARGUMENTS", "Arguments should be a map", null)
            return
        }

        val sdkKey = args["sdkKey"] as? String ?: run {
            result.error("INVALID_ARGUMENTS", "sdkKey is required", null)
            return
        }

        val accountId = args["accountId"] as? Int ?: run {
            result.error("INVALID_ARGUMENTS", "accountId is required", null)
            return
        }

        val logger = args["logger"] as? Map<String, Any>
        val gatewayServiceMap = args["gatewayService"] as? Map<*, *>
        val pollInterval = (args["pollInterval"] as? Int) ?: 0
        val cachedSettingsExpiryTime = (args["cachedSettingsExpiryTime"] as? Int) ?: 0
        val batchMinSize = (args["batchMinSize"] as? Int) ?: -1
        val batchUploadTimeIntervalString = args["batchUploadTimeInterval"] as? String
        val batchUploadTimeInterval = batchUploadTimeIntervalString?.toLongOrNull() ?: -1L
        val sdkVersion = args["sdkVersion"] as? String ?: ""
        val isUsageStatsDisabled = args["isUsageStatsDisabled"] as? Boolean ?: false
        val vwoMeta = args["_vwo_meta"] as? Map<String, Any> ?: mapOf()
        val hasIntegrations = args["hasIntegrations"] as? Boolean ?: false
        val isAliasingEnabled = args["isAliasingEnabled"] as? Boolean ?: false
        val useWingifyApi = args["useWingifyApi"] as? Boolean ?: false

        val initOptions: WingifyInitOptions =
            if (useWingifyApi) WingifyInitOptions() else VWOInitOptions()
        initOptions.apply {
            this.sdkKey = sdkKey
            this.accountId = accountId
            logger?.let { map ->
                val loggerMap = mutableMapOf<String, Any>()
                map["name"]?.let { loggerMap["name"] = it }
                map["level"]?.let { loggerMap["level"] = it }
                map["prefix"]?.let { loggerMap["prefix"] = it }
                map["dateTimeFormat"]?.let { loggerMap["dateTimeFormat"] = it }

                setLogger(map, loggerMap, channel)
                this.logger = loggerMap
            }
            gatewayServiceMap?.let { map ->
                val gatewayMap = mutableMapOf<String, Any>()
                map["url"]?.let { gatewayMap["url"] = it }
                map["protocol"]?.let { gatewayMap["protocol"] = it }
                map["port"]?.let { gatewayMap["port"] = it }
                this.gatewayService = gatewayMap
            }
            if (pollInterval > 0) {
                this.pollInterval = pollInterval
            }
            if (cachedSettingsExpiryTime > 0) {
                this.cachedSettingsExpiryTime = cachedSettingsExpiryTime
            }
            if (batchMinSize > 0) {
                this.batchMinSize = batchMinSize
            }
            if (batchUploadTimeInterval > 0) {
                this.batchUploadTimeInterval = batchUploadTimeInterval
            }
            this.context = this@VWOBridge.context.applicationContext
            this.sdkVersion = sdkVersion
            this.sdkName = if (useWingifyApi) WINGIFY_SDK_NAME else SDK_NAME
            this.isUsageStatsDisabled = isUsageStatsDisabled
            this._vwo_meta = vwoMeta
            this.isAliasingEnabled = isAliasingEnabled
        }

        // Only set integrations if provided by the client
        if (hasIntegrations) {
            initOptions.integrations = object : IntegrationCallback {
                override fun execute(properties: Map<String, Any>) {
                    Handler(Looper.getMainLooper()).post {
                        // Filter out objects and keep only basic data types
                        val filteredProperties = filterBasicDataTypes(properties)
                        channel.invokeMethod("onIntegrationCallback", filteredProperties)
                    }
                }
            }
        }

        if (useWingifyApi) {
            Wingify.init(initOptions, object : IWingifyInitCallback {
                override fun wingifyInitSuccess(wingify: Wingify, message: String) {
                    result.success("Wingify is ready to use.")
                }

                override fun wingifyInitFailed(message: String) {
                    result.error("INIT_ERROR", message, null)
                }
            })
        } else {
            VWO.init(initOptions as VWOInitOptions, object : IVwoInitCallback {
                override fun vwoInitSuccess(vwo: VWO, message: String) {
                    result.success("VWO is ready to use.")
                }

                override fun vwoInitFailed(message: String) {
                    result.error("INIT_ERROR", message, null)
                }
            })
        }
    }

    /**
     * Sets up a logger for the FME SDK to forward log messages to Flutter.
     *
     * This function configures a logging mechanism that captures log messages
     * from the native (Android) side and sends them to the Flutter side via a
     * [MethodChannel]. It checks if the provided map contains a "transports" key
     * and if the corresponding value is a non-empty map. If these conditions are
     * met, it creates a [LogTransport] implementation that invokes the
     * "onLoggerCallback" method on the Flutter side with the log message details.
     *
     * The log messages are sent to the Flutter side on the main thread to ensure
     * they are handled correctly in the Flutter environment.
     *
     * @param map A map containing configuration details, including a "transports" key.
     * @param outMap A mutable map where the configured logger will be added under the "transports" key.
     * @param channel The [MethodChannel] used to communicate with the Flutter side.
     */
    private fun setLogger(
        map: Map<String, Any>,
        outMap: MutableMap<String, Any>,
        channel: MethodChannel
    ) {
        if (map["transports"] == null) return

        val logListener = map["transports"] as? Map<String, Any>
        if (logListener?.isEmpty() == true) return

        val nativeTransport: MutableMap<String, Any> = mutableMapOf()
        nativeTransport["defaultTransport"] = object : LogTransport {
            override fun log(level: LogLevelEnum, message: String?) {
                if (message == null) return
                Handler(Looper.getMainLooper()).post {

                    val properties = mapOf<String, Any>(
                        "level" to level.name,
                        "message" to message
                    )
                    channel.invokeMethod("onLoggerCallback", properties)
                }
            }
        }

        val nativeLogger: MutableList<Map<String, Any>> = mutableListOf()
        nativeLogger.add(nativeTransport)
        outMap["transports"] = nativeLogger
    }

    /**
     * Gets the flag value for the given feature key.
     */
    fun getFlag(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val flagName = args?.get("flagName") as? String
            val userContextMap = args?.get("userContext") as? Map<*, *>

            if (flagName == null || userContextMap == null) {
                result.error("INVALID_ARGUMENTS", "flagName and userContext are required", null)
                return
            }

            val client = getClient(
                args["accountId"] as? Int,
                args["sdkKey"] as? String,
                args["useWingifyApi"] as? Boolean ?: false
            )
            if (client == null) {
                result.error(
                    "UNEXPECTED_ERROR",
                    "Could not get instance, please ensure the SDK is initialized properly.",
                    null
                )
                return
            }

            val userContext = buildUserContext(userContextMap)

            // Mirror the native async overloads by evaluating off the platform thread.
            thread(start = true) {
                try {
                    val flag = client.getFlag(flagName, userContext)
                    result.success(
                        mapOf(
                            "isEnabled" to flag.isEnabled(),
                            "variables" to flag.getVariables()
                        )
                    )
                } catch (e: Exception) {
                    result.error(
                        "FLAG_ERROR",
                        e.message ?: e.toString(),
                        e.stackTraceToString()
                    )
                }
            }
        } catch (e: Exception) {
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Tracks an event.
     */
    fun trackEvent(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val eventName = args?.get("eventName") as? String
        val contextMap = args?.get("context") as? Map<*, *>
        val eventProperties = args?.get("eventProperties") as? Map<String, Any>

        if (eventName.isNullOrBlank() || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Event name, context, must not be null or empty",
                null
            )
            return
        }

        val client = getClient(
            args["accountId"] as? Int,
            args["sdkKey"] as? String,
            args["useWingifyApi"] as? Boolean ?: false
        )
        if (client == null) {
            result.error(
                "UNEXPECTED_ERROR",
                "Could not get instance, please ensure the SDK is initialized properly.",
                null
            )
            return
        }

        try {
            val context = buildUserContext(contextMap)
            val trackingResult = if (eventProperties == null) {
                client.trackEvent(eventName, context)
            } else {
                client.trackEvent(eventName, context, eventProperties)
            }
            result.success(trackingResult)
        } catch (e: Exception) {
            result.error(
                "TRACK_EVENT_ERROR",
                "Error while tracking event: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Sets attributes for a user in the context provided.
     */
    fun setAttribute(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val attributes = args?.get("attributes") as? Map<String, Any>
        val contextMap = args?.get("context") as? Map<*, *>

        if (attributes == null || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Attributes and context must not be null or empty",
                null
            )
            return
        }

        val client = getClient(
            args["accountId"] as? Int,
            args["sdkKey"] as? String,
            args["useWingifyApi"] as? Boolean ?: false
        )
        if (client == null) {
            result.error(
                "UNEXPECTED_ERROR",
                "Could not get instance, please ensure the SDK is initialized properly.",
                null
            )
            return
        }

        try {
            client.setAttribute(attributes, buildUserContext(contextMap))
            result.success(true)
        } catch (e: Exception) {
            result.error(
                "SET_ATTRIBUTE_ERROR",
                "Error while setting attribute: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Function to filter out objects and keep only basic data types.
     */
    private fun filterBasicDataTypes(map: Map<String, Any?>): Map<String, Any> {
        val filteredMap = mutableMapOf<String, Any>()

        for ((key, value) in map) {
            when (value) {
                is String, is Int, is Double, is Boolean, is Char -> {
                    // Include basic data types
                    filteredMap[key] = value
                }

                is Map<*, *> -> {
                    // Recursively filter nested maps
                    val nestedMap = value as Map<*, *>
                    val filteredNestedMap =
                        filterBasicDataTypes(nestedMap.mapKeys { it.key.toString() })
                    filteredMap[key] = filteredNestedMap
                }

                is List<*> -> {
                    // Recursively filter nested lists
                    val filteredList = value.filterIsInstance<Any>()
                        .map {
                            if (it is Map<*, *>) {
                                filterBasicDataTypes(it.mapKeys { innerKey -> innerKey.toString() })
                            } else {
                                it
                            }
                        }
                    filteredMap[key] = filteredList
                }

                else -> {
                    // Skip other types (e.g., objects)
                    Log.w("FME", "Skipping non-basic data type for key: $key")
                }
            }
        }

        return filteredMap
    }

    /**
     * Sets the session data.
     */
    fun setSessionData(call: MethodCall, result: Result) {

        val sessionData = call.arguments<Map<String, Any>>()
        if (sessionData != null && sessionData.isNotEmpty()) {
            FMEConfig.setSessionData(sessionData)
            result.success(null)
        } else {
            result.error("INVALID_ARGUMENT", "Session data is null", null)
        }
    }

    /**
     * Sends the SDK initialization event with timing information.
     */
    fun sendSdkInitEvent(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val accountId = args?.get("accountId") as? Int
            val sdkKey = args?.get("sdkKey") as? String
            val useWingifyApi = args?.get("useWingifyApi") as? Boolean ?: false

            if (accountId == null || sdkKey == null) {
                result.error("INVALID_ARGUMENTS", "Invalid accountId and sdkKey passed.", null)
                return
            }

            val sdkInitTimeStr = args["sdkInitTime"] as? String
            if (sdkInitTimeStr == null) {
                result.error("INVALID_ARGUMENTS", "sdkInitTime is required", null)
                return
            }

            val sdkInitTime = sdkInitTimeStr.toLongOrNull()
            if (sdkInitTime == null) {
                result.error("INVALID_ARGUMENTS", "sdkInitTime must be a valid number", null)
                return
            }

            getClient(accountId, sdkKey, useWingifyApi)?.sendSdkInitEvent(sdkInitTime)
            result.success(true)
        } catch (e: Exception) {
            result.error(
                "SEND_SDK_INIT_EVENT_ERROR",
                "Error while sending SDK init event: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Sets an alias for the current user.
     */
    fun setAlias(call: MethodCall, result: Result) {

        val contextMap = call.argument<Map<String, Any>>("userContext")
        val aliasId = call.argument<String>("alias")

        if (aliasId.isNullOrBlank()) {
            result.error("FME", "alias parameter is required and cannot be null or empty.", null)
            return
        }

        if (contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "userContext and alias are required",
                null
            )
            return
        }

        val args = call.arguments as? Map<*, *>
        val client = getClient(
            args?.get("accountId") as? Int,
            args?.get("sdkKey") as? String,
            args?.get("useWingifyApi") as? Boolean ?: false
        )

        if (client == null) {
            val message = "SDK is not initialized, please try again later."
            result.error("SET_ALIAS_ERROR", message, null)
            Log.e("FME", message)
            return
        }

        try {
            client.setAlias(buildUserContext(contextMap), aliasId)
            result.success(true)
        } catch (e: Exception) {
            result.error(
                "SET_ALIAS_ERROR",
                "Error while setting alias: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Clears a specific instance from the shared native cache.
     *
     * @param call The method call containing accountId and sdkKey
     * @param result The result callback; returns an error if accountId or sdkKey is missing.
     */
    fun clearInstance(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val accountId = args?.get("accountId") as? Int
        val sdkKey = args?.get("sdkKey") as? String

        if (accountId == null || sdkKey.isNullOrBlank()) {
            result.error(
                "INVALID_ARGUMENTS",
                "accountId and sdkKey are required",
                null
            )
            return
        }

        try {
            // VWO.clearInstance delegates to Wingify.clearInstance; both target the shared cache.
            Wingify.clearInstance(accountId, sdkKey)
            result.success(true)
        } catch (e: Exception) {
            result.error(
                "CLEAR_INSTANCE_ERROR",
                "Error while clearing instance: ${e.message}",
                e.stackTraceToString()
            )
        }
    }
}
