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

enum _AuthGateStatus { checking, blocked, updateAvailable, signedOut, signedIn }

enum _AuthMode { login, register }

enum _AuthChannel { email, phone }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.updateResponseOverride});

  final Future<Map<String, dynamic>> Function()? updateResponseOverride;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

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
    return error.code == 'invalid_token' ||
        error.code == 'missing_token' ||
        error.code == 'invalid_refresh_token';
  }

  Future<void> _handleSignedIn(_AuthSession session) async {
    await _store.save(session);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = _AuthGateStatus.signedIn;
    });
  }

  Future<void> _handleSignOut() async {
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
    final atIndex = account.indexOf('@');
    if (atIndex <= 0 || atIndex != account.lastIndexOf('@')) {
      return false;
    }
    final domain = account.substring(atIndex + 1);
    final dotIndex = domain.lastIndexOf('.');
    return dotIndex > 0 && dotIndex < domain.length - 1;
  }

  bool _looksLikePhone(String account) {
    return account.length == 11 &&
        account.startsWith('1') &&
        account.codeUnits.every(_isAsciiDigit);
  }

  bool _isAsciiDigit(int codeUnit) {
    return codeUnit >= 0x30 && codeUnit <= 0x39;
  }

  String _authErrorMessage(_ApiException error) {
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
    if (includeName) {
      _nameController.clear();
    }
    _accountController.clear();
    _passwordController.clear();
  }

  void _handleModeChanged(_AuthMode mode) {
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
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthLaunchBackdrop()),
          SafeArea(
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
        ],
      ),
    );
  }
}

class _AuthStatusPage extends StatelessWidget {
  const _AuthStatusPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
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
    );
  }
}
