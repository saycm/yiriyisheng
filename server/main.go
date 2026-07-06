// 中文注释：Go 服务端入口，负责认证、更新策略、APK 下载和数据持久化接口。

package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/pbkdf2"
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"hash"
	"io"
	"log"
	"math"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode"

	_ "modernc.org/sqlite"
)

const (
	defaultDataFile            = "data/db.json"
	defaultDatabaseFile        = "data/pingsheng-life.db"
	defaultDownloadDir         = "downloads"
	defaultTokenSecret         = "change-this-dev-token-secret"
	defaultAdminToken          = "change-this-admin-token"
	defaultAccessTokenTTL      = 900
	defaultRefreshTokenTTLDays = 30
	maxBodyBytes               = 1024 * 1024
)

var (
	emailRE          = regexp.MustCompile(`^[^@\s]+@[^@\s]+\.[^@\s]+$`)
	phoneRE          = regexp.MustCompile(`^1[0-9]{10}$`)
	hiddenWhitespace = regexp.MustCompile(`[\s\x{00A0}\x{200B}-\x{200D}\x{FEFF}\x{3000}]`)
	phoneRemovable   = regexp.MustCompile(`[\s\x{00A0}\x{200B}-\x{200D}\x{FEFF}\x{3000}\-()（）]`)
	// 这个服务是单进程部署，写库前用互斥锁保护“读-改-写”完整事务。
	dbMu sync.Mutex
)

type apiError struct {
	Status  int
	Code    string
	Message string
}

func (e apiError) Error() string {
	return e.Message
}

type dbFile struct {
	Users         []user         `json:"users"`
	RefreshTokens []refreshToken `json:"refreshTokens"`
	UpdatePolicy  updatePolicy   `json:"updatePolicy"`
}

type user struct {
	ID           string  `json:"id"`
	Email        *string `json:"email"`
	Phone        *string `json:"phone"`
	DisplayName  string  `json:"displayName"`
	PasswordHash string  `json:"passwordHash"`
	CreatedAt    string  `json:"createdAt"`
	UpdatedAt    string  `json:"updatedAt"`
}

type publicUser struct {
	ID          string  `json:"id"`
	Email       *string `json:"email"`
	Phone       *string `json:"phone"`
	DisplayName string  `json:"displayName"`
	CreatedAt   string  `json:"createdAt"`
	UpdatedAt   string  `json:"updatedAt"`
}

type refreshToken struct {
	ID        string `json:"id"`
	UserID    string `json:"userId"`
	TokenHash string `json:"tokenHash"`
	CreatedAt string `json:"createdAt"`
	ExpiresAt string `json:"expiresAt"`
}

type updatePolicy struct {
	Platform                string   `json:"platform"`
	LatestVersionCode       int      `json:"latestVersionCode"`
	LatestVersionName       string   `json:"latestVersionName"`
	MinSupportedVersionCode int      `json:"minSupportedVersionCode"`
	DownloadURL             string   `json:"downloadUrl"`
	ReleaseNotes            []string `json:"releaseNotes"`
	Message                 string   `json:"message"`
	UpdatedAt               string   `json:"updatedAt"`
}

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

type tokenPair struct {
	AccessToken           string `json:"accessToken"`
	TokenType             string `json:"tokenType"`
	ExpiresIn             int    `json:"expiresIn"`
	RefreshToken          string `json:"refreshToken"`
	RefreshTokenExpiresAt string `json:"refreshTokenExpiresAt"`
}

type accessPayload struct {
	Subject string `json:"sub"`
	Type    string `json:"type"`
	Issued  int64  `json:"iat"`
	Expires int64  `json:"exp"`
}

func main() {
	if tokenSecret() == defaultTokenSecret {
		log.Println("Warning: TOKEN_SECRET is using the development default.")
	}
	if adminToken() == defaultAdminToken {
		log.Println("Warning: ADMIN_TOKEN is using the development default.")
	}

	addr := ":" + envString("PORT", "3000")
	log.Printf("PingSheng Life Go server listening on http://0.0.0.0%s", addr)
	if err := http.ListenAndServe(addr, routes()); err != nil {
		log.Fatal(err)
	}
}

