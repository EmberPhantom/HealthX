package com.healthxworld.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.*

class StepCountService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var stepSensor: Sensor? = null
    private lateinit var prefs: SharedPreferences

    private var sensorBaseline: Int = -1
    private var savedStepsBeforeRestart: Int = 0

    // Track last milestone & motivational notif to avoid repeated firing
    private var lastMilestoneFired: Int = -1
    private var lastMotivationalMinute: Long = -1L
    private var isTrackingPaused: Boolean = false
    private var manualOffset: Int = 0

    companion object {
        const val CHANNEL_ID         = "step_counter_channel"
        const val CHANNEL_MOTIV_ID   = "step_motivation_channel"
        const val NOTIF_ID           = 1001
        const val NOTIF_MILESTONE_ID = 1002
        const val NOTIF_REMINDER_ID  = 1003
        const val PREFS_NAME         = "step_counter_prefs"
        const val KEY_STEPS          = "today_steps"
        const val KEY_DATE           = "step_date"
        const val KEY_GOAL           = "daily_step_goal"
        const val HISTORY_PREFIX     = "history_"

        fun getTodayKey(): String {
            val cal = Calendar.getInstance()
            val y = cal.get(Calendar.YEAR)
            val m = (cal.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
            val d = cal.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
            return "$y$m$d"
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepSensor    = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)

        isTrackingPaused = prefs.getBoolean("is_tracking_paused", false)
        manualOffset = prefs.getInt("manual_steps_offset", 0)

        createNotificationChannels()
        startForeground(NOTIF_ID, buildPersistentNotification(0))

        if (!isTrackingPaused) {
            stepSensor?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }

        checkAndResetForNewDay()
        savedStepsBeforeRestart = prefs.getInt(KEY_STEPS, 0)

        scheduleEndOfDayAlarm()
        scheduleMorningMotivation()
        scheduleAfternoonNudge()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            "ACTION_SAVE_AND_RESET" -> {
                saveCurrentDayToHistory()
                checkAndResetForNewDay()
                scheduleEndOfDayAlarm()
                scheduleMorningMotivation()
                scheduleAfternoonNudge()
            }
            "ACTION_MORNING_MOTIVATE" -> {
                sendMorningMotivation()
                scheduleMorningMotivation() // schedule for next day
            }
            "ACTION_AFTERNOON_NUDGE" -> {
                sendAfternoonNudge()
                scheduleAfternoonNudge() // schedule for next day
            }
            "ACTION_PAUSE_TRACKING" -> {
                pauseTracking()
            }
            "ACTION_RESUME_TRACKING" -> {
                resumeTracking()
            }
            "ACTION_REFRESH_STEPS" -> {
                refreshSteps()
            }
            "ACTION_ADD_STEPS" -> {
                val amount = intent.getIntExtra("amount", 500)
                addManualSteps(amount)
            }
        }
        return START_STICKY
    }

    override fun onSensorChanged(event: SensorEvent?) {
        event ?: return
        val totalSinceBoot = event.values[0].toInt()
        if (sensorBaseline == -1) {
            sensorBaseline = totalSinceBoot - savedStepsBeforeRestart + manualOffset
        }
        val todaySteps = (totalSinceBoot - sensorBaseline + manualOffset).coerceAtLeast(0)
        prefs.edit().putInt(KEY_STEPS, todaySteps).apply()
        updatePersistentNotification(todaySteps)
        checkMilestones(todaySteps)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        super.onDestroy()
    }

    private fun pauseTracking() {
        if (!isTrackingPaused) {
            isTrackingPaused = true
            sensorManager.unregisterListener(this)
            prefs.edit().putBoolean("is_tracking_paused", true).apply()
            updatePersistentNotification(prefs.getInt(KEY_STEPS, 0))
        }
    }

    private fun resumeTracking() {
        if (isTrackingPaused) {
            isTrackingPaused = false
            prefs.edit().putBoolean("is_tracking_paused", false).apply()
            stepSensor?.let {
                sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
            // Force sensor baseline recalc
            sensorBaseline = -1
            savedStepsBeforeRestart = prefs.getInt(KEY_STEPS, 0)
            updatePersistentNotification(prefs.getInt(KEY_STEPS, 0))
        }
    }

    private fun refreshSteps() {
        val steps = prefs.getInt(KEY_STEPS, 0)
        updatePersistentNotification(steps)
    }

    private fun addManualSteps(amount: Int) {
        manualOffset += amount
        prefs.edit().putInt("manual_steps_offset", manualOffset).apply()

        val currentSteps = prefs.getInt(KEY_STEPS, 0)
        val newSteps = currentSteps + amount
        prefs.edit().putInt(KEY_STEPS, newSteps).apply()

        updatePersistentNotification(newSteps)
        checkMilestones(newSteps)
    }

    // ─── Check & fire milestone notifications ────────────────────────────────
    private fun checkMilestones(steps: Int) {
        val goal = getGoal()

        // milestone thresholds: 25%, 50%, 75%, 100%, beyond
        val milestones = listOf(
            Pair((goal * 0.25).toInt(), "milestone_25"),
            Pair((goal * 0.50).toInt(), "milestone_50"),
            Pair((goal * 0.75).toInt(), "milestone_75"),
            Pair(goal,                  "milestone_100"),
            Pair((goal * 1.25).toInt(), "milestone_125"),
        )

        for ((threshold, key) in milestones) {
            val lastFiredForKey = prefs.getString("notif_fired_$key", "") ?: ""
            val today = getTodayKey()
            if (steps >= threshold && lastFiredForKey != today) {
                prefs.edit().putString("notif_fired_$key", today).apply()
                sendMilestoneNotification(steps, threshold, goal, key)
                break // only one milestone per sensor update
            }
        }
    }

    // ─── Milestone notification ───────────────────────────────────────────────
    private fun sendMilestoneNotification(steps: Int, threshold: Int, goal: Int, milestoneKey: String) {
        val intent     = packageManager.getLaunchIntentForPackage(packageName)
        val pi         = PendingIntent.getActivity(
            this, milestoneKey.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val (title, body, emoji) = when (milestoneKey) {
            "milestone_25" -> Triple(
                "🚀 You're on your way!",
                "You've walked ${formatSteps(steps)} steps — 25% of your ${formatSteps(goal)} goal. Keep the momentum going!",
                "🚀"
            )
            "milestone_50" -> Triple(
                "🔥 Halfway there!",
                "Amazing! ${formatSteps(steps)} steps done — you're exactly at the midpoint. Don't stop now!",
                "🔥"
            )
            "milestone_75" -> Triple(
                "💪 Almost there!",
                "75% complete! ${formatSteps(steps)} steps logged. Just ${formatSteps(goal - steps)} more to crush your goal!",
                "💪"
            )
            "milestone_100" -> Triple(
                "🏆 GOAL CRUSHED!",
                "🎉 You did it! ${formatSteps(steps)} steps — your daily goal is complete! You're an absolute legend!",
                "🏆"
            )
            "milestone_125" -> Triple(
                "⭐ Beyond the goal!",
                "Extraordinary! ${formatSteps(steps)} steps — 125% of your goal. You're built different! 🌟",
                "⭐"
            )
            else -> Triple("Great progress!", "Keep walking!", "👟")
        }

        val notif = NotificationCompat.Builder(this, CHANNEL_MOTIV_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            .setColor(
                when (milestoneKey) {
                    "milestone_100" -> 0xFFFFD700.toInt() // gold
                    "milestone_125" -> 0xFF9C27B0.toInt() // purple
                    else            -> 0xFF4CAF50.toInt() // green
                }
            )
            .build()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED &&
                    NotificationManagerCompat.from(this).areNotificationsEnabled())) {
            NotificationManagerCompat.from(this).notify(NOTIF_MILESTONE_ID, notif)
        }
    }

    // ─── Morning motivation (8:00 AM) ────────────────────────────────────────
    private fun sendMorningMotivation() {
        val goal    = getGoal()
        val history = getYesterdaySteps()

        val messages = listOf(
            Triple(
                "🌅 Good morning, Champion!",
                "Today is a fresh start. Your goal: ${formatSteps(goal)} steps. Let's lace up and make it happen! 💪",
                0xFF2979FF.toInt()
            ),
            Triple(
                "☀️ Rise & Walk!",
                "Every step counts today. You've got a ${formatSteps(goal)}-step challenge waiting. Are you ready? 🏃",
                0xFFFF9800.toInt()
            ),
            Triple(
                "🎯 New Day, New Goal!",
                "Morning! Your target today is ${formatSteps(goal)} steps. Yesterday you walked ${formatSteps(history)} — beat that today! 🔥",
                0xFF00BFA5.toInt()
            ),
            Triple(
                "🚀 Your Daily Mission Starts Now!",
                "Hit ${formatSteps(goal)} steps today and feel the energy flow. Small steps, big results — let's go! ⚡",
                0xFF4CAF50.toInt()
            ),
        )

        val pick = messages[Calendar.getInstance().get(Calendar.DAY_OF_YEAR) % messages.size]
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pi     = PendingIntent.getActivity(
            this, 2001, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_MOTIV_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(pick.first)
            .setContentText(pick.second)
            .setStyle(NotificationCompat.BigTextStyle().bigText(pick.second))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setColor(pick.third)
            .build()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED &&
                    NotificationManagerCompat.from(this).areNotificationsEnabled())) {
            NotificationManagerCompat.from(this).notify(NOTIF_REMINDER_ID, notif)
        }
    }

    // ─── Afternoon nudge (2:00 PM) ────────────────────────────────────────────
    private fun sendAfternoonNudge() {
        val steps    = prefs.getInt(KEY_STEPS, 0)
        val goal     = getGoal()
        val remaining = (goal - steps).coerceAtLeast(0)
        val percent  = ((steps.toFloat() / goal) * 100).toInt()

        if (steps >= goal) return // Already completed — no nudge needed

        val (title, body) = when {
            percent < 25 -> Pair(
                "⏰ Time to move!",
                "It's afternoon and you've walked ${formatSteps(steps)} steps. ${formatSteps(remaining)} more to go — every little walk counts! 👟"
            )
            percent < 50 -> Pair(
                "🚶 Keep it going!",
                "Good progress! ${formatSteps(steps)} steps logged. You need ${formatSteps(remaining)} more to hit your goal today. You've got this! 💪"
            )
            percent < 75 -> Pair(
                "🔥 Halfway and climbing!",
                "${percent}% done! ${formatSteps(remaining)} more steps to complete your goal. Take a quick walk — you're SO close! 🏆"
            )
            else -> Pair(
                "⭐ Almost at the finish line!",
                "Just ${formatSteps(remaining)} steps away from crushing your ${formatSteps(goal)}-step goal! Don't stop now — you're amazing! 🎯"
            )
        }

        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pi     = PendingIntent.getActivity(
            this, 2002, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_MOTIV_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(pi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setColor(0xFF2979FF.toInt())
            .build()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            (ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED &&
                    NotificationManagerCompat.from(this).areNotificationsEnabled())) {
            NotificationManagerCompat.from(this).notify(NOTIF_REMINDER_ID + 1, notif)
        }
    }

    // ─── Persistent foreground notification ───────────────────────────────────
    private fun buildPersistentNotification(steps: Int): Notification {
        val goal       = getGoal()
        val remaining  = (goal - steps).coerceAtLeast(0)
        val percent    = ((steps.toFloat() / goal.coerceAtLeast(1)) * 100).toInt().coerceAtMost(100)
        val intent     = packageManager.getLaunchIntentForPackage(packageName)
        val pi         = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val pauseResumeIntent = Intent(this, StepCountService::class.java).apply {
            action = if (isTrackingPaused) "ACTION_RESUME_TRACKING" else "ACTION_PAUSE_TRACKING"
        }
        val pauseResumePendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                this, 101, pauseResumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            PendingIntent.getService(
                this, 101, pauseResumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        val pauseResumeTitle = if (isTrackingPaused) "▶ Resume" else "⏸ Pause"

        val addStepsIntent = Intent(this, StepCountService::class.java).apply {
            action = "ACTION_ADD_STEPS"
            putExtra("amount", 500)
        }
        val addStepsPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                this, 103, addStepsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            PendingIntent.getService(
                this, 103, addStepsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        val stage = when {
            steps >= goal -> "Legend Status 🏆"
            percent >= 75 -> "Hero Stride ⚡"
            percent >= 50 -> "Pace Maker 💪"
            percent >= 25 -> "Flow State 🏃"
            else -> "Warmup Stage 🌅"
        }

        val title = if (isTrackingPaused) {
            "⏸ Paused  •  $stage"
        } else {
            "${formatSteps(steps)} steps  •  $stage"
        }

        val calories = Math.round(steps * 0.04)
        val distance = String.format("%.2f", steps * 0.00075)
        val body = "$distance km  •  $calories kcal  •  $percent%"

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.mipmap.launcher_icon)
            .setContentIntent(pi)
            .setOngoing(true)
            .setSilent(true)
            .setColor(if (steps >= goal) 0xFFFFD700.toInt() else 0xFF2979FF.toInt())
            .setOnlyAlertOnce(true)
            .setProgress(goal, steps, false)
            .addAction(
                android.R.drawable.ic_media_play,
                pauseResumeTitle,
                pauseResumePendingIntent
            )
            .addAction(
                android.R.drawable.ic_input_add,
                "+500 Steps",
                addStepsPendingIntent
            )

        return builder.build()
    }

    // A simple ASCII progress bar e.g. ██████░░░░
    private fun buildProgressBar(percent: Int): String {
        val filled  = (percent / 10).coerceIn(0, 10)
        val empty   = 10 - filled
        return "█".repeat(filled) + "░".repeat(empty)
    }

    private fun updatePersistentNotification(steps: Int) {
        // Only update notification if permission is granted or not required
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIF_ID, buildPersistentNotification(steps))
        }
    }

    // ─── Schedule 11:59 PM alarm (save + reset) ───────────────────────────────
    private fun scheduleEndOfDayAlarm() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_MONTH, 1)
        }
        scheduleAlarm(cal, "ACTION_SAVE_AND_RESET", 3001)
    }

    // ─── Schedule 8:00 AM morning motivation ──────────────────────────────────
    private fun scheduleMorningMotivation() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 8)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_MONTH, 1)
        }
        scheduleAlarm(cal, "ACTION_MORNING_MOTIVATE", 3002)
    }

    // ─── Schedule 2:00 PM afternoon nudge ─────────────────────────────────────
    private fun scheduleAfternoonNudge() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_MONTH, 1)
        }
        scheduleAlarm(cal, "ACTION_AFTERNOON_NUDGE", 3003)
    }

    private fun scheduleAlarm(cal: Calendar, action: String, requestCode: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent       = Intent(this, StepCountService::class.java).apply { this.action = action }
        val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            PendingIntent.getForegroundService(
                this, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else {
            PendingIntent.getService(
                this, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pendingIntent)
        }
    }

    // ─── New day reset ────────────────────────────────────────────────────────
    private fun checkAndResetForNewDay() {
        val today     = getTodayKey()
        val savedDate = prefs.getString(KEY_DATE, "")
        if (savedDate != today) {
            prefs.edit()
                .putInt(KEY_STEPS, 0)
                .putString(KEY_DATE, today)
                .putInt("manual_steps_offset", 0)
                // reset milestone flags for new day
                .remove("notif_fired_milestone_25")
                .remove("notif_fired_milestone_50")
                .remove("notif_fired_milestone_75")
                .remove("notif_fired_milestone_100")
                .remove("notif_fired_milestone_125")
                .apply()
            sensorBaseline          = -1
            savedStepsBeforeRestart = 0
            manualOffset            = 0
        }
    }

    // ─── Save current day to history ──────────────────────────────────────────
    private fun saveCurrentDayToHistory() {
        val steps      = prefs.getInt(KEY_STEPS, 0)
        val historyKey = HISTORY_PREFIX + getTodayKey()
        val existing   = prefs.getInt(historyKey, 0)
        if (steps > existing) prefs.edit().putInt(historyKey, steps).apply()

        val cal = Calendar.getInstance()
        if (cal.get(Calendar.DAY_OF_MONTH) == cal.getActualMaximum(Calendar.DAY_OF_MONTH)) {
            deleteOldMonthData(cal)
        }
    }

    private fun deleteOldMonthData(cal: Calendar) {
        val currentYear  = cal.get(Calendar.YEAR)
        val currentMonth = cal.get(Calendar.MONTH) + 1
        val prefix       = "$currentYear${currentMonth.toString().padStart(2, '0')}"
        val editor       = prefs.edit()
        for (key in prefs.all.keys.toList()) {
            if (key.startsWith(HISTORY_PREFIX)) {
                val dateStr = key.removePrefix(HISTORY_PREFIX)
                if (dateStr.length == 8 && dateStr.substring(0, 6) != prefix) editor.remove(key)
            }
        }
        editor.apply()
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private fun getGoal(): Int {
        // 1. Check native prefs (synced from MainActivity on every getTodaySteps call)
        val nativeGoal = prefs.getInt(KEY_GOAL, 0)
        if (nativeGoal > 0) return nativeGoal

        // 2. Read from Flutter's prefs file using getLong
        return try {
            val flutterGoal = readFlutterGoal()
            if (flutterGoal > 0) {
                prefs.edit().putInt(KEY_GOAL, flutterGoal).apply()
                flutterGoal
            } else {
                10000
            }
        } catch (_: Exception) {
            10000
        }
    }

    private fun readFlutterGoal(): Int {
        val fp = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // 1. Check "flutter.step_goal" first
        var asLong = fp.getLong("flutter.step_goal", 0L)
        if (asLong > 0L) return asLong.toInt()
        var asInt = fp.getInt("flutter.step_goal", 0)
        if (asInt > 0) return asInt

        // 2. Fallback to "flutter.daily_step_goal"
        asLong = fp.getLong("flutter.$KEY_GOAL", 0L)
        if (asLong > 0L) return asLong.toInt()
        asInt = fp.getInt("flutter.$KEY_GOAL", 0)
        return asInt
    }

    private fun formatSteps(n: Int): String {
        return if (n >= 1000) "${n / 1000},${(n % 1000).toString().padStart(3, '0')}"
        else n.toString()
    }

    private fun getYesterdaySteps(): Int {
        val cal = Calendar.getInstance().apply { add(Calendar.DAY_OF_MONTH, -1) }
        val y = cal.get(Calendar.YEAR)
        val m = (cal.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
        val d = cal.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
        return prefs.getInt(HISTORY_PREFIX + "$y$m$d", 0)
    }

    // ─── Notification Channels ────────────────────────────────────────────────
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val persistentChannel = NotificationChannel(
                CHANNEL_ID, "Step Counter", NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Live step count in the status bar"
                setShowBadge(false)
            }

            val motivChannel = NotificationChannel(
                CHANNEL_MOTIV_ID, "Step Motivation", NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Milestone achievements & daily motivation"
                setShowBadge(true)
                enableVibration(true)
            }

            getSystemService(NotificationManager::class.java).apply {
                createNotificationChannel(persistentChannel)
                createNotificationChannel(motivChannel)
            }
        }
    }
}
