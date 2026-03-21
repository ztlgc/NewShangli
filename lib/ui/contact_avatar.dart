import 'dart:io';

import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// 联系人默认头像（文字头像 + 网络头像兜底）。
///
/// 设计目标：
/// - 当联系人未上传头像，或网络加载失败/无网络时，也能稳定渲染文字头像；
/// - 文字头像从姓名中提取“首字/首字母”（中文取姓氏首字，英文取第一个单词首字母）；
/// - 支持多种姓名格式（中英文混合、空格分隔、包含符号/表情等极端输入）；
/// - 为不同字母/字符分配稳定的配色方案，保证前景文字清晰可读；
/// - 支持圆形与圆角矩形两种形态，字号随尺寸自适应。
enum ContactAvatarShape {
  /// 圆形头像（默认）。
  circle,

  /// 圆角矩形头像。
  roundedRect,
}

/// 头像配色方案（背景 + 前景文字）。
@immutable
class ContactAvatarColorScheme {
  const ContactAvatarColorScheme({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// 依据姓名生成联系人头像。
///
/// - [avatarUrl] 非空时优先加载网络图片；
/// - 加载中/失败时回退为文字头像（不会出现“空白占位”）。
class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.size,
    this.shape = ContactAvatarShape.circle,
    this.border,
    this.borderRadius,
  });

  /// 联系人姓名（用于生成文字头像内容与配色）。
  final String? name;

  /// 联系人头像网络地址（可空）。
  final String? avatarUrl;

  /// 头像边长（像素）。
  final double size;

  /// 头像形状（圆形/圆角矩形）。
  final ContactAvatarShape shape;

  /// 可选边框（常用于列表小头像的描边）。
  final BoxBorder? border;

  /// 仅当 [shape] 为 [ContactAvatarShape.roundedRect] 时有效。
  /// 若不传，会使用 `size * 0.25` 的默认圆角。
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final displayText = contactAvatarTextFromName(name);
    final colorScheme = contactAvatarColorScheme(displayText);
    final normalizedUrl = avatarUrl?.trim();

    final fallback = _buildTextAvatar(
      text: displayText,
      colorScheme: colorScheme,
    );

