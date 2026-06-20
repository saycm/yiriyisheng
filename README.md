# 平生 Life

平生 Life 是一个本地优先的生活管理 App，当前重点覆盖计划、财务、饮食、锻炼、健康和 Android 桌面小组件。App 使用 Flutter 构建，Android 原生层负责桌面小组件、Health Connect、传感器读取和登录态安全存储；服务端使用 Go 提供账号、Token 和 App 更新策略接口。

## 项目架构

```text
lib/
  main.dart                    Flutter 入口，使用 part 组合各模块
  app/                         App 外壳、路由、版本和全局常量
  auth/                        注册登录、更新检查、登录态恢复
  api/                         Go 服务端 HTTP API 客户端
  home/                        首页状态、模块切换、模块联动汇总
  models/                      健康系统数据模型
  storage/                     App SQLite 存储与桌面小组件同步通道
  modules/
    plan/                      计划、待办箱、周计划、复盘
    finance/                   财务记录、资产、AI 记账入口
    food/                      饮食记录、食物库、模板、热量趋势
    workout/                   锻炼计划、动作、组数、休息和历史
    health/                    Health Connect、传感器、健康趋势
  shared/                      模块弹层、底部模块栏、通用组件

android/app/src/main/kotlin/   Android 原生能力
server/                        Go 后端、SQLite 数据库、下载目录
test/                          Flutter widget、smoke、golden 测试
```

## 当前能力

- 邮箱/手机号注册登录，Refresh token 轮换，Android 侧使用 `EncryptedSharedPreferences` 保存登录态。
- App 更新检查和强制更新拦截。
- 计划模块支持分类、优先级、状态、待办箱、今日/周计划、模块联动和复盘。
- 财务、饮食、锻炼、健康模块已有可交互原型和本地数据联动。
- App 主数据优先写入本地 SQLite，小组件只保存摘要和快捷写入数据。
- Android 小组件支持摘要展示、快捷待办、快捷记账、快捷饮食和模块跳转。
- 健康模块读取 Health Connect 和本机传感器状态。

## 环境要求

- Flutter SDK，项目当前 Dart SDK 约束为 `^3.6.1`
- Android Studio / Android SDK
- Go 1.26 或兼容版本
- Android 8.0+ 设备或模拟器；Health Connect 能力依赖设备系统和授权状态

## 本地运行

安装 Flutter 依赖：

```bash
flutter pub get
```

启动 Go 服务端：

```cmd
cd server
set TOKEN_SECRET=replace-with-a-long-random-secret
set ADMIN_TOKEN=replace-with-a-private-admin-token
go run .
```

PowerShell 可使用：

```powershell
cd server
$env:TOKEN_SECRET="replace-with-a-long-random-secret"
$env:ADMIN_TOKEN="replace-with-a-private-admin-token"
go run .
```

运行 App 时指定服务端地址和版本信息：

```powershell
flutter run `
  --dart-define=PINGSHENG_API_BASE_URL=http://192.168.20.11:3000 `
  --dart-define=PINGSHENG_APP_VERSION_NAME=1.0.5 `
  --dart-define=PINGSHENG_APP_VERSION_CODE=6
```

如果不启用登录入口，`PingShengApp` 默认会直接进入本地模块页；正式入口在 `lib/main.dart` 中通过 `PingShengApp(enableAuth: true)` 启用。

## 测试

Flutter：

```bash
flutter analyze
flutter test
```

Go 服务端：

```bash
cd server
go test ./...
```

Android 原生构建局部检查：

```powershell
cd android
.\gradlew.bat :app:compileDebugKotlin
.\gradlew.bat :app:processDebugResources
```

## 构建 APK

调试包：

```bash
flutter build apk --debug
```

本地测试发布包：

```powershell
flutter build apk --release `
  --dart-define=PINGSHENG_API_BASE_URL=http://192.168.20.11:3000 `
  --dart-define=PINGSHENG_APP_VERSION_NAME=1.0.5 `
  --dart-define=PINGSHENG_APP_VERSION_CODE=6
```

注意：当前 Android release 构建仍使用 debug 签名，适合本地测试分发；正式发布前需要配置独立 release keystore。

## 更新发布流程

1. 更新 `pubspec.yaml` 的 `version`，同时同步 `lib/app/app.dart` 默认版本常量。
2. 运行 `flutter analyze`、`flutter test`、`go test ./...`。
3. 构建 release APK。
4. 将 APK 放到服务端运行目录的 `downloads/` 下，例如 `server/downloads/pingsheng-1.0.6.apk`。
5. 启动或重启 Go 服务端。
6. 调用 `/v1/admin/update-policy` 更新 `latestVersionCode`、`latestVersionName`、`downloadUrl`、`releaseNotes` 和 `minSupportedVersionCode`。
7. 使用旧版本 App 验证是否能看到更新提示或强制更新页。

示例：

```bash
curl -X PUT http://192.168.20.11:3000/v1/admin/update-policy \
  -H "Content-Type: application/json" \
  -H "X-Admin-Token: replace-with-a-private-admin-token" \
  -d "{\"latestVersionCode\":7,\"latestVersionName\":\"1.0.6\",\"minSupportedVersionCode\":6,\"downloadUrl\":\"http://192.168.20.11:3000/downloads/pingsheng-1.0.6.apk\",\"releaseNotes\":[\"修复注册登录体验\",\"优化计划模块日期\"],\"message\":\"发现新版本，建议更新。\"}"
```

## 本地数据与发布产物

以下内容是本地运行数据或构建产物，已在 `.gitignore` 中排除：

- `server/data/db.json`
- `server/data/*.db`
- `server/downloads/*.apk`
- `server/pingsheng-life-server`
- `server/pingsheng-life-server.exe`
- Android/Flutter 构建输出目录

如果需要保留 APK 或服务端二进制，请放在部署机器或发布制品库中，不要提交到源码仓库。

## 下一步建议

- 将大模块文件继续拆分为 `models / store / widgets / sheets / page`。
- 为本地 SQLite 增加 Repository 层，降低页面状态和存储的耦合。
- 将发布流程脚本化，减少版本号、APK、更新策略之间的手工同步风险。
