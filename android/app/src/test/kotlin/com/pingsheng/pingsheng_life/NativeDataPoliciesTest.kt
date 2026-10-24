// 中文注释：Android 原生数据策略测试，验证小组件日期、计步基线和权限交集。

package com.pingsheng.pingsheng_life

import java.time.LocalDate
import org.junit.Assert.assertEquals as junitAssertEquals
import org.junit.Assert.assertTrue as junitAssertTrue
import org.junit.Test

/** 覆盖小组件摘要、计步基线和 Health Connect 部分授权三类策略。 */
class NativeDataPoliciesTest {
    /** 日期过期时显示待记录，跨天时重建基线，部分授权时只返回已授权项。 */
    @Test
    fun widgetDatesStepBaselinesAndPartialPermissionsUseRealData() {
        val today = LocalDate.of(2026, 7, 10)

        assertEquals(
            "饮食\n待记录",
            WidgetSummaryPolicy.foodText(860, "2026-07-09", today),
            "stale food summary"
        )
        assertEquals(
            "饮食\n860 kcal",
            WidgetSummaryPolicy.foodText(860, "2026-07-10", today),
            "current food summary"
        )
        assertEquals(
            "锻炼\n待记录",
            WidgetSummaryPolicy.workoutText(7, "2026-07-09", today),
            "stale workout summary"
        )
        assertEquals(
            "锻炼\n7组",
            WidgetSummaryPolicy.workoutText(7, "2026-07-10", today),
            "workout uses real groups without a fixed target"
        )
        assertEquals(
            "今日消耗\n0 kcal",
            WidgetSummaryPolicy.healthCardText("能量 320 kcal", "2026-07-09", today),
            "stale health summary"
        )
        assertEquals(
            "今日消耗\n320 kcal",
            WidgetSummaryPolicy.healthCardText("能量 320 kcal", "2026-07-10", today),
            "current health summary"
        )
        assertEquals(
            "今日消耗\n0 kcal",
            WidgetSummaryPolicy.healthCardText("能量 0 kcal", "2026-07-10", today),
            "current zero health summary"
        )
        assertEquals(
            "能量 320 kcal",
            WidgetSummaryPolicy.healthStorageText(steps = 8_200, activeCalories = 320),
            "widget health storage follows the displayed energy metric"
        )

        assertEquals(
            StepCounterDecision(todaySteps = null, baselineToStore = 12_000),
            StepCounterPolicy.resolve(
                currentSinceBoot = 12_000,
                storedDate = null,
                storedBaseline = -1,
                today = today,
                hasHealthConnectTodaySteps = false
            ),
            "first daily sensor reading is incomplete"
        )
        assertEquals(
            StepCounterDecision(todaySteps = 450, baselineToStore = null),
            StepCounterPolicy.resolve(
                currentSinceBoot = 12_450,
                storedDate = "2026-07-10",
                storedBaseline = 12_000,
                today = today,
                hasHealthConnectTodaySteps = false
            ),
            "established daily baseline"
        )
        assertEquals(
            StepCounterDecision(todaySteps = null, baselineToStore = null),
            StepCounterPolicy.resolve(
                currentSinceBoot = 12_450,
                storedDate = "2026-07-10",
                storedBaseline = 12_000,
                today = today,
                hasHealthConnectTodaySteps = true
            ),
            "Health Connect today steps take priority"
        )

        val supported = setOf("steps", "sleep", "heart")
        assertEquals(
            setOf("steps", "sleep"),
            HealthPermissionPolicy.readablePermissions(
                supported = supported,
                granted = setOf("steps", "sleep")
            ),
            "partial Health Connect authorization"
        )
        assertTrue(
            HealthPermissionPolicy.canReadAny(
                supported = supported,
                granted = setOf("steps", "sleep")
            ),
            "denied unsupported respiratory permission must not block reads"
        )
    }

    /** 包装 JUnit 断言，用中文失败说明标记具体场景。 */
    private fun assertTrue(actual: Boolean, name: String) {
        junitAssertTrue(name, actual)
    }

    /** 包装 JUnit 相等断言，统一参数顺序。 */
    private fun assertEquals(expected: Any?, actual: Any?, name: String) {
        junitAssertEquals(name, expected, actual)
    }
}
