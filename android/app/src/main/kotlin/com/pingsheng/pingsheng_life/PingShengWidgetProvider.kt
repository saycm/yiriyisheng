// 中文注释：Android 桌面小组件，负责展示生活摘要和处理快捷动作。

package com.pingsheng.pingsheng_life

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class PingShengWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                refreshAllWidgets(context)
                return
            }
            ACTION_REFRESH -> {
                refreshAllWidgets(context)
                return
            }
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    companion object {
        const val PREFS_NAME = "pingsheng_life_widget_summary"
        const val KEY_FOOD_CALORIES = "food_calories"
        const val KEY_PENDING_TODOS = "pending_todos"
        const val KEY_TODOS_JSON = "todos_json"
        const val KEY_FINANCE_RECORDS_JSON = "finance_records_json"
        const val KEY_WORKOUT_GROUPS = "workout_groups"
        const val KEY_WORKOUT_GROUPS_JSON = "workout_groups_json"
        const val KEY_HEALTH_TEXT = "health_text"
        private const val TOTAL_WORKOUT_GROUPS = 19
        private const val ACTION_REFRESH = "com.pingsheng.pingsheng_life.widget.REFRESH"

        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            // 系统可能一次要求刷新多个小组件实例，逐个写入 RemoteViews。
            for (appWidgetId in appWidgetIds) {
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // 小组件没有 Flutter 运行时，只能读取 MainActivity 写入的 SharedPreferences 摘要。
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val foodCalories = prefs.getInt(KEY_FOOD_CALORIES, 0)
            val pendingTodos = prefs.getInt(KEY_PENDING_TODOS, 4)
            val financeRecords = safeJsonArray(
                prefs.getString(KEY_FINANCE_RECORDS_JSON, null),
                defaultFinanceRecordsJson()
            )
            val todayExpense = todayExpense(financeRecords)
            val workoutGroups = prefs.getInt(KEY_WORKOUT_GROUPS, 0)
            val healthText = prefs.getString(KEY_HEALTH_TEXT, "健康待授权").orEmpty()
            val activeCalories = extractCalories(healthText)
            val foodText = if (foodCalories > 0) {
                "饮食 ${foodCalories} kcal"
            } else {
                "饮食待记录"
            }
            val workoutText = "锻炼 ${workoutGroups}/${TOTAL_WORKOUT_GROUPS} 组"
            val financeText = if (todayExpense > 0.0) {
                "¥${formatMoney(todayExpense)}"
            } else {
                "未记账"
            }
            val financeStatus = if (todayExpense > 0.0) "已记账" else "待记账"

            val views = RemoteViews(context.packageName, R.layout.pingsheng_widget)

            // 桌面小组件读取 App 写入的共享摘要，和 Flutter 页面保持同一份联动数据。
            val todoProgress = ((pendingTodos.coerceAtMost(8) / 8.0) * 100).toInt()
            views.setTextViewText(R.id.widget_title, "平生今日")
            views.setTextViewText(R.id.widget_subtitle, "$healthText · 轻量记录")
            views.setTextViewText(R.id.widget_primary_metric_value, "$pendingTodos")
            views.setTextViewText(R.id.widget_primary_metric_label, "项待处理")
            views.setProgressBar(R.id.widget_todo_progress, 100, todoProgress, false)
            views.setTextViewText(R.id.widget_finance, financeText)
            views.setTextViewText(R.id.widget_finance_status, financeStatus)
            views.setTextColor(
                R.id.widget_finance_status,
                Color.parseColor(if (todayExpense > 0.0) "#164B35" else "#7A4D18")
            )
            views.setInt(
                R.id.widget_finance_status,
                "setBackgroundResource",
                if (todayExpense > 0.0) {
                    R.drawable.pingsheng_widget_status_ok
                } else {
                    R.drawable.pingsheng_widget_quick_orange
                }
            )
            views.setTextViewText(R.id.widget_food, "$foodText · $workoutText")
            views.setTextViewText(R.id.widget_plan, "计划\n加待办")
            views.setTextViewText(R.id.widget_quick_food, "饮食\n记录")
            views.setTextViewText(R.id.widget_quick_finance, "记账\n快捷支出")
            views.setTextViewText(
                R.id.widget_active_calories,
                if (activeCalories > 0) {
                    "今日消耗\n${activeCalories} kcal"
                } else {
                    "今日消耗\n待同步"
                }
            )

            // 需要输入内容的操作进入 App 的真实编辑流程；刷新动作留在小组件内完成。
            views.setOnClickPendingIntent(R.id.widget_title, quickIntent(context, ACTION_REFRESH, 1))
            views.setOnClickPendingIntent(
                R.id.widget_summary_card,
                moduleIntent(context, "/finance", 3, "add_finance")
            )
            views.setOnClickPendingIntent(
                R.id.widget_plan,
                moduleIntent(context, "/plan", 2, "add_todo")
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_food,
                moduleIntent(context, "/food", 8, "add_food")
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_finance,
                moduleIntent(context, "/finance", 9, "add_finance")
            )
            views.setOnClickPendingIntent(
                R.id.widget_active_calories,
                quickIntent(context, ACTION_REFRESH, 10)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun refreshAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, PingShengWidgetProvider::class.java)
            )
            updateWidgets(context, manager, ids)
        }

        private fun moduleIntent(
            context: Context,
            route: String,
            requestCode: Int,
            action: String? = null
        ): PendingIntent {
            // 需要用户输入的动作只传 route/action，由 Flutter 打开对应编辑弹层。
            val targetRoute = if (action == null) route else "$route?action=$action"
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("source", "home_widget")
                putExtra(MainActivity.EXTRA_TARGET_ROUTE, targetRoute)
                putExtra(MainActivity.EXTRA_WIDGET_ACTION, action)
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun quickIntent(context: Context, action: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, PingShengWidgetProvider::class.java).apply {
                this.action = action
            }
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun todayExpense(records: JSONArray): Double {
            // 小组件只展示今日支出概览，收入记录不会计入支出金额。
            var total = 0.0
            for (index in 0 until records.length()) {
                val record = records.optJSONObject(index) ?: continue
                if (record.optString("type") == "支出") {
                    total += record.optDouble("amount", 0.0)
                }
            }
            return total
        }

        private fun formatMoney(amount: Double): String {
            if (amount >= 10000.0) {
                val compact = amount / 10000.0
                return if (compact % 1.0 == 0.0) {
                    "${compact.toInt()}万"
                } else {
                    String.format("%.1f万", compact)
                }
            }
            return if (amount % 1.0 == 0.0) {
                amount.toInt().toString()
            } else {
                String.format("%.2f", amount)
            }
        }

        private fun extractCalories(text: String): Int {
            val match = Regex("""(\d+)\s*kcal""").find(text)
            return match?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        }

        private fun defaultTodosJson(): String {
            val defaults = JSONArray()
            listOf("遛狗" to "生活", "打羽毛球" to "健康", "做报表" to "工作", "理财" to "财务")
                .forEach { item ->
                    defaults.put(
                        JSONObject()
                            .put("title", item.first)
                            .put("category", item.second)
                            .put("done", false)
                    )
                }
            return defaults.toString()
        }

        private fun defaultFinanceRecordsJson(): String {
            val defaults = JSONArray()
            listOf(
                Triple("三餐", "原味板烧鸡腿麦满分", 18.0),
                Triple("数码分期", "手机分期还款", 500.0),
                Triple("工资", "本月收入", 3000.0),
                Triple("咖啡", "优品豆浆（小杯）", 6.0)
            ).forEach { item ->
                defaults.put(
                    JSONObject()
                        .put("title", item.first)
                        .put("subtitle", item.second)
                        .put("amount", item.third)
                        .put("type", if (item.first == "工资") "收入" else "支出")
                )
            }
            return defaults.toString()
        }

        private fun safeJsonObject(raw: String?): JSONObject {
            return try {
                JSONObject(raw.orEmpty().ifBlank { "{}" })
            } catch (_: Exception) {
                JSONObject()
            }
        }

        private fun safeJsonArray(raw: String?, fallback: String): JSONArray {
            // SharedPreferences 可能被旧版本写入空值，解析失败时回到展示用默认数据。
            return try {
                JSONArray(raw.orEmpty().ifBlank { fallback })
            } catch (_: Exception) {
                JSONArray(fallback)
            }
        }
    }
}
