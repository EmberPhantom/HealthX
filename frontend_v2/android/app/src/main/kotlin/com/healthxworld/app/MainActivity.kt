package com.healthxworld.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val STEP_CHANNEL  = "com.healthxworld.app/step_service"
    private val SLEEP_CHANNEL = "com.healthxworld.app/sleep_service"
    private val WATER_CHANNEL = "com.healthxworld.app/water_service"
    private val REQUEST_CODE_PERMISSIONS = 1001

    private fun hasRequiredPermissions(): Boolean {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestRequiredPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (permissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissions.toTypedArray(), REQUEST_CODE_PERMISSIONS)
        }
    }

    private fun startStepForegroundService() {
        val intent = Intent(this, StepCountService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                startStepForegroundService()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Step Counter Channel ──────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startStepService" -> {
                        if (hasRequiredPermissions()) {
                            startStepForegroundService()
                        } else {
                            requestRequiredPermissions()
                        }
                        result.success(null)
                    }

                    "setStepGoal", "setGoal" -> {
                        val goal = call.argument<Int>("goal") ?: 10000
                        getSharedPreferences(StepCountService.PREFS_NAME, MODE_PRIVATE)
                            .edit()
                            .putInt(StepCountService.KEY_GOAL, goal)
                            .apply()
                        result.success(null)
                    }

                    "getTodaySteps" -> {
                        val nativePrefs = getSharedPreferences(
                            StepCountService.PREFS_NAME, MODE_PRIVATE)
                        try {
                            val fp = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                            var goalLong = fp.getLong("flutter.step_goal", 0L)
                            var goalInt  = fp.getInt("flutter.step_goal", 0)
                            var goal = if (goalLong > 0L) goalLong.toInt() else goalInt
                            if (goal <= 0) {
                                goalLong = fp.getLong("flutter.${StepCountService.KEY_GOAL}", 0L)
                                goalInt  = fp.getInt("flutter.${StepCountService.KEY_GOAL}", 0)
                                goal = if (goalLong > 0L) goalLong.toInt() else goalInt
                            }
                            if (goal > 0) {
                                nativePrefs.edit()
                                    .putInt(StepCountService.KEY_GOAL, goal)
                                    .apply()
                            }
                        } catch (_: Exception) {}

                        val cal  = java.util.Calendar.getInstance()
                        val y    = cal.get(java.util.Calendar.YEAR)
                        val m    = cal.get(java.util.Calendar.MONTH) + 1
                        val d    = cal.get(java.util.Calendar.DAY_OF_MONTH)
                        val today = "$y${m.toString().padStart(2,'0')}${d.toString().padStart(2,'0')}"
                        val savedDate = nativePrefs.getString(StepCountService.KEY_DATE, "")

                        if (savedDate == today) {
                            result.success(nativePrefs.getInt(StepCountService.KEY_STEPS, 0))
                        } else {
                            result.success(0)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Sleep Alarm Channel ───────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SLEEP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleSleepAlarms" -> {
                        try {
                            val bedtimeHour   = call.argument<Int>("bedtimeHour")   ?: 23
                            val bedtimeMinute = call.argument<Int>("bedtimeMinute") ?: 0
                            val wakeHour      = call.argument<Int>("wakeHour")      ?: 6
                            val wakeMinute    = call.argument<Int>("wakeMinute")    ?: 0

                            SleepAlarmReceiver.scheduleAll(
                                this,
                                bedtimeHour, bedtimeMinute,
                                wakeHour, wakeMinute
                            )
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SLEEP_ALARM_ERROR", e.message, null)
                        }
                    }

                    "cancelSleepAlarms" -> {
                        try {
                            SleepAlarmReceiver.cancelAll(this)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SLEEP_ALARM_ERROR", e.message, null)
                        }
                    }

                    "snoozeSleepAlarm" -> {
                        try {
                            val addMinutes = call.argument<Int>("addMinutes") ?: 15
                            SleepAlarmReceiver.snoozeBedtimeAlert(this, addMinutes)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SLEEP_ALARM_ERROR", e.message, null)
                        }
                    }

                    "getPendingSleepLog" -> {
                        val prefs = getSharedPreferences(SleepAlarmReceiver.PREFS_NAME, MODE_PRIVATE)
                        val log = prefs.getString("pending_sleep_log", null)
                        result.success(log)
                    }

                    "clearPendingSleepLog" -> {
                        getSharedPreferences(SleepAlarmReceiver.PREFS_NAME, MODE_PRIVATE)
                            .edit()
                            .remove("pending_sleep_log")
                            .apply()
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Water Reminder Channel ────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startWaterReminders" -> {
                        val interval = call.argument<Int>("intervalMinutes") ?: 120
                        WaterReminderReceiver.schedule(this, interval)
                        result.success(null)
                    }
                    "stopWaterReminders" -> {
                        WaterReminderReceiver.cancel(this)
                        result.success(null)
                    }
                    "getTodayWater" -> {
                        val prefs = getSharedPreferences(WaterReminderReceiver.PREFS_NAME, MODE_PRIVATE)
                        val today = WaterReminderReceiver.getTodayKey()
                        val savedDate = prefs.getString(WaterReminderReceiver.KEY_DATE, "")
                        if (savedDate == today) {
                            result.success(prefs.getInt(WaterReminderReceiver.KEY_TODAY_AMOUNT, 0))
                        } else {
                            result.success(0)
                        }
                    }
                    "setWaterGoal" -> {
                        val goal = call.argument<Int>("goal") ?: 2500
                        getSharedPreferences(WaterReminderReceiver.PREFS_NAME, MODE_PRIVATE)
                            .edit()
                            .putInt(WaterReminderReceiver.KEY_GOAL, goal)
                            .apply()
                        result.success(null)
                    }
                    "syncTodayWater" -> {
                        val total = call.argument<Int>("todayTotal") ?: 0
                        val prefs = getSharedPreferences(WaterReminderReceiver.PREFS_NAME, MODE_PRIVATE)
                        prefs.edit()
                            .putString(WaterReminderReceiver.KEY_DATE, WaterReminderReceiver.getTodayKey())
                            .putInt(WaterReminderReceiver.KEY_TODAY_AMOUNT, total)
                            .apply()
                        result.success(null)
                    }
                    "getPendingWaterLogs" -> {
                        val prefs = getSharedPreferences(WaterReminderReceiver.PREFS_NAME, MODE_PRIVATE)
                        val logs = prefs.getString(WaterReminderReceiver.KEY_PENDING_LOGS, null)
                        result.success(logs)
                    }
                    "clearPendingWaterLogs" -> {
                        getSharedPreferences(WaterReminderReceiver.PREFS_NAME, MODE_PRIVATE)
                            .edit()
                            .remove(WaterReminderReceiver.KEY_PENDING_LOGS)
                            .apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra("sleep_snooze_action", false)) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, SLEEP_CHANNEL)
                    .invokeMethod("onSnoozeAction", null)
            }
        }
    }
}
