package com.ocsafe.ocsafe_cyberguard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.content.IntentFilter
import androidx.core.app.NotificationCompat

class BackgroundScannerService : Service() {

    private val CHANNEL_ID = "cyberguard_background_service_v2"
    private var packageReceiver: PackageReceiver? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // Dynamically register receiver to ensure it stays alive with the service
        packageReceiver = PackageReceiver()
        val filter = IntentFilter(Intent.ACTION_PACKAGE_ADDED).apply {
            addDataScheme("package")
        }
        registerReceiver(packageReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notificationIntent = Intent(this, MainActivity::class.java)
        
        // Define flags based on Android version
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            pendingIntentFlags
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CyberGuard Protection")
            .setContentText("Scanning for threats in the background...")
            .setSmallIcon(android.R.drawable.ic_secure) // Using Android's default secure icon, since mipmap isn't accessible here directly safely
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MIN) // Keeps it silent
            .setGroup("SILENT_BACKGROUND_GROUP") // Keeps separated from high priority alerts
            .setOngoing(true)
            .build()

        startForeground(1001, notification)

        // START_STICKY tells the OS to restart this service if it gets killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        // We don't provide binding for this service
        return null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        packageReceiver?.let {
            unregisterReceiver(it)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Background Protection Service",
                NotificationManager.IMPORTANCE_MIN // Sets it to silent/minimized
            ).apply {
                description = "Keeps OCSafe CyberGuard running in the background to detect malware instantly."
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }
}
