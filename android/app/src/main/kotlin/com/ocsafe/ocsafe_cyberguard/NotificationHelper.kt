package com.ocsafe.ocsafe_cyberguard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat

object NotificationHelper {
    fun showMalwareNotification(context: Context, appName: String, riskLevel: String, reason: String, packageName: String) {
        val channelId = "malware_alert_channel"
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, 
                "Malware Alerts", 
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High priority alerts for newly installed malware"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 1. The native uninstall action intent - pure background launch
        val uninstallIntent = Intent(Intent.ACTION_DELETE).apply {
            data = Uri.parse("package:$packageName")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingUninstallIntent = PendingIntent.getActivity(
            context,
            packageName.hashCode(),
            uninstallIntent,
            pendingIntentFlags
        )

        // 2. The main app launch intent when tapping the notification body
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingMainIntent = PendingIntent.getActivity(
            context,
            0,
            mainIntent,
            pendingIntentFlags
        )

        // Build the native notification
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("⚠️ Threat Detected: $appName")
            .setContentText("$riskLevel risk app. $reason. Tap to view.")
            .setColor(Color.parseColor("#E53935")) // Red color
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(pendingMainIntent)
            .setAutoCancel(true)
            .setGroup("MALWARE_GROUP") // Prevents grouping with the silent foreground service
            // Add the action button that completely bypasses Dart!
            .addAction(android.R.drawable.ic_delete, "Uninstall App", pendingUninstallIntent)
            .build()

        notificationManager.notify(appName.hashCode(), notification)
    }

    fun cancelMalwareNotification(context: Context, appName: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(appName.hashCode())
    }
}
