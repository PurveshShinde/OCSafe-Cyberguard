package com.ocsafe.ocsafe_cyberguard

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ocsafe.cyberguard/uninstall"
    private val STORAGE_CHANNEL = "com.ocsafe.cyberguard/storage_permission"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }
}
