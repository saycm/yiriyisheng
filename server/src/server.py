#!/usr/bin/env python3
import base64
import hashlib
import hmac
import json
import os
import re
import secrets
import time
import unicodedata
import uuid
from datetime import datetime, timedelta
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from socketserver import ThreadingMixIn
from urllib.parse import parse_qs, unquote, urlparse


BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DATA_FILE = BASE_DIR / "data" / "db.json"
DEFAULT_DOWNLOAD_DIR = BASE_DIR / "downloads"
DEFAULT_TOKEN_SECRET = "change-this-dev-token-secret"
DEFAULT_ADMIN_TOKEN = "change-this-admin-token"
ACCESS_TOKEN_TTL_SECONDS = int(os.environ.get("ACCESS_TOKEN_TTL_SECONDS", "900"))
REFRESH_TOKEN_TTL_DAYS = int(os.environ.get("REFRESH_TOKEN_TTL_DAYS", "30"))
MAX_BODY_BYTES = 1024 * 1024
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
PHONE_RE = re.compile(r"^1[0-9]{10}$")
PHONE_REMOVABLE_RE = re.compile("[\\s\\u00A0\\u200B-\\u200D\\uFEFF\\u3000\\-()（）]")


class ApiError(Exception):
    def __init__(self, status, code, message):
        super(ApiError, self).__init__(message)
        self.status = status
        self.code = code
        self.message = message


def now_iso():
    return datetime.utcnow().replace(microsecond=0).isoformat() + "Z"


def data_file():
    return Path(os.environ.get("DATA_FILE", str(DEFAULT_DATA_FILE)))


def download_dir():
    return Path(os.environ.get("DOWNLOAD_DIR", str(DEFAULT_DOWNLOAD_DIR)))


def token_secret():
    return os.environ.get("TOKEN_SECRET", DEFAULT_TOKEN_SECRET)


def admin_token():
    return os.environ.get("ADMIN_TOKEN", DEFAULT_ADMIN_TOKEN)


def default_db():
    return {
        "users": [],
        "refreshTokens": [],
        "updatePolicy": {
            "platform": "android",
            "latestVersionCode": 2,
            "latestVersionName": "1.0.1",
            "minSupportedVersionCode": 2,
            "downloadUrl": "http://192.168.20.11:3000/downloads/pingsheng-1.0.1.apk",
            "releaseNotes": ["发布 1.0.1 更新包。"],
            "message": "请更新到最新版本后继续使用。",
            "updatedAt": now_iso(),
        },
    }


def read_db():
    file_path = data_file()
    if not file_path.exists():
        write_db(default_db())
    with file_path.open("r", encoding="utf-8") as file:
        loaded = json.load(file)
    fallback = default_db()
    return {
        "users": loaded.get("users") if isinstance(loaded.get("users"), list) else [],
        "refreshTokens": loaded.get("refreshTokens")
        if isinstance(loaded.get("refreshTokens"), list)
        else [],
        "updatePolicy": sanitize_update_policy(
            loaded.get("updatePolicy") or {},
            fallback["updatePolicy"],
            keep_updated_at=True,
        ),
    }


