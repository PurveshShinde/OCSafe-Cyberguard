package com.ocsafe.ocsafe_cyberguard.theft

import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.abs

class TheftMotionAnalyzer(sensitivityName: String) {

    // Thresholds matching Dart implementation
    private val jerkThresholdLow = 150.0f
    private val jerkThresholdMedium = 200.0f
    private val jerkThresholdHigh = 250.0f

    private val continuousThreshold = 25.0f
    private val continuousSampleCount = 5

    var jerkThreshold: Float = jerkThresholdMedium
    private var continuousCount = 0

    init {
        updateSensitivity(sensitivityName)
    }

    fun updateSensitivity(sensitivityName: String) {
        jerkThreshold = when (sensitivityName.lowercase()) {
            "low" -> jerkThresholdLow
            "high" -> jerkThresholdHigh
            else -> jerkThresholdMedium
        }
    }

    fun detectJerk(x: Float, y: Float, z: Float): Boolean {
        val magnitudeSquared = x * x + y * y + z * z
        return magnitudeSquared > jerkThreshold
    }

    fun detectContinuous(x: Float, y: Float, z: Float): Boolean {
        val sumAbs = abs(x) + abs(y) + abs(z)
        if (sumAbs > continuousThreshold) {
            continuousCount++
        }
        return continuousCount >= continuousSampleCount
    }

    fun reset() {
        continuousCount = 0
    }
}
