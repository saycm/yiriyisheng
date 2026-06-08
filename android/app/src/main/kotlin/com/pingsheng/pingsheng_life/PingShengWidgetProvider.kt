package com.pingsheng.pingsheng_life

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class PingShengWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_QUICK_TODO -> {
                addQuickTodo(
                    context,
                    intent.getStringExtra(EXTRA_TODO_TITLE) ?: "桌面待办",
                    intent.getStringExtra(EXTRA_TODO_CATEGORY) ?: "生活"
                )
                refreshAllWidgets(context)
                return
            }
            ACTION_QUICK_FOOD -> {
                addQuickFood(context)
                refreshAllWidgets(context)
                return
            }
            ACTION_QUICK_FINANCE -> {
                addQuickFinance(context)
                refreshAllWidgets(context)
                return
            }
            ACTION_QUICK_WORKOUT -> {
                addQuickWorkout(context)
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
        private const val QUICK_FOOD_CALORIES = 80
        private const val QUICK_FINANCE_AMOUNT = 18.0
        private const val ACTION_QUICK_TODO = "com.pingsheng.pingsheng_life.widget.ADD_TODO"
        private const val ACTION_QUICK_FOOD = "com.pingsheng.pingsheng_life.widget.ADD_FOOD"
        private const val ACTION_QUICK_FINANCE = "com.pingsheng.pingsheng_life.widget.ADD_FINANCE"
        private const val ACTION_QUICK_WORKOUT = "com.pingsheng.pingsheng_life.widget.ADD_WORKOUT"
        private const val EXTRA_TODO_TITLE = "todo_title"
        private const val EXTRA_TODO_CATEGORY = "todo_category"

        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
        ) {
            for (appWidgetId in appWidgetIds) {
                updateWidget(context, appWidgetManager, appWidgetId)
            }
        }

        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val foodCalories = prefs.getInt(KEY_FOOD_CALORIES, 0)
            val pendingTodos = prefs.getInt(KEY_PENDING_TODOS, 4)
            val workoutGroups = prefs.getInt(KEY_WORKOUT_GROUPS, 0)
            val healthText = prefs.getString(KEY_HEALTH_TEXT, "健康待授权").orEmpty()
            val foodText = if (foodCalories > 0) {
                "饮食 ${foodCalories} kcal"
            } else {
                "饮食待记录"
            }
            val workoutText = "锻炼 ${workoutGroups}/${TOTAL_WORKOUT_GROUPS} 组"

            val views = RemoteViews(context.packageName, R.layout.pingsheng_widget)

            // 桌面小组件读取 App 写入的共享摘要，和 Flutter 页面保持同一份联动数据。
            views.setTextViewText(R.id.widget_title, "平生今日")
            views.setTextViewText(R.id.widget_subtitle, "桌面快速记录")
            views.setTextViewText(R.id.widget_plan, "待办 ${pendingTodos} 项")
            views.setTextViewText(R.id.widget_finance, "净资产 ¥1,555")
            views.setTextViewText(R.id.widget_health, "${healthText} · ${workoutGroups}组")
            views.setTextViewText(R.id.widget_food, foodText)
            views.setTextViewText(R.id.widget_workout, workoutText)

            // 标题和摘要负责进 App；底部快捷按钮直接写入桌面共享数据，不强制打开 App。
            views.setOnClickPendingIntent(R.id.widget_title, moduleIntent(context, "/", 1))
            views.setOnClickPendingIntent(R.id.widget_subtitle, moduleIntent(context, "/", 11))
            views.setOnClickPendingIntent(R.id.widget_plan, moduleIntent(context, "/plan", 2))
            views.setOnClickPendingIntent(R.id.widget_finance, moduleIntent(context, "/finance", 3))
            views.setOnClickPendingIntent(
                R.id.widget_health,
                moduleIntent(context, "/health", 4, "open_health")
            )
            views.setOnClickPendingIntent(R.id.widget_food, moduleIntent(context, "/food", 5))
            views.setOnClickPendingIntent(R.id.widget_workout, moduleIntent(context, "/workout", 6))
            views.setOnClickPendingIntent(
                R.id.widget_todo_life,
                quickTodoIntent(context, "桌面生活待办", "生活", 7)
            )
            views.setOnClickPendingIntent(
                R.id.widget_todo_work,
                quickTodoIntent(context, "桌面工作待办", "工作", 12)
            )
            views.setOnClickPendingIntent(
                R.id.widget_todo_health,
                quickTodoIntent(context, "桌面健康待办", "健康", 13)
            )
            views.setOnClickPendingIntent(
                R.id.widget_todo_finance,
                quickTodoIntent(context, "桌面财务待办", "财务", 14)
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_food,
                quickIntent(context, ACTION_QUICK_FOOD, 8)
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_finance,
                quickIntent(context, ACTION_QUICK_FINANCE, 9)
            )
            views.setOnClickPendingIntent(
                R.id.widget_quick_workout,
                quickIntent(context, ACTION_QUICK_WORKOUT, 10)
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

        private fun quickTodoIntent(
            context: Context,
            title: String,
            category: String,
            requestCode: Int
        ): PendingIntent {
            val intent = Intent(context, PingShengWidgetProvider::class.java).apply {
                action = ACTION_QUICK_TODO
                putExtra(EXTRA_TODO_TITLE, title)
                putExtra(EXTRA_TODO_CATEGORY, category)
            }
            return PendingIntent.getBroadcast(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        private fun addQuickFood(context: Context) {
            // 桌面一键饮食用于临时补记，进入 App 后仍可通过饮食模块添加完整细节。
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val total = prefs.getInt(KEY_FOOD_CALORIES, 0) + QUICK_FOOD_CALORIES
            prefs.edit().putInt(KEY_FOOD_CALORIES, total).apply()
        }

        private fun addQuickWorkout(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val groupsJson = safeJsonObject(prefs.getString(KEY_WORKOUT_GROUPS_JSON, "{}"))
            val currentQuickGroups = groupsJson.optInt("桌面快练", 0)
            val currentTotal = groupsJson.keys().asSequence().sumOf { key ->
                groupsJson.optInt(key, 0)
            }
            val addGroups = if (currentTotal < TOTAL_WORKOUT_GROUPS) 1 else 0
            groupsJson.put("桌面快练", currentQuickGroups + addGroups)
            val totalGroups = (currentTotal + addGroups).coerceAtMost(TOTAL_WORKOUT_GROUPS)
            prefs.edit()
                .putInt(KEY_WORKOUT_GROUPS, totalGroups)
                .putString(KEY_WORKOUT_GROUPS_JSON, groupsJson.toString())
                .apply()
        }

        private fun addQuickTodo(context: Context, title: String, category: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val todos = safeJsonArray(prefs.getString(KEY_TODOS_JSON, null), defaultTodosJson())
            todos.put(
                JSONObject()
                    .put("title", title)
                    .put("category", category)
                    .put("done", false)
            )
            val pendingTodos = (0 until todos.length()).count { index ->
                !todos.optJSONObject(index).optBoolean("done", false)
            }
            prefs.edit()
                .putString(KEY_TODOS_JSON, todos.toString())
                .putInt(KEY_PENDING_TODOS, pendingTodos)
                .apply()
        }

        private fun addQuickFinance(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val records = safeJsonArray(
                prefs.getString(KEY_FINANCE_RECORDS_JSON, null),
                defaultFinanceRecordsJson()
            )
            records.put(
                JSONObject()
                    .put("title", "桌面记账")
                    .put("subtitle", "快捷支出")
                    .put("amount", QUICK_FINANCE_AMOUNT)
                    .put("type", "支出")
            )
            prefs.edit()
                .putString(KEY_FINANCE_RECORDS_JSON, records.toString())
                .apply()
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
            return try {
                JSONArray(raw.orEmpty().ifBlank { fallback })
            } catch (_: Exception) {
                JSONArray(fallback)
            }
        }
    }
}
