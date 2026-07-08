#!/usr/bin/env python3
# 中文注释：小组件结构检查脚本，确保双主题布局和原生 Provider 保持新版交互约束。

from pathlib import Path
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
LAYOUTS = [
    ROOT / "android/app/src/main/res/layout/pingsheng_widget_dark.xml",
    ROOT / "android/app/src/main/res/layout/pingsheng_widget_light.xml",
]
WIDGET_INFOS = [
    ROOT / "android/app/src/main/res/xml/pingsheng_widget_dark_info.xml",
    ROOT / "android/app/src/main/res/xml/pingsheng_widget_light_info.xml",
]
TODAY_MARK = ROOT / "android/app/src/main/res/drawable/pingsheng_widget_today_mark.xml"


def main() -> int:
    # 这个检查不跑 Android 构建，只用静态 token 防止关键控件或动作被误删。
    missing_files = [str(path.relative_to(ROOT)) for path in [*LAYOUTS, *WIDGET_INFOS, TODAY_MARK] if not path.exists()]
    if missing_files:
        print("Missing widget theme files: " + ", ".join(missing_files))
        return 1

    required_tokens = [
        "widget_left_summary",
        "widget_right_grid",
        "widget_summary_pair_row",
        "widget_action_pair_row_1",
        "widget_action_pair_row_2",
        "widget_primary_metric_value",
        "widget_primary_metric_label",
        "widget_todo_load_label",
        "widget_next_todo",
        "widget_food",
        "widget_workout",
        "widget_active_calories",
        "widget_finance_expense",
        "widget_finance_income",
        "pingsheng_widget_today_mark",
        "今日支出",
        "今日收入",
        "今日消耗",
        "下一项",
        "计划&#10;加待办",
        "饮食&#10;记录",
        "记账&#10;快捷支出",
    ]
    forbidden_layout_tokens = [
        "@+id/widget_status_pill",
        "widget_subtitle",
        "平生今日",
        "轻量记录",
        "今日同步",
        "待办负载",
        'android:text="今"',
    ]
    android_id = "{http://schemas.android.com/apk/res/android}id"
    orientation = "{http://schemas.android.com/apk/res/android}orientation"
    auto_size = "{http://schemas.android.com/apk/res/android}autoSizeTextType"
    layout_height = "{http://schemas.android.com/apk/res/android}layout_height"
    margin_top = "{http://schemas.android.com/apk/res/android}layout_marginTop"
    padding_top = "{http://schemas.android.com/apk/res/android}paddingTop"
    padding_bottom = "{http://schemas.android.com/apk/res/android}paddingBottom"

    for layout in LAYOUTS:
        xml = layout.read_text(encoding="utf-8")
        root = ET.fromstring(xml)
        missing = [token for token in required_tokens if token not in xml]
        if missing:
            print(f"Missing widget redesign tokens in {layout.name}: " + ", ".join(missing))
            return 1
        forbidden_layout = [token for token in forbidden_layout_tokens if token in xml]
        if forbidden_layout:
            print(f"Forbidden widget brand tokens in {layout.name}: " + ", ".join(forbidden_layout))
            return 1
        parent_by_child = {child: parent for parent in root.iter() for child in parent}
        row_heights = []
        row_margins = []
        for row_id in ("widget_summary_pair_row", "widget_action_pair_row_1", "widget_action_pair_row_2"):
            row = next(
                (
                    node
                    for node in root.iter()
                    if node.attrib.get(android_id) == f"@+id/{row_id}"
                ),
                None,
            )
            if row is None:
                print(f"Missing widget right grid row in {layout.name}: {row_id}.")
                return 1
            row_heights.append(_dp_value(row.attrib.get(layout_height)))
            row_margins.append(_dp_value(row.attrib.get(margin_top)))
        root_vertical_padding = _dp_value(root.attrib.get(padding_top)) + _dp_value(root.attrib.get(padding_bottom))
        if root_vertical_padding + sum(row_heights) + sum(row_margins) > 110:
            print(f"Widget right grid exceeds 4x2 compact height in {layout.name}.")
            return 1
        for finance_id in ("widget_finance_expense", "widget_finance_income"):
            finance = next(
                (
                    node
                    for node in root.iter()
                    if node.attrib.get(android_id) == f"@+id/{finance_id}"
                ),
                None,
            )
            if finance is None:
                print(f"Missing widget finance value view in {layout.name}: {finance_id}.")
                return 1
            finance_parent = parent_by_child.get(finance)
            if finance_parent is None or finance_parent.attrib.get(orientation) != "vertical":
                print(
                    f"Widget finance value must sit in a vertical label/value column in {layout.name}: {finance_id}."
                )
                return 1
            if finance.attrib.get(auto_size) != "uniform":
                print(f"Widget finance value must use uniform auto size to avoid clipping in {layout.name}: {finance_id}.")
                return 1

    info_expectations = {
        "minWidth": "250dp",
        "minHeight": "110dp",
        "minResizeWidth": "250dp",
        "minResizeHeight": "110dp",
        "targetCellWidth": "4",
        "targetCellHeight": "2",
    }
    for widget_info in WIDGET_INFOS:
        root = ET.fromstring(widget_info.read_text(encoding="utf-8"))
        for attr, expected in info_expectations.items():
            actual = root.attrib.get(f"{{http://schemas.android.com/apk/res/android}}{attr}")
            if actual != expected:
                print(
                    f"Widget size must match original 4x2 compact size in {widget_info.name}: "
                    f"{attr} expected {expected}, got {actual}."
                )
                return 1

    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    required_manifest_tokens = [
        ".PingShengWidgetProvider",
        ".PingShengLightWidgetProvider",
        "@xml/pingsheng_widget_dark_info",
        "@xml/pingsheng_widget_light_info",
        "@string/pingsheng_widget_dark_name",
        "@string/pingsheng_widget_light_name",
    ]
    missing_manifest = [token for token in required_manifest_tokens if token not in manifest]
    if missing_manifest:
        print("Missing widget manifest tokens: " + ", ".join(missing_manifest))
        return 1
    provider = (
        ROOT
        / "android/app/src/main/kotlin/com/pingsheng/pingsheng_life/PingShengWidgetProvider.kt"
    ).read_text(encoding="utf-8")
    required_provider_tokens = [
        "ACTION_REFRESH",
        "R.id.widget_plan",
        "R.id.widget_left_summary",
        "R.id.widget_next_todo",
        "nextTodoTitle(",
        "moduleIntent(context, \"/plan\", 2, \"add_todo\")",
        "R.id.widget_quick_finance",
        "moduleIntent(context, \"/finance\", 9, \"add_finance\")",
        "moduleIntent(context, \"/food\", 8, \"add_food\")",
        "R.id.widget_active_calories",
        "R.layout.pingsheng_widget_dark",
        "R.layout.pingsheng_widget_light",
        "class PingShengLightWidgetProvider",
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
        "moduleIntent(context, \"/finance\", 3, \"add_finance\")",
        "R.id.widget_summary_card",
        "R.id.widget_title",
        "R.id.widget_subtitle",
        "R.id.widget_expense_card",
        "R.id.widget_income_card",
        "平生今日",
        "轻量记录",
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


def _dp_value(raw: str | None) -> int:
    if not raw or not raw.endswith("dp"):
        return 0
    return int(float(raw[:-2]))


if __name__ == "__main__":
    sys.exit(main())
