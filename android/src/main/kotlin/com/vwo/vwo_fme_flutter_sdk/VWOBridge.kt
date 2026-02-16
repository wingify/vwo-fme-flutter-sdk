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
package com.vwo.vwo_fme_flutter_sdk

import android.content.Context
import android.util.Log
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import com.vwo.VWO
import com.vwo.models.user.VWOInitOptions
import com.vwo.interfaces.IVwoInitCallback
import com.vwo.interfaces.IVwoListener
import com.vwo.models.user.GetFlag
import com.vwo.models.user.VWOUserContext
import com.vwo.models.user.GatewayService
import com.vwo.interfaces.logger.LogTransport
import com.vwo.packages.logger.enums.LogLevelEnum
import com.vwo.models.user.FMEConfig
import com.vwo.models.Variable
import com.vwo.interfaces.integration.IntegrationCallback
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel
import kotlin.text.toLongOrNull

const val SDK_NAME = "vwo-fme-flutter-sdk"

/**
 *  VWO (Visual Website Optimizer) is a powerful A/B testing and experimentation platform.
 *
 * This object provides a singleton instance for interacting with the VWO SDK. It offers methods
 * for initialization, configuration, feature flag evaluation, event tracking, and user attribute
 * management.
 */
class VWOBridge(private val context: Context) {

    // Native SDK manages instances internally, no need to store here
    private val flagMap: HashMap<String, GetFlag> = HashMap() // Store flags with their names

    /**
     * Helper method to get VWO instance from native SDK
     *
     * @param accountId The account ID for the instance (optional)
     * @param sdkKey The SDK key for the instance (optional)
     * @return The VWO instance if found, or null if not provided/available
     *
     * Note: The native SDK caches instances internally, so calling getInstance()
     * multiple times with the same accountId/sdkKey is efficient.
     */
    private fun getVWOInstance(accountId: Int?, sdkKey: String?): VWO? {
        return if (accountId != null && !sdkKey.isNullOrEmpty()) {
            // Use native SDK's getInstance method directly
            // The native SDK caches instances internally, so this is efficient
            VWO.getInstance(accountId, sdkKey)
        } else {
            // If not provided, return null (native SDK will handle default)
            null
        }
    }

