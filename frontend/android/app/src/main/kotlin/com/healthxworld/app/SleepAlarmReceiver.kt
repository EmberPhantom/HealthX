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

// ══════════════════════════════════════════════════════════════════════════════
//  SleepAlarmReceiver
//  ✅ Exact same pattern as StepCountService — proven reliable
//  ✅ Snooze button → BroadcastReceiver (NO app open, background only)
//  ✅ Snooze fires ACTION_SNOOZE_15 → onReceive handles it → reschedules alert
//  ✅ Works when app completely closed
//  ✅ Auto-reschedules next day after every fire
// ══════════════════════════════════════════════════════════════════════════════

class SleepAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val PREFS_NAME         = "sleep_alarm_prefs"
        const val KEY_BEDTIME_HOUR   = "bedtime_hour"
        const val KEY_BEDTIME_MINUTE = "bedtime_minute"
        const val KEY_WAKE_HOUR      = "wake_hour"
        const val KEY_WAKE_MINUTE    = "wake_minute"
        const val KEY_ENABLED        = "sleep_alarms_enabled"

        // Alarm actions
        const val ACTION_BEDTIME_REMINDER = "com.healthxworld.app.SLEEP_BEDTIME_REMINDER"
        const val ACTION_BEDTIME_ALERT    = "com.healthxworld.app.SLEEP_BEDTIME_ALERT"
        const val ACTION_SLEEP_GOAL       = "com.healthxworld.app.SLEEP_GOAL_COMPLETE"
        const val ACTION_MORNING_MOTIV    = "com.healthxworld.app.SLEEP_MORNING_MOTIV"
        // ✅ Snooze — BroadcastReceiver action (background, no app open)
        const val ACTION_SNOOZE_15        = "com.healthxworld.app.SLEEP_SNOOZE_15"

        // Notification IDs
        const val CHANNEL_SLEEP_ID  = "sleep_reminder_channel"
        const val CHANNEL_MOTIV_ID  = "sleep_motivation_channel"
        const val NOTIF_REMINDER_ID = 5001
        const val NOTIF_ALERT_ID    = 5002
        const val NOTIF_GOAL_ID     = 5003
        const val NOTIF_MOTIV_ID    = 5004

        // Request codes
        const val RC_REMINDER = 6001
        const val RC_ALERT    = 6002
        const val RC_GOAL     = 6003
        const val RC_MOTIV    = 6004
        const val RC_SNOOZE   = 6005  // ✅ Snooze broadcast request code

        // ── Schedule all 4 alarms ─────────────────────────────────────────────
        fun scheduleAll(context: Context, bedtimeHour: Int, bedtimeMinute: Int,
                        wakeHour: Int, wakeMinute: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putInt(KEY_BEDTIME_HOUR,   bedtimeHour)
                .putInt(KEY_BEDTIME_MINUTE, bedtimeMinute)
                .putInt(KEY_WAKE_HOUR,      wakeHour)
                .putInt(KEY_WAKE_MINUTE,    wakeMinute)
                .putBoolean(KEY_ENABLED,    true)
                .apply()

            createChannels(context)

            scheduleAlarm(context, ACTION_BEDTIME_REMINDER, RC_REMINDER,
                bedtimeHour, bedtimeMinute, offsetMinutes = -10)
            scheduleAlarm(context, ACTION_BEDTIME_ALERT, RC_ALERT,
                bedtimeHour, bedtimeMinute, offsetMinutes = 0)
            scheduleAlarm(context, ACTION_SLEEP_GOAL, RC_GOAL,
                wakeHour, wakeMinute, offsetMinutes = 0)
            scheduleAlarm(context, ACTION_MORNING_MOTIV, RC_MOTIV,
                wakeHour, wakeMinute, offsetMinutes = 0)

            android.util.Log.d("SleepAlarm",
                "✅ All 4 sleep alarms scheduled: " +
                        "Bedtime $bedtimeHour:${bedtimeMinute.toString().padStart(2,'0')} | " +
                        "Wake $wakeHour:${wakeMinute.toString().padStart(2,'0')}")
        }

        // ── Cancel all alarms ─────────────────────────────────────────────────
        fun cancelAll(context: Context) {
            listOf(
                ACTION_BEDTIME_REMINDER to RC_REMINDER,
                ACTION_BEDTIME_ALERT    to RC_ALERT,
                ACTION_SLEEP_GOAL       to RC_GOAL,
                ACTION_MORNING_MOTIV    to RC_MOTIV,
            ).forEach { (action, rc) ->
                val pi = PendingIntent.getBroadcast(
                    context, rc,
                    Intent(context, SleepAlarmReceiver::class.java).apply { this.action = action },
                    PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
                )
                pi?.let {
                    (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(it)
                    it.cancel()
                }
            }
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().putBoolean(KEY_ENABLED, false).apply()
        }

        // ── Snooze from Flutter side (via MethodChannel) ──────────────────────
        fun snoozeBedtimeAlert(context: Context, addMinutes: Int) {
            doSnooze(context, addMinutes)
        }

        // ── Restore after reboot ──────────────────────────────────────────────
        fun restoreAfterBoot(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            if (!prefs.getBoolean(KEY_ENABLED, false)) return

            val bHour   = prefs.getInt(KEY_BEDTIME_HOUR,   -1)
            val bMinute = prefs.getInt(KEY_BEDTIME_MINUTE,  0)
            val wHour   = prefs.getInt(KEY_WAKE_HOUR,      -1)
            val wMinute = prefs.getInt(KEY_WAKE_MINUTE,     0)

            if (bHour == -1 || wHour == -1) return
            scheduleAll(context, bHour, bMinute, wHour, wMinute)
            android.util.Log.d("SleepAlarm", "✅ Sleep alarms restored after reboot")
        }

        // ── Core snooze logic — shared between notification button + Flutter ──
        fun doSnooze(context: Context, addMinutes: Int) {
            val prefs   = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val bHour   = prefs.getInt(KEY_BEDTIME_HOUR,   23)
            val bMinute = prefs.getInt(KEY_BEDTIME_MINUTE,  0)

            // Cancel existing bedtime alert
            val existingPi = PendingIntent.getBroadcast(
                context, RC_ALERT,
                Intent(context, SleepAlarmReceiver::class.java).apply {
                    action = ACTION_BEDTIME_ALERT
                },
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            existingPi?.let {
                (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(it)
            }

            // Dismiss the current notification
            NotificationManagerCompat.from(context).cancel(NOTIF_ALERT_ID)

            // Compute snoozed time (+15 min from NOW, not original bedtime)
            val nowCal = Calendar.getInstance()
            nowCal.add(Calendar.MINUTE, addMinutes)
            val newHour   = nowCal.get(Calendar.HOUR_OF_DAY)
            val newMinute = nowCal.get(Calendar.MINUTE)

            // Reschedule bedtime alert at snoozed time
            scheduleAlarm(context, ACTION_BEDTIME_ALERT, RC_ALERT,
                newHour, newMinute, offsetMinutes = 0)

            // Show a small confirmation notification
            val confirmBody = "Bedtime snoozed by $addMinutes min. " +
                    "New alert at $newHour:${newMinute.toString().padStart(2,'0')}. Sweet dreams soon! 😴"
            val confirmNotif = NotificationCompat.Builder(context, CHANNEL_SLEEP_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("⏰ Snoozed +$addMinutes min")
                .setContentText(confirmBody)
                .setStyle(NotificationCompat.BigTextStyle().bigText(confirmBody))
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .setColor(0xFF7B5FE8.toInt())
                .build()
            sendNotifIfAllowed(context, NOTIF_ALERT_ID, confirmNotif)

            android.util.Log.d("SleepAlarm",
                "⏰ Snoozed $addMinutes min → $newHour:${newMinute.toString().padStart(2,'0')}")
        }

        // ── Internal: schedule single alarm ──────────────────────────────────
        private fun scheduleAlarm(context: Context, action: String, requestCode: Int,
                                  hour: Int, minute: Int, offsetMinutes: Int) {
            val cal = Calendar.getInstance().apply {
                var h = hour
                var m = minute + offsetMinutes
                while (m < 0)   { m += 60; h -= 1 }
                while (m >= 60) { m -= 60; h += 1 }
                h = ((h % 24) + 24) % 24
                set(Calendar.HOUR_OF_DAY, h)
                set(Calendar.MINUTE,      m)
                set(Calendar.SECOND,      0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= System.currentTimeMillis()) {
                    add(Calendar.DAY_OF_MONTH, 1)
                }
            }
            val intent = Intent(context, SleepAlarmReceiver::class.java).apply {
                this.action = action
            }
            val pi = PendingIntent.getBroadcast(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            } else {
                am.setExact(AlarmManager.RTC_WAKEUP, cal.timeInMillis, pi)
            }
        }

        // ── Create notification channels ──────────────────────────────────────
        fun createChannels(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val nm = context.getSystemService(NotificationManager::class.java)
                nm.createNotificationChannel(NotificationChannel(
                    CHANNEL_SLEEP_ID, "Sleep Reminders",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Bedtime and wake-up notifications"
                    enableVibration(true)
                    setShowBadge(true)
                })
                nm.createNotificationChannel(NotificationChannel(
                    CHANNEL_MOTIV_ID, "Morning Motivation",
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = "Daily motivational messages"
                    enableVibration(false)
                    setShowBadge(false)
                })
            }
        }

        private fun sendNotifIfAllowed(context: Context, id: Int,
                                       notif: android.app.Notification) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                (ContextCompat.checkSelfPermission(context,
                    android.Manifest.permission.POST_NOTIFICATIONS) ==
                        android.content.pm.PackageManager.PERMISSION_GRANTED &&
                        NotificationManagerCompat.from(context).areNotificationsEnabled())) {
                NotificationManagerCompat.from(context).notify(id, notif)
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    //  onReceive — alarm fires here
    // ════════════════════════════════════════════════════════════════════════
    override fun onReceive(context: Context, intent: Intent) {
        createChannels(context)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        when (intent.action) {
            ACTION_BEDTIME_REMINDER -> {
                sendBedtimeReminder(context, prefs)
                val bH = prefs.getInt(KEY_BEDTIME_HOUR, 23)
                val bM = prefs.getInt(KEY_BEDTIME_MINUTE, 0)
                scheduleAlarm(context, ACTION_BEDTIME_REMINDER, RC_REMINDER, bH, bM, -10)
            }
            ACTION_BEDTIME_ALERT -> {
                sendBedtimeAlert(context)
                val bH = prefs.getInt(KEY_BEDTIME_HOUR, 23)
                val bM = prefs.getInt(KEY_BEDTIME_MINUTE, 0)
                scheduleAlarm(context, ACTION_BEDTIME_ALERT, RC_ALERT, bH, bM, 0)
            }
            ACTION_SLEEP_GOAL -> {
                sendSleepGoalComplete(context, prefs)
                val wH = prefs.getInt(KEY_WAKE_HOUR, 6)
                val wM = prefs.getInt(KEY_WAKE_MINUTE, 0)
                scheduleAlarm(context, ACTION_SLEEP_GOAL, RC_GOAL, wH, wM, 0)
            }
            ACTION_MORNING_MOTIV -> {
                sendMorningMotivation(context)
                val wH = prefs.getInt(KEY_WAKE_HOUR, 6)
                val wM = prefs.getInt(KEY_WAKE_MINUTE, 0)
                scheduleAlarm(context, ACTION_MORNING_MOTIV, RC_MOTIV, wH, wM, 0)
            }
            // ✅ Snooze — fires from notification button, NO app open
            ACTION_SNOOZE_15 -> {
                doSnooze(context, 15)
            }
        }
    }

    // ── Notification 1: Bedtime Reminder ─────────────────────────────────────
    private fun sendBedtimeReminder(context: Context, prefs: SharedPreferences) {
        val bH     = prefs.getInt(KEY_BEDTIME_HOUR, 23)
        val bM     = prefs.getInt(KEY_BEDTIME_MINUTE, 0)
        val period = if (bH >= 12) "PM" else "AM"
        val h12    = if (bH == 0) 12 else if (bH > 12) bH - 12 else bH
        val timeStr = "$h12:${bM.toString().padStart(2, '0')} ${period.lowercase()}"
        val body   = "Your bedtime is $timeStr. Start winding down, dim the lights and put your phone away. 😴"

        notify(context,
            id       = NOTIF_REMINDER_ID,
            channel  = CHANNEL_SLEEP_ID,
            title    = "🌙 Bedtime in 10 minutes!",
            body     = body,
            color    = 0xFF7B5FE8.toInt(),
            priority = NotificationCompat.PRIORITY_HIGH
        )
    }

    // ── Notification 2: Bedtime Alert with action buttons ────────────────────
    private fun sendBedtimeAlert(context: Context) {
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)

        // "Yes, Sleeping Now" → opens app, dismisses notification
        val sleepNowPi = PendingIntent.getActivity(
            context, 7001, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ✅ "Snooze" → BroadcastReceiver (background, NO app open)
        //    Directly calls doSnooze(15) via ACTION_SNOOZE_15
        val snoozeBroadcastIntent = Intent(context, SleepAlarmReceiver::class.java).apply {
            action = ACTION_SNOOZE_15
        }
        val snoozePi = PendingIntent.getBroadcast(
            context, RC_SNOOZE,
            snoozeBroadcastIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openPi = PendingIntent.getActivity(
            context, 7003, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, CHANNEL_SLEEP_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("🌙 Time for Bed!")
            .setContentText("Are you going to sleep now?")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("It's your scheduled bedtime. Your body is ready for rest.\n" +
                        "Are you going to sleep now, or do you need a little more time?"))
            .setContentIntent(openPi)
            .setAutoCancel(false)  // ✅ Don't auto-dismiss — user must tap a button
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_SOUND or NotificationCompat.DEFAULT_VIBRATE)
            .setColor(0xFF4A6CF7.toInt())
            .addAction(android.R.drawable.ic_dialog_info,
                "😴 Yes, Sleeping Now", sleepNowPi)   // opens app
            .addAction(android.R.drawable.ic_dialog_info,
                "⏰ Snooze 15 min", snoozePi)          // ✅ background only
            .build()

        sendNotifIfAllowed(context, NOTIF_ALERT_ID, notif)
    }

    // ── Notification 3: Sleep Goal Complete ──────────────────────────────────
    private fun sendSleepGoalComplete(context: Context, prefs: SharedPreferences) {
        val bH = prefs.getInt(KEY_BEDTIME_HOUR,   23)
        val bM = prefs.getInt(KEY_BEDTIME_MINUTE,  0)
        val wH = prefs.getInt(KEY_WAKE_HOUR,        6)
        val wM = prefs.getInt(KEY_WAKE_MINUTE,      0)

        var bedMins  = bH * 60 + bM
        var wakeMins = wH * 60 + wM
        if (wakeMins <= bedMins) wakeMins += 24 * 60
        val durationMins = wakeMins - bedMins
        val dH = durationMins / 60
        val dM = durationMins % 60
        val durationStr = if (dM > 0) "${dH}h ${dM}m" else "${dH}h"

        val body = "🌟 You slept $durationStr last night! Your body has recovered and recharged. " +
                "Open the app to see your detailed sleep analysis."

        notify(context,
            id       = NOTIF_GOAL_ID,
            channel  = CHANNEL_SLEEP_ID,
            title    = "🎉 Sleep Goal Complete!",
            body     = body,
            color    = 0xFF4CAF50.toInt(),
            priority = NotificationCompat.PRIORITY_HIGH
        )
    }

    // ── Notification 4: Morning Motivation ───────────────────────────────────
    private fun sendMorningMotivation(context: Context) {
        val quotes = listOf(
            "Rise & shine! Every morning is a chance to rewrite your story. 🌅",
            "Your body rested. Your mind is sharp. Today you are unstoppable. 💪",
            "Good sleep is the foundation of great days. You just built one. 🏗️",
            "The best project you'll ever work on is you. Good morning! 🌟",
            "Sleep well → Think clearly → Win the day. You're ready. ⚡",
            "Champions rest AND hustle. You did both. Go get your day! 🏆",
            "Waking up is the first victory of the day. You've already won. 🎯",
            "A rested mind moves mountains. What's your mountain today? 🏔️",
            "Your health is your greatest wealth. Guard it well. Good morning! 💎",
            "Every sunrise is an invitation to make today better than yesterday. 🌄",
            "You slept. You restored. You're recharged. Now go be extraordinary! ⚡",
            "Morning light, fresh mind, full energy. This is YOUR time. ✨",
            "Small healthy habits create big life changes. Good sleep = big win. 🎉",
            "The world is full of opportunities. Well-rested people see them first. 👁️",
            "You gave your body what it needed. Now your body will give you everything. 💪",
            "Today's success was built last night with good sleep. Rise and shine! 🚀",
            "A fresh morning after quality sleep — this is your superpower. 🦸",
            "Consistency is key. Another night of good sleep. Keep going! 🔑",
            "Your mind is clearest in the morning. Use this time wisely. 🧠",
            "Great days start with great mornings. You're already ahead. 📈",
            "Sleep is the golden chain that ties health and our bodies together. 🌙✨",
            "You invested in yourself last night. Time to collect the returns. 💰",
            "Wellness is a lifestyle, not a destination. Today is part of the journey. 🛤️",
            "Your future self will thank you for the sleep you got last night. 🙏",
            "New day, full energy, endless possibilities. Let's go! 🌈"
        )
        val idx   = Calendar.getInstance().get(Calendar.DAY_OF_YEAR) % quotes.size
        val quote = quotes[idx]

        notify(context,
            id       = NOTIF_MOTIV_ID,
            channel  = CHANNEL_MOTIV_ID,
            title    = "💪 Good Morning, Champion!",
            body     = quote,
            color    = 0xFFE8D98E.toInt(),
            priority = NotificationCompat.PRIORITY_DEFAULT
        )
    }

    // ── Helper: build + send ──────────────────────────────────────────────────
    private fun notify(context: Context, id: Int, channel: String,
                       title: String, body: String, color: Int, priority: Int) {
        val launchPi = PendingIntent.getActivity(
            context, id,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notif = NotificationCompat.Builder(context, channel)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(launchPi)
            .setAutoCancel(true)
            .setPriority(priority)
            .setColor(color)
            .apply {
                if (priority == NotificationCompat.PRIORITY_HIGH) {
                    setDefaults(NotificationCompat.DEFAULT_SOUND or
                            NotificationCompat.DEFAULT_VIBRATE)
                }
            }
            .build()
        sendNotifIfAllowed(context, id, notif)
    }

    private fun sendNotifIfAllowed(context: Context, id: Int,
                                   notif: android.app.Notification) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            (ContextCompat.checkSelfPermission(context,
                android.Manifest.permission.POST_NOTIFICATIONS) ==
                    android.content.pm.PackageManager.PERMISSION_GRANTED &&
                    NotificationManagerCompat.from(context).areNotificationsEnabled())) {
            NotificationManagerCompat.from(context).notify(id, notif)
        }
    }
}