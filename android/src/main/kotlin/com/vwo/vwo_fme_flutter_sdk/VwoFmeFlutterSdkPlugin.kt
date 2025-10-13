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

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * VwoFmeFlutterSdkPlugin that will do the communication between Flutter and native Android.
 */
class VwoFmeFlutterSdkPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var bridge: VWOBridge? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "vwo_fme_flutter_sdk")
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
        bridge = VWOBridge(applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {

        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            VWOConstants.INITIALIZE_VWO -> {
                bridge?.initializeVWO(call, result, channel)
            }
            VWOConstants.ANDROID_GET_FLAG -> {
                bridge?.getFlag(call, result)
            }
            VWOConstants.ANDROID_TRACK_EVENT -> {
                bridge?.trackEvent(call, result)
            }
            VWOConstants.ANDROID_SET_ATTRIBUTE -> {
                bridge?.setAttribute(call, result)
            }
            VWOConstants.ANDROID_SET_SESSION -> {
                bridge?.setSessionData(call, result)
            }
            VWOConstants.ANDROID_SEND_SDK_INIT_EVENT -> {
                bridge?.sendSdkInitEvent(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
