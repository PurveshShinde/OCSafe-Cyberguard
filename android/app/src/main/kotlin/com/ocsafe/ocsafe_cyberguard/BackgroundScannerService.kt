package com.ocsafe.ocsafe_cyberguard

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import androidx.core.app.NotificationCompat
import com.ocsafe.ocsafe_cyberguard.theft.DeviceLockManager
import com.ocsafe.ocsafe_cyberguard.theft.TheftMotionAnalyzer

class BackgroundScannerService : Service(), SensorEventListener, SharedPreferences.OnSharedPreferenceChangeListener {

    private val CHANNEL_ID = "cyberguard_background_service_v2"
    private var packageReceiver: PackageReceiver? = null

    // Anti-theft attributes
    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var analyzer: TheftMotionAnalyzer? = null
    private var lockManager: DeviceLockManager? = null

    private var isMonitoring = false
    private var windowStartTime: Long = 0
    private var isCooldown = false

    private val MONITORING_WINDOW_MS = 5000L
    private val LOCK_DELAY_MS = 1500L
    private val COOLDOWN_MS = 5000L

    private lateinit var prefs: SharedPreferences

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // Dynamically register receiver to ensure it stays alive with the service.
        packageReceiver = PackageReceiver()
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_ADDED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addDataScheme("package")
        }
        registerReceiver(packageReceiver, filter)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        lockManager = DeviceLockManager(this)

        // Setup SharedPreferences listener
        prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.registerOnSharedPreferenceChangeListener(this)
        
        applyTheftSettings()
    }

    private fun applyTheftSettings() {
        val enabled = prefs.getBoolean("flutter.theft_protection_enabled", false)
        val sensitivity = prefs.getString("flutter.theft_protection_sensitivity", "medium") ?: "medium"

        if (enabled) {
            if (analyzer == null) {
                analyzer = TheftMotionAnalyzer(sensitivity)
            } else {
                analyzer?.updateSensitivity(sensitivity)
            }
            // Register listener if not already
            sensorManager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        } else {
            // Disable
            sensorManager?.unregisterListener(this)
            analyzer = null
        }
    }

    override fun onSharedPreferenceChanged(sharedPreferences: SharedPreferences?, key: String?) {
        if (key == "flutter.theft_protection_enabled" || key == "flutter.theft_protection_sensitivity") {
            applyTheftSettings()
        }
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
            .setSmallIcon(android.R.drawable.ic_secure) // Using Android's default secure icon
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
        sensorManager?.unregisterListener(this)
        prefs.unregisterOnSharedPreferenceChangeListener(this)
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

    // --- Sensor Events ---
    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return
        if (isCooldown || analyzer == null) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        val currentAnalyzer = analyzer ?: return

        // Skip when screen is off to avoid pocket-lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        if (!powerManager.isInteractive) return
        
        // Phase 1 - Jerk window
        if (!isMonitoring && currentAnalyzer.detectJerk(x, y, z)) {
            isMonitoring = true
            windowStartTime = System.currentTimeMillis()
            currentAnalyzer.reset()
        }

        // Phase 2 - Inside monitoring window
        if (isMonitoring) {
            val elapsed = System.currentTimeMillis() - windowStartTime

            if (elapsed > MONITORING_WINDOW_MS) {
                resetMonitoring()
                return
            }

            if (currentAnalyzer.detectContinuous(x, y, z)) {
                triggerLock()
                resetMonitoring()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed
    }

    private fun resetMonitoring() {
        isMonitoring = false
        windowStartTime = 0
        analyzer?.reset()
    }

    private fun triggerLock() {
        if (isCooldown) return
        isCooldown = true

        val handler = Handler(Looper.getMainLooper())
        handler.postDelayed({
            lockManager?.lock()
            
            // Release cooldown after delay
            handler.postDelayed({
                isCooldown = false
            }, COOLDOWN_MS)

        }, LOCK_DELAY_MS)
    }
}
