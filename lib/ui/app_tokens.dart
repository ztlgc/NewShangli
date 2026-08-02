import 'package:flutter/material.dart';

/// 由 prototype/design-tokens.json 映射得到的设计令牌。
/// 目标：让 UI 代码在 Flutter 中使用与原型一致的颜色、字号、圆角、阴影与尺寸。
class AppTokens {
  static const Size designSize = Size(393, 852);
  static const double statusBarHeight = 47;
  static const double tabBarHeight = 64;
  static const double tapTargetMin = 44;
  static const double bottomSafeSpacing = 0;

  /// 悬浮底部导航栏：距屏幕底部安全区外侧的间距。
  static const double floatingNavBottomInset = 24;

  /// 悬浮底部导航栏：左右两侧留白。
  static const double floatingNavSideInset = 32;

  /// 悬浮底部导航栏自身高度。
  static const double floatingNavHeight = 56;

  static const double space0 = 0;
  static const double space0_5 = 2;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
}

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);

  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo200 = Color(0xFFC7D2FE);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo800 = Color(0xFF3730A3);
  static const indigo900 = Color(0xFF312E81);

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);

  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);

  static const red100 = Color(0xFFFEE2E2);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);

  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);

  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple500 = Color(0xFFA855F7);
  static const purple600 = Color(0xFF9333EA);

  static const pink50 = Color(0xFFFDF2F8);
  static const pink100 = Color(0xFFFCE7F3);
  static const pink500 = Color(0xFFEC4899);
  static const pink600 = Color(0xFFDB2777);

  static const orange50 = Color(0xFFFFF7ED);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange400 = Color(0xFFFB923C);
  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);

  static const yellow500 = Color(0xFFEAB308);

  static const scrimBlack30 = Color(0x4D000000);
  static const indigo900_40 = Color(0x66312E81);
  static const white10 = Color(0x1AFFFFFF);
  static const white20 = Color(0x33FFFFFF);

  static const brandPrimary = indigo900;
  static const brandSecondary = indigo600;
  static const brandSoft = indigo50;

  static const surfaceApp = gray50;
  static const surfaceCard = white;
  static const surfaceSubtle = gray100;

  static const textPrimary = gray900;
  static const textSecondary = gray600;
  static const textTertiary = gray500;
  static const textMuted = gray400;
  static const textInverse = white;
  static const textBrand = indigo900;

  static const borderDefault = gray200;
  static const borderSubtle = gray100;
  static const borderDivider = gray50;
  static const borderFocus = indigo600;

  static const stateSuccess = green600;
  static const stateSuccessSoft = green100;
  static const stateDanger = red500;
  static const stateDangerStrong = red600;
  static const stateDangerSoft = red100;
  static const stateWarning = orange500;
  static const stateWarningSoft = orange100;
}

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.surfaceApp,
    required this.surfaceCard,
    required this.surfaceSubtle,
    required this.surfacePressed,
    required this.surfaceDisabled,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textMuted,
    required this.textInverse,
    required this.textBrand,
    required this.brandPrimary,
    required this.brandSecondary,
    required this.brandSoft,
    required this.brandOnSoft,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderDivider,
    required this.borderFocus,
    required this.stateSuccess,
    required this.stateSuccessSoft,
    required this.stateDanger,
    required this.stateDangerStrong,
    required this.stateDangerSoft,
    required this.stateWarning,
    required this.stateWarningSoft,
    required this.blueAccent,
    required this.blueSoft,
    required this.purpleAccent,
    required this.purpleSoft,
    required this.pinkAccent,
    required this.pinkSoft,
    required this.orangeAccent,
    required this.orangeSoft,
    required this.neutralAccent,
  });

  final Color surfaceApp;
  final Color surfaceCard;
  final Color surfaceSubtle;
  final Color surfacePressed;
  final Color surfaceDisabled;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textMuted;
  final Color textInverse;
  final Color textBrand;
  final Color brandPrimary;
  final Color brandSecondary;
  final Color brandSoft;
  final Color brandOnSoft;
  final Color borderDefault;
  final Color borderSubtle;
  final Color borderDivider;
  final Color borderFocus;
  final Color stateSuccess;
  final Color stateSuccessSoft;
  final Color stateDanger;
  final Color stateDangerStrong;
  final Color stateDangerSoft;
  final Color stateWarning;
  final Color stateWarningSoft;
  final Color blueAccent;
  final Color blueSoft;
  final Color purpleAccent;
  final Color purpleSoft;
  final Color pinkAccent;
  final Color pinkSoft;
  final Color orangeAccent;
  final Color orangeSoft;
  final Color neutralAccent;

  static const light = AppThemeColors(
    surfaceApp: AppColors.surfaceApp,
    surfaceCard: AppColors.surfaceCard,
    surfaceSubtle: AppColors.surfaceSubtle,
    surfacePressed: AppColors.gray50,
    surfaceDisabled: AppColors.gray200,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    textMuted: AppColors.textMuted,
    textInverse: AppColors.textInverse,
    textBrand: AppColors.textBrand,
    brandPrimary: AppColors.brandPrimary,
    brandSecondary: AppColors.brandSecondary,
    brandSoft: AppColors.brandSoft,
    brandOnSoft: AppColors.indigo700,
    borderDefault: AppColors.borderDefault,
    borderSubtle: AppColors.borderSubtle,
    borderDivider: AppColors.borderDivider,
    borderFocus: AppColors.borderFocus,
    stateSuccess: AppColors.stateSuccess,
    stateSuccessSoft: AppColors.stateSuccessSoft,
    stateDanger: AppColors.stateDanger,
    stateDangerStrong: AppColors.stateDangerStrong,
    stateDangerSoft: AppColors.stateDangerSoft,
    stateWarning: AppColors.stateWarning,
    stateWarningSoft: AppColors.stateWarningSoft,
    blueAccent: AppColors.blue600,
    blueSoft: AppColors.blue50,
    purpleAccent: AppColors.purple600,
    purpleSoft: AppColors.purple50,
    pinkAccent: AppColors.pink600,
    pinkSoft: AppColors.pink50,
    orangeAccent: AppColors.orange600,
    orangeSoft: AppColors.orange50,
    neutralAccent: AppColors.gray500,
  );

  static const dark = AppThemeColors(
    surfaceApp: Color(0xFF0E1116),
    surfaceCard: Color(0xFF171B22),
    surfaceSubtle: Color(0xFF222832),
    surfacePressed: Color(0xFF2A3140),
    surfaceDisabled: Color(0xFF3C4658),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFD1D5DB),
    textTertiary: Color(0xFF9CA3AF),
    textMuted: Color(0xFF6B7280),
    textInverse: AppColors.white,
    textBrand: Color(0xFFC7D2FE),
    brandPrimary: AppColors.indigo500,
    brandSecondary: Color(0xFF818CF8),
    brandSoft: Color(0xFF252146),
    brandOnSoft: Color(0xFFC7D2FE),
    borderDefault: Color(0xFF3B4358),
    borderSubtle: Color(0xFF2A3140),
    borderDivider: Color(0xFF222832),
    borderFocus: Color(0xFF818CF8),
    stateSuccess: Color(0xFF4ADE80),
    stateSuccessSoft: Color(0xFF052E16),
    stateDanger: Color(0xFFF87171),
    stateDangerStrong: Color(0xFFFCA5A5),
    stateDangerSoft: Color(0xFF450A0A),
    stateWarning: Color(0xFFFDBA74),
    stateWarningSoft: Color(0xFF431407),
    blueAccent: Color(0xFF93C5FD),
    blueSoft: Color(0xFF172554),
    purpleAccent: Color(0xFFD8B4FE),
    purpleSoft: Color(0xFF3B0764),
    pinkAccent: Color(0xFFF9A8D4),
    pinkSoft: Color(0xFF500724),
    orangeAccent: Color(0xFFFDBA74),
    orangeSoft: Color(0xFF431407),
    neutralAccent: Color(0xFF9CA3AF),
  );

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  Color pageBackgroundFor(Color color) {
    if (color == AppColors.white ||
        color == AppColors.surfaceCard ||
        color == AppColors.surfaceApp ||
        color == AppColors.gray50 ||
        color == AppColors.gray100) {
      return surfaceApp;
    }
    return surfaceFor(color);
  }

  Color surfaceFor(Color color) {
    if (color == AppColors.white || color == AppColors.surfaceCard) {
      return surfaceCard;
    }
    if (color == AppColors.surfaceApp || color == AppColors.gray50) {
      return surfaceApp;
    }
    if (color == AppColors.surfaceSubtle ||
        color == AppColors.gray100 ||
        color == AppColors.gray200) {
      return surfaceSubtle;
    }
    return softFor(color);
  }

  Color softFor(Color color) {
    if (color == AppColors.indigo50 ||
        color == AppColors.indigo100 ||
        color == AppColors.indigo200 ||
        color == AppColors.brandSoft) {
      return brandSoft;
    }
    if (color == AppColors.blue50 || color == AppColors.blue100) {
      return blueSoft;
    }
    if (color == AppColors.green50 ||
        color == AppColors.green100 ||
        color == AppColors.stateSuccessSoft) {
      return stateSuccessSoft;
    }
    if (color == AppColors.red100 || color == AppColors.stateDangerSoft) {
      return stateDangerSoft;
    }
    if (color == AppColors.orange50 ||
        color == AppColors.orange100 ||
        color == AppColors.stateWarningSoft) {
      return stateWarningSoft;
    }
    if (color == AppColors.purple50 || color == AppColors.purple100) {
      return purpleSoft;
    }
    if (color == AppColors.pink50 || color == AppColors.pink100) {
      return pinkSoft;
    }
    if (color == AppColors.gray50 ||
        color == AppColors.gray100 ||
        color == AppColors.gray200 ||
        color == AppColors.surfaceSubtle) {
      return surfaceSubtle;
    }
    return color;
  }

  Color foregroundFor(Color color) {
    if (color == AppColors.textPrimary ||
        color == AppColors.gray900 ||
        color == AppColors.gray800) {
      return textPrimary;
    }
    if (color == AppColors.textSecondary ||
        color == AppColors.gray700 ||
        color == AppColors.gray600) {
      return textSecondary;
    }
    if (color == AppColors.textTertiary || color == AppColors.gray500) {
      return textTertiary;
    }
    if (color == AppColors.textMuted ||
        color == AppColors.gray400 ||
        color == AppColors.gray300) {
      return textMuted;
    }
    if (color == AppColors.textBrand ||
        color == AppColors.brandPrimary ||
        color == AppColors.brandSecondary ||
        color == AppColors.indigo900 ||
        color == AppColors.indigo800 ||
        color == AppColors.indigo700 ||
        color == AppColors.indigo600 ||
        color == AppColors.indigo500) {
      return brandOnSoft;
    }
    if (color == AppColors.green600 || color == AppColors.green500) {
      return stateSuccess;
    }
    if (color == AppColors.red600 ||
        color == AppColors.red500 ||
        color == AppColors.stateDanger ||
        color == AppColors.stateDangerStrong) {
      return color == AppColors.red600 || color == AppColors.stateDangerStrong
          ? stateDangerStrong
          : stateDanger;
    }
    if (color == AppColors.orange600 ||
        color == AppColors.orange500 ||
        color == AppColors.orange400 ||
        color == AppColors.stateWarning) {
      return stateWarning;
    }
    if (color == AppColors.blue600 || color == AppColors.blue500) {
      return blueAccent;
    }
    if (color == AppColors.purple600 || color == AppColors.purple500) {
      return purpleAccent;
    }
    if (color == AppColors.pink600 || color == AppColors.pink500) {
      return pinkAccent;
    }
    return color;
  }

  Color borderFor(Color color) {
    if (color == AppColors.borderDefault ||
        color == AppColors.gray200 ||
        color == AppColors.gray300) {
      return borderDefault;
    }
    if (color == AppColors.borderSubtle || color == AppColors.gray100) {
      return borderSubtle;
    }
    if (color == AppColors.borderDivider ||
        color == AppColors.gray50 ||
        color == AppColors.white) {
      return borderDivider;
    }
    if (color == AppColors.borderFocus) return borderFocus;
    return color;
  }

  @override
  AppThemeColors copyWith({
    Color? surfaceApp,
    Color? surfaceCard,
    Color? surfaceSubtle,
    Color? surfacePressed,
    Color? surfaceDisabled,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textMuted,
    Color? textInverse,
    Color? textBrand,
    Color? brandPrimary,
    Color? brandSecondary,
    Color? brandSoft,
    Color? brandOnSoft,
    Color? borderDefault,
    Color? borderSubtle,
    Color? borderDivider,
    Color? borderFocus,
    Color? stateSuccess,
    Color? stateSuccessSoft,
    Color? stateDanger,
    Color? stateDangerStrong,
    Color? stateDangerSoft,
    Color? stateWarning,
    Color? stateWarningSoft,
    Color? blueAccent,
    Color? blueSoft,
    Color? purpleAccent,
    Color? purpleSoft,
    Color? pinkAccent,
    Color? pinkSoft,
    Color? orangeAccent,
    Color? orangeSoft,
    Color? neutralAccent,
  }) {
    return AppThemeColors(
      surfaceApp: surfaceApp ?? this.surfaceApp,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      surfaceDisabled: surfaceDisabled ?? this.surfaceDisabled,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textMuted: textMuted ?? this.textMuted,
      textInverse: textInverse ?? this.textInverse,
      textBrand: textBrand ?? this.textBrand,
      brandPrimary: brandPrimary ?? this.brandPrimary,
      brandSecondary: brandSecondary ?? this.brandSecondary,
      brandSoft: brandSoft ?? this.brandSoft,
      brandOnSoft: brandOnSoft ?? this.brandOnSoft,
      borderDefault: borderDefault ?? this.borderDefault,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDivider: borderDivider ?? this.borderDivider,
      borderFocus: borderFocus ?? this.borderFocus,
      stateSuccess: stateSuccess ?? this.stateSuccess,
      stateSuccessSoft: stateSuccessSoft ?? this.stateSuccessSoft,
      stateDanger: stateDanger ?? this.stateDanger,
      stateDangerStrong: stateDangerStrong ?? this.stateDangerStrong,
      stateDangerSoft: stateDangerSoft ?? this.stateDangerSoft,
      stateWarning: stateWarning ?? this.stateWarning,
      stateWarningSoft: stateWarningSoft ?? this.stateWarningSoft,
      blueAccent: blueAccent ?? this.blueAccent,
      blueSoft: blueSoft ?? this.blueSoft,
      purpleAccent: purpleAccent ?? this.purpleAccent,
      purpleSoft: purpleSoft ?? this.purpleSoft,
      pinkAccent: pinkAccent ?? this.pinkAccent,
      pinkSoft: pinkSoft ?? this.pinkSoft,
      orangeAccent: orangeAccent ?? this.orangeAccent,
      orangeSoft: orangeSoft ?? this.orangeSoft,
      neutralAccent: neutralAccent ?? this.neutralAccent,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      surfaceApp: Color.lerp(surfaceApp, other.surfaceApp, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      surfaceDisabled: Color.lerp(surfaceDisabled, other.surfaceDisabled, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      brandPrimary: Color.lerp(brandPrimary, other.brandPrimary, t)!,
      brandSecondary: Color.lerp(brandSecondary, other.brandSecondary, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      brandOnSoft: Color.lerp(brandOnSoft, other.brandOnSoft, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDivider: Color.lerp(borderDivider, other.borderDivider, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      stateSuccess: Color.lerp(stateSuccess, other.stateSuccess, t)!,
      stateSuccessSoft: Color.lerp(
        stateSuccessSoft,
        other.stateSuccessSoft,
        t,
      )!,
      stateDanger: Color.lerp(stateDanger, other.stateDanger, t)!,
      stateDangerStrong: Color.lerp(
        stateDangerStrong,
        other.stateDangerStrong,
        t,
      )!,
      stateDangerSoft: Color.lerp(stateDangerSoft, other.stateDangerSoft, t)!,
      stateWarning: Color.lerp(stateWarning, other.stateWarning, t)!,
      stateWarningSoft: Color.lerp(
        stateWarningSoft,
        other.stateWarningSoft,
        t,
      )!,
      blueAccent: Color.lerp(blueAccent, other.blueAccent, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      purpleAccent: Color.lerp(purpleAccent, other.purpleAccent, t)!,
      purpleSoft: Color.lerp(purpleSoft, other.purpleSoft, t)!,
      pinkAccent: Color.lerp(pinkAccent, other.pinkAccent, t)!,
      pinkSoft: Color.lerp(pinkSoft, other.pinkSoft, t)!,
      orangeAccent: Color.lerp(orangeAccent, other.orangeAccent, t)!,
      orangeSoft: Color.lerp(orangeSoft, other.orangeSoft, t)!,
      neutralAccent: Color.lerp(neutralAccent, other.neutralAccent, t)!,
    );
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors => AppThemeColors.of(this);
}

class AppRadii {
  static const none = Radius.circular(0);
  static const sm = Radius.circular(2);
  static const md = Radius.circular(6);
  static const lg = Radius.circular(8);
  static const xl = Radius.circular(12);
  static const r2xl = Radius.circular(16);
  static const r3xl = Radius.circular(24);
  static const heroBottom = Radius.circular(30);

  static const BorderRadius brMd = BorderRadius.all(md);
  static const BorderRadius brLg = BorderRadius.all(lg);
  static const BorderRadius brXl = BorderRadius.all(xl);
  static const BorderRadius br2xl = BorderRadius.all(r2xl);
  static const BorderRadius br3xl = BorderRadius.all(r3xl);
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(9999));
}

class AppShadows {
  static const sm = <BoxShadow>[
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const lg = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static const xl = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 25,
      offset: Offset(0, 20),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 10,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  static const brandSoft = <BoxShadow>[
    BoxShadow(
      color: Color(0x33C7D2FE),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x1AC7D2FE),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];

  static const brandFab = <BoxShadow>[
    BoxShadow(
      color: AppColors.indigo900_40,
      blurRadius: 25,
      offset: Offset(0, 20),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: AppColors.indigo900_40,
      blurRadius: 10,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

class AppTypography {
  static const String primaryFontFamily = 'Noto Sans SC';
  static const List<String> fontFamilyFallback = <String>[
    'Noto Sans CJK SC',
    'Noto Sans',
    'Roboto',
    'sans-serif',
  ];

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  static const double fs10 = 10;
  static const double fs12 = 12;
  static const double fs14 = 14;
  static const double fs16 = 16;
  static const double fs18 = 18;
  static const double fs20 = 20;
  static const double fs24 = 24;
  static const double fs30 = 30;
  static const double fs36 = 36;

  static TextStyle base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: _resolveTypographyColor(color),
      height: height,
      letterSpacing: letterSpacing,
      decoration: TextDecoration.none,
    );
  }

  static Color _resolveTypographyColor(Color color) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness != Brightness.dark) return color;
    return AppThemeColors.dark.foregroundFor(color);
  }

  static TextStyle h1() =>
      _base(fontSize: fs24, fontWeight: bold, color: AppColors.textPrimary);

  static TextStyle h2() =>
      _base(fontSize: fs20, fontWeight: bold, color: AppColors.textPrimary);

  static TextStyle h3() =>
      _base(fontSize: fs18, fontWeight: bold, color: AppColors.textPrimary);

  static TextStyle body() => _base(
    fontSize: fs14,
    fontWeight: regular,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyStrong() =>
      _base(fontSize: fs16, fontWeight: medium, color: AppColors.textPrimary);

  static TextStyle caption() =>
      _base(fontSize: fs12, fontWeight: regular, color: AppColors.textMuted);

  static TextStyle overlineUpper() => _base(
    fontSize: fs10,
    fontWeight: bold,
    color: AppColors.textTertiary,
    letterSpacing: 0.05 * fs10,
  );

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) => base(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
