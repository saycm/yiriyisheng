part of '../main.dart';

enum _AuthGateStatus { checking, blocked, signedOut, signedIn }

enum _AuthMode { login, register }

enum _AuthChannel { email, phone }

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _api = const _PingShengApi();
  final _store = const _AuthSessionStore();

  _AuthGateStatus _status = _AuthGateStatus.checking;
  _UpdateInfo? _updateInfo;
  String? _message;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final update = await _api.checkUpdate();
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
      final user = await _api.me(stored.accessToken);
      return stored.copyWith(user: user);
    } catch (_) {
      try {
        final refreshed = await _api.refresh(stored.refreshToken);
        await _store.save(refreshed);
        return refreshed;
      } catch (_) {
        await _store.clear();
        return null;
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return switch (_status) {
      _AuthGateStatus.checking =>
        _AuthStatusPage(message: _message ?? '正在连接服务端'),
      _AuthGateStatus.blocked => _ForceUpdatePage(update: _updateInfo),
      _AuthGateStatus.signedOut => _AuthPage(
          api: _api,
          initialMessage: _message,
          onSignedIn: _handleSignedIn,
        ),
      _AuthGateStatus.signedIn => LifeHomePage(onSignOut: _handleSignOut),
    };
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
    var normalized = _toHalfWidthAscii(value.trim())
        .replaceAll('。', '.')
        .replaceAll('．', '.')
        .replaceAll('｡', '.');
    if (_channel == _AuthChannel.email) {
      return normalized
          .replaceAll(_authHiddenOrWhitespacePattern, '')
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
        .replaceAll(_authHiddenOrWhitespacePattern, '')
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
      onModeChanged: (mode) => setState(() => _mode = mode),
      onChannelChanged: (channel) => setState(() => _channel = channel),
      onSubmit: _submit,
    );
    final parsedBaseUrl = Uri.tryParse(_apiBaseUrl);
    final serverNote = parsedBaseUrl?.host.isNotEmpty == true
        ? parsedBaseUrl!.host
        : _apiBaseUrl
            .replaceAll(RegExp(r'^https?://'), '')
            .replaceAll('/api', '');

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
                        child: Text(
                          '本地服务 · $serverNote',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
            const _AppIconMark(size: 64),
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

class _ForceUpdatePage extends StatelessWidget {
  const _ForceUpdatePage({required this.update});

  final _UpdateInfo? update;
  static const _launcher = MethodChannel('pingsheng_life/update_launcher');

  Future<void> _openDownload(BuildContext context, String url) async {
    try {
      await _launcher.invokeMethod<void>('openDownloadUrl', {'url': url});
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开浏览器，下载地址已复制')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = update;
    final downloadUrl = info?.downloadUrl ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AppIconMark(size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    '需要更新后继续使用',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info?.message?.isNotEmpty == true
                        ? info!.message!
                        : '当前版本已低于服务端最低支持版本。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UpdateLine(
                            label: '当前版本',
                            value: '$_appVersionName ($_appVersionCode)'),
                        const SizedBox(height: 10),
                        _UpdateLine(
                          label: '最新版本',
                          value:
                              '${info?.latestVersionName ?? '-'} (${info?.latestVersionCode ?? '-'})',
                        ),
                        if (info?.releaseNotes.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          ...info!.releaseNotes.map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '• $note',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (downloadUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SelectableText(
                      downloadUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => unawaited(
                        _openDownload(context, downloadUrl),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded),
                      label: const Text('立即更新'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        fixedSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: downloadUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('下载地址已复制')),
                        );
                      },
                      icon: const Icon(Icons.content_copy_rounded),
                      label: const Text('复制下载地址'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        fixedSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateLine extends StatelessWidget {
  const _UpdateLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted, fontWeight: FontWeight.w800)),
        Text(value,
            style: const TextStyle(
                color: AppColors.ink, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _AuthLaunchBackdrop extends StatelessWidget {
  const _AuthLaunchBackdrop();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _AuthLaunchBackdropPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _AuthLaunchBackdropPainter extends CustomPainter {
  const _AuthLaunchBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFFE4AE),
            Color(0xFFF9EFD9),
            Color(0xFFDDEAF1),
          ],
          stops: [0, 0.54, 1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.42, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFC05A).withValues(alpha: 0.2),
            const Color(0xFFFFF3D7).withValues(alpha: 0),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width * 0.42, size.height)),
    );

    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.56, 0, size.width * 0.44, size.height),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFF8ECD4).withValues(alpha: 0),
            const Color(0xFFB8D2E4).withValues(alpha: 0.3),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromLTWH(size.width * 0.56, 0, size.width * 0.44, size.height),
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFF3CF85).withValues(alpha: 0),
            const Color(0xFF82BFE0).withValues(alpha: 0.16),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromLTWH(0, size.height * 0.68, size.width, size.height * 0.32),
        ),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFB99E72).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const spacing = 48.0;
    for (var x = 0.0; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final softGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var x = spacing / 2; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), softGridPaint);
    }
    for (var y = spacing / 2; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), softGridPaint);
    }

    final vignette = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant _AuthLaunchBackdropPainter oldDelegate) => false;
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
    required this.mode,
    required this.channel,
    required this.nameController,
    required this.accountController,
    required this.passwordController,
    required this.busy,
    required this.error,
    required this.onModeChanged,
    required this.onChannelChanged,
    required this.onSubmit,
  });

  final _AuthMode mode;
  final _AuthChannel channel;
  final TextEditingController nameController;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final bool busy;
  final String? error;
  final ValueChanged<_AuthMode> onModeChanged;
  final ValueChanged<_AuthChannel> onChannelChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final isRegister = mode == _AuthMode.register;
    final isEmail = channel == _AuthChannel.email;
    final title = isRegister ? '创建账号' : '欢迎回来';
    final submitLabel = isRegister ? '进入我的平生' : '回到我的平生';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74624D).withValues(alpha: 0.13),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ACCOUNT',
                      style: TextStyle(
                        color: Color(0xFFA8AFC0),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF9EE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBDF0DC), width: 2),
                ),
                child: Icon(
                  isRegister
                      ? Icons.check_box_outline_blank_rounded
                      : Icons.login_rounded,
                  color: const Color(0xFF44B892),
                  size: isRegister ? 17 : 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AuthSegment(
            leftLabel: '注册',
            rightLabel: '登录',
            leftSelected: isRegister,
            onLeft: () => onModeChanged(_AuthMode.register),
            onRight: () => onModeChanged(_AuthMode.login),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AuthChannelCard(
                  icon: Icons.alternate_email_rounded,
                  label: '邮箱',
                  selected: isEmail,
                  onTap: () => onChannelChanged(_AuthChannel.email),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AuthChannelCard(
                  icon: Icons.phone_iphone_rounded,
                  label: '手机号',
                  selected: !isEmail,
                  onTap: () => onChannelChanged(_AuthChannel.phone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isRegister) ...[
            _AuthTextField(
              controller: nameController,
              icon: Icons.auto_awesome_rounded,
              label: '给自己取个昵称',
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          _AuthTextField(
            controller: accountController,
            icon: isEmail ? Icons.alternate_email_rounded : Icons.phone_rounded,
            label: isEmail ? '邮箱地址' : '手机号码',
            keyboardType:
                isEmail ? TextInputType.emailAddress : TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: passwordController,
            icon: Icons.circle_rounded,
            label: '设置密码',
            obscureText: true,
            onSubmitted: (_) {
              if (!busy) {
                unawaited(onSubmit());
              }
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: error == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _AuthErrorBanner(message: error!),
                  ),
          ),
          const SizedBox(height: 18),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: busy
                    ? [
                        const Color(0xFF7B91E8),
                        const Color(0xFFB86F5C),
                      ]
                    : [
                        const Color(0xFF4E659A),
                        const Color(0xFF2646FF),
                        const Color(0xFFD76A42),
                      ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2D49D6).withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FilledButton(
              onPressed: busy ? null : () => unawaited(onSubmit()),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.78),
                shadowColor: Colors.transparent,
                fixedSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.isRegister});

  final bool isRegister;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today =
        '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final title = isRegister ? '把今天，留在平生。' : '回到今天，继续平生。';
    final description = isRegister
        ? '一个干净、私密、只属于你的记录空间。先\n创建账号，开始写下第一条。'
        : '你的记录都在这里。登录账号，接上\n今天的生活线索。';

    return SizedBox(
      height: 350,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFFCF6),
                    Color(0xFFF9ECCC),
                    Color(0xFFFFFBF3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7D6A50).withValues(alpha: 0.12),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: CustomPaint(painter: _AuthHeaderMotifPainter()),
                    ),
                    const Positioned(
                      top: 22,
                      left: 22,
                      child: _AuthLogoBadge(),
                    ),
                    Positioned(
                      top: 24,
                      right: 20,
                      child: _AuthBrandLockup(today: today),
                    ),
                    Positioned(
                      left: 26,
                      right: 30,
                      top: 152,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF172038),
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 26,
                      right: 28,
                      bottom: 34,
                      child: Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF5B584F),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.6,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 54,
            bottom: -2,
            child: _AuthPaperClip(),
          ),
        ],
      ),
    );
  }
}

