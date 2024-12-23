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
import com.vwo.models.user.VWOContext
import com.vwo.models.user.GatewayService
import com.vwo.models.Variable
import com.vwo.interfaces.integration.IntegrationCallback
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel

const val SDK_VERSION = "1.0.0"
const val SDK_NAME = "vwo-fme-flutter-sdk"

/**
 *  VWO (Visual Website Optimizer) is a powerful A/B testing and experimentation platform.
 *
 * This object provides a singleton instance for interacting with the VWO SDK. It offers methods
 * for initialization, configuration, feature flag evaluation, event tracking, and user attribute
 * management.
 */
class VWOBridge(private val context: Context) {

    private var vwo: VWO? = null

    private val flagMap: HashMap<String, GetFlag> = HashMap() // Store flags with their names

    /**
     * Initializes VWO-FME sdk sending the desired parameters to native SDK.
     */
    fun initializeVWO(call:MethodCall, result: Result, channel: MethodChannel) {

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

        val logger = args["logger"] as? Map<*, *>
        val gatewayServiceMap = args["gatewayService"] as? Map<*, *>
        val pollInterval = (args["pollInterval"] as? Int) ?: 0
        val cachedSettingsExpiryTime = (args["cachedSettingsExpiryTime"] as? Int) ?: 0
        val loggerLevel = args["loggerLevel"] as? String ?: "TRACE"

        val vwoInitOptions = VWOInitOptions().apply {
            this.sdkKey = sdkKey
            this.accountId = accountId
            logger?.let { map ->
                val loggerMap = mutableMapOf<String, Any>()
                map["name"]?.let { loggerMap["name"] = it }
                map["level"]?.let { loggerMap["level"] = it }
                map["prefix"]?.let { loggerMap["prefix"] = it }
                map["dateTimeFormat"]?.let { loggerMap["dateTimeFormat"] = it }
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
            this.context = this@VWOBridge.context.applicationContext
            this.sdkVersion = SDK_VERSION
            this.sdkName = SDK_NAME
        }
        vwoInitOptions.integrations = object : IntegrationCallback {
            override fun execute(properties: Map<String, Any>) {
                Handler(Looper.getMainLooper()).post {
                    // Filter out objects and keep only basic data types
                    val filteredProperties = filterBasicDataTypes(properties)
                    channel.invokeMethod("onIntegrationCallback", filteredProperties)
                }
            }
        }

        VWO.init(vwoInitOptions, object : IVwoInitCallback {
            override fun vwoInitSuccess(vwo: VWO, message: String) {
                this@VWOBridge.vwo = vwo
                result.success("VWO is ready to use.")
            }

            override fun vwoInitFailed(message: String) {
                result.error("INIT_ERROR", message, null)
            }
        })
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

            // Create VWOContext from userContextMap
            val userContext = VWOContext().apply {
                id = userContextMap["id"] as? String
                userAgent = userContextMap["userAgent"] as? String ?: ""
                ipAddress = userContextMap["ipAddress"] as? String ?: ""
                sessionId = (userContextMap["sessionId"] as? Number)?.toLong() ?: 0L
                customVariables.putAll(userContextMap["customVariables"] as? Map<String, Any> ?: emptyMap())
                variationTargetingVariables.putAll(userContextMap["variationTargetingVariables"] as? Map<String, Any> ?: emptyMap())
            }

            // Handle gatewayService if present
            val gatewayServiceMap = userContextMap["gatewayService"] as? Map<*, *>
            if (gatewayServiceMap != null) {
                val gatewayService = GatewayService().apply {
                    location = gatewayServiceMap["location"] as? Map<String, String>
                    userAgent = gatewayServiceMap["userAgent"] as? Map<String, String>
                }
                userContext.vwo = gatewayService
            }

            // Call the VWO SDK's getFlag method
            handleGetFlag(flagName, userContext, result)
        } catch (e: Exception) {
            // Handle unexpected errors
            result.error("UNEXPECTED_ERROR", "An unexpected error occurred: ${e.message}", e.stackTraceToString())
        }
    }

    private fun handleGetFlag(flagName: String, userContext: VWOContext, result: Result) {
        try {
            vwo?.getFlag(flagName, userContext, object : IVwoListener {
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
            result.error("UNEXPECTED_ERROR", "An unexpected error occurred: ${e.message}", e.stackTraceToString())
        }
    }

    /**
     * Track method to track the event.
     */
    fun trackEvent(call: MethodCall, result: Result) {
        val eventName = call.argument<String>("eventName")
        val contextMap = call.argument<Map<String, Any>>("context")
        val eventProperties = call.argument<Map<String, Any>>("eventProperties")

        if (eventName.isNullOrBlank() || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Event name, context, must not be null or empty",
                null
            )
            return
        }

        handleTrackEvent(eventName, contextMap, eventProperties, result)
    }

    /**
     * Track method to track the event.
     */
    private fun handleTrackEvent(
        eventName: String,
        contextMap: Map<String, Any>,
        eventProperties: Map<String, Any>?,
        result: Result
    ) {
        try {
            // Convert the incoming context map to a VWOContext object
            val context = VWOContext().apply {
                id = contextMap["id"] as? String
                userAgent = contextMap["userAgent"] as? String ?: ""
                ipAddress = contextMap["ipAddress"] as? String ?: ""
                customVariables = contextMap["customVariables"] as? MutableMap<String, Any> ?: mutableMapOf()
                variationTargetingVariables = contextMap["variationTargetingVariables"] as? MutableMap<String, Any> ?: mutableMapOf()
            }

            // Call the appropriate `trackEvent` method based on the presence of eventProperties
            val trackingResult = if (eventProperties == null) {
                vwo?.trackEvent(eventName, context)
            } else {
                vwo?.trackEvent(eventName, context, eventProperties)
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
        val attributeKey = call.argument<String>("attributeKey")
        val attributeValue = call.argument<Any>("attributeValue")
        val contextMap = call.argument<Map<String, Any>>("context")

        if (attributeKey.isNullOrBlank() || attributeValue == null || contextMap == null) {
            result.error(
                "INVALID_ARGUMENTS",
                "Attribute key, attributeValue and context must not be null or empty",
                null
            )
            return
        }

        handleSetAttribute(attributeKey, attributeValue, contextMap, result)
    }

    /**
    * Sets an attribute for a user in the context provided.
    * This method validates the types of the inputs before proceeding with the API call.
    */
    private fun handleSetAttribute(
        attributeKey: String,
        attributeValue: Any,
        contextMap: Map<String, Any>,
        result: Result
    ) {
        try {
            // Convert contextMap to VWOContext object
            val context = VWOContext().apply {
                id = contextMap["id"] as? String
                userAgent = contextMap["userAgent"] as? String ?: ""
                ipAddress = contextMap["ipAddress"] as? String ?: ""
                customVariables =
                    contextMap["customVariables"] as? MutableMap<String, Any> ?: mutableMapOf()
                variationTargetingVariables =
                    contextMap["variationTargetingVariables"] as? MutableMap<String, Any>
                        ?: mutableMapOf()
            }

            // Call the setAttribute method
            vwo?.setAttribute(attributeKey, attributeValue, context)
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
                    val filteredNestedMap = filterBasicDataTypes(nestedMap.mapKeys { it.key.toString() })
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
}