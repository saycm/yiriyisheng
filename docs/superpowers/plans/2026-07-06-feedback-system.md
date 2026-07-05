# 问题反馈系统实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 把 App 内“问题反馈”从本地假提交升级为真实服务端提交、失败兜底复制、管理员后台查看与处理的闭环功能。

**架构：** Go 服务端新增反馈表、提交接口、管理员列表/状态接口和一个轻量 HTML 后台页面。Flutter 端在现有模块中心反馈弹层内接入 `_PingShengApi.submitFeedback`，保留用户输入，失败时提供复制反馈内容和复制联系方式。服务端仍沿用现有 SQLite、`X-Admin-Token` 和集中路由模式，不引入新前端构建系统。

**技术栈：** Flutter/Dart、Go `net/http`、SQLite `modernc.org/sqlite`、Flutter widget tests、Go `httptest`。

---

## 文件结构

创建或修改以下文件：

- 修改：`server/main.go`
  - 新增 `feedbackItem` 模型、SQLite 表、提交/列表/状态更新处理函数、后台 HTML 页面处理函数。
  - 在 `routeAPI` 中注册 `/v1/feedback`、`/v1/admin/feedback`、`/v1/admin/feedback/{id}`、`/admin/feedback`。
- 修改：`server/main_test.go`
  - 覆盖反馈创建、校验、管理员鉴权、列表查询、状态更新、后台页面。
- 修改：`lib/api/pingsheng_api.dart`
  - 新增 `FeedbackDraft`、`FeedbackReceipt`、`debugFeedbackResponseOverride` 和 `_PingShengApi.submitFeedback`。
- 修改：`lib/shared/module_info_sheets.dart`
  - 重做 `_FeedbackSheet` 表单、提交状态和失败兜底。
- 修改：`test/widget_test.dart`
  - 覆盖反馈表单校验、成功提交、失败兜底。
- 修改：`pubspec.yaml` 和 `lib/core/app_core.dart`
  - 发布实现时版本号递增，保持 `test/version_sync_test.dart` 通过。
- 修改：`server/README.md`
  - 补充反馈 API 和后台页面说明。

---

### 任务 1：服务端反馈表和基础模型

**文件：**
- 修改：`server/main.go`
- 测试：`server/main_test.go`

- [ ] **步骤 1：编写失败的表结构测试**

在 `server/main_test.go` 追加：

```go
func TestFeedbackTableIsCreated(t *testing.T) {
	app := newTestApp(t)

	db, err := openDataDB()
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	var name string
	err = db.QueryRow(`SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'feedback_items'`).Scan(&name)
	if err != nil {
		t.Fatalf("feedback table was not created: %v", err)
	}
	if name != "feedback_items" {
		t.Fatalf("unexpected table name: %q", name)
	}
}
```

如果 `server/main_test.go` import 尚未包含新测试需要的包，保持 import 为：

```go
import (
	"bytes"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
go test ./server -run TestFeedbackTableIsCreated -v
```

预期：FAIL，错误包含 `feedback table was not created` 或 `no such table`。

- [ ] **步骤 3：实现反馈模型和 SQLite 表**

在 `server/main.go` 的 `updatePolicy` 后添加：

```go
type feedbackItem struct {
	ID             string `json:"id"`
	Type           string `json:"type"`
	Content        string `json:"content"`
	Contact        string `json:"contact"`
	Platform       string `json:"platform"`
	AppVersionName string `json:"appVersionName"`
	AppVersionCode int    `json:"appVersionCode"`
	DeviceInfo     string `json:"deviceInfo"`
	Status         string `json:"status"`
	CreatedAt      string `json:"createdAt"`
	UpdatedAt      string `json:"updatedAt"`
}
```

在 `initSQLite` 的 `statements` 中，紧跟 `app_meta` 表后添加：

```go
`CREATE TABLE IF NOT EXISTS feedback_items (
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
)`,
`CREATE INDEX IF NOT EXISTS idx_feedback_items_status ON feedback_items(status)`,
`CREATE INDEX IF NOT EXISTS idx_feedback_items_created_at ON feedback_items(created_at)`,
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```powershell
go test ./server -run TestFeedbackTableIsCreated -v
```

预期：PASS。

- [ ] **步骤 5：Commit**

```powershell
git add server/main.go server/main_test.go
git commit -m "feat: add feedback storage table"
```

---

### 任务 2：服务端提交反馈接口

**文件：**
- 修改：`server/main.go`
- 测试：`server/main_test.go`

- [ ] **步骤 1：编写失败的提交接口测试**

在 `server/main_test.go` 追加：

```go
func TestCreateFeedback(t *testing.T) {
	app := newTestApp(t)

	status, payload := app.jsonRequest(t, http.MethodPost, "/v1/feedback", map[string]any{
		"type":           "界面显示",
		"content":        "桌面小组件今日支出显示不全",
		"contact":        "微信 saycm",
		"platform":       "android",
		"appVersionName": "1.0.59",
		"appVersionCode": 60,
		"deviceInfo":     "Android 15",
	}, nil)
	if status != http.StatusCreated {
		t.Fatalf("create feedback status = %d, payload = %#v", status, payload)
	}
	feedback := payload["feedback"].(map[string]any)
	if feedback["id"] == "" || feedback["status"] != "pending" {
		t.Fatalf("unexpected feedback receipt: %#v", feedback)
	}
}