class _AuthBrandLockup extends StatelessWidget {
  const _AuthBrandLockup({required this.today});

  final String today;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 46,
            top: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'PINGSHENG NOTES',
                  style: TextStyle(
                    color: Color(0xFF9E9A98),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '平生',
                  style: TextStyle(
                    color: Color(0xFF171B2E),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: _AuthDateStamp(today: today),
          ),
        ],
      ),
    );
  }
}

class _AuthDateStamp extends StatelessWidget {
  const _AuthDateStamp({required this.today});

  final String today;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.32),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF0B391).withValues(alpha: 0.78),
          width: 1.1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '今日',
            style: TextStyle(
              color: Color(0xFFA58980),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            today,
            style: const TextStyle(
              color: Color(0xFFE16C45),
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogoBadge extends StatelessWidget {
  const _AuthLogoBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 12,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFCEC8B4).withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFAE5C),
                    Color(0xFFFF7A4B),
                    Color(0xFF4769E8),
                  ],
                  stops: [0, 0.42, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF344BD5).withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  Positioned.fill(
                    child: CustomPaint(painter: _AuthLogoSlashPainter()),
                  ),
                  Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLogoSlashPainter extends CustomPainter {
  const _AuthLogoSlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final slash = Path()
      ..moveTo(size.width * 0.35, size.height * 0.72)
      ..lineTo(size.width * 0.68, size.height * 0.24);
    canvas.drawPath(slash, paint);

    final note = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.31,
        size.height * 0.31,
        size.width * 0.24,
        size.height * 0.34,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(note, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthLogoSlashPainter oldDelegate) => false;
}

