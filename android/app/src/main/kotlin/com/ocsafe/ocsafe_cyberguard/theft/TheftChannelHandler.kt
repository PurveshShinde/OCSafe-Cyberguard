package com.ocsafe.ocsafe_cyberguard.theft

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Registers and handles the Flutter method channel `cyberguard/theft_lock`.
 *
 * Supported methods:
 *  - `lockDevice`             → locks screen via [DeviceLockManager]
 *  - `isAdminActive`          → returns Boolean admin permission state
 *  - `requestAdminPermission` → opens Android Device Admin settings dialog
 *
 * Isolated in its own class — [MainActivity] registers this with one line.
 */
class TheftChannelHandler(
    private val activity: Activity,
    messenger: BinaryMessenger,
) {
    companion object {
        private const val CHANNEL = "cyberguard/theft_lock"
    }

    private val lockManager = DeviceLockManager(activity)
    private val componentName = ComponentName(activity, TheftAdminReceiver::class.java)

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "lockDevice" -> {
                    lockManager.lock()
                    result.success(null)
                }
                "isAdminActive" -> {
                    result.success(lockManager.isAdminActive())
                }
                "requestAdminPermission" -> {
                    requestAdminPermission()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Fix #3: Opens the Android system dialog for granting Device Admin.
     * This is the ONLY correct way — settings page alone doesn't work.
     */
    private fun requestAdminPermission() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
            putExtra(
                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                "OcSafe CyberGuard needs Device Admin permission to lock your screen " +
                "instantly when theft is detected."
            )
        }
        activity.startActivity(intent)
    }
}
