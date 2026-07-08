// 中文注释：登录注册与更新提示界面，负责进入首页前的账号和版本流程。

part of 'auth.dart';

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

    return GlassSurface(
      borderRadius: 12,
      color: Colors.white.withValues(alpha: 0.88),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
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
            inputFormatters: isEmail
                ? null
                : [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: passwordController,
            icon: Icons.circle_rounded,
            label: isRegister ? '设置密码' : '输入密码',
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
    this.inputFormatters,
    this.textInputAction,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isDotIcon = icon == Icons.circle_rounded;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
