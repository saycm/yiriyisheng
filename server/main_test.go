// 中文注释：Go 服务端测试，负责验证认证、更新策略和下载接口。

package main

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

// testApp 封装测试服务器和它使用的临时数据路径。
type testApp struct {
	server       *httptest.Server
	dataFile     string
	databaseFile string
	downloadDir  string
}

// newTestApp 创建不带旧数据的隔离测试服务。
func newTestApp(t *testing.T) *testApp {
	return newTestAppWithLegacyDB(t, nil)
}

// newTestAppWithLegacyDB 创建隔离测试服务，并可预置旧版 JSON 数据。
func newTestAppWithLegacyDB(t *testing.T, legacyDB *dbFile) *testApp {
	t.Helper()
	tempDir := t.TempDir()
	app := &testApp{
		dataFile:     filepath.Join(tempDir, "db.json"),
		databaseFile: filepath.Join(tempDir, "pingsheng-life.db"),
		downloadDir:  filepath.Join(tempDir, "downloads"),
	}
	if legacyDB != nil {
		raw, err := json.MarshalIndent(legacyDB, "", "  ")
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(app.dataFile, append(raw, '\n'), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	t.Setenv("DATA_FILE", app.dataFile)
	t.Setenv("DATABASE_FILE", app.databaseFile)
	t.Setenv("DOWNLOAD_DIR", app.downloadDir)
	t.Setenv("TOKEN_SECRET", "test-token-secret")
	t.Setenv("ADMIN_TOKEN", "test-admin-token")
	t.Setenv("ACCESS_TOKEN_TTL_SECONDS", "900")
	t.Setenv("REFRESH_TOKEN_TTL_DAYS", "30")
	app.server = httptest.NewServer(routes())
	t.Cleanup(app.server.Close)
	return app
}

// jsonRequest 发送 JSON 请求并解析状态码和响应对象。
func (app *testApp) jsonRequest(t *testing.T, method string, path string, body any, headers map[string]string) (int, map[string]any) {
	t.Helper()
	var reader io.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(raw)
	}
	req, err := http.NewRequest(method, app.server.URL+path, reader)
	if err != nil {
		t.Fatal(err)
	}
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	for key, value := range headers {
		req.Header.Set(key, value)
	}
	res, err := app.server.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	raw, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	var payload map[string]any
	if len(bytes.TrimSpace(raw)) > 0 {
		if err := json.Unmarshal(raw, &payload); err != nil {
			t.Fatalf("invalid response JSON: %s", raw)
		}
	}
	return res.StatusCode, payload
}

// chunkedJSONRequest 用分块传输发送 POST 请求，验证服务端兼容性。
func (app *testApp) chunkedJSONRequest(t *testing.T, path string, body any) (int, map[string]any) {
	t.Helper()
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	req, err := http.NewRequest(http.MethodPost, app.server.URL+path, bytes.NewReader(raw))
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.ContentLength = -1
	req.TransferEncoding = []string{"chunked"}

	res, err := app.server.Client().Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	responseRaw, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	var payload map[string]any
	if err := json.Unmarshal(responseRaw, &payload); err != nil {
		t.Fatalf("invalid response JSON: %s", responseRaw)
	}
	return res.StatusCode, payload
}

// TestAuthEmailMeAndRefresh 验证邮箱注册、当前用户查询和刷新令牌轮换。
func TestAuthEmailMeAndRefresh(t *testing.T) {
	app := newTestApp(t)

	status, payload := app.jsonRequest(t, http.MethodPost, "/v1/auth/register/email", map[string]any{
		"email":       " Alice。Example@Example.COM ",
		"password":    "secret123",
		"displayName": "Alice",
	}, nil)
	if status != http.StatusCreated {
		t.Fatalf("register status = %d, payload = %#v", status, payload)
	}
	user := payload["user"].(map[string]any)
	if user["email"] != "alice.example@example.com" {
		t.Fatalf("email was not normalized: %#v", user["email"])
	}

	accessToken := payload["accessToken"].(string)
	refreshToken := payload["refreshToken"].(string)
	status, payload = app.jsonRequest(t, http.MethodGet, "/v1/me", nil, map[string]string{
		"Authorization": "Bearer " + accessToken,
	})
	if status != http.StatusOK {
		t.Fatalf("me status = %d, payload = %#v", status, payload)
	}

	status, payload = app.jsonRequest(t, http.MethodPost, "/v1/auth/refresh", map[string]any{
		"refreshToken": refreshToken,
	}, nil)
	if status != http.StatusOK {
		t.Fatalf("refresh status = %d, payload = %#v", status, payload)
	}

	status, _ = app.jsonRequest(t, http.MethodPost, "/v1/auth/refresh", map[string]any{
		"refreshToken": refreshToken,
	}, nil)
	if status != http.StatusUnauthorized {
		t.Fatalf("old refresh token should be rotated, status = %d", status)
	}
}

// TestPhoneRegistrationAcceptsChunkedJSON 验证手机号注册支持 chunked JSON 请求体。
func TestPhoneRegistrationAcceptsChunkedJSON(t *testing.T) {
	app := newTestApp(t)

	status, payload := app.chunkedJSONRequest(t, "/v1/auth/register/phone", map[string]any{
		"phone":       "+86 138-0013-8000",
		"password":    "secret123",
		"displayName": "Phone",
	})
	if status != http.StatusCreated {
		t.Fatalf("register phone status = %d, payload = %#v", status, payload)
	}
	user := payload["user"].(map[string]any)
	if user["phone"] != "13800138000" {
		t.Fatalf("phone was not normalized: %#v", user["phone"])
	}
}

// TestMigratesLegacyJSONToSQLite 验证旧 JSON 数据首次启动时迁移到 SQLite。
func TestMigratesLegacyJSONToSQLite(t *testing.T) {
	email := "legacy@example.com"
	passwordHash, err := hashPassword("secret123")
	if err != nil {
		t.Fatal(err)
	}
	app := newTestAppWithLegacyDB(t, &dbFile{
		Users: []user{
			{
				ID:           "legacy-user",
				Email:        &email,
				DisplayName:  "Legacy",
				PasswordHash: passwordHash,
				CreatedAt:    "2026-01-02T03:04:05Z",
				UpdatedAt:    "2026-01-02T03:04:05Z",
			},
		},
		RefreshTokens: []refreshToken{},
		UpdatePolicy: updatePolicy{
			Platform:                "android",
			LatestVersionCode:       9,
			LatestVersionName:       "1.0.9",
			MinSupportedVersionCode: 8,
			DownloadURL:             "http://example.com/downloads/legacy.apk",
			ReleaseNotes:            []string{"legacy import"},
			Message:                 "legacy policy",
			UpdatedAt:               "2026-01-03T03:04:05Z",
		},
	})

	status, payload := app.jsonRequest(t, http.MethodPost, "/v1/auth/login/email", map[string]any{
		"email":    "legacy@example.com",
		"password": "secret123",
	}, nil)
	if status != http.StatusOK {
		t.Fatalf("legacy login status = %d, payload = %#v", status, payload)
	}
	user := payload["user"].(map[string]any)
	if user["id"] != "legacy-user" {
		t.Fatalf("legacy user was not imported: %#v", user)
	}
	if _, err := os.Stat(app.databaseFile); err != nil {
		t.Fatalf("sqlite database was not created: %v", err)
	}

	status, payload = app.jsonRequest(t, http.MethodGet, "/v1/app/update?platform=android&versionCode=8&versionName=1.0.8", nil, nil)
	if status != http.StatusOK {
		t.Fatalf("check update status = %d, payload = %#v", status, payload)
	}
	if payload["latestVersionCode"] != float64(9) || payload["downloadUrl"] != "http://example.com/downloads/legacy.apk" {
		t.Fatalf("legacy update policy was not imported: %#v", payload)
	}
}

// TestUpdatePolicy 验证更新检查结果和管理员策略更新。
func TestUpdatePolicy(t *testing.T) {
	app := newTestApp(t)

	status, _ := app.jsonRequest(t, http.MethodPut, "/v1/admin/update-policy", map[string]any{
		"latestVersionCode":       7,
		"latestVersionName":       "1.0.7",
		"minSupportedVersionCode": 6,
	}, nil)
	if status != http.StatusUnauthorized {
		t.Fatalf("missing admin token status = %d", status)
	}

	status, payload := app.jsonRequest(t, http.MethodPut, "/v1/admin/update-policy", map[string]any{
		"latestVersionCode":       7,
		"latestVersionName":       "1.0.7",
		"minSupportedVersionCode": 6,
		"downloadUrl":             "http://example.com/downloads/app.apk",
		"releaseNotes":            []string{"Go server"},
		"message":                 "请更新。",
	}, map[string]string{"X-Admin-Token": "test-admin-token"})
	if status != http.StatusOK {
		t.Fatalf("update policy status = %d, payload = %#v", status, payload)
	}

	status, payload = app.jsonRequest(t, http.MethodGet, "/v1/app/update?platform=android&versionCode=5&versionName=1.0.5", nil, nil)
	if status != http.StatusOK {
		t.Fatalf("check update status = %d, payload = %#v", status, payload)
	}
	if payload["hasUpdate"] != true || payload["forceUpdate"] != true {
		t.Fatalf("unexpected update response: %#v", payload)
	}
}

// TestDownloadAPK 验证 APK 下载、HEAD 请求和路径穿越防护。
func TestDownloadAPK(t *testing.T) {
	app := newTestApp(t)
	if err := os.MkdirAll(app.downloadDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(app.downloadDir, "pingsheng-test.apk"), []byte("apk"), 0o644); err != nil {
		t.Fatal(err)
	}

	res, err := app.server.Client().Get(app.server.URL + "/downloads/pingsheng-test.apk")
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	raw, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	if res.StatusCode != http.StatusOK || string(raw) != "apk" {
		t.Fatalf("download status = %d body = %q", res.StatusCode, raw)
	}

	head, err := app.server.Client().Head(app.server.URL + "/downloads/pingsheng-test.apk")
	if err != nil {
		t.Fatal(err)
	}
	defer head.Body.Close()
	raw, err = io.ReadAll(head.Body)
	if err != nil {
		t.Fatal(err)
	}
	if head.StatusCode != http.StatusOK {
		t.Fatalf("head download status = %d", head.StatusCode)
	}
	if head.Header.Get("Content-Type") != "application/vnd.android.package-archive" {
		t.Fatalf("head download content type = %q", head.Header.Get("Content-Type"))
	}
	if head.ContentLength != 3 {
		t.Fatalf("head download content length = %d", head.ContentLength)
	}
	if len(raw) != 0 {
		t.Fatalf("head download body = %q", raw)
	}
}
