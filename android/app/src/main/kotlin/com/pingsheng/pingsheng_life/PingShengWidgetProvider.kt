// 中文注释：Android 桌面小组件，负责展示生活摘要和处理快捷动作。

package com.pingsheng.pingsheng_life

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

private const val ACTION_REFRESH = "com.pingsheng.pingsheng_life.widget.REFRESH"

/** 深色/浅色小组件共用的基类，统一处理系统刷新和广播事件。 */
abstract class PingShengBaseWidgetProvider(
    private val layoutResId: Int
) : AppWidgetProvider() {
    /** 应用升级或内部刷新广播时重绘全部小组件。 */
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_MY_PACKAGE_REPLACED,
            ACTION_REFRESH -> {
                refreshAllWidgets(context)
                return
            }
        }
        super.onReceive(context, intent)
    }

    /** 系统要求更新小组件时交给统一渲染器绘制。 */
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        PingShengWidgetRenderer.updateWidgets(
            context,
            appWidgetManager,
            appWidgetIds,
            layoutResId,
            javaClass
        )
    }

    /** 找到当前 Provider 的所有实例并逐个刷新。 */
    private fun refreshAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, javaClass))
        PingShengWidgetRenderer.updateWidgets(context, manager, ids, layoutResId, javaClass)
    }
}

/** 深色主题小组件 Provider，同时提供共享偏好键和主动刷新入口。 */
class PingShengWidgetProvider : PingShengBaseWidgetProvider(R.layout.pingsheng_widget_dark) {
    /** 小组件共享存储键与静态刷新方法。 */
    companion object {
        const val PREFS_NAME = "pingsheng_life_widget_summary"
        const val KEY_FOOD_CALORIES = "food_calories"
        const val KEY_FOOD_SUMMARY_DATE = "food_summary_date"
        const val KEY_FOOD_LOGS_JSON = "food_logs_json"
        const val KEY_PENDING_TODOS = "pending_todos"
        const val KEY_TODOS_JSON = "todos_json"
        const val KEY_FINANCE_RECORDS_JSON = "finance_records_json"
        const val KEY_WORKOUT_GROUPS = "workout_groups"
        const val KEY_WORKOUT_GROUPS_JSON = "workout_groups_json"
        const val KEY_WORKOUT_PROGRESS_DATE = "workout_progress_date"
        const val KEY_HEALTH_TEXT = "health_text"
        const val KEY_HEALTH_SUMMARY_DATE = "health_summary_date"

        /** 主动刷新所有深色小组件实例。 */
        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            PingShengWidgetRenderer.updateWidgets(
                context,
                appWidgetManager,
                appWidgetIds,
                R.layout.pingsheng_widget_dark,
                PingShengWidgetProvider::class.java
            )
        }
    }
}

/** 浅色主题小组件 Provider。 */
class PingShengLightWidgetProvider : PingShengBaseWidgetProvider(R.layout.pingsheng_widget_light) {
    /** 主动刷新所有浅色小组件实例。 */
    companion object {
        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            PingShengWidgetRenderer.updateWidgets(
                context,
                appWidgetManager,
                appWidgetIds,
                R.layout.pingsheng_widget_light,
                PingShengLightWidgetProvider::class.java
            )
        }
    }
}

