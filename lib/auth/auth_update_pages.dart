// 中文注释：登录注册与更新提示界面，负责进入首页前的账号和版本流程。

part of 'auth.dart';

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
                  const AppIconMark(size: 64),
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
                            value: '$appVersionName ($appVersionCode)'),
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

class _OptionalUpdatePage extends StatelessWidget {
  const _OptionalUpdatePage({
    required this.update,
    required this.onSkip,
  });

  final _UpdateInfo? update;
  final VoidCallback onSkip;
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
                  const AppIconMark(size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    '发现新版本',
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
                        : '有新版本可用，建议更新后获得最新体验。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
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
                          value: '$appVersionName ($appVersionCode)',
                        ),
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
                  const SizedBox(height: 16),
                  if (downloadUrl.isNotEmpty)
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      fixedSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('稍后再说'),
                  ),
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
