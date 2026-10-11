---
name: newshangli-ui-design
description: Project-specific UI design and implementation guidance for the NewShangli Flutter app. Use when Codex redesigns existing pages, adds new pages, creates reusable widgets, reviews UI consistency, maps prototypes to Flutter, or changes visual styling in lib/ui for this app.
---

# NewShangli UI Design

## Start Here

Use this skill for any UI work in the NewShangli Flutter app. Keep changes aligned with the existing app language instead of introducing a separate design system.

Before editing UI, read the target page and these local sources:

- `lib/ui/app_tokens.dart` for colors, spacing, radii, shadows, and typography.
- `lib/ui/app_theme.dart` for Material 3 theme behavior.
- `lib/ui/app_scaffold.dart` for page shell behavior.
- `lib/ui/ui_kit.dart` and `lib/ui/components.dart` for existing shared UI primitives.
- `lib/ui/app_forui_theme.dart` and `docs/FORUI_MIGRATION_PLAN.md` for the current Forui design language.

If the task references a prototype or token mapping, also inspect:

- `prototype/design-tokens.json`
- `prototype/index.html`
- `stitch_exports/`

## Design Intent

Design for a personal gift-money and relationship ledger. The UI should feel calm, clear, trustworthy, and fast to scan. Prioritize record entry, relationship lookup, totals, status, and settings workflows over decorative presentation.

Use a mobile-first single-column structure based on the current 393 x 852 prototype baseline. Maintain dense but readable information hierarchy.

## Implementation Rules

- Use `AppScaffold` as the page shell unless the target page already has a justified custom shell.
- Use token classes from `app_tokens.dart`: `AppColors`, `AppTypography`, `AppRadii`, `AppShadows`, and `AppTokens`.
- Use existing primitives before adding new ones: `AppTopBar`, `AppIconButton`, `AppCard`, `AppPrimaryButton`, `AppSecondaryButton`, `AppSearchField`, `AppPressableRow`, `AppPill`, `PressableScale`, and `ContactAvatar`.
- Prefer Forui components and `AppIcons` from `lib/ui/app_icons.dart` for page actions and navigation.
- Keep page backgrounds on `AppColors.surfaceApp` or the current page's established neutral background.
- Use white cards with `AppRadii.br2xl`, `AppShadows.sm`, and subtle borders/dividers for grouped content.
- Use `AppTypography.base(...)` or named typography helpers. Do not introduce unrelated font families.
- Keep minimum tap targets at or above `AppTokens.tapTargetMin` where controls are not already constrained by existing components.
- Preserve Chinese UI copy style: short nouns for labels, short action verbs for buttons, direct status text for feedback.
- Keep layout responsive to safe-area and bottom inset behavior in `MainTabShell` and `FBottomNavigationBar`.

## Visual Defaults

- Primary brand: `AppColors.brandPrimary` (`#111827`) for selected navigation, primary buttons, FABs, and key active states.
- Secondary brand: `AppColors.brandSecondary` for supporting emphasis, progress, and links.
- Soft selected backgrounds: `AppColors.brandSoft` / `AppColors.indigo50`.
- Income/success: `AppColors.stateSuccess` or `AppColors.green600`.
- Expense/destructive: `AppColors.stateDanger` or `AppColors.red500`.
- Warning: `AppColors.stateWarning`.
- Text: `textPrimary` for headings and key numbers, `textSecondary` for body, `textTertiary` or `textMuted` only for secondary metadata.
- Spacing: page padding 16, section gap 24, card inner padding 16, row vertical padding 12, row inner gap 8 or 12.
- Type: page title 18-20 bold, card title 16-18 bold, body 14 regular, metadata 12 regular, key amounts 16-30 semibold/bold depending on context.

## Page Patterns

- Top bar: white background, 16 horizontal padding, 12 vertical padding, subtle bottom border. Center title when there is a back action; left-align top-level tab titles.
- List pages: search/filter area near the top, grouped or flat list rows, stable row height, avatar/icon at 32-40, primary text + metadata + right-side amount/status.
- Detail pages: key identity or amount block first, then grouped information cards, then destructive or secondary actions near the bottom.
- Form pages: one vertical flow, grouped cards for related fields, primary save action in top bar or bottom action area, disabled/busy state visible.
- Settings pages: grouped white cards with colored icon wells, concise row labels, chevron/status on the right.
- Stats pages: keep chart cards readable, use the chart palette from existing stats code, and avoid adding decorative chart colors outside `AppColors`.
- Empty states: concise message, muted text, optional single primary action. Avoid large illustrations unless an existing page pattern already uses one.

## Avoid

- Raw `Color(...)` values when an `AppColors` token exists.
- New gradients, oversized hero sections, marketing layouts, or decorative image-heavy sections.
- Nested cards and excessive shadows.
- Large corner radii beyond existing tokens unless using pills or circular avatars/FABs.
- Mixing Material default widgets without tokenized styling when they visibly conflict with current pages.
- Overusing gray-400 for important text; it may not meet contrast for core content.
- Adding new dependencies for common UI controls unless there is a clear product need.

## Verification

After UI edits:

- Run `dart format` on touched Dart files.
- Run the narrowest relevant Flutter test if one exists for the page or widget.
- For larger UI work, run `flutter test` if feasible.
- Inspect the changed UI path manually or with an available screenshot workflow when the task is visual.
- Re-scan touched code for hard-coded colors, inconsistent spacing, text overflow risks, and unhandled loading/empty/error states.

## Local-only and migration rules

- Do not reintroduce user accounts or cloud synchronization. Keep local backup/restore and user-configured WebDAV whole-archive backup.
- Use `app_layout.dart` for shared page geometry and `app_icons.dart` for existing Lucide mappings; preserve the current Forui visual style.
- Use `AppPlatform` for file selection, sharing and application directories. Keep platform plugin imports inside the adapter.
- Treat `DESIGN_SPEC.md` as the current canonical contract and the earlier Forui migration record as historical evidence.
- Do not claim HarmonyOS support until the migration proof of concept and device checks have passed.
