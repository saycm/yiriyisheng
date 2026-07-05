from pathlib import Path
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
LAYOUT = ROOT / "android/app/src/main/res/layout/pingsheng_widget.xml"


def main() -> int:
    xml = LAYOUT.read_text(encoding="utf-8")
    ET.fromstring(xml)
    required_tokens = [
        "widget_status_pill",
        "widget_primary_metric_value",
        "widget_primary_metric_label",
        "widget_active_calories",
        "今日消耗",
        "计划&#10;加待办",
        "饮食&#10;记录",
        "记账&#10;快捷支出",
    ]
    missing = [token for token in required_tokens if token not in xml]
    if missing:
        print("Missing widget redesign tokens: " + ", ".join(missing))
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
