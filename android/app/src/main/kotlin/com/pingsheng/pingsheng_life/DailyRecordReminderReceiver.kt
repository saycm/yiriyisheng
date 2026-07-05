// 中文注释：每日记录提醒，负责本地通知展示和 Android 闹钟调度。

package com.pingsheng.pingsheng_life

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import java.util.Calendar

class DailyRecordReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            if (isReminderEnabled(context)) {
                schedule(context)
            }
            return
        }
        showNotification(context)
    }

    companion object {
        const val PREFS_NAME = "pingsheng_app_preferences"
        const val KEY_THEME_MODE = "theme_mode"
        const val KEY_DAILY_RECORD_REMINDER = "daily_record_reminder"

        private const val CHANNEL_ID = "daily_record_reminder"
        private const val NOTIFICATION_ID = 1007
        private const val REQUEST_CODE = 1007
        private const val REMINDER_HOUR = 20
        private const val REMINDER_MINUTE = 30

        fun loadPreferences(context: Context): Map<String, Any> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            return mapOf(
                "themeMode" to (prefs.getString(KEY_THEME_MODE, "system") ?: "system"),
                "dailyRecordReminderEnabled" to prefs.getBoolean(
                    KEY_DAILY_RECORD_REMINDER,
                    false
                )
            )
        }

        fun saveThemeMode(context: Context, themeMode: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_THEME_MODE, themeMode)
                .apply()
        }

        fun setReminderEnabled(context: Context, enabled: Boolean) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_DAILY_RECORD_REMINDER, enabled)
                .apply()
            if (enabled) {
                schedule(context)
            } else {
                cancel(context)
            }
        }

        fun isReminderEnabled(context: Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_DAILY_RECORD_REMINDER, false)
        }

        fun schedule(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                nextReminderMillis(),
                AlarmManager.INTERVAL_DAY,
                reminderPendingIntent(context)
            )
        }

        fun cancel(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(reminderPendingIntent(context))
        }

        private fun showNotification(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                "每日记录提醒",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationManager.createNotificationChannel(channel)

            val openIntent = Intent(context, MainActivity::class.java).apply {
                putExtra(MainActivity.EXTRA_TARGET_ROUTE, "/plan")
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val contentIntent = PendingIntent.getActivity(
                context,
                REQUEST_CODE,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val notification = Notification.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("平生记录提醒")
                .setContentText("今天的计划、饮食和锻炼还没有整理，花 1 分钟补一下。")
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .build()
            notificationManager.notify(NOTIFICATION_ID, notification)
        }

        private fun nextReminderMillis(): Long {
            val calendar = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, REMINDER_HOUR)
                set(Calendar.MINUTE, REMINDER_MINUTE)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            if (calendar.timeInMillis <= System.currentTimeMillis()) {
                calendar.add(Calendar.DAY_OF_YEAR, 1)
            }
            return calendar.timeInMillis
        }

        private fun reminderPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, DailyRecordReminderReceiver::class.java)
            return PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
