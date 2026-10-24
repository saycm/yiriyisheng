// 中文注释：登录注册与更新提示界面，负责进入首页前的账号和版本流程。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_core.dart';
import '../home/life_home.dart';
import '../shared/shared.dart';

part '../api/pingsheng_api.dart';
part 'auth_update_pages.dart';
part 'auth_visuals.dart';

/// 启动门禁状态：检查中、被强制更新拦截、有可选更新、未登录、已登录。
enum _AuthGateStatus { checking, blocked, updateAvailable, signedOut, signedIn }

/// 登录/注册模式。
enum _AuthMode { login, register }

/// 账号渠道：邮箱或手机号。
enum _AuthChannel { email, phone }

/// 启动门禁：检查更新、恢复登录态，再决定进入登录页还是首页。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.updateResponseOverride});

  final Future<Map<String, dynamic>> Function()? updateResponseOverride;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

/// 门禁状态机：维护更新信息、登录会话和当前页面。
class _AuthGateState extends State<AuthGate> {
  final _api = const _PingShengApi();
  final _store = const _AuthSessionStore();

  _AuthGateStatus _status = _AuthGateStatus.checking;
  _UpdateInfo? _updateInfo;
  String? _message;

  @override
  void initState() {
    super.initState();
    // 启动门禁顺序：先检查更新，再恢复登录态，最后决定进入首页或登录页。
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    // 先检查更新；强制更新会直接拦截，可选更新则显示可跳过的提示页。
    try {
      final update = widget.updateResponseOverride == null
          ? await _api.checkUpdate()
          : _UpdateInfo.fromJson(await widget.updateResponseOverride!());
      if (!mounted) {
        return;
      }
      if (update.forceUpdate) {
        setState(() {
          _updateInfo = update;
          _status = _AuthGateStatus.blocked;
        });
        return;
      }
      if (update.hasUpdate) {
        setState(() {
          _updateInfo = update;
          _status = _AuthGateStatus.updateAvailable;
        });
        return;
      }
    } catch (_) {
      if (mounted) {
        _message = '更新检查暂时不可用，请确认服务器连接。';
      }
    }

    // 更新检查通过后恢复本地登录态。
    final stored = await _store.load();
    if (stored != null) {
      final active = await _resolveStoredSession(stored);
      if (!mounted) {
        return;
      }
      if (active != null) {
        setState(() {
          _status = _AuthGateStatus.signedIn;
        });
        return;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() => _status = _AuthGateStatus.signedOut);
  }

  Future<_AuthSession?> _resolveStoredSession(_AuthSession stored) async {
    // 用 access token 换取用户信息；token 失效时尝试 refresh。
    try {
      // access token 仍有效时直接换取用户信息，避免频繁刷新 token。
      final user = await _api.me(stored.accessToken);
      return stored.copyWith(user: user);
    } on _ApiException catch (error) {
      if (!_isAuthInvalid(error)) {
        return stored;
      }
      try {
        // access token 过期后用 refresh token 换新会话，并写回安全存储。
        final refreshed = await _api.refresh(stored.refreshToken);
        await _store.save(refreshed);
        return refreshed;
      } on _ApiException catch (refreshError) {
        if (!_isAuthInvalid(refreshError)) {
          return stored;
        }
        await _store.clear();
        return null;
      }
    } catch (_) {
      return stored;
    }
  }

  bool _isAuthInvalid(_ApiException error) {
    // 这些错误码表示登录态已失效，需要刷新或重新登录。
    return error.code == 'invalid_token' ||
        error.code == 'missing_token' ||
        error.code == 'invalid_refresh_token';
  }

  Future<void> _handleSignedIn(_AuthSession session) async {
    // 登录成功后保存会话并进入首页。
    await _store.save(session);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = _AuthGateStatus.signedIn;
    });
  }

  Future<void> _handleSignOut() async {
    // 退出登录：清空本地会话并回到登录页。
    await _store.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _message = null;
      _status = _AuthGateStatus.signedOut;
    });
  }

  Future<void> _continueAfterOptionalUpdate() async {
    // 用户跳过可选更新后，继续恢复登录态。
    final stored = await _store.load();
    if (stored != null) {
      final active = await _resolveStoredSession(stored);
      if (!mounted) {
        return;
      }
      if (active != null) {
        setState(() => _status = _AuthGateStatus.signedIn);
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() => _status = _AuthGateStatus.signedOut);
  }

  @override
  Widget build(BuildContext context) {
    // 根据门禁状态选择加载页、更新页、登录页或首页。
    return switch (_status) {
      _AuthGateStatus.checking =>
        _AuthStatusPage(message: _message ?? '正在连接服务端'),
      _AuthGateStatus.blocked => _ForceUpdatePage(update: _updateInfo),
      _AuthGateStatus.updateAvailable => _OptionalUpdatePage(
          update: _updateInfo,
          onSkip: () => unawaited(_continueAfterOptionalUpdate()),
        ),
      _AuthGateStatus.signedOut => _AuthPage(
          api: _api,
          initialMessage: _message,
          onSignedIn: _handleSignedIn,
        ),
      _AuthGateStatus.signedIn => LifeHomePage(onSignOut: _handleSignOut),
    };
  }
}

