// 中文注释：Android 原生入口，负责 Flutter 通道、权限申请、更新下载和健康数据桥接。

package com.pingsheng.pingsheng_life

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.aggregate.AggregateMetric
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.BasalMetabolicRateRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.roundToInt
import kotlin.math.sqrt
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity(), SensorEventListener {
    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private var widgetChannel: MethodChannel? = null
    private var healthPermissionLauncher: ActivityResultLauncher<Set<String>>? = null
    private var notificationPermissionLauncher: ActivityResultLauncher<String>? = null
    private var pendingHealthPermissionResult: MethodChannel.Result? = null
    private var pendingReminderResult: MethodChannel.Result? = null
    private var sensorManager: SensorManager? = null
    private var latestStepCounter: Float? = null
    private var latestHeartRate: Float? = null
    private var latestAcceleration: Float? = null
    private var lastSensorUpdateMillis: Long? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        healthPermissionLauncher =
            registerForActivityResult(PermissionController.createRequestPermissionResultContract()) {
                grantedPermissions: Set<String> ->
                pendingHealthPermissionResult?.success(
                    mapOf(
                        "granted" to HealthPermissionPolicy.canReadAny(
                            HEALTH_PERMISSIONS,
                            grantedPermissions
                        ),
                        "grantedCount" to grantedPermissions.size
                    )
                )
                pendingHealthPermissionResult = null
            }
        notificationPermissionLauncher =
            registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
                finishDailyRecordReminderRequest(granted)
            }
        super.onCreate(savedInstanceState)
    }

    override fun getInitialRoute(): String? {
        // 桌面小组件点击不同摘要时，会通过这里把用户带到对应 Flutter 模块。
        return intent?.getStringExtra(EXTRA_TARGET_ROUTE) ?: super.getInitialRoute()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // widget_summary 通道连接 Flutter 状态和 Android 桌面小组件共享摘要。
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "loadLifeSummary" -> result.success(loadLifeSummary())
                        "saveLifeSummary" -> {
                            saveLifeSummary(call.arguments)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }

        // 健康通道把 Health Connect 和手机传感器统一成 Flutter 可读的 Map。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadHealthSnapshot" -> loadHealthSnapshot(result)
                    "requestHealthPermissions" -> requestHealthPermissions(result)
                    "openHealthConnectSettings" -> {
                        openHealthConnectSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 主观状态记录独立于 Health Connect，按日期保存 Flutter 生成的 JSON。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HEALTH_MANUAL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadHealthManualRecords" -> result.success(
                        getSharedPreferences(HEALTH_MANUAL_PREFS_NAME, MODE_PRIVATE)
                            .getString(KEY_HEALTH_MANUAL_RECORDS_JSON, "[]")
                    )
                    "saveHealthManualRecords" -> {
                        val recordsJson = call.argument<String>("recordsJson") ?: "[]"
                        getSharedPreferences(HEALTH_MANUAL_PREFS_NAME, MODE_PRIVATE)
                            .edit()
                            .putString(KEY_HEALTH_MANUAL_RECORDS_JSON, recordsJson)
                            .apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 登录态放进加密 SharedPreferences，避免 access/refresh token 明文落盘。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadAuthSession" -> result.success(loadAuthSession())
                    "saveAuthSession" -> {
                        try {
                            saveAuthSession(call.arguments as? String ?: "")
                            result.success(null)
                        } catch (error: Exception) {
                            result.error(
                                "secure_store_unavailable",
                                error.message ?: "登录态安全存储不可用",
                                null
                            )
                        }
                    }
                    "clearAuthSession" -> {
                        clearAuthSession()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // 更新下载交给系统浏览器/下载器处理，Flutter 只负责拿到下载 URL。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDownloadUrl" -> openDownloadUrl(call.argument<String>("url"), result)
                    else -> result.notImplemented()
                }
            }

        // 应用偏好目前承载主题和每日记录提醒，提醒需要 Android 13 通知权限。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_PREFERENCES_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "loadAppPreferences" -> result.success(
                        DailyRecordReminderReceiver.loadPreferences(this)
                    )
                    "saveThemeMode" -> {
                        val themeMode = call.argument<String>("themeMode") ?: "system"
                        DailyRecordReminderReceiver.saveThemeMode(this, themeMode)
                        result.success(null)
                    }
                    "setDailyRecordReminder" -> setDailyRecordReminder(
                        call.argument<Boolean>("enabled") == true,
                        result
                    )
                    else -> result.notImplemented()
                }
            }

    }

    override fun onResume() {
        super.onResume()
        startSensorListeners()
    }

    override fun onPause() {
        sensorManager?.unregisterListener(this)
        super.onPause()
    }

    override fun onDestroy() {
        pendingHealthPermissionResult?.success(
            mapOf("granted" to false, "grantedCount" to 0)
        )
        pendingHealthPermissionResult = null
        pendingReminderResult?.success(
            mapOf("enabled" to false, "permissionGranted" to false)
        )
        pendingReminderResult = null
        mainScope.cancel()
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchWidgetAction(intent)
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_STEP_COUNTER -> latestStepCounter = event.values.firstOrNull()
            Sensor.TYPE_HEART_RATE -> latestHeartRate = event.values.firstOrNull()
            Sensor.TYPE_ACCELEROMETER -> {
                val x = event.values.getOrNull(0) ?: 0f
                val y = event.values.getOrNull(1) ?: 0f
                val z = event.values.getOrNull(2) ?: 0f
                latestAcceleration = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
            }
        }
        lastSensorUpdateMillis = System.currentTimeMillis()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun dispatchWidgetAction(intent: Intent?) {
        val route = intent?.getStringExtra(EXTRA_TARGET_ROUTE) ?: return
        val action = intent.getStringExtra(EXTRA_WIDGET_ACTION)
        // App 已经在前台/后台时，小组件点击通过 MethodChannel 继续触发 Flutter 页面动作。
        widgetChannel?.invokeMethod(
            "openWidgetAction",
            mapOf(
                "route" to route,
                "action" to action
            )
        )
    }

    private fun loadLifeSummary(): Map<String, Any?> {
        val prefs = getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
        return mapOf(
            "foodCalories" to prefs.getInt(PingShengWidgetProvider.KEY_FOOD_CALORIES, 0),
            "foodSummaryDate" to prefs.getString(
                PingShengWidgetProvider.KEY_FOOD_SUMMARY_DATE,
                null
            ),
            "foodLogsJson" to prefs.getString(
                PingShengWidgetProvider.KEY_FOOD_LOGS_JSON,
                null
            ),
            "pendingTodos" to prefs.getInt(PingShengWidgetProvider.KEY_PENDING_TODOS, 0),
            "todosJson" to prefs.getString(
                PingShengWidgetProvider.KEY_TODOS_JSON,
                null
            ),
            "financeRecordsJson" to prefs.getString(
                PingShengWidgetProvider.KEY_FINANCE_RECORDS_JSON,
                null
            ),
            "workoutGroups" to prefs.getInt(PingShengWidgetProvider.KEY_WORKOUT_GROUPS, 0),
            "workoutGroupsJson" to prefs.getString(
                PingShengWidgetProvider.KEY_WORKOUT_GROUPS_JSON,
                "{}"
            ).orEmpty(),
            "workoutProgressDate" to prefs.getString(
                PingShengWidgetProvider.KEY_WORKOUT_PROGRESS_DATE,
                null
            )
        )
    }

    private fun saveLifeSummary(arguments: Any?) {
        val args = arguments as? Map<*, *> ?: return
        val foodCalories = (args["foodCalories"] as? Number)?.toInt() ?: 0
        val foodLogsJson = args["foodLogsJson"] as? String ?: "[]"
        val pendingTodos = (args["pendingTodos"] as? Number)?.toInt() ?: 0
        val todosJson = args["todosJson"] as? String ?: ""
        val financeRecordsJson = args["financeRecordsJson"] as? String ?: ""
        val workoutGroups = (args["workoutGroups"] as? Number)?.toInt() ?: 0
        val workoutGroupsJson = args["workoutGroupsJson"] as? String ?: "{}"
        val workoutProgressDate = args["workoutProgressDate"] as? String ?: ""
        val summaryDate = LocalDate.now().toString()

        // Flutter 侧的共享状态写入原生 SharedPreferences，桌面小组件可直接读取。
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putInt(PingShengWidgetProvider.KEY_FOOD_CALORIES, foodCalories)
            .putString(PingShengWidgetProvider.KEY_FOOD_SUMMARY_DATE, summaryDate)
            .putString(PingShengWidgetProvider.KEY_FOOD_LOGS_JSON, foodLogsJson)
            .putInt(PingShengWidgetProvider.KEY_PENDING_TODOS, pendingTodos)
            .putString(PingShengWidgetProvider.KEY_TODOS_JSON, todosJson)
            .putString(PingShengWidgetProvider.KEY_FINANCE_RECORDS_JSON, financeRecordsJson)
            .putInt(PingShengWidgetProvider.KEY_WORKOUT_GROUPS, workoutGroups)
            .putString(PingShengWidgetProvider.KEY_WORKOUT_GROUPS_JSON, workoutGroupsJson)
            .putString(PingShengWidgetProvider.KEY_WORKOUT_PROGRESS_DATE, workoutProgressDate)
            .apply()

        refreshHomeWidgets()
    }

    private fun loadHealthSnapshot(result: MethodChannel.Result) {
        mainScope.launch {
            try {
                val snapshot = withContext(Dispatchers.IO) { readHealthSnapshot() }
                result.success(snapshot)
            } catch (error: Exception) {
                result.success(
                    mapOf(
                        "status" to "error",
                        "message" to (error.message ?: "系统健康数据读取失败"),
                        "lastUpdated" to Instant.now().toString(),
                        "days" to emptyList<Map<String, Any?>>(),
                        "sensors" to buildSensorSnapshot()
                    )
                )
            }
        }
    }

    private suspend fun readHealthSnapshot(): Map<String, Any?> {
        // 先判断 Health Connect 是否可用，再检查授权，避免无意义地请求数据。
        val sdkStatus = HealthConnectClient.getSdkStatus(
            this,
            HEALTH_CONNECT_PROVIDER_PACKAGE
        )
        if (sdkStatus == HealthConnectClient.SDK_UNAVAILABLE) {
            return healthStatusMap("unavailable", "当前设备没有可用的 Health Connect。")
        }
        if (sdkStatus == HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED) {
            return healthStatusMap("updateRequired", "需要安装或更新 Health Connect 后才能读取系统健康数据。")
        }

        val client = HealthConnectClient.getOrCreate(this)
        val granted = client.permissionController.getGrantedPermissions()
        val readablePermissions = HealthPermissionPolicy.readablePermissions(
            HEALTH_PERMISSIONS,
            granted
        )
        if (readablePermissions.isEmpty()) {
            return healthStatusMap("permissionRequired", "请授权 Health Connect 读取步数、能量、睡眠或心率数据。")
        }

        val today = LocalDate.now()
        // 读取最近 7 天数据，Flutter 侧趋势卡片直接消费这个列表。
        val days = (6 downTo 0).map { offset ->
            readHealthDay(client, today.minusDays(offset.toLong()), readablePermissions)
        }
        val todayMap = days.lastOrNull()
        saveHealthForWidget(todayMap)

        return mapOf(
            "status" to "ok",
            "message" to if (readablePermissions == HEALTH_PERMISSIONS) {
                "已连接 Health Connect 和本机传感器。"
            } else {
                "已连接 Health Connect，正在展示已授权数据。"
            },
            "lastUpdated" to Instant.now().toString(),
            "days" to days,
            "sensors" to buildSensorSnapshot(
                hasHealthConnectTodaySteps = todayMap?.get("steps") != null
            )
        )
    }

    private fun healthStatusMap(status: String, message: String): Map<String, Any?> {
        saveHealthStatusForWidget(message)
        return mapOf(
            "status" to status,
            "message" to message,
            "lastUpdated" to Instant.now().toString(),
            "days" to emptyList<Map<String, Any?>>(),
            "sensors" to buildSensorSnapshot()
        )
    }

    private suspend fun readHealthDay(
        client: HealthConnectClient,
        date: LocalDate,
        grantedPermissions: Set<String>
    ): Map<String, Any?> {
        // Health Connect 聚合接口按日期范围返回总步数、能量、均值心率等指标。
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = if (date == LocalDate.now()) {
            Instant.now()
        } else {
            date.plusDays(1).atStartOfDay(zone).toInstant()
        }
        val metrics = mutableSetOf<AggregateMetric<*>>()
        if (STEP_PERMISSION in grantedPermissions) {
            metrics.add(StepsRecord.COUNT_TOTAL)
        }
        if (ACTIVE_CALORIES_PERMISSION in grantedPermissions) {
            metrics.add(ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL)
        }
        if (BASAL_CALORIES_PERMISSION in grantedPermissions) {
            metrics.add(BasalMetabolicRateRecord.BASAL_CALORIES_TOTAL)
        }
        if (HEART_RATE_PERMISSION in grantedPermissions) {
            metrics.add(HeartRateRecord.BPM_AVG)
        }
        if (SLEEP_PERMISSION in grantedPermissions) {
            metrics.add(SleepSessionRecord.SLEEP_DURATION_TOTAL)
        }
        val aggregate = client.aggregate(
            AggregateRequest(
                metrics = metrics,
                timeRangeFilter = TimeRangeFilter.between(start, end)
            )
        )

        return mapOf(
            "dateIso" to date.toString(),
            "steps" to aggregate[StepsRecord.COUNT_TOTAL],
            "activeCaloriesKcal" to aggregate[ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL]?.inKilocalories,
            "basalCaloriesKcal" to aggregate[BasalMetabolicRateRecord.BASAL_CALORIES_TOTAL]?.inKilocalories,
            "heartRateBpm" to aggregate[HeartRateRecord.BPM_AVG]?.toInt(),
            "respiratoryRate" to null,
            "sleepMinutes" to aggregate[SleepSessionRecord.SLEEP_DURATION_TOTAL]?.toMinutes()
        )
    }

    private fun requestHealthPermissions(result: MethodChannel.Result) {
        if (pendingHealthPermissionResult != null) {
            result.error("permission_pending", "健康权限请求正在进行中", null)
            return
        }
        val sdkStatus = HealthConnectClient.getSdkStatus(
            this,
            HEALTH_CONNECT_PROVIDER_PACKAGE
        )
        if (sdkStatus != HealthConnectClient.SDK_AVAILABLE) {
            result.success(mapOf("granted" to false, "grantedCount" to 0))
            openHealthConnectSettings()
            return
        }

        requestSensorRuntimePermissions()
        pendingHealthPermissionResult = result
        healthPermissionLauncher?.launch(HEALTH_PERMISSIONS)
            ?: run {
                pendingHealthPermissionResult = null
                result.error("launcher_missing", "健康权限请求器初始化失败", null)
            }
    }

    private fun requestSensorRuntimePermissions() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return
        }
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.ACTIVITY_RECOGNITION)
        }
        if (checkSelfPermission(Manifest.permission.BODY_SENSORS) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.BODY_SENSORS)
        }
        if (permissions.isNotEmpty()) {
            requestPermissions(permissions.toTypedArray(), SENSOR_PERMISSION_REQUEST)
        }
    }

    private fun openHealthConnectSettings() {
        val intent = Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS).apply {
            setPackage(HEALTH_CONNECT_PROVIDER_PACKAGE)
        }
        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName")
                )
            )
        }
    }

    private fun openDownloadUrl(url: String?, result: MethodChannel.Result) {
        val target = url?.trim().orEmpty()
        if (target.isEmpty()) {
            result.error("missing_url", "下载地址为空", null)
            return
        }
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(target)).apply {
                addCategory(Intent.CATEGORY_BROWSABLE)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(null)
        } catch (_: ActivityNotFoundException) {
            Toast.makeText(this, "没有可用的浏览器", Toast.LENGTH_SHORT).show()
            result.error("browser_missing", "没有可用的浏览器", null)
        }
    }

    private fun setDailyRecordReminder(enabled: Boolean, result: MethodChannel.Result) {
        if (!enabled) {
            DailyRecordReminderReceiver.setReminderEnabled(this, false)
            result.success(mapOf("enabled" to false, "permissionGranted" to true))
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingReminderResult != null) {
                result.error("reminder_request_busy", "已有通知权限请求正在进行", null)
                return
            }
            pendingReminderResult = result
            notificationPermissionLauncher?.launch(Manifest.permission.POST_NOTIFICATIONS)
                ?: finishDailyRecordReminderRequest(false)
            return
        }
        DailyRecordReminderReceiver.setReminderEnabled(this, true)
        result.success(mapOf("enabled" to true, "permissionGranted" to true))
    }

    private fun finishDailyRecordReminderRequest(granted: Boolean) {
        val result = pendingReminderResult ?: return
        pendingReminderResult = null
        if (granted) {
            DailyRecordReminderReceiver.setReminderEnabled(this, true)
            result.success(mapOf("enabled" to true, "permissionGranted" to true))
        } else {
            DailyRecordReminderReceiver.setReminderEnabled(this, false)
            result.success(mapOf("enabled" to false, "permissionGranted" to false))
        }
    }

    private fun loadAuthSession(): String? {
        // 新版本优先读取加密存储；旧明文缓存只作为迁移兜底。
        val secureValue = try {
            secureAuthPrefs().getString(KEY_AUTH_SESSION_JSON, null)
        } catch (_: Exception) {
            null
        }
        if (!secureValue.isNullOrEmpty()) {
            return secureValue
        }

        val legacyPrefs = getSharedPreferences(AUTH_PREFS_NAME, MODE_PRIVATE)
        val legacyValue = legacyPrefs.getString(KEY_AUTH_SESSION_JSON, null)
        if (!legacyValue.isNullOrEmpty()) {
            try {
                saveAuthSession(legacyValue)
                legacyPrefs.edit().remove(KEY_AUTH_SESSION_JSON).apply()
            } catch (_: Exception) {
                return legacyValue
            }
        }
        return legacyValue
    }

    private fun saveAuthSession(sessionJson: String) {
        secureAuthPrefs()
            .edit()
            .putString(KEY_AUTH_SESSION_JSON, sessionJson)
            .apply()
        getSharedPreferences(AUTH_PREFS_NAME, MODE_PRIVATE)
            .edit()
            .remove(KEY_AUTH_SESSION_JSON)
            .apply()
    }

    private fun clearAuthSession() {
        try {
            secureAuthPrefs().edit().remove(KEY_AUTH_SESSION_JSON).apply()
        } catch (_: Exception) {
            // 安全存储不可用时仍清理旧明文缓存。
        }
        getSharedPreferences(AUTH_PREFS_NAME, MODE_PRIVATE)
            .edit()
            .remove(KEY_AUTH_SESSION_JSON)
            .apply()
    }

    private fun secureAuthPrefs(): SharedPreferences {
        val masterKey = MasterKey.Builder(this)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        return EncryptedSharedPreferences.create(
            this,
            AUTH_SECURE_PREFS_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    private fun startSensorListeners() {
        // 本机传感器只补充“实时能力/最近读数”，核心健康历史仍来自 Health Connect。
        val manager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager ?: return
        sensorManager = manager
        registerSensorIfAllowed(manager, Sensor.TYPE_STEP_COUNTER)
        registerSensorIfAllowed(manager, Sensor.TYPE_HEART_RATE)
        registerSensorIfAllowed(manager, Sensor.TYPE_ACCELEROMETER)
    }

    private fun registerSensorIfAllowed(manager: SensorManager, type: Int) {
        val sensor = manager.getDefaultSensor(type) ?: return
        try {
            manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL)
        } catch (_: SecurityException) {
            // 传感器权限没给时不伪造数据，Flutter 侧会显示未授权/无实时读数。
        }
    }

    private fun buildSensorSnapshot(
        hasHealthConnectTodaySteps: Boolean = false
    ): Map<String, Any?> {
        val manager = sensorManager ?: getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        return mapOf(
            "stepCounterAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null),
            "heartRateSensorAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_HEART_RATE) != null),
            "accelerometerAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null),
            "stepCounterToday" to todayStepCounter(
                latestStepCounter?.roundToInt(),
                hasHealthConnectTodaySteps
            ),
            "heartRateBpm" to latestHeartRate,
            "accelerationMagnitude" to latestAcceleration,
            "lastSensorUpdateMillis" to lastSensorUpdateMillis
        )
    }

    private fun todayStepCounter(
        currentSinceBoot: Int?,
        hasHealthConnectTodaySteps: Boolean
    ): Int? {
        val today = LocalDate.now()
        val todayKey = today.toString()
        val prefs = getSharedPreferences(STEP_COUNTER_BASELINE_PREFS, MODE_PRIVATE)
        val storedDate = prefs.getString(KEY_STEP_COUNTER_BASELINE_DATE, null)
        val storedBaseline = prefs.getInt(KEY_STEP_COUNTER_BASELINE_VALUE, -1)
        val decision = StepCounterPolicy.resolve(
            currentSinceBoot = currentSinceBoot,
            storedDate = storedDate,
            storedBaseline = storedBaseline,
            today = today,
            hasHealthConnectTodaySteps = hasHealthConnectTodaySteps
        )
        decision.baselineToStore?.let { baseline ->
            prefs.edit()
                .putString(KEY_STEP_COUNTER_BASELINE_DATE, todayKey)
                .putInt(KEY_STEP_COUNTER_BASELINE_VALUE, baseline)
                .apply()
        }
        return decision.todaySteps
    }

    private fun saveHealthForWidget(today: Map<String, Any?>?) {
        // 小组件空间有限，只同步一行最有代表性的状态摘要。
        val steps = (today?.get("steps") as? Number)?.toInt()
        val activeCalories = (today?.get("activeCaloriesKcal") as? Number)?.toInt()
        val summaryDate = today?.get("dateIso") as? String ?: LocalDate.now().toString()
        val text = WidgetSummaryPolicy.healthStorageText(steps, activeCalories)
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString(PingShengWidgetProvider.KEY_HEALTH_TEXT, text)
            .putString(PingShengWidgetProvider.KEY_HEALTH_SUMMARY_DATE, summaryDate)
            .apply()
        refreshHomeWidgets()
    }

    private fun saveHealthStatusForWidget(message: String) {
        val text = when {
            message.contains("授权") -> "状态待授权"
            message.contains("更新") -> "状态需更新"
            else -> "状态待连接"
        }
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString(PingShengWidgetProvider.KEY_HEALTH_TEXT, text)
            .putString(
                PingShengWidgetProvider.KEY_HEALTH_SUMMARY_DATE,
                LocalDate.now().toString()
            )
            .apply()
        refreshHomeWidgets()
    }

    private fun refreshHomeWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val darkIds = manager.getAppWidgetIds(
            ComponentName(this, PingShengWidgetProvider::class.java)
        )
        val lightIds = manager.getAppWidgetIds(
            ComponentName(this, PingShengLightWidgetProvider::class.java)
        )
        PingShengWidgetProvider.updateWidgets(this, manager, darkIds)
        PingShengLightWidgetProvider.updateWidgets(this, manager, lightIds)
    }

    companion object {
        const val EXTRA_TARGET_ROUTE = "target_route"
        const val EXTRA_WIDGET_ACTION = "widget_action"
        private const val WIDGET_CHANNEL = "pingsheng_life/widget_summary"
        private const val HEALTH_CHANNEL = "pingsheng_life/system_health"
        private const val HEALTH_MANUAL_CHANNEL = "pingsheng_life/health_manual"
        private const val AUTH_CHANNEL = "pingsheng_life/auth_session"
        private const val UPDATE_LAUNCHER_CHANNEL = "pingsheng_life/update_launcher"
        private const val APP_PREFERENCES_CHANNEL = "pingsheng_life/app_preferences"
        private const val AUTH_PREFS_NAME = "pingsheng_auth"
        private const val AUTH_SECURE_PREFS_NAME = "pingsheng_auth_secure"
        private const val STEP_COUNTER_BASELINE_PREFS = "pingsheng_step_counter_baseline"
        private const val HEALTH_MANUAL_PREFS_NAME = "pingsheng_health_manual"
        private const val KEY_AUTH_SESSION_JSON = "auth_session_json"
        private const val KEY_HEALTH_MANUAL_RECORDS_JSON = "manual_records_json"
        private const val KEY_STEP_COUNTER_BASELINE_DATE = "date"
        private const val KEY_STEP_COUNTER_BASELINE_VALUE = "value"
        private const val SENSOR_PERMISSION_REQUEST = 42
        private const val HEALTH_CONNECT_PROVIDER_PACKAGE = "com.google.android.apps.healthdata"

        private val STEP_PERMISSION = HealthPermission.getReadPermission(StepsRecord::class)
        private val ACTIVE_CALORIES_PERMISSION =
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class)
        private val BASAL_CALORIES_PERMISSION =
            HealthPermission.getReadPermission(BasalMetabolicRateRecord::class)
        private val HEART_RATE_PERMISSION =
            HealthPermission.getReadPermission(HeartRateRecord::class)
        private val SLEEP_PERMISSION =
            HealthPermission.getReadPermission(SleepSessionRecord::class)

        private val HEALTH_PERMISSIONS = setOf(
            STEP_PERMISSION,
            ACTIVE_CALORIES_PERMISSION,
            BASAL_CALORIES_PERMISSION,
            HEART_RATE_PERMISSION,
            SLEEP_PERMISSION
        )
    }
}
