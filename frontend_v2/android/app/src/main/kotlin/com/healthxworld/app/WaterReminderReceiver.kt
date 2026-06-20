package com.healthxworld.app

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import java.util.Calendar

class WaterReminderReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME             = "water_tracker_prefs"
        const val KEY_GOAL               = "water_goal"
        const val KEY_TODAY_AMOUNT       = "today_water"
        const val KEY_DATE               = "water_date"
        const val KEY_PENDING_LOGS       = "pending_water_logs" // Serialized list: "amount|timestamp,amount|timestamp..."
        const val KEY_ENABLED            = "water_reminders_enabled"
        const val KEY_INTERVAL_MINUTES   = "water_interval_minutes"

        const val ACTION_WATER_REMINDER = "com.healthxworld.app.WATER_REMINDER"
        const val ACTION_ADD_250        = "com.healthxworld.app.WATER_ADD_250"
        const val ACTION_ADD_500        = "com.healthxworld.app.WATER_ADD_500"

        const val CHANNEL_WATER_ID      = "water_reminder_channel"
        const val NOTIF_WATER_ID        = 4001

        const val RC_REMINDER           = 7001
        const val RC_ADD_250            = 7002
        const val RC_ADD_500            = 7003

        // ── Schedule periodic water alarms ───────────────────────────────────
        fun schedule(context: Context, intervalMinutes: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putBoolean(KEY_ENABLED, true)
                .putInt(KEY_INTERVAL_MINUTES, intervalMinutes)
                .apply()

            createChannel(context)
            scheduleNextAlarm(context, intervalMinutes)

            android.util.Log.d("WaterReminder", "✅ Water reminders scheduled every $intervalMinutes minutes.")
        }

        // ── Cancel reminders ──────────────────────────────────────────────────
        fun cancel(context: Context) {
            val intent = Intent(context, WaterReminderReceiver::class.java).apply {
                action = ACTION_WATER_REMINDER
            }
            val pi = PendingIntent.getBroadcast(
                context, RC_REMINDER, intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            pi?.let {
                (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(it)
                it.cancel()
            }
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().putBoolean(KEY_ENABLED, false).apply()

            NotificationManagerCompat.from(context).cancel(NOTIF_WATER_ID)
            android.util.Log.d("WaterReminder", "❌ Water reminders cancelled.")
        }

        // ── Restore after boot ────────────────────────────────────────────────
        fun restoreAfterBoot(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            if (prefs.getBoolean(KEY_ENABLED, false)) {
                val interval = prefs.getInt(KEY_INTERVAL_MINUTES, 120)
                schedule(context, interval)
            }
        }

        // ── Schedule the next single alarm ───────────────────────────────────
        private fun scheduleNextAlarm(context: Context, intervalMinutes: Int) {
            val intent = Intent(context, WaterReminderReceiver::class.java).apply {
                action = ACTION_WATER_REMINDER
            }
            val pi = PendingIntent.getBroadcast(
                context, RC_REMINDER, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val triggerAtMillis = System.currentTimeMillis() + (intervalMinutes * 60 * 1000)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pi)
            }
        }

        // ── Create Notification Channel ──────────────────────────────────────
        fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm = context.getSystemService(NotificationManager::class.java)
                nm.createNotificationChannel(NotificationChannel(
                    CHANNEL_WATER_ID, "Water Reminders",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Periodic water intake reminders"
                    enableVibration(true)
                    setShowBadge(true)
                })
            }
        }

        fun getTodayKey(): String {
            val cal = Calendar.getInstance()
            val y = cal.get(Calendar.YEAR)
            val m = (cal.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
            val d = cal.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
            return "$y$m$d"
        }

        private fun sendNotifIfAllowed(context: Context, id: Int, notif: android.app.Notification) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                (ContextCompat.checkSelfPermission(context, android.Manifest.permission.POST_NOTIFICATIONS) ==
                        android.content.pm.PackageManager.PERMISSION_GRANTED &&
                        NotificationManagerCompat.from(context).areNotificationsEnabled())) {
                NotificationManagerCompat.from(context).notify(id, notif)
            }
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        createChannel(context)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Prevent showing reminders during sleeping hours (11 PM - 6 AM by default)
        val sleepPrefs = context.getSharedPreferences("sleep_alarm_prefs", Context.MODE_PRIVATE)
        val bHour = sleepPrefs.getInt("bedtime_hour", 23)
        val wHour = sleepPrefs.getInt("wake_hour", 6)

        when (intent.action) {
            ACTION_WATER_REMINDER -> {
                val cal = Calendar.getInstance()
                val hour = cal.get(Calendar.HOUR_OF_DAY)

                // If currently in sleep window, silent bypass and reschedule
                var isSleeping = false
                if (bHour > wHour) {
                    if (hour >= bHour || hour < wHour) isSleeping = true
                } else {
                    if (hour in bHour until wHour) isSleeping = true
                }

                if (!isSleeping) {
                    sendHydrationReminder(context, prefs)
                }

                // Reschedule next check
                if (prefs.getBoolean(KEY_ENABLED, false)) {
                    val interval = prefs.getInt(KEY_INTERVAL_MINUTES, 120)
                    scheduleNextAlarm(context, interval)
                }
            }

            ACTION_ADD_250 -> {
                addWaterIntake(context, prefs, 250)
            }

            ACTION_ADD_500 -> {
                addWaterIntake(context, prefs, 500)
            }
        }
    }

    private fun sendHydrationReminder(context: Context, prefs: SharedPreferences) {
        val today = getTodayKey()
        val savedDate = prefs.getString(KEY_DATE, "")
        val todayAmount = if (savedDate == today) prefs.getInt(KEY_TODAY_AMOUNT, 0) else 0
        val goal = prefs.getInt(KEY_GOAL, 2500)

        val body = "You have drank $todayAmount mL today. Target: $goal mL. Stay hydrated! 💧"

        val add250Intent = Intent(context, WaterReminderReceiver::class.java).apply { action = ACTION_ADD_250 }
        val add250Pi = PendingIntent.getBroadcast(
            context, RC_ADD_250, add250Intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val add500Intent = Intent(context, WaterReminderReceiver::class.java).apply { action = ACTION_ADD_500 }
        val add500Pi = PendingIntent.getBroadcast(
            context, RC_ADD_500, add500Intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openPi = PendingIntent.getActivity(
            context, NOTIF_WATER_ID, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, CHANNEL_WATER_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Matches step/launcher icons if available
            .setContentTitle("💧 Time to Hydrate!")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(openPi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setColor(0xFF2196F3.toInt()) // Water blue theme
            .addAction(android.R.drawable.ic_input_add, "+250 mL", add250Pi)
            .addAction(android.R.drawable.ic_input_add, "+500 mL", add500Pi)
            .build()

        sendNotifIfAllowed(context, NOTIF_WATER_ID, notif)
    }

    private fun addWaterIntake(context: Context, prefs: SharedPreferences, amount: Int) {
        val today = getTodayKey()
        val savedDate = prefs.getString(KEY_DATE, "")
        val currentAmount = if (savedDate == today) prefs.getInt(KEY_TODAY_AMOUNT, 0) else 0
        val goal = prefs.getInt(KEY_GOAL, 2500)
        val newAmount = currentAmount + amount

        // Append to serialized pending logs "amount|timestamp"
        val timestamp = System.currentTimeMillis()
        val currentLogs = prefs.getString(KEY_PENDING_LOGS, "")
        val newLogs = if (currentLogs.isNullOrEmpty()) {
            "$amount|$timestamp"
        } else {
            "$currentLogs,$amount|$timestamp"
        }

        prefs.edit()
            .putString(KEY_DATE, today)
            .putInt(KEY_TODAY_AMOUNT, newAmount)
            .putString(KEY_PENDING_LOGS, newLogs)
            .apply()

        // Update existing notification with new amount
        val body = "Logged $amount mL! Today: $newAmount / $goal mL. Keep it up! 💧"
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val openPi = PendingIntent.getActivity(
            context, NOTIF_WATER_ID, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, CHANNEL_WATER_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("💧 Hydration Updated")
            .setContentText(body)
            .setContentIntent(openPi)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setColor(0xFF2196F3.toInt())
            .build()

        sendNotifIfAllowed(context, NOTIF_WATER_ID, notif)
        android.util.Log.d("WaterReminder", "💧 Logged $amount mL. Total today: $newAmount mL.")
    }
}
