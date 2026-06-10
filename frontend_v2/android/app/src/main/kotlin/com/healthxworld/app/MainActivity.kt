package com.healthxworld.app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val STEP_CHANNEL  = "com.healthxworld.app/step_service"
    private val SLEEP_CHANNEL = "com.healthxworld.app/sleep_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Step Counter Channel ──────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STEP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startStepService" -> {
                        val intent = Intent(this, StepCountService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "setStepGoal" -> {
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
                            val goalLong = fp.getLong("flutter.${StepCountService.KEY_GOAL}", 0L)
                            val goalInt  = fp.getInt("flutter.${StepCountService.KEY_GOAL}", 0)
                            val goal = if (goalLong > 0L) goalLong.toInt() else goalInt
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