    /**
     * Initializes VWO-FME sdk sending the desired parameters to native SDK.
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
        val loggerLevel = args["loggerLevel"] as? String ?: "TRACE"
        val batchMinSize = (args["batchMinSize"] as? Int) ?: -1
        val batchUploadTimeIntervalString = args["batchUploadTimeInterval"] as? String
        val batchUploadTimeInterval = batchUploadTimeIntervalString?.toLongOrNull() ?: -1L
        val sdkVersion = args["sdkVersion"] as? String ?: ""
        val isUsageStatsDisabled = args["isUsageStatsDisabled"] as? Boolean ?: false
        val vwoMeta = args["_vwo_meta"] as? Map<String, Any> ?: mapOf()
        val hasIntegrations = args["hasIntegrations"] as? Boolean ?: false
        val isAliasingEnabled = args["isAliasingEnabled"] as? Boolean ?: false

        val vwoInitOptions = VWOInitOptions().apply {
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
            this.sdkName = SDK_NAME
            this.isUsageStatsDisabled = isUsageStatsDisabled
            this._vwo_meta = vwoMeta
            this.isAliasingEnabled = isAliasingEnabled
        }

        // Only set integrations if provided by the client
        if (hasIntegrations) {
            vwoInitOptions.integrations = object : IntegrationCallback {
                override fun execute(properties: Map<String, Any>) {
                    Handler(Looper.getMainLooper()).post {
                        // Filter out objects and keep only basic data types
                        val filteredProperties = filterBasicDataTypes(properties)
                        channel.invokeMethod("onIntegrationCallback", filteredProperties)
                    }
                }
            }
        }

        VWO.init(vwoInitOptions, object : IVwoInitCallback {
            override fun vwoInitSuccess(vwo: VWO, message: String) {
                // Native SDK manages instances internally, no need to store here
                result.success("VWO is ready to use.")
            }

            override fun vwoInitFailed(message: String) {
                result.error("INIT_ERROR", message, null)
            }
        })
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
                //Log.d("FME", message)
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
     * This method is used to get the flag value for the given feature key
     */
    fun getFlag(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<*, *>
            val flagName = args?.get("flagName") as? String
            val userContextMap = args?.get("userContext") as? Map<*, *>

            // Validate required arguments
            if (flagName == null || userContextMap == null) {
                result.error("INVALID_ARGUMENTS", "flagName and userContext are required", null)
                return
            }

            // Extract accountId and sdkKey for multi-instance support (optional)
            val accountId = args?.get("accountId") as? Int
            val sdkKey = args?.get("sdkKey") as? String

            // Create VWOUserContext from userContextMap
            val userContext = VWOUserContext().apply {
                id = userContextMap["id"] as? String

                customVariables.putAll(
                    userContextMap["customVariables"] as? Map<String, Any> ?: emptyMap()
                )
                variationTargetingVariables.putAll(
                    userContextMap["variationTargetingVariables"] as? Map<String, Any> ?: emptyMap()
                )

                shouldUseDeviceIdAsUserId =
                    userContextMap["shouldUseDeviceIdAsUserId"] as? Boolean ?: false
            }

            // Handle gatewayService if present
            val gatewayServiceMap = userContextMap["gatewayService"] as? Map<*, *>
            if (gatewayServiceMap != null) {
                val gatewayService = GatewayService().apply {
                    location = gatewayServiceMap["location"] as? Map<String, String>
                }
                userContext.vwo = gatewayService
            }

            // Get the appropriate instance or use default
            val vwoInstance = getVWOInstance(accountId, sdkKey)
            handleGetFlag(vwoInstance, flagName, userContext, result)
        } catch (e: Exception) {
            // Handle unexpected errors
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    private fun handleGetFlag(
        vwoInstance: VWO?,
        flagName: String,
        userContext: VWOUserContext,
        result: Result
    ) {
        try {

            if (vwoInstance == null) {
                result.error(
                    "UNEXPECTED_ERROR",
                    "Could not get VWO instance, please ensure VWO is initialized properly.",
                    null
                )
                return
            }

            vwoInstance.getFlag(flagName, userContext, object : IVwoListener {
                override fun onSuccess(data: Any) {
                    val featureFlag = data as? GetFlag
                    val response = if (featureFlag != null) {
                        mapOf(
                            "isEnabled" to featureFlag.isEnabled(),
                            "variables" to featureFlag.getVariables()
                        )
                    } else {
                        mapOf(
                            "isEnabled" to false,
                            "variables" to listOf<Map<String, Any>>()
                        )
                    }
                    result.success(response)
                }

                override fun onFailure(message: String) {
                    result.error("FLAG_ERROR", message, null)
                }
            })
        } catch (e: Exception) {
            // Handle unexpected errors in the VWO SDK call
            result.error(
                "UNEXPECTED_ERROR",
                "An unexpected error occurred: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Track method to track the event.
     */
    fun trackEvent(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val eventName = args?.get("eventName") as? String
        val contextMap = args?.get("context") as? Map<String, Any>
        val eventProperties = args?.get("eventProperties") as? Map<String, Any>

        if (eventName.isNullOrBlank() || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Event name, context, must not be null or empty",
                null
            )
            return
        }

        // Extract accountId and sdkKey for multi-instance support (optional)
        val accountId = args?.get("accountId") as? Int
        val sdkKey = args?.get("sdkKey") as? String

        // Get the appropriate instance or use default
        val vwoInstance = getVWOInstance(accountId, sdkKey)
        handleTrackEvent(vwoInstance, eventName, contextMap, eventProperties, result)
    }

    /**
     * Track method to track the event.
     */
    private fun handleTrackEvent(
        vwoInstance: VWO?,
        eventName: String,
        contextMap: Map<String, Any>,
        eventProperties: Map<String, Any>?,
        result: Result
    ) {
        try {
            // Convert the incoming context map to a VWOUserContext object
            val context = VWOUserContext().apply {
                id = contextMap["id"] as? String

                customVariables =
                    contextMap["customVariables"] as? MutableMap<String, Any> ?: mutableMapOf()
                variationTargetingVariables =
                    contextMap["variationTargetingVariables"] as? MutableMap<String, Any>
                        ?: mutableMapOf()

                shouldUseDeviceIdAsUserId =
                    contextMap["shouldUseDeviceIdAsUserId"] as? Boolean ?: false
            }

            if (vwoInstance == null) {
                result.error(
                    "UNEXPECTED_ERROR",
                    "Could not get VWO instance, please ensure VWO is initialized properly.",
                    null
                )
                return
            }

            // Call the appropriate `trackEvent` method based on the presence of eventProperties
            val trackingResult = if (eventProperties == null) {
                vwoInstance.trackEvent(eventName, context)
            } else {
                vwoInstance.trackEvent(eventName, context, eventProperties)
            }

            if (trackingResult != null) {
                // Send the result map back to Flutter
                result.success(trackingResult)
            } else {
                result.error(
                    "TRACK_EVENT_FAILED",
                    "Tracking event returned null",
                    null
                )
            }
        } catch (e: Exception) {
            result.error(
                "TRACK_EVENT_ERROR",
                "Error while tracking event: ${e.message}",
                e.stackTraceToString()
            )
        }
    }

    /**
     * Sets an attribute for a user in the context provided.
     * This method validates the types of the inputs before proceeding with the API call.
     */
    fun setAttribute(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val attributes = args?.get("attributes") as? Map<String, Any>
        val contextMap = args?.get("context") as? Map<String, Any>

        if (attributes == null || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Attributes and context must not be null or empty",
                null
            )
            return
        }

        // Extract accountId and sdkKey for multi-instance support (optional)
        val accountId = args?.get("accountId") as? Int
        val sdkKey = args?.get("sdkKey") as? String

        // Get the appropriate instance or use default
        val vwoInstance = getVWOInstance(accountId, sdkKey)
        handleSetAttribute(vwoInstance, attributes, contextMap, result)
    }

    /**
     * Sets an attribute for a user in the context provided.
     * This method validates the types of the inputs before proceeding with the API call.
     */
    private fun handleSetAttribute(
        vwoInstance: VWO?,
        attributes: Map<String, Any>,
        contextMap: Map<String, Any>,
        result: Result
    ) {
        try {
            // Convert contextMap to VWOUserContext object
            val context = VWOUserContext().apply {
                id = contextMap["id"] as? String
                customVariables =
                    contextMap["customVariables"] as? MutableMap<String, Any> ?: mutableMapOf()
                variationTargetingVariables =
                    contextMap["variationTargetingVariables"] as? MutableMap<String, Any>
                        ?: mutableMapOf()
                shouldUseDeviceIdAsUserId =
                    contextMap["shouldUseDeviceIdAsUserId"] as? Boolean ?: false
            }

            if (vwoInstance == null) {
                result.error(
                    "UNEXPECTED_ERROR",
                    "Could not get VWO instance, please ensure VWO is initialized properly.",
                    null
                )
                return
            }

            vwoInstance.setAttribute(attributes, context)
            result.success(true) // Return success to Flutter
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
                    Log.w("VWO", "Skipping non-basic data type for key: $key")
                }
            }
        }

        return filteredMap
    }

