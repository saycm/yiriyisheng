# PingSheng Life Server

平生 Life 的 Go 后端服务，提供账号认证、Token 换新、当前用户查询、App 更新策略和 APK 静态下载。

## 能力

- `GET /health` 健康检查
- 邮箱注册、手机号注册
- 邮箱登录、手机号登录
- Access token 鉴权
- Refresh token 轮换和退出
- App 更新检查
- 管理员更新发布策略
- `/downloads/<filename>` 静态 APK 下载

## 数据存储

当前主数据源是 SQLite：

```text
data/pingsheng-life.db
```

服务端启动时会初始化以下表：

- `users`
- `refresh_tokens`
- `update_policy`
- `app_meta`

为了兼容早期测试数据，启动时会检查旧 JSON 文件：

```text
data/db.json
```

如果 SQLite 里还没有数据，且旧 JSON 文件存在，服务端会自动迁移一次并在 `app_meta` 中记录 `legacy_json_migrated=1`。迁移后主流程不再写入 `db.json`。

## 环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PORT` | `3000` | HTTP 监听端口 |
| `DATABASE_FILE` | `data/pingsheng-life.db` | SQLite 数据库路径 |
| `DATA_FILE` | `data/db.json` | 旧 JSON 迁移来源 |
| `DOWNLOAD_DIR` | `downloads` | APK 下载目录 |
| `TOKEN_SECRET` | `change-this-dev-token-secret` | Access token 签名密钥 |
| `ADMIN_TOKEN` | `change-this-admin-token` | 管理接口令牌 |
| `ACCESS_TOKEN_TTL_SECONDS` | `900` | Access token 有效期 |
| `REFRESH_TOKEN_TTL_DAYS` | `30` | Refresh token 有效期 |

生产或长期测试环境必须设置 `TOKEN_SECRET` 和 `ADMIN_TOKEN`。默认值只适合本机开发。

## 本地运行

PowerShell：

```powershell
cd server
$env:TOKEN_SECRET="replace-with-a-long-random-secret"
$env:ADMIN_TOKEN="replace-with-a-private-admin-token"
go run .
```

Bash：

```bash
cd server
export TOKEN_SECRET="replace-with-a-long-random-secret"
export ADMIN_TOKEN="replace-with-a-private-admin-token"
go run .
```

默认地址：

```text
http://localhost:3000
```

## 构建部署

Linux amd64：

```bash
cd server
GOOS=linux GOARCH=amd64 go build -o pingsheng-life-server .
```

Windows：

```powershell
cd server
go build -o pingsheng-life-server.exe .
```

CentOS/systemd 建议使用独立运行目录，例如：

```text
/opt/pingsheng-life/
  pingsheng-life-server
  data/
  downloads/
```

启动前设置环境变量：

```bash
export PORT=3000
export DATABASE_FILE=/opt/pingsheng-life/data/pingsheng-life.db
export DATA_FILE=/opt/pingsheng-life/data/db.json
export DOWNLOAD_DIR=/opt/pingsheng-life/downloads
export TOKEN_SECRET="replace-with-a-long-random-secret"
export ADMIN_TOKEN="replace-with-a-private-admin-token"
```

## 测试

```bash
cd server
go test ./...
```

## 接口

健康检查：

```http
GET /health
```

注册邮箱账号：

```http
POST /v1/auth/register/email
Content-Type: application/json

{
  "email": "alice@example.com",
  "password": "secret123",
  "displayName": "Alice"
}
```

注册手机号账号：

```http
POST /v1/auth/register/phone
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "secret123",
  "displayName": "Alice"
}
```

登录：

```text
POST /v1/auth/login/email
POST /v1/auth/login/phone
```

刷新 Token：

```http
POST /v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "<refreshToken>"
}
```

退出登录：

```http
POST /v1/auth/logout
Content-Type: application/json

{
  "refreshToken": "<refreshToken>"
}
```

当前用户：

```http
GET /v1/me
Authorization: Bearer <accessToken>
```

更新检查：

```http
GET /v1/app/update?platform=android&versionCode=6&versionName=1.0.5
```

管理员修改更新策略：

```http
PUT /v1/admin/update-policy
Content-Type: application/json
X-Admin-Token: <ADMIN_TOKEN>

{
  "latestVersionCode": 7,
  "latestVersionName": "1.0.6",
  "minSupportedVersionCode": 6,
  "downloadUrl": "http://192.168.20.11:3000/downloads/pingsheng-1.0.6.apk",
  "releaseNotes": ["修复注册登录体验", "优化计划模块日期"],
  "message": "发现新版本，建议更新。"
}
```

## 发布产物

`downloads/` 下的 APK、`data/` 下的数据库和编译出的服务端二进制都是运行时产物，已由根目录 `.gitignore` 排除。部署时把这些文件放在服务器运行目录或制品库，不提交到 Git。

## 旧 Python 服务

`server/src/server.py` 是旧版 Python 服务，仅作为回滚和接口参考保留。当前主服务是 `server/main.go`。
