# 尚礼应用图标

图标以「礼」字为主标识。米白底与深色字形对应应用当前克制的中性色界面，字形右下角的一枚朱红印记保留了人情往来的温度。字形已经转为矢量轮廓，不依赖设备字体。

## 源文件与预览

- `assets/images/logo.svg`：标准图标矢量源文件。
- `assets/images/logo.png`：512 × 512 预览图。
- `assets/images/logo_foreground.svg`：Android 自适应图标的透明前景。字形控制在系统的安全区域内。
- `assets/images/logo_monochrome.svg`：Android 主题图标的单色前景。

Android 8.0 及更新版本通过 `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` 使用分层图标。旧版本通过各 `mipmap-*` 目录下的 `ic_launcher.png` 使用标准图标。项目当前没有 iOS 工程。

## 重新生成 PNG

字形轮廓来自 SIL Open Font License 1.1 授权的 Noto Sans SC。PNG 资源由 `tool/generate_app_icon.py` 从 SVG 生成。生成环境需要 Python、CairoSVG 与 Pillow；这些工具仅用于设计资源，不属于 Flutter 运行时依赖。

```powershell
py -3 tool/generate_app_icon.py
```

生成后检查 `assets/images/logo.png` 和 `mipmap-mdpi/ic_launcher.png` 的视觉效果，再构建 Android 应用验证资源引用。
