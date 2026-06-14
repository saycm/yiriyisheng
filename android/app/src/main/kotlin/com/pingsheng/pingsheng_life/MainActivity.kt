package com.pingsheng.pingsheng_life

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
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
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.BasalMetabolicRateRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.RespiratoryRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.AggregateRequest
import androidx.health.connect.client.time.TimeRangeFilter
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
    private var pendingHealthPermissionResult: MethodChannel.Result? = null
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
                        "granted" to HEALTH_PERMISSIONS.all { permission ->
                            grantedPermissions.contains(permission)
                        },
                        "grantedCount" to grantedPermissions.size
                    )
                )
                pendingHealthPermissionResult = null
            }
        super.onCreate(savedInstanceState)
    }

    override fun getInitialRoute(): String? {
        // 桌面小组件点击不同摘要时，会通过这里把用户带到对应 Flutter 模块。
        return intent?.getStringExtra(EXTRA_TARGET_ROUTE) ?: super.getInitialRoute()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTH_CHANNEL)
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(AUTH_PREFS_NAME, MODE_PRIVATE)
                when (call.method) {
                    "loadAuthSession" -> result.success(
                        prefs.getString(KEY_AUTH_SESSION_JSON, null)
                    )
                    "saveAuthSession" -> {
                        prefs.edit()
                            .putString(KEY_AUTH_SESSION_JSON, call.arguments as? String ?: "")
                            .apply()
                        result.success(null)
                    }
                    "clearAuthSession" -> {
                        prefs.edit().remove(KEY_AUTH_SESSION_JSON).apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_LAUNCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openDownloadUrl" -> openDownloadUrl(call.argument<String>("url"), result)
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
            "pendingTodos" to prefs.getInt(PingShengWidgetProvider.KEY_PENDING_TODOS, 4),
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
            ).orEmpty()
        )
    }

    private fun saveLifeSummary(arguments: Any?) {
        val args = arguments as? Map<*, *> ?: return
        val foodCalories = (args["foodCalories"] as? Number)?.toInt() ?: 0
        val pendingTodos = (args["pendingTodos"] as? Number)?.toInt() ?: 4
        val todosJson = args["todosJson"] as? String ?: ""
        val financeRecordsJson = args["financeRecordsJson"] as? String ?: ""
        val workoutGroups = (args["workoutGroups"] as? Number)?.toInt() ?: 0
        val workoutGroupsJson = args["workoutGroupsJson"] as? String ?: "{}"

        // Flutter 侧的共享状态写入原生 SharedPreferences，桌面小组件可直接读取。
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putInt(PingShengWidgetProvider.KEY_FOOD_CALORIES, foodCalories)
            .putInt(PingShengWidgetProvider.KEY_PENDING_TODOS, pendingTodos)
            .putString(PingShengWidgetProvider.KEY_TODOS_JSON, todosJson)
            .putString(PingShengWidgetProvider.KEY_FINANCE_RECORDS_JSON, financeRecordsJson)
            .putInt(PingShengWidgetProvider.KEY_WORKOUT_GROUPS, workoutGroups)
            .putString(PingShengWidgetProvider.KEY_WORKOUT_GROUPS_JSON, workoutGroupsJson)
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
        if (!granted.containsAll(HEALTH_PERMISSIONS)) {
            return healthStatusMap("permissionRequired", "请授权 Health Connect 读取步数、能量、睡眠、心率和呼吸数据。")
        }

        val today = LocalDate.now()
        val days = (6 downTo 0).map { offset ->
            readHealthDay(client, today.minusDays(offset.toLong()))
        }
        val todayMap = days.lastOrNull()
        saveHealthForWidget(todayMap)

        return mapOf(
            "status" to "ok",
            "message" to "已连接 Health Connect 和本机传感器。",
            "lastUpdated" to Instant.now().toString(),
            "days" to days,
            "sensors" to buildSensorSnapshot()
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
        date: LocalDate
    ): Map<String, Any?> {
        val zone = ZoneId.systemDefault()
        val start = date.atStartOfDay(zone).toInstant()
        val end = if (date == LocalDate.now()) {
            Instant.now()
        } else {
            date.plusDays(1).atStartOfDay(zone).toInstant()
        }
        val aggregate = client.aggregate(
            AggregateRequest(
                metrics = setOf(
                    StepsRecord.COUNT_TOTAL,
                    ActiveCaloriesBurnedRecord.ACTIVE_CALORIES_TOTAL,
                    BasalMetabolicRateRecord.BASAL_CALORIES_TOTAL,
                    HeartRateRecord.BPM_AVG,
                    SleepSessionRecord.SLEEP_DURATION_TOTAL
                ),
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

    private fun startSensorListeners() {
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

    private fun buildSensorSnapshot(): Map<String, Any?> {
        val manager = sensorManager ?: getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        return mapOf(
            "stepCounterAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null),
            "heartRateSensorAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_HEART_RATE) != null),
            "accelerometerAvailable" to (manager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null),
            "stepCounterSinceBoot" to latestStepCounter?.roundToInt(),
            "heartRateBpm" to latestHeartRate,
            "accelerationMagnitude" to latestAcceleration,
            "lastSensorUpdateMillis" to lastSensorUpdateMillis
        )
    }

    private fun saveHealthForWidget(today: Map<String, Any?>?) {
        val steps = (today?.get("steps") as? Number)?.toInt()
        val activeCalories = (today?.get("activeCaloriesKcal") as? Number)?.toInt()
        val text = when {
            steps != null -> "步数 ${formatNumber(steps)}"
            activeCalories != null -> "能量 ${activeCalories} kcal"
            else -> "健康无系统记录"
        }
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString(PingShengWidgetProvider.KEY_HEALTH_TEXT, text)
            .apply()
        refreshHomeWidgets()
    }

    private fun saveHealthStatusForWidget(message: String) {
        val text = when {
            message.contains("授权") -> "健康待授权"
            message.contains("更新") -> "健康需更新"
            else -> "健康待连接"
        }
        getSharedPreferences(PingShengWidgetProvider.PREFS_NAME, MODE_PRIVATE)
            .edit()
            .putString(PingShengWidgetProvider.KEY_HEALTH_TEXT, text)
            .apply()
        refreshHomeWidgets()
    }

    private fun formatNumber(value: Int): String {
        return "%,d".format(value)
    }

    private fun refreshHomeWidgets() {
        val manager = AppWidgetManager.getInstance(this)
        val ids = manager.getAppWidgetIds(
            ComponentName(this, PingShengWidgetProvider::class.java)
        )
        PingShengWidgetProvider.updateWidgets(this, manager, ids)
    }

    companion object {
        const val EXTRA_TARGET_ROUTE = "target_route"
        const val EXTRA_WIDGET_ACTION = "widget_action"
        private const val WIDGET_CHANNEL = "pingsheng_life/widget_summary"
        private const val HEALTH_CHANNEL = "pingsheng_life/system_health"
        private const val AUTH_CHANNEL = "pingsheng_life/auth_session"
        private const val UPDATE_LAUNCHER_CHANNEL = "pingsheng_life/update_launcher"
        private const val AUTH_PREFS_NAME = "pingsheng_auth"
        private const val KEY_AUTH_SESSION_JSON = "auth_session_json"
        private const val SENSOR_PERMISSION_REQUEST = 42
        private const val HEALTH_CONNECT_PROVIDER_PACKAGE = "com.google.android.apps.healthdata"

        private val HEALTH_PERMISSIONS = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
            HealthPermission.getReadPermission(BasalMetabolicRateRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(RespiratoryRateRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class)
        )
    }
}