func routes() http.Handler {
	mux := http.NewServeMux()
	// 所有 API 先进入统一入口，便于集中处理 CORS、错误格式和 404。
	mux.HandleFunc("/", handleAPI)
	return corsMiddleware(mux)
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		addCORSHeaders(w)
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func handleAPI(w http.ResponseWriter, r *http.Request) {
	if err := routeAPI(w, r); err != nil {
		var apiErr apiError
		if errors.As(err, &apiErr) {
			// 业务错误直接返回给 App，客户端会显示其中的中文 message。
			sendJSON(w, apiErr.Status, map[string]any{
				"error": map[string]any{
					"code":    apiErr.Code,
					"message": apiErr.Message,
				},
			})
			return
		}
		// 未预期错误只记录服务端日志，避免把内部路径或 SQL 信息暴露给客户端。
		log.Printf("internal_error: %v", err)
		sendJSON(w, http.StatusInternalServerError, map[string]any{
			"error": map[string]any{
				"code":    "internal_error",
				"message": "Internal server error.",
			},
		})
	}
}

func routeAPI(w http.ResponseWriter, r *http.Request) error {
	path := r.URL.Path
	switch {
	// 路由表故意集中在一个 switch 中，方便小型服务快速查看所有公开接口。
	case r.Method == http.MethodGet && path == "/health":
		sendJSON(w, http.StatusOK, map[string]any{
			"ok":        true,
			"service":   "pingsheng-life-server",
			"runtime":   "go",
			"timestamp": nowISO(),
		})
	case r.Method == http.MethodPost && path == "/v1/auth/register/email":
		return register(w, r, "email")
	case r.Method == http.MethodPost && path == "/v1/auth/register/phone":
		return register(w, r, "phone")
	case r.Method == http.MethodPost && path == "/v1/auth/login/email":
		return login(w, r, "email")
	case r.Method == http.MethodPost && path == "/v1/auth/login/phone":
		return login(w, r, "phone")
	case r.Method == http.MethodPost && path == "/v1/auth/refresh":
		return refresh(w, r)
	case r.Method == http.MethodPost && path == "/v1/auth/logout":
		return logout(w, r)
	case r.Method == http.MethodGet && path == "/v1/me":
		return me(w, r)
	case (r.Method == http.MethodGet || r.Method == http.MethodPost) && path == "/v1/app/update":
		return checkUpdate(w, r)
	case r.Method == http.MethodPut && path == "/v1/admin/update-policy":
		return updatePolicyHandler(w, r)
	case r.Method == http.MethodGet && strings.HasPrefix(path, "/downloads/"):
		return serveDownload(w, r)
	default:
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Route not found."}
	}
	return nil
}

func register(w http.ResponseWriter, r *http.Request, kind string) error {
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	identifier, err := normalizeIdentifier(body, kind)
	if err != nil {
		return err
	}
	password, err := validatePassword(stringValue(body["password"]))
	if err != nil {
		return err
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	// 注册是“校验唯一性 -> 建用户 -> 发 token -> 落库”的原子流程。
	db, err := readDB()
	if err != nil {
		return err
	}
	if findUserIndex(db.Users, kind, identifier) != -1 {
		return apiError{Status: http.StatusConflict, Code: "account_exists", Message: "这个账号已经注册过，可以切换到登录。"}
	}
	user := makeUser(kind, identifier, password, stringValue(body["displayName"]))
	db.Users = append(db.Users, user)
	tokens, err := issueTokenPair(&db, user)
	if err != nil {
		return err
	}
	if err := writeDB(db); err != nil {
		return err
	}
	sendJSON(w, http.StatusCreated, authResponse(user, tokens))
	return nil
}

func login(w http.ResponseWriter, r *http.Request, kind string) error {
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	identifier, err := normalizeIdentifier(body, kind)
	if err != nil {
		return err
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := readDB()
	if err != nil {
		return err
	}
	index := findUserIndex(db.Users, kind, identifier)
	if index == -1 || !verifyPassword(stringValue(body["password"]), db.Users[index].PasswordHash) {
		return apiError{Status: http.StatusUnauthorized, Code: "invalid_credentials", Message: "账号或密码不正确。"}
	}
	tokens, err := issueTokenPair(&db, db.Users[index])
	if err != nil {
		return err
	}
	if err := writeDB(db); err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, authResponse(db.Users[index], tokens))
	return nil
}

func refresh(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	tokenHash := hashRefreshToken(stringValue(body["refreshToken"]))

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := readDB()
	if err != nil {
		return err
	}
	cleanExpiredRefreshTokens(&db)
	tokenIndex := -1
	for i, token := range db.RefreshTokens {
		if token.TokenHash == tokenHash {
			tokenIndex = i
			break
		}
	}
	if tokenIndex == -1 {
		_ = writeDB(db)
		return apiError{Status: http.StatusUnauthorized, Code: "invalid_refresh_token", Message: "Refresh token is invalid or expired."}
	}
	userIndex := -1
	for i, item := range db.Users {
		if item.ID == db.RefreshTokens[tokenIndex].UserID {
			userIndex = i
			break
		}
	}
	// Refresh token 只允许使用一次：旧 token 删除，再签发一组新 token。
	db.RefreshTokens = append(db.RefreshTokens[:tokenIndex], db.RefreshTokens[tokenIndex+1:]...)
	if userIndex == -1 {
		_ = writeDB(db)
		return apiError{Status: http.StatusUnauthorized, Code: "invalid_refresh_token", Message: "Refresh token is invalid or expired."}
	}
	tokens, err := issueTokenPair(&db, db.Users[userIndex])
	if err != nil {
		return err
	}
	if err := writeDB(db); err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, authResponse(db.Users[userIndex], tokens))
	return nil
}

func logout(w http.ResponseWriter, r *http.Request) error {
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}
	tokenHash := hashRefreshToken(stringValue(body["refreshToken"]))

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := readDB()
	if err != nil {
		return err
	}
	filtered := db.RefreshTokens[:0]
	for _, token := range db.RefreshTokens {
		if token.TokenHash != tokenHash {
			filtered = append(filtered, token)
		}
	}
	db.RefreshTokens = filtered
	if err := writeDB(db); err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, map[string]any{"ok": true})
	return nil
}

