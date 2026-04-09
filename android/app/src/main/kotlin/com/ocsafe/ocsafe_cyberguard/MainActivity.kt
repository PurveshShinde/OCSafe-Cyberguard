package com.ocsafe.ocsafe_cyberguard

import android.content.Intent
import com.ocsafe.ocsafe_cyberguard.theft.TheftChannelHandler
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.engine.FlutterEngineCache
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ocsafe.cyberguard/uninstall"
    private val STORAGE_CHANNEL = "com.ocsafe.cyberguard/storage_permission"
    private val EVENT_CHANNEL = "com.ocsafe.cyberguard/package_receiver"
    private val APK_HASH_CHANNEL = "com.ocsafe.cyberguard/apk_hash"
    
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onDestroy() {
        super.onDestroy()
        eventSink = null
        FlutterEngineCache.getInstance().remove("ocsafe_engine")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Start persistent background service to keep BroadcastReceiver alive
        val serviceIntent = Intent(this, BackgroundScannerService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Cache engine for background broadcast receiver
        FlutterEngineCache.getInstance().put("ocsafe_engine", flutterEngine)

        // Smart Theft Shield — registers cyberguard/theft_lock channel
        TheftChannelHandler(this, flutterEngine.dartExecutor.binaryMessenger)

        // Setup EventChannel for package events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )

        // Uninstall channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "uninstall_app") {
                val packageName = call.argument<String>("package_name")
                if (packageName != null) {
                    val intent = Intent(Intent.ACTION_DELETE)
                    intent.data = Uri.parse("package:$packageName")
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "Package name not provided.", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Storage permission channel — directly uses Android APIs, bypasses permission_handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "check_all_files_access" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        result.success(Environment.isExternalStorageManager())
                    } else {
                        // Below Android 11, MANAGE_EXTERNAL_STORAGE doesn't exist
                        result.success(true)
                    }
                }
                "request_all_files_access" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        if (Environment.isExternalStorageManager()) {
                            result.success(true)
                        } else {
                            try {
                                // This opens the "All Files Access" toggle page for THIS app
                                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                                intent.data = Uri.parse("package:${applicationContext.packageName}")
                                startActivity(intent)
                                result.success(false) // Not granted yet — user must toggle
                            } catch (e: Exception) {
                                // Fallback: open the general "All Files Access" list
                                try {
                                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                                    startActivity(intent)
                                    result.success(false)
                                } catch (e2: Exception) {
                                    result.error("INTENT_FAILED", "Could not open settings: ${e2.message}", null)
                                }
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // APK hash channel — computes SHA-256 of installed APKs
        // Uses publicSourceDir (primary) + splitSourceDirs (fallback) for split APK support
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APK_HASH_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApkHash") {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARG", "packageName is required", null)
                    return@setMethodCallHandler
                }

                try {
                    val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.ApplicationInfoFlags.of(0)
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        packageManager.getApplicationInfo(packageName, 0)
                    }

                    // Priority: publicSourceDir → sourceDir → first splitSourceDir
                    val apkPath = appInfo.publicSourceDir
                        ?: appInfo.sourceDir
                        ?: appInfo.splitSourceDirs?.firstOrNull()

                    if (apkPath == null) {
                        result.error("NO_APK", "Could not locate APK for $packageName", null)
                        return@setMethodCallHandler
                    }

                    val file = File(apkPath)
                    if (!file.exists()) {
                        result.error("NOT_FOUND", "APK file not found at $apkPath", null)
                        return@setMethodCallHandler
                    }

                    // Stream-based SHA-256 (memory efficient for large APKs)
                    val digest = MessageDigest.getInstance("SHA-256")
                    val buffer = ByteArray(8192)
                    FileInputStream(file).use { fis ->
                        var bytesRead: Int
                        while (fis.read(buffer).also { bytesRead = it } != -1) {
                            digest.update(buffer, 0, bytesRead)
                        }
                    }

                    val hashHex = digest.digest().joinToString("") { "%02x".format(it) }
                    result.success(hashHex)

                } catch (e: PackageManager.NameNotFoundException) {
                    result.error("NOT_FOUND", "Package $packageName not found", null)
                } catch (e: Exception) {
                    result.error("HASH_ERROR", "Failed to hash APK: ${e.message}", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