    /**
     * Function to set the session data.
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
     * Function to send SDK initialization event with timing information.
     */
    fun sendSdkInitEvent(call: MethodCall, result: Result) {
        try {

            val accountId = call.argument<String>("accountId") as? Int
            val sdkKey = call.argument<String>("sdkKey")

            if (accountId == null || sdkKey == null) {
                result.error("INVALID_ARGUMENTS", "Invalid accountId and sdkKey passed.", null)
                return
            }

            val sdkInitTimeStr = call.argument<String>("sdkInitTime")

            if (sdkInitTimeStr == null) {
                result.error("INVALID_ARGUMENTS", "sdkInitTime is required", null)
                return
            }

            val sdkInitTime = sdkInitTimeStr.toLongOrNull()
            if (sdkInitTime == null) {
                result.error("INVALID_ARGUMENTS", "sdkInitTime must be a valid number", null)
                return
            }

            // Use default instance for sendSdkInitEvent
            val instance = VWO.getInstance(accountId, sdkKey)
            instance?.sendSdkInitEvent(sdkInitTime)
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
     * Sets an alias for the current user in VWO.
     * This method allows you to associate an alias ID with a user context for tracking purposes.
     *
     * @param call MethodCall containing the following arguments:
     *   - "aliasId": String - The alias identifier to set for the user (required, cannot be null or empty)
     *   - "context": Map<String, Any> - User context containing:
     *     - "id": String - User identifier
     *     - "shouldUseDeviceIdAsUserId": Boolean - Whether to use device ID as user ID (optional, defaults to false)
     * @param result Result object to return success/error status to Flutter
     */
    fun setAlias(call: MethodCall, result: Result) {

        val contextMap = call.argument<Map<String, Any>>("userContext")
        val aliasId = (call.argument<String>("alias") as? String)

        if (aliasId == null || aliasId.isBlank()) {
            result.error("VWO", "alias parameter is required and cannot be null or empty.", null)
            return
        }

        if (contextMap == null || aliasId.isNullOrBlank()) {
            result.error(
                "INVALID_ARGUMENTS",
                "userContext and alias are required",
                null
            )
            return
        }

        // Extract accountId and sdkKey for multi-instance support (optional)
        val args = call.arguments as? Map<*, *>
        val accountId = args?.get("accountId") as? Int
        val sdkKey = args?.get("sdkKey") as? String

        val vwoInstance = getVWOInstance(accountId, sdkKey)

        try {
            // Convert contextMap to VWOUserContext object
            val context = VWOUserContext().apply {
                id = contextMap["id"] as? String
                shouldUseDeviceIdAsUserId =
                    (contextMap?.get("shouldUseDeviceIdAsUserId") as? Boolean) ?: false
            }

            if(vwoInstance == null) {
                val message = "SDK is not initialized, please try again later."
                result.error("SET_ALIAS_ERROR", message, null)
                Log.e("VWO", message)
                return
            }

            // Use the provided instance or fallback to default instance
            vwoInstance.setAlias(context, aliasId)
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
     * Clears a specific VWO instance.
     *
     * @param call The method call containing accountId and sdkKey
     * @param result The result callback, if account id or sdkKey is missing will return error, else success
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
            // Clear from native SDK (native SDK manages instances internally)
            VWO.clearInstance(accountId, sdkKey)
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
