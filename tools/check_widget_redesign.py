#!/usr/bin/env python3
# 中文注释：小组件结构检查脚本，确保布局和原生 Provider 保持新版交互约束。

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
LAYOUT = ROOT / "android/app/src/main/res/layout/pingsheng_widget.xml"


def main() -> int:
    # 这个检查不跑 Android 构建，只用静态 token 防止关键控件或动作被误删。
    xml = LAYOUT.read_text(encoding="utf-8")
    ET.fromstring(xml)
    required_tokens = [
        "widget_status_pill",
        "widget_primary_metric_value",
        "widget_primary_metric_label",
        "widget_active_calories",
        "widget_finance_status",
        "今日消耗",
        "计划&#10;加待办",
        "饮食&#10;记录",
        "记账&#10;快捷支出",
    ]
    missing = [token for token in required_tokens if token not in xml]
    if missing:
        print("Missing widget redesign tokens: " + ", ".join(missing))
        return 1
    root = ET.fromstring(xml)
    android_id = "{http://schemas.android.com/apk/res/android}id"
    orientation = "{http://schemas.android.com/apk/res/android}orientation"
    auto_size = "{http://schemas.android.com/apk/res/android}autoSizeTextType"
    parent_by_child = {child: parent for parent in root.iter() for child in parent}
    finance = next(
        (
            node
            for node in root.iter()
            if node.attrib.get(android_id) == "@+id/widget_finance"
        ),
        None,
    )
    if finance is None:
        print("Missing widget finance value view.")
        return 1
    finance_parent = parent_by_child.get(finance)
    if finance_parent is None or finance_parent.attrib.get(orientation) != "vertical":
        print("Widget finance value must sit in a vertical label/value column.")
        return 1
    if finance.attrib.get(auto_size) != "uniform":
        print("Widget finance value must use uniform auto size to avoid clipping.")
        return 1
    provider = (
        ROOT
        / "android/app/src/main/kotlin/com/pingsheng/pingsheng_life/PingShengWidgetProvider.kt"
    ).read_text(encoding="utf-8")
    required_provider_tokens = [
        "ACTION_REFRESH",
        "R.id.widget_plan",
        "moduleIntent(context, \"/plan\", 2, \"add_todo\")",
        "R.id.widget_summary_card",
        "moduleIntent(context, \"/finance\", 3, \"add_finance\")",
        "moduleIntent(context, \"/finance\", 9, \"add_finance\")",
        "moduleIntent(context, \"/food\", 8, \"add_food\")",
        "R.id.widget_active_calories",
        "ACTION_QUICK_WORKOUT",
    ]
    missing_provider = []
    for token in required_provider_tokens:
        if token == "ACTION_QUICK_WORKOUT":
            # 旧版本会在小组件内静默加锻炼组数，新版要求进入真实记录流程。
            if token in provider:
                missing_provider.append("removed " + token)
        elif token not in provider:
            missing_provider.append(token)
    if missing_provider:
        print("Missing widget provider tokens: " + ", ".join(missing_provider))
        return 1
    forbidden_provider_tokens = [
        "ACTION_QUICK_TODO",
        "QUICK_FINANCE_AMOUNT",
        "quickTodoIntent(context, \"桌面待办\", \"生活\", 2)",
        "quickIntent(context, ACTION_QUICK_FINANCE, 3)",
        "quickIntent(context, ACTION_QUICK_FINANCE, 9)",
        "ACTION_QUICK_FOOD",
        "addQuickFood(",
        "addQuickWorkout(",
        "addQuickTodo(",
        "addQuickFinance(",
    ]
    forbidden = [token for token in forbidden_provider_tokens if token in provider]
    if forbidden:
        print("Forbidden silent widget actions: " + ", ".join(forbidden))
        return 1
    print("Widget redesign structure check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
