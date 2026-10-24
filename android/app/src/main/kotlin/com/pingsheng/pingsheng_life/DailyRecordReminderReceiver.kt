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

/** 每日提醒广播接收器：设备重启后恢复闹钟，到点后展示本地通知。 */
class DailyRecordReminderReceiver : BroadcastReceiver() {
    /** 开机时重新调度提醒，普通闹钟触发时展示通知。 */
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            if (isReminderEnabled(context)) {
                schedule(context)
            }
            return
        }
        showNotification(context)
    }

    /** 提醒相关的静态方法和偏好键。 */
    companion object {
        const val PREFS_NAME = "pingsheng_app_preferences"
        const val KEY_THEME_MODE = "theme_mode"
        const val KEY_DAILY_RECORD_REMINDER = "daily_record_reminder"

        private const val CHANNEL_ID = "daily_record_reminder"
        private const val NOTIFICATION_ID = 1007
        private const val REQUEST_CODE = 1007
        private const val REMINDER_HOUR = 20
        private const val REMINDER_MINUTE = 30

        /** 读取主题模式和每日提醒开关，供 Flutter 初始化设置页。 */
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

        /** 保存用户选择的主题模式。 */
        fun saveThemeMode(context: Context, themeMode: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_THEME_MODE, themeMode)
                .apply()
        }

        /** 保存提醒开关，并在开启时调度、关闭时取消闹钟。 */
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

        /** 查询每日提醒是否已经开启。 */
        fun isReminderEnabled(context: Context): Boolean {
            return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(KEY_DAILY_RECORD_REMINDER, false)
        }

        /** 从下一个 20:30 开始，每天重复一次不精确闹钟。 */
        fun schedule(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                nextReminderMillis(),
                AlarmManager.INTERVAL_DAY,
                reminderPendingIntent(context)
            )
        }

        /** 取消已经注册的每日提醒。 */
        fun cancel(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(reminderPendingIntent(context))
        }

        /** 创建通知渠道并展示点击后跳转到计划页的提醒通知。 */
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

        /** 计算下一次提醒时间；今天已过 20:30 则顺延到明天。 */
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

        /** 创建指向提醒广播接收器的 PendingIntent。 */
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
