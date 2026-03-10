# 图标设计说明

## 设计理念
基于 "尚礼" (人情往来记录) 的应用定位，图标采用了以下设计元素：
- **主体**：一个白色的礼物盒，象征着 "礼" 与 "往来"。
- **装饰**：红色的丝带与心形结，寓意着人情温暖与喜庆。
- **背景**：深靛蓝 (Indigo-900, #312E81)，符合 Material Design 3 的应用主色调，稳重且大气。

## 文件位置
- **SVG 源文件**: `assets/images/logo.svg`
- **预览文件**: `icon_preview.html` (用浏览器打开查看)

## 如何应用图标
由于 Android 需要不同分辨率的 PNG 图标，建议按以下步骤操作：

1. **预览与确认**：
   用浏览器打开 `icon_preview.html`，确认图标设计是否满意。

2. **生成图标**：
   推荐使用 [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) 插件自动生成。
   
   在 `pubspec.yaml` 中添加：
   ```yaml
   dev_dependencies:
     flutter_launcher_icons: ^0.13.1

   flutter_launcher_icons:
     android: "ic_launcher"
     ios: true
     image_path: "assets/images/logo.png" # 注意：需要先将 SVG 转为 PNG
     min_sdk_android: 21 # android min sdk min:16, default 21
   ```
   
   或者使用在线工具 (如 [App Icon Generator](https://appicon.co/)) 将 `assets/images/logo.svg` 转换为 Android/iOS 需要的图标文件，并替换 `android/app/src/main/res/` 下的 `mipmap-*` 文件夹内容。

## APP 名字修改
- Android 应用名称已修改为 "尚礼" (`android/app/src/main/AndroidManifest.xml`)。
- 项目描述已更新 (`pubspec.yaml`)。