def write_db(db):
    file_path = data_file()
    file_path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = file_path.with_suffix(file_path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as file:
        json.dump(db, file, ensure_ascii=False, indent=2)
        file.write("\n")
    tmp_path.replace(file_path)


def parse_version_code(value):
    try:
        number = int(value)
    except (TypeError, ValueError):
        return None
    return number if number >= 0 else None


def sanitize_update_policy(input_policy, fallback, keep_updated_at=False):
    latest = parse_version_code(input_policy.get("latestVersionCode"))
    minimum = parse_version_code(input_policy.get("minSupportedVersionCode"))
    notes = input_policy.get("releaseNotes")
    if isinstance(notes, list):
        notes = [str(item).strip() for item in notes if str(item).strip()][:20]
    else:
        notes = fallback.get("releaseNotes", [])
    return {
        "platform": str(input_policy.get("platform") or fallback.get("platform") or "android")
        .strip()
        .lower(),
        "latestVersionCode": latest
        if latest is not None
        else int(fallback.get("latestVersionCode", 0)),
        "latestVersionName": str(
            input_policy.get("latestVersionName") or fallback.get("latestVersionName") or "1.0.0"
        ).strip(),
        "minSupportedVersionCode": minimum
        if minimum is not None
        else int(fallback.get("minSupportedVersionCode", 0)),
        "downloadUrl": str(
            input_policy.get("downloadUrl")
            if "downloadUrl" in input_policy
            else fallback.get("downloadUrl") or ""
        ).strip(),
        "releaseNotes": notes,
        "message": str(
            input_policy.get("message")
            if "message" in input_policy
            else fallback.get("message") or ""
        ).strip(),
        "updatedAt": str(input_policy.get("updatedAt") or fallback.get("updatedAt") or now_iso())
        if keep_updated_at
        else now_iso(),
    }


def normalize_email(value):
    email = unicodedata.normalize("NFKC", str(value or "").strip()).lower()
    email = (
        email.replace("。", ".")
        .replace("．", ".")
        .replace("｡", ".")
        .replace("\u200b", "")
        .replace("\u200c", "")
        .replace("\u200d", "")
        .replace("\ufeff", "")
    )
    email = re.sub(r"\s+", "", email)
    if not EMAIL_RE.match(email):
        raise ApiError(400, "invalid_email", "邮箱格式不对，请检查 @ 和后缀。")
    return email


def normalize_phone(value):
    phone = unicodedata.normalize("NFKC", str(value or "").strip())
    phone = PHONE_REMOVABLE_RE.sub("", phone)
    if phone.startswith("+"):
        if phone.startswith("+86") and len(phone) == 14:
            phone = phone[3:]
        else:
            raise ApiError(400, "invalid_phone", "手机号格式不对，请输入 11 位手机号。")
    if phone.startswith("0086") and len(phone) == 15:
        phone = phone[4:]
    elif phone.startswith("86") and len(phone) == 13:
        phone = phone[2:]
    if not PHONE_RE.match(phone):
        raise ApiError(400, "invalid_phone", "手机号格式不对，请输入 11 位手机号。")
    return phone


def validate_password(password):
    password = str(password or "")
    if len(password) < 6:
        raise ApiError(400, "weak_password", "密码至少需要 6 位。")
    return password


def hash_password(password):
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120000)
    return "pbkdf2_sha256:{}:{}".format(salt, digest.hex())


def verify_password(password, stored_hash):
    parts = str(stored_hash or "").split(":")
    if len(parts) != 3 or parts[0] != "pbkdf2_sha256":
        return False
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), parts[1].encode("utf-8"), 120000)
    return hmac.compare_digest(digest.hex(), parts[2])


def hash_refresh_token(token):
    return hashlib.sha256(str(token).encode("utf-8")).hexdigest()


def b64url_encode(raw):
    if isinstance(raw, str):
        raw = raw.encode("utf-8")
    return base64.urlsafe_b64encode(raw).rstrip(b"=").decode("ascii")


def b64url_decode(raw):
    padding = "=" * (-len(raw) % 4)
    return base64.urlsafe_b64decode((raw + padding).encode("ascii")).decode("utf-8")


def sign_value(value):
    digest = hmac.new(token_secret().encode("utf-8"), value.encode("utf-8"), hashlib.sha256).digest()
    return b64url_encode(digest)


def sign_access_token(user):
    issued_at = int(time.time())
    payload = {
        "sub": user["id"],
        "type": "access",
        "iat": issued_at,
        "exp": issued_at + ACCESS_TOKEN_TTL_SECONDS,
    }
    encoded = b64url_encode(json.dumps(payload, separators=(",", ":")))
    return "{}.{}".format(encoded, sign_value(encoded))


