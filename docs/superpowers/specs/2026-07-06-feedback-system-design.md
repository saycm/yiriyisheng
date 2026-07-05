# 问题反馈系统设计

更新时间：2026-07-06  
当前代码基线：`1.0.59+60`

## 1. 目标

把当前“问题反馈”从本地假提交升级为真实可用的反馈闭环：

1. 用户在 App 内提交问题或建议。
2. App 优先把反馈提交到服务端。
3. 提交失败时，用户可以复制反馈内容或复制联系方式，避免内容丢失。
4. 管理员通过服务端后台页面查看、筛选和处理反馈。

本设计只覆盖“反馈收集与处理状态管理”，不做客服聊天、多账号后台权限、推送通知或多端同步。

## 2. 当前现状

入口位于模块中心的“更多”区域：

- `lib/shared/module_center_sheet.dart` 打开问题反馈弹层。
- `lib/shared/module_info_sheets.dart` 中的 `_FeedbackSheet` 只维护本地 `_sent` 状态。

当前问题：

- 点击“提交反馈”不会发送到服务端。
- 服务端没有保存反馈的接口或表结构。
- 管理员没有查看反馈的页面。
- 提交失败和成功没有真实区别，用户可能以为反馈已经送达。

## 3. 推荐方案

采用“服务端提交 + 本地兜底 + 后台查看”的组合方案。

对比：

| 方案 | 优点 | 缺点 |
|---|---|---|
| 只做服务器接口 | 提交真实有效 | 管理员查看麻烦 |
| 只跳转微信或邮箱 | 实现快 | 反馈分散，不可追踪 |
| 服务端 + 兜底 + 后台页面 | 提交可靠，管理集中，失败不丢内容 | 实现范围略大 |

最终选择第三种。

## 4. App 端设计

### 4.1 表单字段

反馈弹层保留在模块中心内，升级为正式表单：

| 字段 | 是否必填 | 说明 |
|---|---|---|
| 反馈类型 | 必填 | 问题、建议、崩溃、界面显示、数据异常、其他 |
| 反馈内容 | 必填 | 最少 5 个字符，最多 1000 个字符 |
| 联系方式 | 选填 | 微信、手机号或邮箱，由用户自由填写 |

### 4.2 自动附带信息

App 提交时自动带上：

- `appVersionName`
- `appVersionCode`
- `platform`
- `deviceInfo`
- `createdAt`

其中版本号使用现有 `appVersionName` 和 `appVersionCode`，平台优先传 `android`。设备信息第一版可以使用 Flutter 可获得的基础信息；如果没有额外依赖，先传简短运行环境文本。

### 4.3 提交状态

表单有 4 种状态：

| 状态 | 展示 |
|---|---|
| 未提交 | 展示表单和提交按钮 |
| 提交中 | 禁用输入和按钮，显示加载状态 |
| 提交成功 | 显示“已提交，我们会尽快处理” |
| 提交失败 | 显示失败原因和兜底按钮 |

提交失败时提供：

- 复制反馈内容
- 复制客服联系方式
- 重新提交

### 4.4 兜底联系方式

第一版不强制跳转第三方 App，避免不同设备环境下失败。先提供“复制客服联系方式”：

- 文案：`复制联系方式`
- 内容可先使用项目固定联系方式配置。
- 后续如需要，可以再扩展为邮箱、微信或浏览器跳转。

## 5. 服务端设计

### 5.1 数据模型

新增反馈实体：

| 字段 | 类型 | 说明 |
|---|---|---|
| `id` | string | 服务端生成 |
| `type` | string | 反馈类型 |
| `content` | string | 反馈正文 |
| `contact` | string | 联系方式，可为空 |
| `platform` | string | 平台 |
| `appVersionName` | string | App 版本名 |
| `appVersionCode` | int | App 版本号 |
| `deviceInfo` | string | 设备信息 |
| `status` | string | `pending`、`processing`、`resolved`、`archived` |
| `createdAt` | string | 创建时间 |
| `updatedAt` | string | 更新时间 |

状态中文含义：

| 状态 | 中文 |
|---|---|
| `pending` | 待处理 |
| `processing` | 处理中 |
| `resolved` | 已处理 |
| `archived` | 已归档 |

### 5.2 存储

服务端 SQLite 新增 `feedback_items` 表。

建议字段：

