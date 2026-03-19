package com.ocsafe.ocsafe_cyberguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel

/**
 * Listens for package install/update/uninstall events and dispatches
 * them to the Flutter headless engine for threat analysis.
 *
 * Key improvements:
 *  - Handles PACKAGE_ADDED, PACKAGE_REPLACED (split APK sessions), and PACKAGE_REMOVED
 *  - Full OEM-aware trusted installer allowlist (Play Store + OEM package managers)
 *  - 5-minute per-package scan cooldown to prevent duplicate analysis
 *  - Passes `is_sideloaded` to Flutter so the Dart layer can decide notification priority
 */
class PackageReceiver : BroadcastReceiver() {

    companion object {
        const val BACKGROUND_CHANNEL = "com.ocsafe.cyberguard/background"

        // Cache to prevent multiple headless engines from spawning at once
        var headlessEngine: FlutterEngine? = null

        // Prefs key prefix for scan cooldown timestamps
        private const val PREFS_NAME = "ocsafe_scan_prefs"
        private const val LAST_SCAN_PREFIX = "last_scan_"
        private const val SCAN_COOLDOWN_MS = 5 * 60 * 1000L // 5 minutes

        /**
         * Full list of trusted installer package names.
         * Apps installed by any of these are NOT considered sideloaded.
         * OEM-specific package managers are included for Xiaomi, Samsung, OnePlus, etc.
         */
        val TRUSTED_INSTALLERS = setOf(
            "com.android.vending",                  // Google Play Store
            "com.google.android.packageinstaller",  // Google default package installer
            "com.android.packageinstaller",         // AOSP package installer
            "com.miui.packageinstaller",            // Xiaomi / MIUI
            "com.samsung.android.packageinstaller", // Samsung
            "com.oneplus.packageinstaller",         // OnePlus
            "com.coloros.packageinstaller",         // ColorOS / OPPO / realme
            "com.huawei.appmarket",                 // Huawei AppGallery
            "com.amazon.venezia"                    // Amazon Appstore
        )
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val data = intent.data ?: return
        val packageName = data.schemeSpecificPart ?: return

        when (action) {
            Intent.ACTION_PACKAGE_ADDED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                // Skip if this is just an update to an existing app and not a fresh install
                // EXTRA_REPLACING == true means the package already existed (update, not new install)
                val isReplacing = intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)

                // Determine if the app was sideloaded (not from a trusted store)
                val isSideloaded = checkIsSideloaded(context, packageName)

                // Apply 5-minute cooldown to prevent duplicate scans on the same package
                if (isWithinCooldown(context, packageName)) {
                    return
                }
                recordScanTimestamp(context, packageName)

                startHeadlessTask(
                    context,
                    packageName,
                    action,
                    isSideloaded = isSideloaded,
                    isUpdate = isReplacing
                )
            }

            Intent.ACTION_PACKAGE_REMOVED -> {
                // Don't fire cleanup if this removal is part of an update (package is being replaced)
                val isReplacing = intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)
                if (isReplacing) return

                startHeadlessTask(
                    context,
                    packageName,
                    action,
                    isSideloaded = false,
                    isUpdate = false
                )
            }
        }
    }

    /**
     * Determines whether the app was installed from outside a trusted store.
     * Uses the modern API on Android 11+ and falls back to the deprecated API otherwise.
     */
    private fun checkIsSideloaded(context: Context, packageName: String): Boolean {
        return try {
            val pm = context.packageManager
            val installer: String? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+: Use getInstallSourceInfo for accurate installer info
                pm.getInstallSourceInfo(packageName).installingPackageName
            } else {
                // Android ≤10: deprecated but reliable
                @Suppress("DEPRECATION")
                pm.getInstallerPackageName(packageName)
            }
            // If installer is null or not in our trusted list → sideloaded
            installer == null || installer !in TRUSTED_INSTALLERS
        } catch (e: Exception) {
            // If we can't determine installer, treat as unknown (assume sideloaded = safer)
            true
        }
    }

    /**
     * Returns true if this package was scanned within the cooldown window.
     * Prevents duplicate scans when the OS fires multiple install events.
     */
    private fun isWithinCooldown(context: Context, packageName: String): Boolean {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val lastScan = prefs.getLong("$LAST_SCAN_PREFIX$packageName", 0L)
        return System.currentTimeMillis() - lastScan < SCAN_COOLDOWN_MS
    }

    /**
     * Records the current timestamp as the last scan time for this package.
     */
    private fun recordScanTimestamp(context: Context, packageName: String) {
        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong("$LAST_SCAN_PREFIX$packageName", System.currentTimeMillis()).apply()
    }

    private fun startHeadlessTask(
        context: Context,
        packageName: String,
        action: String,
        isSideloaded: Boolean,
        isUpdate: Boolean
    ) {
        // Initialize Flutter environment if not already done
        FlutterInjector.instance().flutterLoader().startInitialization(context)
        FlutterInjector.instance().flutterLoader().ensureInitializationComplete(context, null)

        val eventPayload = mapOf(
            "package_name" to packageName,
            "action" to action,
            "is_sideloaded" to isSideloaded,
            "is_update" to isUpdate
        )

        if (headlessEngine == null) {
            headlessEngine = FlutterEngine(context)

            val methodChannel = MethodChannel(
                headlessEngine!!.dartExecutor.binaryMessenger,
                BACKGROUND_CHANNEL
            )

            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "flutter_ready" -> {
                        result.success(null)
                        // Flutter engine is ready — dispatch the queued event
                        methodChannel.invokeMethod("package_event", eventPayload)
                    }

                    "show_malware_notification" -> {
                        val appName = call.argument<String>("app_name") ?: "Unknown App"
                        val riskLevel = call.argument<String>("risk_level") ?: "HIGH"
                        val reason = call.argument<String>("reason") ?: "Threat detected"
                        val pkgName = call.argument<String>("package_name") ?: ""
                        NotificationHelper.showMalwareNotification(
                            context, appName, riskLevel, reason, pkgName
                        )
                        result.success(true)
                    }

                    "cancel_malware_notification" -> {
                        val appName = call.argument<String>("app_name") ?: ""
                        if (appName.isNotEmpty()) {
                            NotificationHelper.cancelMalwareNotification(context, appName)
                        }
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

            // Execute the custom mainBackground entry point
            val entryPoint = DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "mainBackground"
            )
            headlessEngine!!.dartExecutor.executeDartEntrypoint(entryPoint)

        } else {
            // Engine already running — send the event directly
            val methodChannel = MethodChannel(
                headlessEngine!!.dartExecutor.binaryMessenger,
                BACKGROUND_CHANNEL
            )
            methodChannel.invokeMethod("package_event", eventPayload)
        }
    }
}