def verify_access_token(token):
    parts = str(token or "").split(".")
    if len(parts) != 2 or not hmac.compare_digest(parts[1], sign_value(parts[0])):
        raise ApiError(401, "invalid_token", "Bearer token is invalid.")
    try:
        payload = json.loads(b64url_decode(parts[0]))
    except (TypeError, ValueError):
        raise ApiError(401, "invalid_token", "Bearer token is invalid.")
    if payload.get("type") != "access" or not payload.get("sub") or int(payload.get("exp", 0)) <= int(time.time()):
        raise ApiError(401, "invalid_token", "Bearer token is invalid or expired.")
    return payload


def public_user(user):
    return {
        "id": user.get("id"),
        "email": user.get("email"),
        "phone": user.get("phone"),
        "displayName": user.get("displayName"),
        "createdAt": user.get("createdAt"),
        "updatedAt": user.get("updatedAt"),
    }


def clean_expired_refresh_tokens(db):
    now = datetime.utcnow()
    kept = []
    for token in db["refreshTokens"]:
        try:
            expires_at = datetime.strptime(token.get("expiresAt", ""), "%Y-%m-%dT%H:%M:%SZ")
        except ValueError:
            continue
        if expires_at > now:
            kept.append(token)
    db["refreshTokens"] = kept


def issue_token_pair(db, user):
    clean_expired_refresh_tokens(db)
    refresh_token = secrets.token_urlsafe(48)
    expires_at = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_TTL_DAYS)
    db["refreshTokens"].append(
        {
            "id": str(uuid.uuid4()),
            "userId": user["id"],
            "tokenHash": hash_refresh_token(refresh_token),
            "createdAt": now_iso(),
            "expiresAt": expires_at.replace(microsecond=0).isoformat() + "Z",
        }
    )
    return {
        "accessToken": sign_access_token(user),
        "tokenType": "Bearer",
        "expiresIn": ACCESS_TOKEN_TTL_SECONDS,
        "refreshToken": refresh_token,
        "refreshTokenExpiresAt": expires_at.replace(microsecond=0).isoformat() + "Z",
    }


def find_user(db, kind, identifier):
    return next((user for user in db["users"] if user.get(kind) == identifier), None)


def make_user(kind, identifier, password, display_name):
    now = now_iso()
    user = {
        "id": str(uuid.uuid4()),
        "email": None,
        "phone": None,
        "displayName": str(display_name or "").strip() or identifier,
        "passwordHash": hash_password(password),
        "createdAt": now,
        "updatedAt": now,
    }
    user[kind] = identifier
    return user


