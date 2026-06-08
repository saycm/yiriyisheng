package com.pingsheng.pingsheng_life

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = ScrollView(this).apply {
            setBackgroundColor(0xFFF4F6FB.toInt())
            addView(
                LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(44, 54, 44, 54)
                    addView(titleView("平生需要读取健康数据"))
                    addView(bodyView("App 会读取 Health Connect 中的步数、能量、睡眠、心率和呼吸频率，用于健康页展示和桌面小组件摘要。"))
                    addView(bodyView("数据只保存在本机，不会上传服务器；你可以随时在系统 Health Connect 权限设置中关闭读取权限。"))
                    addView(bodyView("传感器数据仅用于判断设备实时状态，例如计步器、心率传感器和加速度传感器是否可用。"))
                }
            )
        }
        setContentView(root)
    }

    private fun titleView(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(0xFF182033.toInt())
            textSize = 24f
            gravity = Gravity.START
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 26)
        }
    }

    private fun bodyView(text: String): TextView {
        return TextView(this).apply {
            this.text = text
            setTextColor(0xFF566070.toInt())
            textSize = 16f
            setLineSpacing(6f, 1.0f)
            setPadding(0, 0, 0, 18)
        }
    }
}
