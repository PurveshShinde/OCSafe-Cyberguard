package com.ocsafe.ocsafe_cyberguard.theft

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * Required stub for Device Policy Manager.
 * Android mandates a [DeviceAdminReceiver] subclass to grant
 * `BIND_DEVICE_ADMIN` permission and enable `lockNow()`.
 *
 * No business logic lives here — all lock logic is in [DeviceLockManager].
 */
class TheftAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Device Admin was granted — no action required.
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Device Admin was revoked — service will gracefully no-op on next lock attempt.
    }
}