class Handler(BaseHTTPRequestHandler):
    server_version = "PingShengLifeServer/0.2"

    def do_OPTIONS(self):
        self.send_response(204)
        self.add_cors_headers()
        self.end_headers()

    def do_GET(self):
        self.handle_api()

    def do_POST(self):
        self.handle_api()

    def do_PUT(self):
        self.handle_api()

    def handle_api(self):
        try:
            parsed = urlparse(self.path)
            path = parsed.path
            query = {key: values[-1] for key, values in parse_qs(parsed.query).items()}
            if self.command == "GET" and path == "/health":
                self.send_json(200, {"ok": True, "service": "pingsheng-life-server", "timestamp": now_iso()})
            elif self.command == "POST" and path == "/v1/auth/register/email":
                self.register("email")
            elif self.command == "POST" and path == "/v1/auth/register/phone":
                self.register("phone")
            elif self.command == "POST" and path == "/v1/auth/login/email":
                self.login("email")
            elif self.command == "POST" and path == "/v1/auth/login/phone":
                self.login("phone")
            elif self.command == "POST" and path == "/v1/auth/refresh":
                self.refresh()
            elif self.command == "POST" and path == "/v1/auth/logout":
                self.logout()
            elif self.command == "GET" and path == "/v1/me":
                self.me()
            elif path == "/v1/app/update" and self.command in ("GET", "POST"):
                self.check_update(query)
            elif self.command == "PUT" and path == "/v1/admin/update-policy":
                self.update_policy()
            elif self.command == "GET" and path.startswith("/downloads/"):
                self.serve_download(path)
            else:
                raise ApiError(404, "not_found", "Route not found.")
        except ApiError as error:
            self.send_json(error.status, {"error": {"code": error.code, "message": error.message}})
        except Exception as error:
            print("internal_error: {}".format(error))
            self.send_json(500, {"error": {"code": "internal_error", "message": "Internal server error."}})

    def register(self, kind):
        body = self.read_json_body()
        identifier = normalize_email(body.get("email")) if kind == "email" else normalize_phone(body.get("phone"))
        password = validate_password(body.get("password"))
        db = read_db()
        if find_user(db, kind, identifier):
            raise ApiError(409, "account_exists", "这个账号已经注册过，可以切换到登录。")
        user = make_user(kind, identifier, password, body.get("displayName"))
        db["users"].append(user)
        tokens = issue_token_pair(db, user)
        write_db(db)
        result = {"user": public_user(user)}
        result.update(tokens)
        self.send_json(201, result)

    def login(self, kind):
        body = self.read_json_body()
        identifier = normalize_email(body.get("email")) if kind == "email" else normalize_phone(body.get("phone"))
        db = read_db()
        user = find_user(db, kind, identifier)
        if not user or not verify_password(str(body.get("password") or ""), user.get("passwordHash")):
            raise ApiError(401, "invalid_credentials", "账号或密码不正确。")
        tokens = issue_token_pair(db, user)
        write_db(db)
        result = {"user": public_user(user)}
        result.update(tokens)
        self.send_json(200, result)

    def refresh(self):
        body = self.read_json_body()
        token_hash = hash_refresh_token(body.get("refreshToken") or "")
        db = read_db()
        clean_expired_refresh_tokens(db)
        existing = next((token for token in db["refreshTokens"] if token.get("tokenHash") == token_hash), None)
        if not existing:
            write_db(db)
            raise ApiError(401, "invalid_refresh_token", "Refresh token is invalid or expired.")
        user = next((item for item in db["users"] if item.get("id") == existing.get("userId")), None)
        db["refreshTokens"] = [token for token in db["refreshTokens"] if token.get("tokenHash") != token_hash]
        if not user:
            write_db(db)
            raise ApiError(401, "invalid_refresh_token", "Refresh token is invalid or expired.")
        tokens = issue_token_pair(db, user)
        write_db(db)
        result = {"user": public_user(user)}
        result.update(tokens)
        self.send_json(200, result)

    def logout(self):
        body = self.read_json_body()
        token_hash = hash_refresh_token(body.get("refreshToken") or "")
        db = read_db()
        db["refreshTokens"] = [token for token in db["refreshTokens"] if token.get("tokenHash") != token_hash]
        write_db(db)
        self.send_json(200, {"ok": True})

    def me(self):
        auth = self.headers.get("Authorization", "")
        token = auth[7:].strip() if auth.startswith("Bearer ") else ""
        if not token:
            raise ApiError(401, "missing_token", "Bearer token is required.")
        payload = verify_access_token(token)
        db = read_db()
        user = next((item for item in db["users"] if item.get("id") == payload.get("sub")), None)
        if not user:
            raise ApiError(401, "invalid_token", "Bearer token is invalid.")
        self.send_json(200, {"user": public_user(user)})

    def check_update(self, query):
        body = self.read_json_body() if self.command == "POST" else {}
        input_data = body if self.command == "POST" else query
        version_code = parse_version_code(input_data.get("versionCode") or input_data.get("currentVersionCode"))
        if version_code is None:
            raise ApiError(400, "invalid_version_code", "versionCode must be a non-negative integer.")
        policy = read_db()["updatePolicy"]
        latest = int(policy.get("latestVersionCode", 0))
        minimum = int(policy.get("minSupportedVersionCode", 0))
        self.send_json(
            200,
            {
                "platform": str(input_data.get("platform") or "android").strip().lower(),
                "currentVersionCode": version_code,
                "currentVersionName": str(input_data.get("versionName") or input_data.get("currentVersionName") or ""),
                "latestVersionCode": latest,
                "latestVersionName": policy.get("latestVersionName"),
                "minSupportedVersionCode": minimum,
                "hasUpdate": version_code < latest,
                "forceUpdate": version_code < minimum,
                "downloadUrl": policy.get("downloadUrl"),
                "releaseNotes": policy.get("releaseNotes"),
                "message": policy.get("message"),
                "updatedAt": policy.get("updatedAt"),
            },
        )

    def update_policy(self):
        if self.headers.get("X-Admin-Token") != admin_token():
            raise ApiError(401, "admin_unauthorized", "Admin token is missing or invalid.")
        db = read_db()
        db["updatePolicy"] = sanitize_update_policy(self.read_json_body(), db["updatePolicy"])
        write_db(db)
        self.send_json(200, {"updatePolicy": db["updatePolicy"]})

    def serve_download(self, request_path):
        filename = unquote(request_path[len("/downloads/") :]).strip()
        if not filename or "/" in filename or "\\" in filename or not filename.endswith(".apk"):
            raise ApiError(404, "not_found", "Download not found.")
        file_path = (download_dir() / filename).resolve()
        if file_path.parent != download_dir().resolve() or not file_path.is_file():
            raise ApiError(404, "not_found", "Download not found.")
        size = file_path.stat().st_size
        self.send_response(200)
        self.add_cors_headers()
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Length", str(size))
        self.send_header("Content-Disposition", 'attachment; filename="{}"'.format(file_path.name))
        self.end_headers()
        with file_path.open("rb") as file:
            while True:
                chunk = file.read(64 * 1024)
                if not chunk:
                    break
                self.wfile.write(chunk)

    def read_json_body(self):
        if "chunked" in str(self.headers.get("Transfer-Encoding") or "").lower():
            raw = self.read_chunked_body()
        else:
            length = int(self.headers.get("Content-Length") or 0)
            if length > MAX_BODY_BYTES:
                raise ApiError(413, "body_too_large", "Request body is too large.")
            raw = self.rfile.read(length) if length else b""
        if not raw:
            return {}
        try:
            return json.loads(raw.decode("utf-8"))
        except ValueError:
            raise ApiError(400, "invalid_json", "Request body must be valid JSON.")

    def read_chunked_body(self):
        chunks = []
        total = 0
        while True:
            line = self.rfile.readline(128)
            if not line:
                raise ApiError(400, "invalid_chunked_body", "Chunked body is invalid.")
            try:
                size = int(line.split(b";", 1)[0].strip(), 16)
            except ValueError:
                raise ApiError(400, "invalid_chunked_body", "Chunked body is invalid.")
            if size == 0:
                while True:
                    trailer = self.rfile.readline(1024)
                    if trailer in (b"", b"\r\n", b"\n"):
                        return b"".join(chunks)
            total += size
            if total > MAX_BODY_BYTES:
                raise ApiError(413, "body_too_large", "Request body is too large.")
            chunk = self.rfile.read(size)
            if len(chunk) != size or self.rfile.read(2) != b"\r\n":
                raise ApiError(400, "invalid_chunked_body", "Chunked body is invalid.")
            chunks.append(chunk)

    def send_json(self, status, payload):
        raw = json.dumps(payload, ensure_ascii=False).encode("utf-8") + b"\n"
        self.send_response(status)
        self.add_cors_headers()
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def add_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PUT,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization,X-Admin-Token")

    def log_message(self, fmt, *args):
        print("{} - {}".format(self.address_string(), fmt % args))


class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True


def main():
    port = int(os.environ.get("PORT", "3000"))
    if token_secret() == DEFAULT_TOKEN_SECRET:
        print("Warning: TOKEN_SECRET is using the development default.")
    if admin_token() == DEFAULT_ADMIN_TOKEN:
        print("Warning: ADMIN_TOKEN is using the development default.")
    server = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("PingSheng Life server listening on http://0.0.0.0:{}".format(port))
    server.serve_forever()


if __name__ == "__main__":
    main()