/// 登录页预览入口，用于开发时直接查看登录界面。
class AuthPreviewPage extends StatelessWidget {
  const AuthPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthPage(
      api: const _PingShengApi(),
      onSignedIn: (_) async {},
    );
  }
}

/// 登录/注册页面。
class _AuthPage extends StatefulWidget {
  const _AuthPage({
    required this.api,
    required this.onSignedIn,
    this.initialMessage,
  });

  final _PingShengApi api;
  final String? initialMessage;
  final Future<void> Function(_AuthSession session) onSignedIn;

  @override
  State<_AuthPage> createState() => _AuthPageState();
}

/// 登录/注册表单状态：输入校验、提交和错误提示。
class _AuthPageState extends State<_AuthPage> {
  final _nameController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.register;
  _AuthChannel _channel = _AuthChannel.email;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.initialMessage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizeAuthAccount(String value) {
    // 前端先做一次账号规范化，减少用户因全角字符、中文句号等输入细节失败。
    var normalized = _toHalfWidthAscii(value.trim())
        .replaceAll('。', '.')
        .replaceAll('．', '.')
        .replaceAll('｡', '.');
    if (_channel == _AuthChannel.email) {
      return normalized
          .replaceAll(authHiddenOrWhitespacePattern, '')
          .toLowerCase();
    }
    return _normalizePhoneInput(normalized);
  }

