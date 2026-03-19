package com.ocsafe.ocsafe_cyberguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper

/**
 * Restarts BackgroundScannerService after device boot or app update.
 *
 * A 15-second delay is used to let the Android OS fully initialize
 * before we start the foreground service, preventing race conditions
 * where the system is still loading critical components.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val BOOT_DELAY_MS = 15_000L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED) {

            // Use a 15-second delay after boot to avoid race conditions
            // with the Android OS still initializing system services
            Handler(Looper.getMainLooper()).postDelayed({
                try {
                    val serviceIntent = Intent(context, BackgroundScannerService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    // Service may fail to start in edge cases (e.g., app in stopped state)
                    // on Android 12+. Logging is safest option here.
                    e.printStackTrace()
                }
            }, BOOT_DELAY_MS)
        }
    }
}
