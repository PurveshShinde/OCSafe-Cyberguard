package com.ocsafe.ocsafe_cyberguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel

class PackageReceiver : BroadcastReceiver() {
    companion object {
        const val EVENT_CHANNEL = "com.ocsafe.cyberguard/package_receiver"
        const val BACKGROUND_CHANNEL = "com.ocsafe.cyberguard/background"
        
        // Cache to prevent multiple headless engines from spawning at once
        var headlessEngine: FlutterEngine? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        val data = intent.data
        if (data != null && (Intent.ACTION_PACKAGE_ADDED == action || Intent.ACTION_PACKAGE_REMOVED == action)) {
            val packageName = data.schemeSpecificPart
            // Always use the headless engine for real-time background scans.
            // The main UI isolate gets paused by Android, which swallows the intent
            // until the user manually resumes the app.
            startHeadlessTask(context, packageName, action ?: "")
        }
    }
    
    private fun startHeadlessTask(context: Context, packageName: String, action: String) {
        // Initialize Flutter environment if not already done
        FlutterInjector.instance().flutterLoader().startInitialization(context)
        FlutterInjector.instance().flutterLoader().ensureInitializationComplete(context, null)

        if (headlessEngine == null) {
            headlessEngine = FlutterEngine(context)
            
            // Register MethodChannel to communicate with the background engine
            val methodChannel = MethodChannel(headlessEngine!!.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
            
            // Listen for flutter to tell us it is ready, or to trigger native alerts
            methodChannel.setMethodCallHandler { call, result ->
                if (call.method == "flutter_ready") {
                    result.success(null)
                    // Flutter is ready, send the package event
                    methodChannel.invokeMethod("package_event", mapOf(
                        "package_name" to packageName,
                        "action" to action
                    ))
                } else if (call.method == "show_malware_notification") {
                    val appName = call.argument<String>("app_name") ?: "Unknown App"
                    val riskLevel = call.argument<String>("risk_level") ?: "HIGH"
                    val reason = call.argument<String>("reason") ?: "Threat detected"
                    val pkgName = call.argument<String>("package_name") ?: ""
                    NotificationHelper.showMalwareNotification(context, appName, riskLevel, reason, pkgName)
                    result.success(true)
                } else if (call.method == "cancel_malware_notification") {
                    val appName = call.argument<String>("app_name") ?: ""
                    if (appName.isNotEmpty()) {
                        NotificationHelper.cancelMalwareNotification(context, appName)
                    }
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }

            // Execute the custom mainBackground entry point instead of default main
            val entryPoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "mainBackground"
            )
            headlessEngine!!.dartExecutor.executeDartEntrypoint(entryPoint)
        } else {
            // Engine already running, just send the command
            val methodChannel = MethodChannel(headlessEngine!!.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)
            methodChannel.invokeMethod("package_event", mapOf(
                "package_name" to packageName,
                "action" to action
            ))
        }
    }
}