class _AuthHeaderMotifPainter extends CustomPainter {
  const _AuthHeaderMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            const Color(0xFFFFE7B7).withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..color = const Color(0xFFE8A36F).withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.79),
      size.width * 0.23,
      ringPaint,
    );

    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFE8A36F).withValues(alpha: 0.16);
    canvas.drawCircle(
      Offset(size.width * 0.83, size.height * 0.79),
      size.width * 0.31,
      innerRingPaint,
    );

    final baseLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1;
    for (var y = 30.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), baseLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthHeaderMotifPainter oldDelegate) => false;
}

class _AuthPaperClip extends StatelessWidget {
  const _AuthPaperClip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 70,
      height: 58,
      child: CustomPaint(painter: _AuthPaperClipPainter()),
    );
  }
}

class _AuthPaperClipPainter extends CustomPainter {
  const _AuthPaperClipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF9AAFFF).withValues(alpha: 0.64);

    final outer = Path()
      ..moveTo(size.width * 0.26, size.height * 0.93)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.48,
        size.width * 0.22,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.14,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.09,
        size.width * 0.79,
        size.height * 0.36,
        size.width * 0.82,
        size.height * 0.78,
      );
    canvas.drawPath(outer, paint);

    final inner = Path()
      ..moveTo(size.width * 0.39, size.height * 0.9)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.55,
        size.width * 0.38,
        size.height * 0.32,
        size.width * 0.55,
        size.height * 0.29,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.27,
        size.width * 0.68,
        size.height * 0.46,
        size.width * 0.7,
        size.height * 0.72,
      );
    paint.strokeWidth = 2.4;
    canvas.drawPath(inner, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthPaperClipPainter oldDelegate) => false;
}

class _AuthSegment extends StatelessWidget {
  const _AuthSegment({
    required this.leftLabel,
    required this.rightLabel,
    required this.leftSelected,
    required this.onLeft,
    required this.onRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool leftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1DCCF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthSegmentButton(
              label: leftLabel,
              selected: leftSelected,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _AuthSegmentButton(
              label: rightLabel,
              selected: !leftSelected,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthSegmentButton extends StatelessWidget {
  const _AuthSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF121A31) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF182033).withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF777C8A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AuthChannelCard extends StatelessWidget {
  const _AuthChannelCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F4FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF9AAFFF) : const Color(0xFFE4E8EF),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9CA9C0).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF315DE8) : AppColors.muted,
              size: 17,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF315DE8) : AppColors.muted,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFC5BA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_rounded,
            color: AppColors.financeRed,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.financeRed,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDotIcon = icon == Icons.circle_rounded;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.primary,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        prefixIcon: SizedBox(
          width: 50,
          child: Center(
            child: Icon(
              icon,
              color: const Color(0xFFE16C45),
              size: isDotIcon ? 7 : 18,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints.tightFor(width: 50),
        hintText: label,
        hintStyle: const TextStyle(
          color: Color(0xFF9AA2AF),
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF9AAFFF), width: 1.5),
        ),
      ),
    );
  }
}
