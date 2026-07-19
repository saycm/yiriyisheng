package com.pingsheng.pingsheng_life

import java.time.LocalDate

internal object WidgetSummaryPolicy {
    fun foodText(calories: Int, summaryDate: String?, today: LocalDate): String {
        return if (isCurrent(summaryDate, today) && calories > 0) {
            "饮食\n${calories} kcal"
        } else {
            "饮食\n待记录"
        }
    }

    fun workoutText(groups: Int, summaryDate: String?, today: LocalDate): String {
        return if (isCurrent(summaryDate, today) && groups > 0) {
            "锻炼\n${groups}组"
        } else {
            "锻炼\n待记录"
        }
    }

    fun healthCardText(healthText: String, summaryDate: String?, today: LocalDate): String {
        if (!isCurrent(summaryDate, today)) {
            return "今日消耗\n0 kcal"
        }
        val calories = activeCalories(healthText)
        return if (calories != null) {
            "今日消耗\n${calories} kcal"
        } else {
            "今日消耗\n待同步"
        }
    }

    fun healthStorageText(steps: Int?, activeCalories: Int?): String {
        return when {
            activeCalories != null -> "能量 ${activeCalories} kcal"
            steps != null -> "步数 ${"%,d".format(steps)}"
            else -> "状态无系统记录"
        }
    }

    private fun activeCalories(healthText: String): Int? {
        val match = Regex("""(\d+)\s*kcal""").find(healthText)
        return match?.groupValues?.getOrNull(1)?.toIntOrNull()
    }

    private fun isCurrent(summaryDate: String?, today: LocalDate): Boolean {
        return summaryDate == today.toString()
    }
}

internal data class StepCounterDecision(
    val todaySteps: Int?,
    val baselineToStore: Int?
)

internal object StepCounterPolicy {
    fun resolve(
        currentSinceBoot: Int?,
        storedDate: String?,
        storedBaseline: Int,
        today: LocalDate,
        hasHealthConnectTodaySteps: Boolean
    ): StepCounterDecision {
        if (currentSinceBoot == null || hasHealthConnectTodaySteps) {
            return StepCounterDecision(todaySteps = null, baselineToStore = null)
        }
        if (storedDate == today.toString() &&
            storedBaseline >= 0 &&
            storedBaseline <= currentSinceBoot
        ) {
            return StepCounterDecision(
                todaySteps = currentSinceBoot - storedBaseline,
                baselineToStore = null
            )
        }
        return StepCounterDecision(todaySteps = null, baselineToStore = currentSinceBoot)
    }
}

internal object HealthPermissionPolicy {
    fun readablePermissions(supported: Set<String>, granted: Set<String>): Set<String> {
        return supported.intersect(granted)
    }

    fun canReadAny(supported: Set<String>, granted: Set<String>): Boolean {
        return readablePermissions(supported, granted).isNotEmpty()
    }
}