/** 小组件渲染器：把 SharedPreferences 摘要写入 RemoteViews 并绑定点击动作。 */
private object PingShengWidgetRenderer {
    /** 批量刷新系统给出的所有小组件 id。 */
    fun updateWidgets(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        layoutResId: Int,
        providerClass: Class<out AppWidgetProvider>
    ) {
        // 系统可能一次要求刷新多个小组件实例，逐个写入 RemoteViews。
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId, layoutResId, providerClass)
        }
    }

    /** 读取今日数据并渲染单个小组件，包括摘要、进度和快捷入口。 */
    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        layoutResId: Int,
        providerClass: Class<out AppWidgetProvider>
    ) {
        // 小组件没有 Flutter 运行时，只能读取 MainActivity 写入的 SharedPreferences 摘要。
        val prefs = context.getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
        val today = java.time.LocalDate.now()
        val foodCalories = prefs.getInt(PingShengWidgetProvider.KEY_FOOD_CALORIES, 0)
        val foodSummaryDate = prefs.getString(
            PingShengWidgetProvider.KEY_FOOD_SUMMARY_DATE,
            null
        )
        val pendingTodos = prefs.getInt(PingShengWidgetProvider.KEY_PENDING_TODOS, 0)
        val todos = safeJsonArray(
            prefs.getString(PingShengWidgetProvider.KEY_TODOS_JSON, null),
            "[]"
        )
        val financeRecords = safeJsonArray(
            prefs.getString(PingShengWidgetProvider.KEY_FINANCE_RECORDS_JSON, null),
            "[]"
        )
        val nextTodoTitle = nextTodoTitle(todos)
        val todayExpense = todayExpense(financeRecords)
        val todayIncome = todayIncome(financeRecords)
        val workoutGroups = prefs.getInt(PingShengWidgetProvider.KEY_WORKOUT_GROUPS, 0)
        val workoutSummaryDate = prefs.getString(
            PingShengWidgetProvider.KEY_WORKOUT_PROGRESS_DATE,
            null
        )
        val healthText = prefs.getString(PingShengWidgetProvider.KEY_HEALTH_TEXT, "状态待授权").orEmpty()
        val healthSummaryDate = prefs.getString(
            PingShengWidgetProvider.KEY_HEALTH_SUMMARY_DATE,
            null
        )
        val healthCardText = WidgetSummaryPolicy.healthCardText(
            healthText,
            healthSummaryDate,
            today
        )
        val foodText = WidgetSummaryPolicy.foodText(foodCalories, foodSummaryDate, today)
        val workoutText = WidgetSummaryPolicy.workoutText(
            workoutGroups,
            workoutSummaryDate,
            today
        )
        val expenseText = "¥${formatMoney(todayExpense)}"
        val incomeText = "¥${formatMoney(todayIncome)}"

        val views = RemoteViews(context.packageName, layoutResId)

        // 桌面小组件读取 App 写入的共享摘要，和 Flutter 页面保持同一份联动数据。
        val todoProgress = ((pendingTodos.coerceAtMost(8) / 8.0) * 100).toInt()
        views.setTextViewText(R.id.widget_primary_metric_value, "$pendingTodos")
        views.setTextViewText(R.id.widget_primary_metric_label, "待处理")
        views.setTextViewText(R.id.widget_todo_load_label, "待办")
        views.setTextViewText(R.id.widget_next_todo, "待处理 · 下一项 $nextTodoTitle")
        views.setProgressBar(R.id.widget_todo_progress, 100, todoProgress, false)
        views.setTextViewText(R.id.widget_finance_expense, expenseText)
        views.setTextViewText(R.id.widget_finance_income, incomeText)
        views.setTextViewText(R.id.widget_food, foodText)
        views.setTextViewText(R.id.widget_workout, workoutText)
        views.setTextViewText(R.id.widget_plan, "计划\n加待办")
        views.setTextViewText(R.id.widget_quick_food, "饮食\n记录")
        views.setTextViewText(R.id.widget_quick_finance, "记账\n快捷支出")
        views.setTextViewText(
            R.id.widget_active_calories,
            healthCardText
        )

        // 需要输入内容的操作进入 App 的真实编辑流程；刷新动作留在小组件内完成。
        views.setOnClickPendingIntent(
            R.id.widget_left_summary,
            quickIntent(context, providerClass, ACTION_REFRESH, 1)
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
            quickIntent(context, providerClass, ACTION_REFRESH, 10)
        )

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    /** 创建打开指定 Flutter 模块的点击意图，可附带快捷动作。 */
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

    /** 创建留在小组件内部执行的刷新广播意图。 */
    private fun quickIntent(
        context: Context,
        providerClass: Class<out AppWidgetProvider>,
        action: String,
        requestCode: Int
    ): PendingIntent {
        val intent = Intent(context, providerClass).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** 汇总今日支出金额。 */
    private fun todayExpense(records: JSONArray): Double {
        // 小组件只展示今日支出概览，收入记录不会计入支出金额。
        return todayFinanceTotal(records, "支出")
    }

    /** 汇总今日收入金额。 */
    private fun todayIncome(records: JSONArray): Double {
        // 收入只作为桌面摘要展示，不在小组件内触发任何记账动作。
        return todayFinanceTotal(records, "收入")
    }

    /** 找到第一条未完成待办的标题，用作小组件摘要。 */
    private fun nextTodoTitle(todos: JSONArray): String {
        for (index in 0 until todos.length()) {
            val todo = todos.optJSONObject(index) ?: continue
            val status = todo.optString("status")
            if (status == "completed" || status == "archived") {
                continue
            }
            val title = todo.optString("title").trim()
            if (title.isNotEmpty()) {
                return title
            }
        }
        return "暂无待办"
    }

    /** 按收支类型筛选今天的记录并求和。 */
    private fun todayFinanceTotal(records: JSONArray, type: String): Double {
        var total = 0.0
        for (index in 0 until records.length()) {
            val record = records.optJSONObject(index) ?: continue
            if (record.optString("type") == type && isToday(record.optString("date"))) {
                total += record.optDouble("amount", 0.0)
            }
        }
        return total
    }

    /** 兼容 ISO 时间字符串和纯日期字符串，判断记录是否属于今天。 */
    private fun isToday(rawDate: String): Boolean {
        return try {
            val date = java.time.Instant.parse(rawDate)
                .atZone(java.time.ZoneId.systemDefault())
                .toLocalDate()
            date == java.time.LocalDate.now()
        } catch (_: Exception) {
            try {
                java.time.LocalDate.parse(rawDate.substringBefore("T")) ==
                    java.time.LocalDate.now()
            } catch (_: Exception) {
                false
            }
        }
    }

    /** 把金额压缩成最多两位小数，超过一万时显示为“万”。 */
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

    /** 安全解析 SharedPreferences 中的 JSON 数组，失败时使用空数组。 */
    private fun safeJsonArray(raw: String?, fallback: String): JSONArray {
        // SharedPreferences 可能被旧版本写入空值，解析失败时回到真实空状态。
        return try {
            JSONArray(raw.orEmpty().ifBlank { fallback })
        } catch (_: Exception) {
            JSONArray(fallback)
        }
    }
}