func me(w http.ResponseWriter, r *http.Request) error {
	token := strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "))
	if token == "" || token == r.Header.Get("Authorization") {
		return apiError{Status: http.StatusUnauthorized, Code: "missing_token", Message: "Bearer token is required."}
	}
	payload, err := verifyAccessToken(token)
	if err != nil {
		return err
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := readDB()
	if err != nil {
		return err
	}
	for _, item := range db.Users {
		if item.ID == payload.Subject {
			sendJSON(w, http.StatusOK, map[string]any{"user": publicUserFrom(item)})
			return nil
		}
	}
	return apiError{Status: http.StatusUnauthorized, Code: "invalid_token", Message: "Bearer token is invalid."}
}

func checkUpdate(w http.ResponseWriter, r *http.Request) error {
	input := map[string]any{}
	// 支持 GET 查询和 POST JSON 两种形式，方便 App 与脚本共用同一接口。
	for key, values := range r.URL.Query() {
		if len(values) > 0 {
			input[key] = values[len(values)-1]
		}
	}
	if r.Method == http.MethodPost {
		body, err := readJSONBody(r)
		if err != nil {
			return err
		}
		input = body
	}
	versionCode := parseVersionCode(input["versionCode"])
	if versionCode == nil {
		versionCode = parseVersionCode(input["currentVersionCode"])
	}
	if versionCode == nil {
		return apiError{Status: http.StatusBadRequest, Code: "invalid_version_code", Message: "versionCode must be a non-negative integer."}
	}

	dbMu.Lock()
	db, err := readDB()
	dbMu.Unlock()
	if err != nil {
		return err
	}
	policy := db.UpdatePolicy
	sendJSON(w, http.StatusOK, map[string]any{
		"platform":                strings.ToLower(strings.TrimSpace(defaultIfEmpty(stringValue(input["platform"]), "android"))),
		"currentVersionCode":      *versionCode,
		"currentVersionName":      defaultIfEmpty(stringValue(input["versionName"]), stringValue(input["currentVersionName"])),
		"latestVersionCode":       policy.LatestVersionCode,
		"latestVersionName":       policy.LatestVersionName,
		"minSupportedVersionCode": policy.MinSupportedVersionCode,
		"hasUpdate":               *versionCode < policy.LatestVersionCode,
		"forceUpdate":             *versionCode < policy.MinSupportedVersionCode,
		"downloadUrl":             policy.DownloadURL,
		"releaseNotes":            policy.ReleaseNotes,
		"message":                 policy.Message,
		"updatedAt":               policy.UpdatedAt,
	})
	return nil
}

func updatePolicyHandler(w http.ResponseWriter, r *http.Request) error {
	if r.Header.Get("X-Admin-Token") != adminToken() {
		return apiError{Status: http.StatusUnauthorized, Code: "admin_unauthorized", Message: "Admin token is missing or invalid."}
	}
	body, err := readJSONBody(r)
	if err != nil {
		return err
	}

	dbMu.Lock()
	defer dbMu.Unlock()

	db, err := readDB()
	if err != nil {
		return err
	}
	db.UpdatePolicy = sanitizeUpdatePolicy(body, db.UpdatePolicy, false)
	if err := writeDB(db); err != nil {
		return err
	}
	sendJSON(w, http.StatusOK, map[string]any{"updatePolicy": db.UpdatePolicy})
	return nil
}

func serveDownload(w http.ResponseWriter, r *http.Request) error {
	name, err := url.PathUnescape(strings.TrimPrefix(r.URL.Path, "/downloads/"))
	if err != nil {
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Download not found."}
	}
	name = strings.TrimSpace(name)
	if name == "" || strings.ContainsAny(name, `/\`) || !strings.HasSuffix(name, ".apk") {
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Download not found."}
	}
	// 下载接口只允许取 downloadDir 内的 apk，防止通过路径穿越读取其他文件。
	dir, err := filepath.Abs(downloadDir())
	if err != nil {
		return err
	}
	filePath, err := filepath.Abs(filepath.Join(dir, name))
	if err != nil {
		return err
	}
	if filepath.Dir(filePath) != dir {
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Download not found."}
	}
	stat, err := os.Stat(filePath)
	if err != nil || stat.IsDir() {
		return apiError{Status: http.StatusNotFound, Code: "not_found", Message: "Download not found."}
	}
	w.Header().Set("Content-Type", "application/vnd.android.package-archive")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filepath.Base(filePath)))
	http.ServeFile(w, r, filePath)
	return nil
}

func readJSONBody(r *http.Request) (map[string]any, error) {
	if r.Body == nil {
		return map[string]any{}, nil
	}
	defer r.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(r.Body, maxBodyBytes+1))
	if err != nil {
		return nil, err
	}
	if len(raw) > maxBodyBytes {
		return nil, apiError{Status: http.StatusRequestEntityTooLarge, Code: "body_too_large", Message: "Request body is too large."}
	}
	if len(bytes.TrimSpace(raw)) == 0 {
		return map[string]any{}, nil
	}
	var body map[string]any
	if err := json.Unmarshal(raw, &body); err != nil {
		return nil, apiError{Status: http.StatusBadRequest, Code: "invalid_json", Message: "Request body must be valid JSON."}
	}
	return body, nil
}

func sendJSON(w http.ResponseWriter, status int, payload any) {
	raw, err := json.Marshal(payload)
	if err != nil {
		status = http.StatusInternalServerError
		raw = []byte(`{"error":{"code":"internal_error","message":"Internal server error."}}`)
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(len(raw)+1))
	w.WriteHeader(status)
	_, _ = w.Write(append(raw, '\n'))
}

func addCORSHeaders(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET,POST,PUT,OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Admin-Token")
}

func readDB() (dbFile, error) {
	// 对外仍返回 dbFile 结构，内部已经从旧 JSON 文件迁移到 SQLite。
	db, err := openDataDB()
	if err != nil {
		return dbFile{}, err
	}
	defer db.Close()
	return readSQLiteDB(db)
}

func writeDB(db dbFile) error {
	sqlDB, err := openDataDB()
	if err != nil {
		return err
	}
	defer sqlDB.Close()

	tx, err := sqlDB.Begin()
	if err != nil {
		return err
	}
	if err := replaceDBInTx(tx, db); err != nil {
		_ = tx.Rollback()
		return err
	}
	if err := setMetaTx(tx, "legacy_json_migrated", "1"); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

func openDataDB() (*sql.DB, error) {
	path := databaseFile()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	db.SetMaxOpenConns(1)
	// modernc sqlite 是纯 Go 驱动，单连接能减少文件锁争用。
	if err := initSQLite(db); err != nil {
		_ = db.Close()
		return nil, err
	}
	return db, nil
}

func initSQLite(db *sql.DB) error {
	// 表结构在启动时幂等创建，部署新版本不需要额外迁移命令。
	statements := []string{
		`PRAGMA foreign_keys = ON`,
		`PRAGMA busy_timeout = 5000`,
		`CREATE TABLE IF NOT EXISTS users (
			id TEXT PRIMARY KEY,
			email TEXT UNIQUE,
			phone TEXT UNIQUE,
			display_name TEXT NOT NULL,
			password_hash TEXT NOT NULL,
			created_at TEXT NOT NULL,
			updated_at TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS refresh_tokens (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			token_hash TEXT NOT NULL UNIQUE,
			created_at TEXT NOT NULL,
			expires_at TEXT NOT NULL,
			FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
		)`,
		`CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id)`,
		`CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at)`,
		`CREATE TABLE IF NOT EXISTS update_policy (
			id INTEGER PRIMARY KEY CHECK (id = 1),
			platform TEXT NOT NULL,
			latest_version_code INTEGER NOT NULL,
			latest_version_name TEXT NOT NULL,
			min_supported_version_code INTEGER NOT NULL,
			download_url TEXT NOT NULL,
			release_notes_json TEXT NOT NULL,
			message TEXT NOT NULL,
			updated_at TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS app_meta (
			key TEXT PRIMARY KEY,
			value TEXT NOT NULL
		)`,
		`CREATE TABLE IF NOT EXISTS feedback_items (
			id TEXT PRIMARY KEY NOT NULL,
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
	}
	for _, statement := range statements {
		if _, err := db.Exec(statement); err != nil {
			return err
		}
	}
	if err := migrateLegacyJSON(db); err != nil {
		return err
	}
	return ensureUpdatePolicy(db)
}

func migrateLegacyJSON(db *sql.DB) error {
	// 旧版本用 data/db.json；首次打开空 SQLite 时迁移一次，随后写 meta 标记。
	value, ok, err := metaValue(db, "legacy_json_migrated")
	if err != nil {
		return err
	}
	if ok && value == "1" {
		return nil
	}

	hasData, err := sqliteHasData(db)
	if err != nil {
		return err
	}
	if hasData {
		return setMeta(db, "legacy_json_migrated", "1")
	}

	legacyDB, ok, err := readLegacyDBFile(dataFile())
	if err != nil {
		return err
	}
	if !ok {
		return setMeta(db, "legacy_json_migrated", "1")
	}

	tx, err := db.Begin()
	if err != nil {
		return err
	}
	if err := replaceDBInTx(tx, legacyDB); err != nil {
		_ = tx.Rollback()
		return err
	}
	if err := setMetaTx(tx, "legacy_json_migrated", "1"); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

func readLegacyDBFile(path string) (dbFile, bool, error) {
	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return dbFile{}, false, nil
	} else if err != nil {
		return dbFile{}, false, err
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return dbFile{}, false, err
	}
	var db dbFile
	if err := json.Unmarshal(raw, &db); err != nil {
		return dbFile{}, false, err
	}
	return normalizeDBFile(db), true, nil
}

func readSQLiteDB(db *sql.DB) (dbFile, error) {
	// 读取时重新组装成历史 dbFile 结构，让认证和更新逻辑不用关心底层存储。
	result := dbFile{
		Users:         []user{},
		RefreshTokens: []refreshToken{},
	}

	userRows, err := db.Query(`SELECT id, email, phone, display_name, password_hash, created_at, updated_at FROM users ORDER BY created_at, id`)
	if err != nil {
		return dbFile{}, err
	}
	defer userRows.Close()
	for userRows.Next() {
		var item user
		var email sql.NullString
		var phone sql.NullString
		if err := userRows.Scan(
			&item.ID,
			&email,
			&phone,
			&item.DisplayName,
			&item.PasswordHash,
			&item.CreatedAt,
			&item.UpdatedAt,
		); err != nil {
			return dbFile{}, err
		}
		if email.Valid {
			value := email.String
			item.Email = &value
		}
		if phone.Valid {
			value := phone.String
			item.Phone = &value
		}
		result.Users = append(result.Users, item)
	}
	if err := userRows.Err(); err != nil {
		return dbFile{}, err
	}

	tokenRows, err := db.Query(`SELECT id, user_id, token_hash, created_at, expires_at FROM refresh_tokens ORDER BY created_at, id`)
	if err != nil {
		return dbFile{}, err
	}
	defer tokenRows.Close()
	for tokenRows.Next() {
		var token refreshToken
		if err := tokenRows.Scan(&token.ID, &token.UserID, &token.TokenHash, &token.CreatedAt, &token.ExpiresAt); err != nil {
			return dbFile{}, err
		}
		result.RefreshTokens = append(result.RefreshTokens, token)
	}
	if err := tokenRows.Err(); err != nil {
		return dbFile{}, err
	}

	policy, err := readUpdatePolicy(db)
	if err != nil {
		return dbFile{}, err
	}
	result.UpdatePolicy = policy
	return normalizeDBFile(result), nil
}

func readUpdatePolicy(db *sql.DB) (updatePolicy, error) {
	var policy updatePolicy
	var notesJSON string
	err := db.QueryRow(`SELECT platform, latest_version_code, latest_version_name, min_supported_version_code, download_url, release_notes_json, message, updated_at FROM update_policy WHERE id = 1`).Scan(
		&policy.Platform,
		&policy.LatestVersionCode,
		&policy.LatestVersionName,
		&policy.MinSupportedVersionCode,
		&policy.DownloadURL,
		&notesJSON,
		&policy.Message,
		&policy.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return defaultDB().UpdatePolicy, nil
	}
	if err != nil {
		return updatePolicy{}, err
	}
	if err := json.Unmarshal([]byte(notesJSON), &policy.ReleaseNotes); err != nil {
		return updatePolicy{}, err
	}
	return policy, nil
}

func replaceDBInTx(tx *sql.Tx, db dbFile) error {
	db = normalizeDBFile(db)
	// 写入策略是整库替换，数据规模很小，代码更直接，也避免局部同步遗漏。
	statements := []string{
		`DELETE FROM refresh_tokens`,
		`DELETE FROM users`,
		`DELETE FROM update_policy`,
	}
	for _, statement := range statements {
		if _, err := tx.Exec(statement); err != nil {
			return err
		}
	}

	for _, item := range db.Users {
		if _, err := tx.Exec(
			`INSERT INTO users (id, email, phone, display_name, password_hash, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)`,
			item.ID,
			nullableString(item.Email),
			nullableString(item.Phone),
			item.DisplayName,
			item.PasswordHash,
			item.CreatedAt,
			item.UpdatedAt,
		); err != nil {
			return err
		}
	}
	for _, token := range db.RefreshTokens {
		if _, err := tx.Exec(
			`INSERT INTO refresh_tokens (id, user_id, token_hash, created_at, expires_at) VALUES (?, ?, ?, ?, ?)`,
			token.ID,
			token.UserID,
			token.TokenHash,
			token.CreatedAt,
			token.ExpiresAt,
		); err != nil {
			return err
		}
	}

	notesJSON, err := json.Marshal(db.UpdatePolicy.ReleaseNotes)
	if err != nil {
		return err
	}
	_, err = tx.Exec(
		`INSERT INTO update_policy (id, platform, latest_version_code, latest_version_name, min_supported_version_code, download_url, release_notes_json, message, updated_at) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)`,
		db.UpdatePolicy.Platform,
		db.UpdatePolicy.LatestVersionCode,
		db.UpdatePolicy.LatestVersionName,
		db.UpdatePolicy.MinSupportedVersionCode,
		db.UpdatePolicy.DownloadURL,
		string(notesJSON),
		db.UpdatePolicy.Message,
		db.UpdatePolicy.UpdatedAt,
	)
	return err
}

func ensureUpdatePolicy(db *sql.DB) error {
	var count int
	if err := db.QueryRow(`SELECT COUNT(*) FROM update_policy WHERE id = 1`).Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil
	}
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	policy := defaultDB().UpdatePolicy
	notesJSON, err := json.Marshal(policy.ReleaseNotes)
	if err != nil {
		_ = tx.Rollback()
		return err
	}
	if _, err := tx.Exec(
		`INSERT INTO update_policy (id, platform, latest_version_code, latest_version_name, min_supported_version_code, download_url, release_notes_json, message, updated_at) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?)`,
		policy.Platform,
		policy.LatestVersionCode,
		policy.LatestVersionName,
		policy.MinSupportedVersionCode,
		policy.DownloadURL,
		string(notesJSON),
		policy.Message,
		policy.UpdatedAt,
	); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}

func sqliteHasData(db *sql.DB) (bool, error) {
	var count int
	if err := db.QueryRow(`SELECT (SELECT COUNT(*) FROM users) + (SELECT COUNT(*) FROM update_policy)`).Scan(&count); err != nil {
		return false, err
	}
	return count > 0, nil
}

func metaValue(db *sql.DB, key string) (string, bool, error) {
	var value string
	err := db.QueryRow(`SELECT value FROM app_meta WHERE key = ?`, key).Scan(&value)
	if errors.Is(err, sql.ErrNoRows) {
		return "", false, nil
	}
	if err != nil {
		return "", false, err
	}
	return value, true, nil
}

func setMeta(db *sql.DB, key string, value string) error {
	_, err := db.Exec(`INSERT INTO app_meta (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`, key, value)
	return err
}

func setMetaTx(tx *sql.Tx, key string, value string) error {
	_, err := tx.Exec(`INSERT INTO app_meta (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value`, key, value)
	return err
}

func normalizeDBFile(db dbFile) dbFile {
	fallback := defaultDB()
	if db.Users == nil {
		db.Users = []user{}
	}
	if db.RefreshTokens == nil {
		db.RefreshTokens = []refreshToken{}
	}
	db.UpdatePolicy = sanitizeUpdatePolicy(policyToMap(db.UpdatePolicy), fallback.UpdatePolicy, true)
	return db
}

func nullableString(value *string) any {
	if value == nil {
		return nil
	}
	return *value
}

func defaultDB() dbFile {
	return dbFile{
		Users:         []user{},
		RefreshTokens: []refreshToken{},
		UpdatePolicy: updatePolicy{
			Platform:                "android",
			LatestVersionCode:       2,
			LatestVersionName:       "1.0.1",
			MinSupportedVersionCode: 2,
			DownloadURL:             "http://192.168.20.11:3000/downloads/pingsheng-1.0.1.apk",
			ReleaseNotes:            []string{"发布 1.0.1 更新包。"},
			Message:                 "请更新到最新版本后继续使用。",
			UpdatedAt:               nowISO(),
		},
	}
}

func sanitizeUpdatePolicy(input map[string]any, fallback updatePolicy, keepUpdatedAt bool) updatePolicy {
	// 管理接口允许部分字段更新；缺省值沿用现有策略或默认策略。
	latest := parseVersionCode(input["latestVersionCode"])
	if latest == nil {
		latest = &fallback.LatestVersionCode
	}
	minimum := parseVersionCode(input["minSupportedVersionCode"])
	if minimum == nil {
		minimum = &fallback.MinSupportedVersionCode
	}
	notes := fallback.ReleaseNotes
	if rawNotes, ok := input["releaseNotes"].([]any); ok {
		notes = []string{}
		for _, item := range rawNotes {
			note := strings.TrimSpace(fmt.Sprint(item))
			if note != "" {
				notes = append(notes, note)
			}
			if len(notes) >= 20 {
				break
			}
		}
	}
	updatedAt := nowISO()
	if keepUpdatedAt {
		updatedAt = defaultIfEmpty(stringValue(input["updatedAt"]), fallback.UpdatedAt)
	}
	return updatePolicy{
		Platform:                strings.ToLower(strings.TrimSpace(defaultIfEmpty(stringValue(input["platform"]), defaultIfEmpty(fallback.Platform, "android")))),
		LatestVersionCode:       *latest,
		LatestVersionName:       strings.TrimSpace(defaultIfEmpty(stringValue(input["latestVersionName"]), defaultIfEmpty(fallback.LatestVersionName, "1.0.0"))),
		MinSupportedVersionCode: *minimum,
		DownloadURL:             strings.TrimSpace(defaultIfEmpty(stringValue(input["downloadUrl"]), fallback.DownloadURL)),
		ReleaseNotes:            notes,
		Message:                 strings.TrimSpace(defaultIfEmpty(stringValue(input["message"]), fallback.Message)),
		UpdatedAt:               updatedAt,
	}
}

func policyToMap(policy updatePolicy) map[string]any {
	notes := make([]any, 0, len(policy.ReleaseNotes))
	for _, note := range policy.ReleaseNotes {
		notes = append(notes, note)
	}
	return map[string]any{
		"platform":                policy.Platform,
		"latestVersionCode":       policy.LatestVersionCode,
		"latestVersionName":       policy.LatestVersionName,
		"minSupportedVersionCode": policy.MinSupportedVersionCode,
		"downloadUrl":             policy.DownloadURL,
		"releaseNotes":            notes,
		"message":                 policy.Message,
		"updatedAt":               policy.UpdatedAt,
	}
}

func normalizeIdentifier(body map[string]any, kind string) (string, error) {
	// 注册和登录共用账号规范化逻辑，避免“同一邮箱不同写法”产生重复账号。
	if kind == "email" {
		return normalizeEmail(stringValue(body["email"]))
	}
	return normalizePhone(stringValue(body["phone"]))
}

func normalizeEmail(value string) (string, error) {
	email := strings.ToLower(toHalfWidthASCII(strings.TrimSpace(value)))
	email = strings.NewReplacer("。", ".", "．", ".", "｡", ".").Replace(email)
	email = hiddenWhitespace.ReplaceAllString(email, "")
	if !emailRE.MatchString(email) {
		return "", apiError{Status: http.StatusBadRequest, Code: "invalid_email", Message: "邮箱格式不对，请检查 @ 和后缀。"}
	}
	return email, nil
}

func normalizePhone(value string) (string, error) {
	phone := toHalfWidthASCII(strings.TrimSpace(value))
	phone = phoneRemovable.ReplaceAllString(phone, "")
	if strings.HasPrefix(phone, "+") {
		if strings.HasPrefix(phone, "+86") && len(phone) == 14 {
			phone = phone[3:]
		} else {
			return "", apiError{Status: http.StatusBadRequest, Code: "invalid_phone", Message: "手机号格式不对，请输入 11 位手机号。"}
		}
	}
	if strings.HasPrefix(phone, "0086") && len(phone) == 15 {
		phone = phone[4:]
	} else if strings.HasPrefix(phone, "86") && len(phone) == 13 {
		phone = phone[2:]
	}
	if !phoneRE.MatchString(phone) {
		return "", apiError{Status: http.StatusBadRequest, Code: "invalid_phone", Message: "手机号格式不对，请输入 11 位手机号。"}
	}
	return phone, nil
}

func toHalfWidthASCII(value string) string {
	// 用户可能从中文输入法粘贴全角数字/字母，这里统一成半角再校验。
	var builder strings.Builder
	for _, r := range value {
		switch {
		case r == 0x3000:
			builder.WriteRune(' ')
		case r >= 0xFF01 && r <= 0xFF5E:
			builder.WriteRune(r - 0xFEE0)
		default:
			builder.WriteRune(r)
		}
	}
	return builder.String()
}

func validatePassword(password string) (string, error) {
	if len(password) < 6 {
		return "", apiError{Status: http.StatusBadRequest, Code: "weak_password", Message: "密码至少需要 6 位。"}
	}
	return password, nil
}

func hashPassword(password string) (string, error) {
	// 密码使用 PBKDF2 加盐哈希；数据库里永远不保存明文密码。
	saltBytes := make([]byte, 16)
	if _, err := rand.Read(saltBytes); err != nil {
		return "", err
	}
	salt := hex.EncodeToString(saltBytes)
	digest, err := pbkdf2.Key[hash.Hash](sha256.New, password, []byte(salt), 120000, sha256.Size)
	if err != nil {
		return "", err
	}
	return "pbkdf2_sha256:" + salt + ":" + hex.EncodeToString(digest), nil
}

func verifyPassword(password string, stored string) bool {
	parts := strings.Split(stored, ":")
	if len(parts) != 3 || parts[0] != "pbkdf2_sha256" {
		return false
	}
	digest, err := pbkdf2.Key[hash.Hash](sha256.New, password, []byte(parts[1]), 120000, sha256.Size)
	if err != nil {
		return false
	}
	// 用 hmac.Equal 做常量时间比较，避免普通字符串比较泄露时序差异。
	return hmac.Equal([]byte(hex.EncodeToString(digest)), []byte(parts[2]))
}

func makeUser(kind string, identifier string, password string, displayName string) user {
	now := nowISO()
	passwordHash, err := hashPassword(password)
	if err != nil {
		panic(err)
	}
	displayName = strings.TrimSpace(displayName)
	if displayName == "" {
		displayName = identifier
	}
	item := user{
		ID:           newUUID(),
		DisplayName:  displayName,
		PasswordHash: passwordHash,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	if kind == "email" {
		item.Email = &identifier
	} else {
		item.Phone = &identifier
	}
	return item
}

func findUserIndex(users []user, kind string, identifier string) int {
	for i, item := range users {
		if kind == "email" && item.Email != nil && *item.Email == identifier {
			return i
		}
		if kind == "phone" && item.Phone != nil && *item.Phone == identifier {
			return i
		}
	}
	return -1
}

func publicUserFrom(item user) publicUser {
	return publicUser{
		ID:          item.ID,
		Email:       item.Email,
		Phone:       item.Phone,
		DisplayName: item.DisplayName,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}

func authResponse(item user, tokens tokenPair) map[string]any {
	return map[string]any{
		"user":                  publicUserFrom(item),
		"accessToken":           tokens.AccessToken,
		"tokenType":             tokens.TokenType,
		"expiresIn":             tokens.ExpiresIn,
		"refreshToken":          tokens.RefreshToken,
		"refreshTokenExpiresAt": tokens.RefreshTokenExpiresAt,
	}
}

func cleanExpiredRefreshTokens(db *dbFile) {
	// 每次签发/刷新前顺手清理过期刷新令牌，保持 token 表轻量。
	now := time.Now().UTC()
	kept := db.RefreshTokens[:0]
	for _, token := range db.RefreshTokens {
		expiresAt, err := time.Parse(time.RFC3339, token.ExpiresAt)
		if err == nil && expiresAt.After(now) {
			kept = append(kept, token)
		}
	}
	db.RefreshTokens = kept
}

func issueTokenPair(db *dbFile, item user) (tokenPair, error) {
	// Access token 短期有效，Refresh token 长期保存哈希，用于无感续期。
	cleanExpiredRefreshTokens(db)
	refresh, err := randomURLToken(48)
	if err != nil {
		return tokenPair{}, err
	}
	expiresAt := time.Now().UTC().AddDate(0, 0, refreshTokenTTLDays()).Truncate(time.Second)
	db.RefreshTokens = append(db.RefreshTokens, refreshToken{
		ID:        newUUID(),
		UserID:    item.ID,
		TokenHash: hashRefreshToken(refresh),
		CreatedAt: nowISO(),
		ExpiresAt: expiresAt.Format(time.RFC3339),
	})
	access, err := signAccessToken(item)
	if err != nil {
		return tokenPair{}, err
	}
	return tokenPair{
		AccessToken:           access,
		TokenType:             "Bearer",
		ExpiresIn:             accessTokenTTL(),
		RefreshToken:          refresh,
		RefreshTokenExpiresAt: expiresAt.Format(time.RFC3339),
	}, nil
}

func hashRefreshToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func signAccessToken(item user) (string, error) {
	// 这里实现的是轻量 HMAC token：payload + 签名，足够当前私有服务使用。
	issuedAt := time.Now().Unix()
	payload := accessPayload{
		Subject: item.ID,
		Type:    "access",
		Issued:  issuedAt,
		Expires: issuedAt + int64(accessTokenTTL()),
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		return "", err
	}
	encoded := base64.RawURLEncoding.EncodeToString(raw)
	return encoded + "." + signValue(encoded), nil
}

func verifyAccessToken(token string) (accessPayload, error) {
	// 验证顺序：格式 -> 签名 -> JSON -> 过期时间，任何一步失败都视为无效 token。
	parts := strings.Split(token, ".")
	if len(parts) != 2 || !hmac.Equal([]byte(parts[1]), []byte(signValue(parts[0]))) {
		return accessPayload{}, apiError{Status: http.StatusUnauthorized, Code: "invalid_token", Message: "Bearer token is invalid."}
	}
	raw, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return accessPayload{}, apiError{Status: http.StatusUnauthorized, Code: "invalid_token", Message: "Bearer token is invalid."}
	}
	var payload accessPayload
	if err := json.Unmarshal(raw, &payload); err != nil {
		return accessPayload{}, apiError{Status: http.StatusUnauthorized, Code: "invalid_token", Message: "Bearer token is invalid."}
	}
	if payload.Type != "access" || payload.Subject == "" || payload.Expires <= time.Now().Unix() {
		return accessPayload{}, apiError{Status: http.StatusUnauthorized, Code: "invalid_token", Message: "Bearer token is invalid or expired."}
	}
	return payload, nil
}

func signValue(value string) string {
	mac := hmac.New(sha256.New, []byte(tokenSecret()))
	_, _ = mac.Write([]byte(value))
	return base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
}

func randomURLToken(size int) (string, error) {
	raw := make([]byte, size)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(raw), nil
}

func newUUID() string {
	raw := make([]byte, 16)
	if _, err := rand.Read(raw); err != nil {
		panic(err)
	}
	raw[6] = (raw[6] & 0x0f) | 0x40
	raw[8] = (raw[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", raw[0:4], raw[4:6], raw[6:8], raw[8:10], raw[10:16])
}

func nowISO() string {
	return time.Now().UTC().Truncate(time.Second).Format(time.RFC3339)
}

func dataFile() string {
	// 旧 JSON 数据文件路径只用于一次性迁移。
	return envString("DATA_FILE", defaultDataFile)
}

func databaseFile() string {
	// SQLite 主库路径，可通过环境变量在服务器部署时切换。
	return envString("DATABASE_FILE", defaultDatabaseFile)
}

func downloadDir() string {
	// APK 下载目录默认是 server/downloads，发布脚本上传的新包会放这里。
	return envString("DOWNLOAD_DIR", defaultDownloadDir)
}

func tokenSecret() string {
	return envString("TOKEN_SECRET", defaultTokenSecret)
}

func adminToken() string {
	return envString("ADMIN_TOKEN", defaultAdminToken)
}

func accessTokenTTL() int {
	return envInt("ACCESS_TOKEN_TTL_SECONDS", defaultAccessTokenTTL)
}

func refreshTokenTTLDays() int {
	return envInt("REFRESH_TOKEN_TTL_DAYS", defaultRefreshTokenTTLDays)
}

func envString(key string, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func envInt(key string, fallback int) int {
	value, err := strconv.Atoi(strings.TrimSpace(os.Getenv(key)))
	if err != nil {
		return fallback
	}
	return value
}

func parseVersionCode(value any) *int {
	switch v := value.(type) {
	case int:
		if v >= 0 {
			return &v
		}
	case int64:
		if v >= 0 && v <= math.MaxInt {
			parsed := int(v)
			return &parsed
		}
	case float64:
		if v >= 0 && math.Trunc(v) == v && v <= math.MaxInt {
			parsed := int(v)
			return &parsed
		}
	case json.Number:
		if parsed, err := strconv.Atoi(v.String()); err == nil && parsed >= 0 {
			return &parsed
		}
	case string:
		if parsed, err := strconv.Atoi(strings.TrimSpace(v)); err == nil && parsed >= 0 {
			return &parsed
		}
	}
	return nil
}

func stringValue(value any) string {
	switch v := value.(type) {
	case nil:
		return ""
	case string:
		return v
	case fmt.Stringer:
		return v.String()
	case float64:
		if math.Trunc(v) == v {
			return strconv.FormatInt(int64(v), 10)
		}
		return strconv.FormatFloat(v, 'f', -1, 64)
	case bool:
		return strconv.FormatBool(v)
	default:
		return strings.TrimFunc(fmt.Sprint(v), unicode.IsSpace)
	}
}

func defaultIfEmpty(value string, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}