  String _toHalfWidthAscii(String value) {
    // 把全角字符转换成半角，避免用户输入法造成的格式问题。
    final buffer = StringBuffer();
    for (final unit in value.codeUnits) {
      if (unit == 0x3000) {
        buffer.writeCharCode(0x20);
      } else if (unit >= 0xFF01 && unit <= 0xFF5E) {
        buffer.writeCharCode(unit - 0xFEE0);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  String _normalizePhoneInput(String value) {
    // 去掉手机号里的空格、括号和 +86/0086 前缀。
    var phone = value
        .replaceAll(authHiddenOrWhitespacePattern, '')
        .replaceAll(RegExp(r'[-()（）]'), '');
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    if (phone.startsWith('0086') && phone.length == 15) {
      return phone.substring(4);
    }
    if (phone.startsWith('86') && phone.length == 13) {
      return phone.substring(2);
    }
    return phone;
  }

  String? _validateAuthInput(String account, String password) {
    // 提交前做基础校验，返回第一条错误文案。
    if (account.isEmpty) {
      return _channel == _AuthChannel.email ? '请填写邮箱地址。' : '请填写手机号码。';
    }
    if (_channel == _AuthChannel.email && !_looksLikeEmail(account)) {
      return '邮箱格式不对，请检查 @ 和后缀，比如 say1024@qq.com。';
    }
    if (_channel == _AuthChannel.phone && !_looksLikePhone(account)) {
      return '手机号格式不对，请输入 11 位手机号。';
    }
    if (password.length < 6) {
      return '密码至少需要 6 位。';
    }
    return null;
  }

  bool _looksLikeEmail(String account) {
    // 简单的邮箱格式检查：有且仅有一个 @，域名里有点且不在首尾。
    final atIndex = account.indexOf('@');
    if (atIndex <= 0 || atIndex != account.lastIndexOf('@')) {
      return false;
    }
    final domain = account.substring(atIndex + 1);
    final dotIndex = domain.lastIndexOf('.');
    return dotIndex > 0 && dotIndex < domain.length - 1;
  }

  bool _looksLikePhone(String account) {
    // 中国大陆手机号：11 位、以 1 开头、全为数字。
    return account.length == 11 &&
        account.startsWith('1') &&
        account.codeUnits.every(_isAsciiDigit);
  }

  bool _isAsciiDigit(int codeUnit) {
    return codeUnit >= 0x30 && codeUnit <= 0x39;
  }

  String _authErrorMessage(_ApiException error) {
    // 把服务端错误码/英文提示翻译成中文提示。
    return switch (error.code) {
      'invalid_email' => '邮箱格式不对，请检查 @ 和后缀，比如 say1024@qq.com。',
      'invalid_phone' => '手机号格式不对，请输入 11 位手机号。',
      'weak_password' => '密码至少需要 6 位。',
      'account_exists' => '这个账号已经注册过，可以切换到登录。',
      'invalid_credentials' => '账号或密码不正确。',
      _ => switch (error.message) {
          'Email is invalid.' => '邮箱格式不对，请检查 @ 和后缀，比如 say1024@qq.com。',
          'Phone number is invalid.' => '手机号格式不对，请输入 11 位手机号。',
          'Password must contain at least 6 characters.' => '密码至少需要 6 位。',
          'Account already exists.' => '这个账号已经注册过，可以切换到登录。',
          'Account or password is incorrect.' => '账号或密码不正确。',
          _ => error.message,
        },
    };
  }

  void _clearAuthInputs({bool includeName = true}) {
    // 切换模式或渠道时清空输入，避免残留上一次的账号。
    if (includeName) {
      _nameController.clear();
    }
    _accountController.clear();
    _passwordController.clear();
  }

  void _handleModeChanged(_AuthMode mode) {
    // 登录/注册切换：清空错误和输入。
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
      _clearAuthInputs();
    });
  }

  void _handleChannelChanged(_AuthChannel channel) {
    // 邮箱/手机号切换：保留昵称，清空账号和密码。
    if (_channel == channel) {
      return;
    }
    setState(() {
      _channel = channel;
      _error = null;
      _clearAuthInputs(includeName: false);
    });
  }

  Future<void> _submit() async {
    // 规范化输入 -> 校验 -> 调用对应注册/登录接口 -> 交给门禁保存会话。
    final account = _normalizeAuthAccount(_accountController.text);
    final password = _passwordController.text;
    if (account != _accountController.text) {
      _accountController.value = TextEditingValue(
        text: account,
        selection: TextSelection.collapsed(offset: account.length),
      );
    }
    final inputError = _validateAuthInput(account, password);
    if (inputError != null) {
      setState(() => _error = inputError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // UI 层只决定注册/登录方式，具体接口路径由 _PingShengApi 封装。
      final session = switch ((_mode, _channel)) {
        (_AuthMode.register, _AuthChannel.email) =>
          await widget.api.registerEmail(
            email: account,
            password: password,
            displayName: _nameController.text.trim(),
          ),
        (_AuthMode.register, _AuthChannel.phone) =>
          await widget.api.registerPhone(
            phone: account,
            password: password,
            displayName: _nameController.text.trim(),
          ),
        (_AuthMode.login, _AuthChannel.email) => await widget.api.loginEmail(
            email: account,
            password: password,
          ),
        (_AuthMode.login, _AuthChannel.phone) => await widget.api.loginPhone(
            phone: account,
            password: password,
          ),
      };
      await widget.onSignedIn(session);
    } on _ApiException catch (error) {
      setState(() => _error = _authErrorMessage(error));
    } catch (_) {
      setState(() => _error = '服务器连接失败，请稍后重试。');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 页面由品牌头部、表单面板和底部说明组成。
    final isRegister = _mode == _AuthMode.register;
    final formPanel = _AuthFormPanel(
      mode: _mode,
      channel: _channel,
      nameController: _nameController,
      accountController: _accountController,
      passwordController: _passwordController,
      busy: _busy,
      error: _error,
      onModeChanged: _handleModeChanged,
      onChannelChanged: _handleChannelChanged,
      onSubmit: _submit,
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF5E7C8),
      body: LiquidModuleBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 388),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthHeader(isRegister: isRegister),
                    Transform.translate(
                      offset: const Offset(0, -42),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: formPanel,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: const Text(
                        '本地数据 · 安全同步',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF8C7A64),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 启动检查时的加载状态页。
class _AuthStatusPage extends StatelessWidget {
  const _AuthStatusPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LiquidModuleBackground(
        child: Center(
          child: GlassSurface(
            borderRadius: 20,
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 22),
            color: AppColors.surface.withValues(alpha: 0.78),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconMark(size: 64),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                      color: AppColors.muted, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