    // 设计选择：当存在 avatarUrl 时，也始终先渲染文字头像作为“底图”。
    // 这样无论是加载中、无网络、图片 404，界面都不会出现闪烁/空白块。
    final isFileUri = normalizedUrl != null && normalizedUrl.startsWith('file://');
    final isLocalPath = normalizedUrl != null && normalizedUrl.isNotEmpty && (normalizedUrl.contains(r'\') || normalizedUrl.contains(':/'));
    final content = normalizedUrl != null && normalizedUrl.isNotEmpty
        ? Stack(
            fit: StackFit.expand,
            children: [
              fallback,
              if (isFileUri || isLocalPath)
                Image.file(
                  File(isFileUri ? Uri.parse(normalizedUrl).toFilePath(windows: Platform.isWindows) : normalizedUrl),
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                )
              else
                Image.network(
                  normalizedUrl,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
            ],
          )
        : fallback;

    // 统一做形状裁剪，保证网络图/文字头像在任何情况下都不会溢出容器。
    final clippedChild = _clipByShape(
      child: content,
    );

    // 外层负责尺寸、背景与边框；内部 child 只负责内容。
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.background,
          shape: shape == ContactAvatarShape.circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: shape == ContactAvatarShape.roundedRect
              ? (borderRadius ?? BorderRadius.circular(size * 0.25))
              : null,
          border: border,
        ),
        child: clippedChild,
      ),
    );
  }

  Widget _clipByShape({required Widget child}) {
    if (shape == ContactAvatarShape.circle) {
      return ClipOval(child: child);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(size * 0.25),
      child: child,
    );
  }

  Widget _buildTextAvatar({
    required String text,
    required ContactAvatarColorScheme colorScheme,
  }) {
    // 采用 FittedBox 做最终兜底缩放，确保小尺寸/宽字母（如 W）也能完整显示。
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: AppTypography.base(
              // 粗略按边长比例给一个字号，再由 FittedBox 兜底缩放。
              fontSize: _recommendedFontSize(text, size),
              fontWeight: AppTypography.bold,
              color: colorScheme.foreground,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// 从姓名中提取用于头像展示的“首字/首字母”。
///
/// 规则（尽量贴合用户认知，同时对极端输入保持稳定）：
/// - 空/全空白：返回 '—'；
/// - 以中文（汉字）为主：取第一个出现的汉字（通常就是姓氏首字，兼容复姓/空格分隔）；
/// - 英文：取第一个“单词”中出现的英文字母（A-Z），并转为大写；
/// - 中英文混合：优先使用首个有效片段的规则；若首片段无效，则在全名中继续查找；
/// - 仍无法提取：返回 '#'.
String contactAvatarTextFromName(String? rawName) {
  final name = (rawName ?? '').trim();
  if (name.isEmpty) return '—';

  // 将连续空白统一为单空格，便于按“单词/片段”处理。
  final normalized = name.replaceAll(RegExp(r'\s+'), ' ');

  // “英文取第一个单词首字母”：这里优先以第一个非空片段为候选。
  final firstSegment = normalized.split(' ').firstWhere((s) => s.trim().isNotEmpty, orElse: () => normalized);

  final fromSegment = _extractAvatarTextFromSegment(firstSegment);
  if (fromSegment != null) return fromSegment;

  // 若首片段无法提取（例如以表情/符号开头），则退而求其次扫描全名。
  final fromAll = _extractAvatarTextFromSegment(normalized);
  if (fromAll != null) return fromAll;

  return '#';
}

String? _extractAvatarTextFromSegment(String segment) {
  if (segment.trim().isEmpty) return null;

  // 1) 若存在汉字：取第一个汉字。
  final hanMatch = RegExp(r'[\u4E00-\u9FFF]').firstMatch(segment);
  if (hanMatch != null) {
    return segment.substring(hanMatch.start, hanMatch.end);
  }

  // 2) 若存在英文字母：取第一个字母，并大写。
  final latinMatch = RegExp(r'[A-Za-z]').firstMatch(segment);
  if (latinMatch != null) {
    return latinMatch.group(0)!.toUpperCase();
  }

  return null;
}

/// 将头像文字映射到稳定的配色方案。
///
/// - 同一个字符始终映射到同一套配色；
/// - '#','—' 走统一“中性”方案；
/// - 其余字符使用字符码点取模进行分配（对中文也稳定）。
ContactAvatarColorScheme contactAvatarColorScheme(String avatarText) {
  final t = avatarText.trim();
  if (t.isEmpty || t == '#' || t == '—') {
    return const ContactAvatarColorScheme(
      background: AppColors.gray200,
      foreground: AppColors.gray700,
    );
  }

  // 统一大小写，确保 'a' 与 'A' 配色一致。
  final normalized = RegExp(r'^[A-Za-z]$').hasMatch(t) ? t.toUpperCase() : t;
  final rune = normalized.runes.isNotEmpty ? normalized.runes.first : 0;

  // 调色板：前景色选择更深色，保证在浅背景上可读。
  const palette = <ContactAvatarColorScheme>[
    ContactAvatarColorScheme(background: AppColors.indigo100, foreground: AppColors.indigo700),
    ContactAvatarColorScheme(background: AppColors.blue100, foreground: AppColors.blue600),
    ContactAvatarColorScheme(background: AppColors.green100, foreground: AppColors.green600),
    ContactAvatarColorScheme(background: AppColors.purple100, foreground: AppColors.purple600),
    ContactAvatarColorScheme(background: AppColors.pink100, foreground: AppColors.pink600),
    ContactAvatarColorScheme(background: AppColors.orange100, foreground: AppColors.orange600),
    ContactAvatarColorScheme(background: AppColors.red100, foreground: AppColors.red600),
  ];

  final index = rune % palette.length;
  return palette[index];
}

double _recommendedFontSize(String text, double size) {
  // 对于单字符头像，经验上 0.52~0.62 的比例较稳；中文略小更舒服。
  final isLatin = RegExp(r'^[A-Z]$').hasMatch(text.trim());
  final factor = isLatin ? 0.58 : 0.52;
  final fs = size * factor;

  // 保护上/下限：避免极小头像不可读或极大头像过分夸张。
  return fs.clamp(10.0, 56.0);
}
