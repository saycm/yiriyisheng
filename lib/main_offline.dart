// 中文注释：临时离线构建入口，不走登录和更新检查，方便无服务器环境测试 App。

import 'package:flutter/material.dart';

import 'app/app.dart';

void main() {
  runApp(const PingShengApp(enableAuth: false));
}
