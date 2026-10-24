// 中文注释：Android 原生数据策略，负责小组件文案、计步基线和健康权限判定。

package com.pingsheng.pingsheng_life

import java.time.LocalDate

/** 小组件摘要文案策略：日期不是今天时显示“待记录”，避免把旧数据当今日数据。 */
internal object WidgetSummaryPolicy {
    /** 生成饮食摘要文案，只有日期为今天且有热量时才显示数值。 */
    fun foodText(calories: Int, summaryDate: String?, today: LocalDate): String {
        return if (isCurrent(summaryDate, today) && calories > 0) {
            "饮食\n${calories} kcal"
        } else {
            "饮食\n待记录"
        }
    }

    /** 生成锻炼摘要文案，只有日期为今天且完成组数大于 0 时才显示数值。 */
    fun workoutText(groups: Int, summaryDate: String?, today: LocalDate): String {
        return if (isCurrent(summaryDate, today) && groups > 0) {
            "锻炼\n${groups}组"
        } else {
            "锻炼\n待记录"
        }
    }

    /** 生成今日消耗文案，并从健康文本中解析 kcal 数值。 */
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

    /** 生成健康数据存储摘要，优先展示消耗能量，其次展示步数。 */
    fun healthStorageText(steps: Int?, activeCalories: Int?): String {
        return when {
            activeCalories != null -> "能量 ${activeCalories} kcal"
            steps != null -> "步数 ${"%,d".format(steps)}"
            else -> "状态无系统记录"
        }
    }

    /** 用正则提取健康文本中的千卡数字。 */
    private fun activeCalories(healthText: String): Int? {
        val match = Regex("""(\d+)\s*kcal""").find(healthText)
        return match?.groupValues?.getOrNull(1)?.toIntOrNull()
    }

    /** 判断摘要日期是否对应当天。 */
    private fun isCurrent(summaryDate: String?, today: LocalDate): Boolean {
        return summaryDate == today.toString()
    }
}

/** 计步决策结果：今日步数，以及需要保存的新基线。 */
internal data class StepCounterDecision(
    val todaySteps: Int?,
    val baselineToStore: Int?
)

/** 计步策略：用开机累计步数减去当天基线，避免把历史步数算进今天。 */
internal object StepCounterPolicy {
    /** 在 Health Connect 无数据时，根据存储基线计算今日步数或初始化基线。 */
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

/** 健康权限策略：始终只使用系统支持且用户已授权的权限交集。 */
internal object HealthPermissionPolicy {
    /** 返回支持且已授权的权限集合。 */
    fun readablePermissions(supported: Set<String>, granted: Set<String>): Set<String> {
        return supported.intersect(granted)
    }

    /** 判断是否至少有一项健康数据权限可读。 */
    fun canReadAny(supported: Set<String>, granted: Set<String>): Boolean {
        return readablePermissions(supported, granted).isNotEmpty()
    }
}
