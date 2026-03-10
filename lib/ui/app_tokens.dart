import 'package:flutter/material.dart';

/// 由 prototype/design-tokens.json 映射得到的设计令牌。
/// 目标：让 UI 代码在 Flutter 中使用与原型一致的颜色、字号、圆角、阴影与尺寸。
class AppTokens {
  static const Size designSize = Size(393, 852);
  static const double statusBarHeight = 47;
  static const double tabBarHeight = 64;
  static const double tapTargetMin = 44;

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
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
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
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle h1() => _base(
        fontSize: fs24,
        fontWeight: bold,
        color: AppColors.textPrimary,
      );

  static TextStyle h2() => _base(
        fontSize: fs20,
        fontWeight: bold,
        color: AppColors.textPrimary,
      );

  static TextStyle h3() => _base(
        fontSize: fs18,
        fontWeight: bold,
        color: AppColors.textPrimary,
      );

  static TextStyle body() => _base(
        fontSize: fs14,
        fontWeight: regular,
        color: AppColors.textSecondary,
      );

  static TextStyle bodyStrong() => _base(
        fontSize: fs16,
        fontWeight: medium,
        color: AppColors.textPrimary,
      );

  static TextStyle caption() => _base(
        fontSize: fs12,
        fontWeight: regular,
        color: AppColors.textMuted,
      );

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
  }) =>
      base(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
}

