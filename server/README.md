# PingSheng Life Server

平生 App 的 Go 后端服务，覆盖：

- 强制更新检查
- 邮箱注册、手机号注册
- 邮箱登录、手机号登录
- Access token 鉴权、Refresh token 换新

Go 版本复用原来的 `server/data/db.json` 和 `server/downloads` 目录，接口返回结构与旧 Python 版本保持一致。

## 运行

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

运行数据默认写入 `server/data/db.json`，该文件已加入 `.gitignore`。
APK 下载文件默认放在 `server/downloads`，并通过 `/downloads/<filename>.apk` 访问。

## 构建部署

Linux:

```bash
cd server
GOOS=linux GOARCH=amd64 go build -o pingsheng-life-server .
TOKEN_SECRET="replace-with-a-long-random-secret" \
ADMIN_TOKEN="replace-with-a-private-admin-token" \
./pingsheng-life-server
```

Windows:

```powershell
cd server
go build -o pingsheng-life-server.exe .
$env:TOKEN_SECRET="replace-with-a-long-random-secret"
$env:ADMIN_TOKEN="replace-with-a-private-admin-token"
.\pingsheng-life-server.exe
```

可选环境变量：

```text
PORT=3000
DATA_FILE=server/data/db.json
DOWNLOAD_DIR=server/downloads
ACCESS_TOKEN_TTL_SECONDS=900
REFRESH_TOKEN_TTL_DAYS=30
```

旧 Python 服务仍保留在 `server/src/server.py`，仅作为回滚参考。

## 接口

```http
GET /health
```

```http
POST /v1/auth/register/email
Content-Type: application/json

{
  "email": "alice@example.com",
  "password": "secret123",
  "displayName": "Alice"
}
```

```http
POST /v1/auth/register/phone
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "secret123",
  "displayName": "Alice"
}
```

登录接口：

```text
POST /v1/auth/login/email
POST /v1/auth/login/phone
```

当前用户：

```http
GET /v1/me
Authorization: Bearer <accessToken>
```

更新检查：

```http
GET /v1/app/update?platform=android&versionCode=1&versionName=1.0.0
```

管理员修改更新策略：

```http
PUT /v1/admin/update-policy
Content-Type: application/json
X-Admin-Token: <ADMIN_TOKEN>

{
  "latestVersionCode": 2,
  "latestVersionName": "1.0.1",
  "minSupportedVersionCode": 2,
  "downloadUrl": "http://192.168.20.11:3000/downloads/pingsheng-1.0.1.apk",
  "releaseNotes": ["强制更新测试"],
  "message": "请更新后继续使用。"
}
```
