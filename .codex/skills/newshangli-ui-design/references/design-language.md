# NewShangli Design Language

## Product Character

NewShangli is a Chinese personal ledger for gift-money records, relationship contacts, account books, statistics, import/export, backup, and sync. The interface should read as a practical record-management app: restrained, legible, quick to operate, and familiar on mobile.

The current visual language is Material 3 plus a custom prototype token system. It uses indigo as the brand anchor, neutral surfaces, white grouped cards, compact rows, Font Awesome icons, and subtle pressed-scale feedback.

## Canonical Sources

- `lib/ui/app_tokens.dart`: authoritative Flutter tokens.
- `prototype/design-tokens.json`: prototype token source.
- `lib/ui/app_theme.dart`: light/dark theme setup and disabled splash/highlight behavior.
- `lib/ui/prototype_kit.dart`: app-specific top bar, icon button, bottom navigation, press feedback.
- `lib/ui/components.dart`: card, primary/secondary buttons, search field, pills, dividers, pressable rows, image fallback.
- `lib/ui/contact_avatar.dart`: relationship/contact avatar behavior and color schemes.

## Core Tokens

Colors:

- Brand primary: `AppColors.brandPrimary` / `AppColors.indigo900` / `#312E81`.
- Brand secondary: `AppColors.brandSecondary` / `AppColors.indigo600` / `#4F46E5`.
- Brand soft: `AppColors.brandSoft` / `AppColors.indigo50`.
- App background: `AppColors.surfaceApp` / `AppColors.gray50`.
- Card surface: `AppColors.surfaceCard` / `AppColors.white`.
- Subtle surface: `AppColors.surfaceSubtle` / `AppColors.gray100`.
- Primary text: `AppColors.textPrimary` / `AppColors.gray900`.
- Secondary text: `AppColors.textSecondary` / `AppColors.gray600`.
- Tertiary text: `AppColors.textTertiary` / `AppColors.gray500`.
- Muted text: `AppColors.textMuted` / `AppColors.gray400`.
- Border: `AppColors.borderDefault`, `borderSubtle`, `borderDivider`, `borderFocus`.
- State: `stateSuccess`, `stateDanger`, `stateWarning` with matching soft variants.

Typography:

- Font family: `Noto Sans SC`, then CJK/Roboto/sans fallbacks.
- Page title: 18-20 bold.
- Major page heading or strong KPI: 20-24 bold.
- Card title: 16-18 bold.
- Primary row text: 16 medium.
- Body: 14 regular.
- Caption/metadata: 12 regular.
- Overline: 10 bold/uppercase-style only for small section labels.
- Amounts: 16 semibold in rows, 24-36 bold for hero/detail totals.

Spacing:

- Base grid: 4 px.
- Page horizontal padding: 16.
- Section gap: 24.
- Card padding: 16.
- Row padding: horizontal 16, vertical 12.
- Control gaps: 8 or 12.
- Minimum tap target: 44.

Shape and depth:

- Small controls: `AppRadii.brLg` or `brXl`.
- Cards/dialog-like groups: `AppRadii.br2xl`.
- Large profile/summary panels: `br2xl` or `br3xl` only when already consistent with nearby pages.
- Pills: `AppRadii.brPill`.
- Use `AppShadows.sm` for standard cards, `AppShadows.brandFab` for the primary FAB, and avoid adding heavier shadows unless the existing screen uses them.

Motion:

- Global splash/highlight is disabled in `AppTheme`.
- Use `PressableScale` for tappable custom surfaces.
- Press and selection feedback should be quick: 150-250 ms.

## Reusable Components

Prefer these before creating new widgets:

- `AppScaffold`: page shell with safe area and optional bottom navigation.
- `PrototypeTopBar`: centered title top bar with optional left/right slots.
- `PrototypeIconButton`: circular/square icon action.
- `PrototypeBottomNav`: four-tab root navigation for records, relationships, stats, settings.
- `PressableScale`: touch feedback for custom buttons/cards.
- `PrototypeCard`: standard white grouped container.
- `PrototypePressableRow`: list row with pressed background and optional bottom divider.
- `PrototypeSearchField`: tokenized search input.
- `PrototypePrimaryButton` / `PrototypeSecondaryButton`: 48 px action buttons.
- `PrototypePill`: status and category tags.
- `ContactAvatar`: generated or image-backed contact avatar.

## Screen Anatomy

Root pages:

- Use top-level left-aligned title bars for primary tabs.
- Keep bottom navigation fixed with `PrototypeBottomNav`.
- Use a 56 px circular indigo FAB only for the dominant create action.
- Reserve search just under the top bar on record/contact-heavy pages.

Pushed pages:

- Use a white top bar with back action on the left.
- Center the title when a back button is present.
- Put primary commit action on the right when editing or creating.
- Keep content in a vertical `ListView` with 16 px padding and 24 px section gaps.

Cards:

- Use white surfaces against gray app background.
- Prefer one card per logical group.
- Use internal rows and dividers rather than nesting another card.
- Put icons in 36-44 px soft-color wells when rows need visual anchoring.

Lists:

- Leading: avatar, icon well, or compact status marker.
- Middle: primary label plus one metadata line.
- Trailing: amount, status, chevron, or compact action.
- Amount rows: income is green, expense/destructive is red.

Forms:

- Use grouped cards for related inputs.
- Keep labels short.
- Use helper/error text only when useful.
- Disabled/busy state must affect the actual trigger, not only show a spinner elsewhere.

Settings:

- Use grouped row cards.
- Use soft category colors for icon wells: indigo, blue, green, orange, purple, red.
- Keep secondary values right-aligned and muted.

Statistics:

- Use indigo for primary data series.
- Use `AppColors` palette order already used in `stats_page.dart` for category charts.
- Avoid adding charts that cannot be read at mobile width.

## Copy Style

- Use concise Chinese labels: `保存`, `取消`, `删除`, `编辑`, `备份`, `恢复`, `导入`, `导出`.
- Use direct feedback: `已保存`, `备份完成`, `请先完善 WebDAV 配置`.
- Use nouns for section labels: `基础信息`, `备份设置`, `历史记录`, `统计概览`.
- Avoid long explanatory paragraphs in-app; prefer one-line helper text.

## Accessibility and Robustness

- Preserve semantic labels for custom selection controls and icon-only actions.
- Keep core text at contrast 4.5:1 where possible.
- Support system font scaling by avoiding fixed-height text containers that clip.
- Use `Expanded`, `Flexible`, ellipsis, or wrapping intentionally for Chinese and mixed Latin strings.
- Account for `MediaQuery.paddingOf(context).bottom` when placing bottom bars or FABs.
- Provide clear loading, empty, and error states for data-backed screens.

## Code Review Checklist

- Does the page use existing token classes instead of ad hoc values?
- Does it reuse existing shared components before creating new ones?
- Are spacing and row heights compatible with nearby screens?
- Are primary, secondary, destructive, and disabled states visually distinct?
- Are loading, empty, error, and busy states represented?
- Is important text readable at mobile width and with font scaling?
- Are tap targets at least 44 px or consistent with existing primitives?
- Are route/navigation patterns consistent with `AppNav` and existing pages?
