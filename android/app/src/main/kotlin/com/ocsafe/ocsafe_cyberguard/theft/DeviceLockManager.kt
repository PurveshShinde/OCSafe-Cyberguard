package com.ocsafe.ocsafe_cyberguard.theft

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context

/**
 * Encapsulates all Device Policy Manager interactions.
 *
 * Graceful failure contract:
 *  - If admin permission is not active, [lock] silently returns.
 *  - No exceptions are thrown — callers don't need try/catch.
 */
class DeviceLockManager(private val context: Context) {

    private val dpm: DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

    private val componentName: ComponentName =
        ComponentName(context, TheftAdminReceiver::class.java)

    /**
     * Immediately locks the screen if Device Admin is active.
     * No-ops silently if permission is missing.
     */
    fun lock() {
        if (dpm.isAdminActive(componentName)) {
            dpm.lockNow()
        }
        // Else: permission not granted — silently ignore.
    }

    /**
     * Returns whether this app currently holds Device Admin rights.
     * Used by Flutter to render the correct permission UI state.
     */
    fun isAdminActive(): Boolean = dpm.isAdminActive(componentName)
}