```sql
CREATE TABLE IF NOT EXISTS feedback_items (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  content TEXT NOT NULL,
  contact TEXT NOT NULL,
  platform TEXT NOT NULL,
  app_version_name TEXT NOT NULL,
  app_version_code INTEGER NOT NULL,
  device_info TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

第一版不删除反馈，只通过 `archived` 状态归档。

### 5.3 API

#### `POST /v1/feedback`

App 提交反馈，不需要管理员 token。

请求：

```json
{
  "type": "问题",
  "content": "小组件今日支出显示不全",
  "contact": "微信 xxx",
  "platform": "android",
  "appVersionName": "1.0.59",
  "appVersionCode": 60,
  "deviceInfo": "Android"
}
```

响应：

```json
{
  "feedback": {
    "id": "019f...",
    "status": "pending",
    "createdAt": "2026-07-06T10:00:00Z"
  }
}
```

校验：

- `content` 必填，长度 5 到 1000。
- `type` 不在允许列表时保存为 `其他`。
- `contact` 可为空，最多 200 字符。
- `deviceInfo` 最多 500 字符。

#### `GET /v1/admin/feedback`

管理员查看反馈列表，需要 `X-Admin-Token`。

查询参数：

- `status`：可选，按状态筛选。
- `limit`：可选，默认 50，最大 100。

响应包含反馈数组，按 `createdAt` 倒序。

#### `PUT /v1/admin/feedback/{id}`

管理员更新反馈状态，需要 `X-Admin-Token`。

请求：

```json
{
  "status": "resolved"
}
```

只允许更新到：

- `pending`
- `processing`
- `resolved`
- `archived`

## 6. 后台页面设计

新增页面：

```text
GET /admin/feedback
```

页面行为：

1. 首次打开显示 token 输入框。
2. 输入现有 admin token 后，请求 `/v1/admin/feedback`。
3. token 保存在浏览器 `localStorage`，便于下一次打开。
4. token 失效时提示重新输入。

页面包含：

- 状态筛选：全部、待处理、处理中、已处理、已归档
- 反馈列表：类型、摘要、联系方式、版本、设备、时间、状态
- 详情区域：完整内容和元信息
- 状态操作：标记处理中、标记已处理、归档

第一版后台页面使用服务端直接返回 HTML、CSS、JavaScript，不引入前端构建系统。

## 7. 错误处理

### 7.1 App 端

如果网络错误、服务端异常或返回校验错误：

- 不清空用户输入。
- 显示明确失败原因。
- 提供复制反馈内容。
- 提供复制联系方式。
- 允许重新提交。

### 7.2 服务端

服务端返回统一 JSON 错误：

```json
{
  "error": "反馈内容不能为空"
}
```

常见状态码：

| 状态码 | 场景 |
|---|---|
| 400 | 请求内容不合法 |
| 401 | 管理员 token 缺失或错误 |
| 404 | 反馈不存在 |
| 500 | 服务端保存失败 |

## 8. 测试策略

### 8.1 Flutter 测试

新增或扩展 widget test：

- 反馈内容为空时不能提交。
- 成功提交后显示成功状态。
- 提交失败后显示复制和重试按钮。
- 失败后输入内容仍保留。

### 8.2 Go 服务端测试

新增 `server/main_test.go` 覆盖：

- `POST /v1/feedback` 成功创建反馈。
- 内容过短时返回 400。
- `GET /v1/admin/feedback` 无 token 返回 401。
- 管理员可读取反馈列表。
- 管理员可更新反馈状态。
- 非法状态返回 400。

### 8.3 手工验收

发布前手工验证：

1. App 内提交一条反馈。
2. 打开 `/admin/feedback` 输入 token。
3. 确认能看到刚提交的内容。
4. 把状态改为“处理中”。
5. 断开服务端后再次提交，确认 App 显示失败兜底，不会假装成功。

## 9. 发布与部署

发布步骤：

1. 更新服务端代码和数据库迁移逻辑。
2. 部署服务端并重启 `pingsheng-life-server`。
3. 构建新 APK。
4. 上传 APK 到服务器 `downloads/`。
5. 更新服务端 update policy。
6. 用旧版本请求更新接口确认 `hasUpdate: true`。

服务端兼容要求：

- 新增表不影响现有用户、登录、更新接口。
- 旧 App 不调用反馈接口，不受影响。

## 10. 非目标

第一版不做：

- 客服实时聊天。
- 图片或截图上传。
- 多管理员账号体系。
- 反馈回复推送。
- 用户登录后绑定反馈历史。
- 删除反馈。

这些能力可以在反馈闭环稳定后再扩展。

## 11. 待确认事项

已确认：

- 使用服务端保存反馈。
- App 提交失败时提供复制兜底。
- 做简易后台页面查看反馈。
- 后台沿用现有 admin token。

暂不阻塞实现的默认选择：

- 第一版客服联系方式使用固定配置文本。
- 第一版不上传截图。
- 第一版后台页面由 Go 服务端直接输出静态 HTML。