func TestCreateFeedbackValidatesContent(t *testing.T) {
	app := newTestApp(t)

	status, payload := app.jsonRequest(t, http.MethodPost, "/v1/feedback", map[string]any{
		"type":    "问题",
		"content": "短",
	}, nil)
	if status != http.StatusBadRequest {
		t.Fatalf("short feedback status = %d, payload = %#v", status, payload)
	}
	errorBody := payload["error"].(map[string]any)
	if errorBody["code"] != "invalid_feedback_content" {
		t.Fatalf("unexpected error: %#v", payload)
	}
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
go test ./server -run "TestCreateFeedback" -v
```

预期：FAIL，`/v1/feedback` 返回 404。

- [ ] **步骤 3：注册路由和实现提交逻辑**

在 `routeAPI` 中添加，放在更新接口附近：

```go
case r.Method == http.MethodPost && path == "/v1/feedback":
	return createFeedback(w, r)
```

在 `server/main.go` 中 `updatePolicyHandler` 后添加：

```go
func createFeedback(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	item, err := feedbackFromInput(body)
	if err != nil {
		return err
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := openDataDB()
	if err != nil {
		return err
	}
	defer db.Close()

	if err := insertFeedback(db, item); err != nil {
		return err
	}
	sendJSON(w, http.StatusCreated, map[string]any{
		"feedback": map[string]any{
			"id":        item.ID,
			"status":    item.Status,
			"createdAt": item.CreatedAt,
		},
	})
	return nil
}

func feedbackFromInput(input map[string]any) (feedbackItem, error) {
	content := strings.TrimSpace(stringValue(input["content"]))
	if len([]rune(content)) < 5 || len([]rune(content)) > 1000 {
		return feedbackItem{}, apiError{Status: http.StatusBadRequest, Code: "invalid_feedback_content", Message: "反馈内容需要 5 到 1000 个字。"}
	}
	kind := normalizeFeedbackType(stringValue(input["type"]))
	contact := trimRunes(stringValue(input["contact"]), 200)
	platform := strings.ToLower(strings.TrimSpace(defaultIfEmpty(stringValue(input["platform"]), "android")))
	deviceInfo := trimRunes(stringValue(input["deviceInfo"]), 500)
	versionCode := parseVersionCode(input["appVersionCode"])
	if versionCode == nil {
		fallback := 0
		versionCode = &fallback
	}
	now := nowISO()
	return feedbackItem{
		ID:             newUUID(),
		Type:           kind,
		Content:        content,
		Contact:        contact,
		Platform:       platform,
		AppVersionName: trimRunes(stringValue(input["appVersionName"]), 50),
		AppVersionCode: *versionCode,
		DeviceInfo:     deviceInfo,
		Status:         "pending",
		CreatedAt:      now,
		UpdatedAt:      now,
	}, nil
}

func normalizeFeedbackType(value string) string {
	value = strings.TrimSpace(value)
	switch value {
	case "问题", "建议", "崩溃", "界面显示", "数据异常", "其他":
		return value
	default:
		return "其他"
	}
}

func trimRunes(value string, max int) string {
	value = strings.TrimSpace(value)
	runes := []rune(value)
	if len(runes) <= max {
		return value
	}
	return string(runes[:max])
}

func insertFeedback(db *sql.DB, item feedbackItem) error {
	_, err := db.Exec(
		`INSERT INTO feedback_items (id, type, content, contact, platform, app_version_name, app_version_code, device_info, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		item.ID,
		item.Type,
		item.Content,
		item.Contact,
		item.Platform,
		item.AppVersionName,
		item.AppVersionCode,
		item.DeviceInfo,
		item.Status,
		item.CreatedAt,
		item.UpdatedAt,
	)
	return err
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```powershell
go test ./server -run "TestCreateFeedback" -v
```

预期：PASS。

- [ ] **步骤 5：Commit**

```powershell
git add server/main.go server/main_test.go
git commit -m "feat: accept feedback submissions"
```

---

### 任务 3：服务端管理员反馈 API

**文件：**
- 修改：`server/main.go`
- 测试：`server/main_test.go`

- [ ] **步骤 1：编写失败的管理员 API 测试**

在 `server/main_test.go` 追加：

```go
func TestAdminFeedbackListAndStatusUpdate(t *testing.T) {
	app := newTestApp(t)

	status, _ := app.jsonRequest(t, http.MethodPost, "/v1/feedback", map[string]any{
		"type":           "问题",
		"content":        "计划点击延后明天的逻辑不符合预期",
		"platform":       "android",
		"appVersionName": "1.0.59",
		"appVersionCode": 60,
	}, nil)
	if status != http.StatusCreated {
		t.Fatalf("create status = %d", status)
	}

	status, _ = app.jsonRequest(t, http.MethodGet, "/v1/admin/feedback", nil, nil)
	if status != http.StatusUnauthorized {
		t.Fatalf("missing admin token status = %d", status)
	}

	status, payload := app.jsonRequest(t, http.MethodGet, "/v1/admin/feedback", nil, map[string]string{
		"X-Admin-Token": "test-admin-token",
	})
	if status != http.StatusOK {
		t.Fatalf("list status = %d, payload = %#v", status, payload)
	}
	items := payload["feedback"].([]any)
	if len(items) != 1 {
		t.Fatalf("feedback item count = %d, payload = %#v", len(items), payload)
	}
	item := items[0].(map[string]any)
	id := item["id"].(string)
	if item["content"] != "计划点击延后明天的逻辑不符合预期" {
		t.Fatalf("unexpected feedback item: %#v", item)
	}

	status, payload = app.jsonRequest(t, http.MethodPut, "/v1/admin/feedback/"+id, map[string]any{
		"status": "processing",
	}, map[string]string{"X-Admin-Token": "test-admin-token"})
	if status != http.StatusOK {
		t.Fatalf("update status = %d, payload = %#v", status, payload)
	}
	updated := payload["feedback"].(map[string]any)
	if updated["status"] != "processing" {
		t.Fatalf("status was not updated: %#v", updated)
	}
}

func TestAdminFeedbackRejectsInvalidStatus(t *testing.T) {
	app := newTestApp(t)
	status, payload := app.jsonRequest(t, http.MethodPut, "/v1/admin/feedback/missing", map[string]any{
		"status": "deleted",
	}, map[string]string{"X-Admin-Token": "test-admin-token"})
	if status != http.StatusBadRequest {
		t.Fatalf("invalid status response = %d, payload = %#v", status, payload)
	}
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
go test ./server -run "TestAdminFeedback" -v
```

预期：FAIL，管理员反馈接口返回 404。

- [ ] **步骤 3：实现管理员鉴权、列表和状态更新**

在 `routeAPI` 中添加：

```go
case r.Method == http.MethodGet && path == "/v1/admin/feedback":
	return listFeedback(w, r)
case r.Method == http.MethodPut && strings.HasPrefix(path, "/v1/admin/feedback/"):
	return updateFeedbackStatus(w, r)
```

在 `server/main.go` 中添加：

```go
func listFeedback(w http.ResponseWriter, r *http.Request) error {
	if err := requireAdmin(r); err != nil {
		return err
	}
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	limit := envLimitedInt(r.URL.Query().Get("limit"), 50, 1, 100)

	db, err := openDataDB()
	if err != nil {
		return err
	}
	defer db.Close()

	items, err := queryFeedback(db, status, limit)
	if err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, map[string]any{"feedback": items})
	return nil
}

func updateFeedbackStatus(w http.ResponseWriter, r *http.Request) error {
	if err := requireAdmin(r); err != nil {
		return err
	}
	id := strings.TrimSpace(strings.TrimPrefix(r.URL.Path, "/v1/admin/feedback/"))
	if id == "" || strings.Contains(id, "/") {
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Feedback not found."}
	}
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	status := strings.TrimSpace(stringValue(body["status"]))
	if !isFeedbackStatus(status) {
		return apiError{Status: http.StatusBadRequest, Code: "invalid_feedback_status", Message: "反馈状态不正确。"}
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := openDataDB()
	if err != nil {
		return err
	}
	defer db.Close()

	item, err := setFeedbackStatus(db, id, status)
	if err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, map[string]any{"feedback": item})
	return nil
}

func requireAdmin(r *http.Request) error {
	if r.Header.Get("X-Admin-Token") != adminToken() {
		return apiError{Status: http.StatusUnauthorized, Code: "unauthorized", Message: "Admin token is required."}
	}
	return nil
}

func isFeedbackStatus(status string) bool {
	switch status {
	case "pending", "processing", "resolved", "archived":
		return true
	default:
		return false
	}
}

func envLimitedInt(raw string, fallback int, minimum int, maximum int) int {
	value, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil || value < minimum {
		return fallback
	}
	if value > maximum {
		return maximum
	}
	return value
}

func queryFeedback(db *sql.DB, status string, limit int) ([]feedbackItem, error) {
	args := []any{}
	where := ""
	if status != "" {
		if !isFeedbackStatus(status) {
			return []feedbackItem{}, nil
		}
		where = " WHERE status = ?"
		args = append(args, status)
	}
	args = append(args, limit)
	rows, err := db.Query(`SELECT id, type, content, contact, platform, app_version_name, app_version_code, device_info, status, created_at, updated_at FROM feedback_items`+where+` ORDER BY created_at DESC LIMIT ?`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := []feedbackItem{}
	for rows.Next() {
		var item feedbackItem
		if err := rows.Scan(&item.ID, &item.Type, &item.Content, &item.Contact, &item.Platform, &item.AppVersionName, &item.AppVersionCode, &item.DeviceInfo, &item.Status, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func setFeedbackStatus(db *sql.DB, id string, status string) (feedbackItem, error) {
	updatedAt := nowISO()
	res, err := db.Exec(`UPDATE feedback_items SET status = ?, updated_at = ? WHERE id = ?`, status, updatedAt, id)
	if err != nil {
		return feedbackItem{}, err
	}
	affected, err := res.RowsAffected()
	if err != nil {
		return feedbackItem{}, err
	}
	if affected == 0 {
		return feedbackItem{}, apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Feedback not found."}
	}
	return getFeedback(db, id)
}

func getFeedback(db *sql.DB, id string) (feedbackItem, error) {
	var item feedbackItem
	err := db.QueryRow(`SELECT id, type, content, contact, platform, app_version_name, app_version_code, device_info, status, created_at, updated_at FROM feedback_items WHERE id = ?`, id).Scan(
		&item.ID,
		&item.Type,
		&item.Content,
		&item.Contact,
		&item.Platform,
		&item.AppVersionName,
		&item.AppVersionCode,
		&item.DeviceInfo,
		&item.Status,
		&item.CreatedAt,
		&item.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return feedbackItem{}, apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Feedback not found."}
	}
	return item, err
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```powershell
go test ./server -run "TestAdminFeedback" -v
```

预期：PASS。

- [ ] **步骤 5：Commit**

```powershell
git add server/main.go server/main_test.go
git commit -m "feat: manage feedback in admin api"
```

---

### 任务 4：服务端后台页面

**文件：**
- 修改：`server/main.go`
- 测试：`server/main_test.go`
- 可选修改：`server/README.md`

- [ ] **步骤 1：编写失败的后台页面测试**

在 `server/main_test.go` 追加：

```go
func TestFeedbackAdminPage(t *testing.T) {
	app := newTestApp(t)

	res, err := app.server.Client().Get(app.server.URL + "/admin/feedback")
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	raw, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	body := string(raw)
	if res.StatusCode != http.StatusOK {
		t.Fatalf("admin page status = %d body = %s", res.StatusCode, body)
	}
	if !strings.Contains(body, "问题反馈后台") || !strings.Contains(body, "/v1/admin/feedback") {
		t.Fatalf("admin page missing expected content: %s", body)
	}
}
```

同时在 import 增加 `strings`。

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
go test ./server -run TestFeedbackAdminPage -v
```

预期：FAIL，`/admin/feedback` 返回 404。

- [ ] **步骤 3：实现 HTML 后台页面**

在 `routeAPI` 中添加：

```go
case r.Method == http.MethodGet && path == "/admin/feedback":
	serveFeedbackAdminPage(w, r)
```

在 `server/main.go` 中添加：

```go
func serveFeedbackAdminPage(w http.ResponseWriter, r *http.Request) {
	html := `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>问题反馈后台</title>
  <style>
    body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f6f8ff; color: #172033; }
    main { max-width: 1080px; margin: 0 auto; padding: 24px; }
    header { display: flex; justify-content: space-between; gap: 16px; align-items: center; margin-bottom: 18px; }
    h1 { margin: 0; font-size: 24px; }
    .panel { background: #fff; border: 1px solid #e4eaf6; border-radius: 8px; padding: 16px; margin-bottom: 14px; }
    .row { display: flex; gap: 10px; flex-wrap: wrap; align-items: center; }
    input, select, button, textarea { border-radius: 8px; border: 1px solid #d8dffe; padding: 10px 12px; font: inherit; }
    input { min-width: 280px; }
    button { background: #5d72f6; color: #fff; border: 0; cursor: pointer; font-weight: 700; }
    button.secondary { background: #edf1ff; color: #3654d7; }
    .item { border-top: 1px solid #eef2fb; padding: 14px 0; }
    .meta { color: #748098; font-size: 13px; margin-top: 6px; }
    .content { white-space: pre-wrap; line-height: 1.55; margin-top: 8px; }
    .error { color: #f35f64; font-weight: 700; }
  </style>
</head>
<body>
<main>
  <header>
    <h1>问题反馈后台</h1>
    <button class="secondary" onclick="loadFeedback()">刷新</button>
  </header>
  <section class="panel">
    <div class="row">
      <input id="token" type="password" placeholder="输入 X-Admin-Token">
      <select id="status">
        <option value="">全部</option>
        <option value="pending">待处理</option>
        <option value="processing">处理中</option>
        <option value="resolved">已处理</option>
        <option value="archived">已归档</option>
      </select>
      <button onclick="saveTokenAndLoad()">查看反馈</button>
    </div>
    <p id="message" class="meta"></p>
  </section>
  <section id="list" class="panel">请输入管理员 token 后查看反馈。</section>
</main>
<script>
const tokenInput = document.getElementById('token');
const statusInput = document.getElementById('status');
const message = document.getElementById('message');
const list = document.getElementById('list');
tokenInput.value = localStorage.getItem('pingsheng_admin_token') || '';
statusInput.addEventListener('change', loadFeedback);
function saveTokenAndLoad() {
  localStorage.setItem('pingsheng_admin_token', tokenInput.value.trim());
  loadFeedback();
}
async function loadFeedback() {
  const token = tokenInput.value.trim();
  if (!token) {
    message.textContent = '请先输入管理员 token。';
    return;
  }
  message.textContent = '加载中...';
  const query = statusInput.value ? '?status=' + encodeURIComponent(statusInput.value) : '';
  const res = await fetch('/v1/admin/feedback' + query, { headers: { 'X-Admin-Token': token } });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    message.textContent = (data.error && data.error.message) || '加载失败';
    list.innerHTML = '<span class="error">无法读取反馈。</span>';
    return;
  }
  message.textContent = '共 ' + data.feedback.length + ' 条';
  list.innerHTML = data.feedback.length ? data.feedback.map(renderItem).join('') : '暂无反馈。';
}
function renderItem(item) {
  return '<article class="item">' +
    '<div class="row"><strong>' + escapeHtml(item.type) + '</strong><span>' + statusLabel(item.status) + '</span></div>' +
    '<div class="content">' + escapeHtml(item.content) + '</div>' +
    '<div class="meta">联系方式：' + escapeHtml(item.contact || '未填写') + ' · 版本：' + escapeHtml(item.appVersionName || '-') + '(' + item.appVersionCode + ') · ' + escapeHtml(item.platform || '-') + ' · ' + escapeHtml(item.deviceInfo || '-') + ' · ' + escapeHtml(item.createdAt || '-') + '</div>' +
    '<div class="row" style="margin-top:10px">' +
    actionButton(item.id, 'processing', '标记处理中') +
    actionButton(item.id, 'resolved', '标记已处理') +
    actionButton(item.id, 'archived', '归档') +
    '</div></article>';
}
function actionButton(id, status, label) {
  return '<button class="secondary" onclick="setStatus(\\'' + id + '\\', \\'' + status + '\\')">' + label + '</button>';
}
async function setStatus(id, status) {
  const res = await fetch('/v1/admin/feedback/' + encodeURIComponent(id), {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'X-Admin-Token': tokenInput.value.trim() },
    body: JSON.stringify({ status })
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    message.textContent = (data.error && data.error.message) || '更新失败';
    return;
  }
  loadFeedback();
}
function statusLabel(status) {
  return ({ pending: '待处理', processing: '处理中', resolved: '已处理', archived: '已归档' })[status] || status;
}
function escapeHtml(value) {
  return String(value || '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
}
</script>
</body>
</html>`
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(html))
}
```

- [ ] **步骤 4：补充 README**

在 `server/README.md` API 列表中增加：

```markdown
- `POST /v1/feedback`：App 提交问题反馈
- `GET /v1/admin/feedback`：管理员查看反馈列表，需要 `X-Admin-Token`
- `PUT /v1/admin/feedback/<id>`：管理员更新反馈状态，需要 `X-Admin-Token`
- `GET /admin/feedback`：简易反馈后台页面
```

- [ ] **步骤 5：运行测试验证通过**

运行：

```powershell
go test ./server -run TestFeedbackAdminPage -v
go test ./server -v
```

预期：全部 PASS。

- [ ] **步骤 6：Commit**

```powershell
git add server/main.go server/main_test.go server/README.md
git commit -m "feat: add feedback admin page"
```

---

### 任务 5：Flutter API 客户端和测试注入入口

**文件：**
- 修改：`lib/api/pingsheng_api.dart`
- 测试：`test/feedback_api_test.dart`

- [ ] **步骤 1：编写失败的 API 模型测试**

新增 `test/feedback_api_test.dart`：

```dart
// 中文注释：反馈 API 模型测试，验证提交回执解析稳定。

import 'package:flutter_test/flutter_test.dart';
import 'package:pingsheng_life/main.dart';

void main() {
  test('feedback receipt parses server response', () {
    final receipt = FeedbackReceipt.fromJson({
      'feedback': {
        'id': 'fb-1',
        'status': 'pending',
        'createdAt': '2026-07-06T10:00:00Z',
      },
    });

    expect(receipt.id, 'fb-1');
    expect(receipt.status, 'pending');
    expect(receipt.createdAt, '2026-07-06T10:00:00Z');
  });

  test('feedback draft serializes app metadata', () {
    final draft = FeedbackDraft(
      type: '问题',
      content: '小组件显示不全',
      contact: '微信 saycm',
      platform: 'android',
      appVersionName: '1.0.60',
      appVersionCode: 61,
      deviceInfo: 'Android',
    );

    expect(draft.toJson(), {
      'type': '问题',
      'content': '小组件显示不全',
      'contact': '微信 saycm',
      'platform': 'android',
      'appVersionName': '1.0.60',
      'appVersionCode': 61,
      'deviceInfo': 'Android',
    });
  });
}
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/feedback_api_test.dart
```

预期：FAIL，提示 `FeedbackReceipt` 或 `FeedbackDraft` 未定义。

- [ ] **步骤 3：实现反馈 API 类型和提交方法**

在 `lib/api/pingsheng_api.dart` 的 `_PingShengApi` 中加入：

```dart
  Future<FeedbackReceipt> submitFeedback(FeedbackDraft draft) async {
    final override = debugFeedbackResponseOverride;
    if (override != null) {
      return FeedbackReceipt.fromJson(await override(draft.toJson()));
    }
    final json = await _requestJson(
      'POST',
      '/v1/feedback',
      body: draft.toJson(),
    );
    return FeedbackReceipt.fromJson(json);
  }
```

在 `_UpdateInfo` 前添加：

```dart
Future<Map<String, dynamic>> Function(Map<String, Object?> body)?
    debugFeedbackResponseOverride;

class FeedbackDraft {
  const FeedbackDraft({
    required this.type,
    required this.content,
    required this.contact,
    required this.platform,
    required this.appVersionName,
    required this.appVersionCode,
    required this.deviceInfo,
  });

  final String type;
  final String content;
  final String contact;
  final String platform;
  final String appVersionName;
  final int appVersionCode;
  final String deviceInfo;

  Map<String, Object?> toJson() {
    return {
      'type': type,
      'content': content,
      'contact': contact,
      'platform': platform,
      'appVersionName': appVersionName,
      'appVersionCode': appVersionCode,
      'deviceInfo': deviceInfo,
    };
  }
}

class FeedbackReceipt {
  const FeedbackReceipt({
    required this.id,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String status;
  final String createdAt;

  factory FeedbackReceipt.fromJson(Map<String, dynamic> json) {
    final feedback = json['feedback'] as Map<String, dynamic>? ?? {};
    return FeedbackReceipt(
      id: feedback['id'] as String? ?? '',
      status: feedback['status'] as String? ?? '',
      createdAt: feedback['createdAt'] as String? ?? '',
    );
  }
}
```

- [ ] **步骤 4：运行测试验证通过**

运行：

```powershell
flutter test test/feedback_api_test.dart
```

预期：PASS。

- [ ] **步骤 5：Commit**

```powershell
git add lib/api/pingsheng_api.dart test/feedback_api_test.dart
git commit -m "feat: add feedback api client"
```

---

### 任务 6：Flutter 问题反馈表单

**文件：**
- 修改：`lib/shared/module_info_sheets.dart`
- 测试：`test/widget_test.dart`

- [ ] **步骤 1：编写失败的表单校验测试**

在 `test/widget_test.dart` 追加：

```dart
testWidgets('feedback sheet validates content before submit', (tester) async {
  await pumpPingShengApp(tester);

  await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
  await tester.pumpAndSettle();

  final feedbackTile = find.text('问题反馈');
  await tester.scrollUntilVisible(
    feedbackTile,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(feedbackTile);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const ValueKey('feedback_submit')));
  await tester.pumpAndSettle();

  expect(find.text('请至少写 5 个字'), findsOneWidget);
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "feedback sheet validates content before submit"
```

预期：FAIL，找不到 `feedback_submit` 或校验文案。

- [ ] **步骤 3：重做 `_FeedbackSheet` 的本地状态和表单 UI**

在 `lib/shared/module_info_sheets.dart` 的 `_FeedbackSheetState` 替换为：

```dart
class _FeedbackSheetState extends State<_FeedbackSheet> {
  static const _api = _PingShengApi();
  static const _contactFallback = '客服联系方式：请在当前测试群或部署者提供的联系方式中反馈。';
  static const _types = ['问题', '建议', '崩溃', '界面显示', '数据异常', '其他'];

  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  String _type = _types.first;
  bool _submitting = false;
  String? _error;
  FeedbackReceipt? _receipt;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InfoSheetFrame(
      title: '问题反馈',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in _types)
                ChoiceChip(
                  key: ValueKey('feedback_type_$type'),
                  label: Text(type),
                  selected: _type == type,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('feedback_content'),
            controller: _contentController,
            minLines: 5,
            maxLines: 7,
            enabled: !_submitting,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: '写下你遇到的问题或想要的功能',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('feedback_contact'),
            controller: _contactController,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: '联系方式（选填，微信/手机号/邮箱）',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const ValueKey('feedback_submit'),
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _submitting ? '提交中...' : '提交反馈',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            EmptyCard(title: '提交失败', subtitle: _error!),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('feedback_copy_content'),
                  onPressed: _copyFeedbackContent,
                  child: const Text('复制反馈内容'),
                ),
                OutlinedButton(
                  key: const ValueKey('feedback_copy_contact'),
                  onPressed: _copyContactFallback,
                  child: const Text('复制联系方式'),
                ),
              ],
            ),
          ],
          if (_receipt != null) ...[
            const SizedBox(height: 14),
            EmptyCard(
              title: '已提交',
              subtitle: '反馈编号 ${_receipt!.id}，我们会尽快处理。',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.length < 5) {
      setState(() {
        _error = '请至少写 5 个字';
        _receipt = null;
      });
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _receipt = null;
    });
    try {
      final receipt = await _api.submitFeedback(
        FeedbackDraft(
          type: _type,
          content: content,
          contact: _contactController.text.trim(),
          platform: 'android',
          appVersionName: appVersionName,
          appVersionCode: appVersionCode,
          deviceInfo: defaultTargetPlatform.name,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _receipt = receipt);
    } on _ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _error = '提交失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _copyFeedbackContent() async {
    await Clipboard.setData(
      ClipboardData(
        text: '类型：$_type\n内容：${_contentController.text.trim()}\n联系方式：${_contactController.text.trim()}',
      ),
    );
  }

  Future<void> _copyContactFallback() async {
    await Clipboard.setData(const ClipboardData(text: _contactFallback));
  }
}
```

确保 `lib/shared/module_info_sheets.dart` 所属 library 已能访问 `Clipboard`、`defaultTargetPlatform`。如果当前 `shared.dart` 没有导入，需要在 `lib/shared/shared.dart` 增加：

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
```

- [ ] **步骤 4：运行校验测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "feedback sheet validates content before submit"
```

预期：PASS。

- [ ] **步骤 5：Commit**

```powershell
git add lib/shared/module_info_sheets.dart lib/shared/shared.dart test/widget_test.dart
git commit -m "feat: build feedback submission form"
```

---

### 任务 7：Flutter 提交成功和失败兜底测试

**文件：**
- 修改：`lib/app/app.dart` 或 `lib/shared/module_info_sheets.dart`
- 修改：`test/widget_test.dart`

- [ ] **步骤 1：确认测试注入入口存在**

确认任务 5 已在 `lib/api/pingsheng_api.dart` 中加入：

```dart
Future<Map<String, dynamic>> Function(Map<String, Object?> body)?
    debugFeedbackResponseOverride;
```

测试中统一使用 `addTearDown(() => debugFeedbackResponseOverride = null);`，避免影响其他用例。

- [ ] **步骤 2：编写成功和失败测试**

在 `test/widget_test.dart` 追加：

```dart
testWidgets('feedback sheet submits to server and shows receipt',
    (tester) async {
  debugFeedbackResponseOverride = (body) async {
    expect(body['type'], '问题');
    expect(body['content'], '小组件显示不全');
    return {
      'feedback': {
        'id': 'fb-123',
        'status': 'pending',
        'createdAt': '2026-07-06T10:00:00Z',
      },
    };
  };
  addTearDown(() => debugFeedbackResponseOverride = null);

  await pumpPingShengApp(tester);
  await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
  await tester.pumpAndSettle();
  final feedbackTile = find.text('问题反馈');
  await tester.scrollUntilVisible(
    feedbackTile,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(feedbackTile);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey('feedback_content')),
    '小组件显示不全',
  );
  await tester.tap(find.byKey(const ValueKey('feedback_submit')));
  await tester.pumpAndSettle();

  expect(find.text('已提交'), findsOneWidget);
  expect(find.textContaining('fb-123'), findsOneWidget);
});

testWidgets('feedback sheet keeps content and offers fallback after failure',
    (tester) async {
  debugFeedbackResponseOverride = (body) async {
    throw Exception('offline');
  };
  addTearDown(() => debugFeedbackResponseOverride = null);

  await pumpPingShengApp(tester);
  await tester.tap(find.byIcon(Icons.view_sidebar_rounded).first);
  await tester.pumpAndSettle();
  final feedbackTile = find.text('问题反馈');
  await tester.scrollUntilVisible(
    feedbackTile,
    180,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(feedbackTile);
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const ValueKey('feedback_content')),
    '服务器无法提交反馈',
  );
  await tester.tap(find.byKey(const ValueKey('feedback_submit')));
  await tester.pumpAndSettle();

  expect(find.text('提交失败'), findsOneWidget);
  expect(find.text('提交失败，请稍后重试。'), findsOneWidget);
  expect(find.byKey(const ValueKey('feedback_copy_content')), findsOneWidget);
  expect(find.byKey(const ValueKey('feedback_copy_contact')), findsOneWidget);
  expect(find.text('服务器无法提交反馈'), findsOneWidget);
});
```

- [ ] **步骤 3：运行测试验证失败**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "feedback sheet submits to server and shows receipt"
flutter test test/widget_test.dart --plain-name "feedback sheet keeps content and offers fallback after failure"
```

预期：如果任务 5 未加入 override，FAIL，提示 `debugFeedbackResponseOverride` 未定义；加入后应 PASS。

- [ ] **步骤 4：实现或修正 override 支持**

如果步骤 3 失败，按任务 5 的方案实现 `debugFeedbackResponseOverride`。失败用例的 override 使用普通 `Exception`：

```dart
debugFeedbackResponseOverride = (body) async {
  throw Exception('offline');
};
```

预期 UI 显示 `_FeedbackSheet._submit` catch-all 的 `提交失败，请稍后重试。`。

- [ ] **步骤 5：运行测试验证通过**

运行：

```powershell
flutter test test/widget_test.dart --plain-name "feedback sheet submits to server and shows receipt"
flutter test test/widget_test.dart --plain-name "feedback sheet keeps content and offers fallback after failure"
```

预期：全部 PASS。

- [ ] **步骤 6：Commit**

```powershell
git add lib/api/pingsheng_api.dart lib/shared/module_info_sheets.dart test/widget_test.dart
git commit -m "test: cover feedback submission states"
```

---

### 任务 8：全量验证与版本发布准备

**文件：**
- 修改：`pubspec.yaml`
- 修改：`lib/core/app_core.dart`

- [ ] **步骤 1：递增版本号**

将 `pubspec.yaml`：

```yaml
version: 1.0.59+60
```

改为：

```yaml
version: 1.0.60+61
```

将 `lib/core/app_core.dart`：

```dart
const String appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.59',
);
const int appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 60,
);
```

改为：

```dart
const String appVersionName = String.fromEnvironment(
  'PINGSHENG_APP_VERSION_NAME',
  defaultValue: '1.0.60',
);
const int appVersionCode = int.fromEnvironment(
  'PINGSHENG_APP_VERSION_CODE',
  defaultValue: 61,
);
```

- [ ] **步骤 2：运行全量服务端测试**

运行：

```powershell
go test ./server -v
```

预期：PASS。

- [ ] **步骤 3：运行 Flutter 静态检查和测试**

运行：

```powershell
flutter analyze
flutter test
```

预期：全部 PASS。

- [ ] **步骤 4：构建 release APK**

运行：

```powershell
flutter build apk --release
Copy-Item -LiteralPath build\app\outputs\flutter-apk\app-release.apk -Destination build\app\outputs\flutter-apk\pingsheng-1.0.60.apk -Force
```

预期：输出 `Built build\app\outputs\flutter-apk\app-release.apk`，并生成 `pingsheng-1.0.60.apk`。

- [ ] **步骤 5：Commit**

```powershell
git add pubspec.yaml lib/core/app_core.dart
git commit -m "chore: release 1.0.60"
```

---

### 任务 9：部署服务端、推送 APK 和验证更新

**文件：**
- 无源码修改，执行部署命令。

- [ ] **步骤 1：构建并上传服务端二进制**

运行：

```powershell
Push-Location server
go build -o pingsheng-life-server.exe .
Pop-Location
& 'C:\Program Files\PuTTY\pscp.exe' -batch -hostkey 'SHA256:qHC9tv6yZ9xBNW9PAMFkGA4kdWBTJsa9+hrlrgeZqyE' -pw 12345678 server\pingsheng-life-server.exe root@192.168.20.11:/opt/pingsheng-life-server/pingsheng-life-server.new
```

预期：上传完成。

- [ ] **步骤 2：替换服务端并重启**

运行：

```powershell
$remote = @'
set -e
systemctl stop pingsheng-life-server
mv /opt/pingsheng-life-server/pingsheng-life-server.new /opt/pingsheng-life-server/pingsheng-life-server
chmod +x /opt/pingsheng-life-server/pingsheng-life-server
systemctl start pingsheng-life-server
systemctl --no-pager --full status pingsheng-life-server
'@
& 'C:\Program Files\PuTTY\plink.exe' -batch -hostkey 'SHA256:qHC9tv6yZ9xBNW9PAMFkGA4kdWBTJsa9+hrlrgeZqyE' -pw 12345678 root@192.168.20.11 $remote
```

预期：服务状态为 `active (running)`。

- [ ] **步骤 3：上传 APK**

运行：

```powershell
& 'C:\Program Files\PuTTY\pscp.exe' -batch -hostkey 'SHA256:qHC9tv6yZ9xBNW9PAMFkGA4kdWBTJsa9+hrlrgeZqyE' -pw 12345678 build\app\outputs\flutter-apk\pingsheng-1.0.60.apk root@192.168.20.11:/opt/pingsheng-life-server/downloads/pingsheng-1.0.60.apk
```

预期：上传完成。

- [ ] **步骤 4：更新服务器 update policy**

运行：

```powershell
$remote = @'
set -e
set -a
. /etc/pingsheng-life-server/env
set +a
curl -s -X PUT http://127.0.0.1:3000/v1/admin/update-policy \
  -H "Content-Type: application/json" \
  -H "X-Admin-Token: ${ADMIN_TOKEN}" \
  --data-binary '{"latestVersionCode":61,"latestVersionName":"1.0.60","minSupportedVersionCode":58,"downloadUrl":"http://192.168.20.11:3000/downloads/pingsheng-1.0.60.apk","releaseNotes":["新增问题反馈真实提交到服务器。","新增反馈失败复制兜底，避免反馈内容丢失。","新增服务端反馈后台页面，可查看和处理用户反馈。"],"message":"发现新版本，建议更新。"}'
'@
& 'C:\Program Files\PuTTY\plink.exe' -batch -hostkey 'SHA256:qHC9tv6yZ9xBNW9PAMFkGA4kdWBTJsa9+hrlrgeZqyE' -pw 12345678 root@192.168.20.11 $remote
```

预期：返回 `latestVersionCode: 61`。

- [ ] **步骤 5：验证线上接口**

运行：

```powershell
curl.exe -s "http://192.168.20.11:3000/v1/app/update?platform=android&versionCode=60&versionName=1.0.59"
curl.exe -L -s -o NUL -w "status=%{http_code} size=%{size_download} type=%{content_type}\n" "http://192.168.20.11:3000/downloads/pingsheng-1.0.60.apk"
curl.exe -s -X POST "http://192.168.20.11:3000/v1/feedback" -H "Content-Type: application/json" --data-binary "{\"type\":\"问题\",\"content\":\"部署后反馈接口验证\",\"platform\":\"android\",\"appVersionName\":\"1.0.60\",\"appVersionCode\":61,\"deviceInfo\":\"curl\"}"
```

预期：

- 更新接口返回 `hasUpdate: true`。
- APK 下载返回 `status=200`。
- 反馈提交返回 `feedback.id` 和 `status: pending`。

- [ ] **步骤 6：打开后台页面手工验证**

浏览器打开：

```text
http://192.168.20.11:3000/admin/feedback
```

输入服务器 `/etc/pingsheng-life-server/env` 中的 `ADMIN_TOKEN`，确认能看到刚才 curl 提交的反馈，并能标记为“处理中”。

- [ ] **步骤 7：推送 GitHub**

运行：

```powershell
git status --short --branch
git push origin main
```

预期：`main...origin/main` 同步，无未提交源码改动。

---

## 自检清单

- 规格中的 App 表单、提交失败兜底、服务端保存、管理员后台、状态更新、测试和发布验证均有对应任务。
- 计划没有使用空白占位语句作为实现步骤。
- Go 类型统一使用 `feedbackItem`，状态统一为 `pending`、`processing`、`resolved`、`archived`。
- Flutter 类型统一使用 `FeedbackDraft` 和 `FeedbackReceipt`，测试注入统一使用 `debugFeedbackResponseOverride`。
- 第一版不包含截图上传、客服聊天、多管理员账号或推送通知。
