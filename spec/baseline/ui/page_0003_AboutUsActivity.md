---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.AboutUsActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/AboutUsActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_about_us.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0003_AboutUsActivity — 关于我们 (复杂度: 2/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.AboutUsActivity`
- **基类**: 推断 BaseActivity
- **布局文件**: `activity_about_us.xml`
- **UI 快照**: ui-snapshots/page_0003_AboutUsActivity/
- **输出文件**: entry/src/main/ets/pages/AboutUsActivityPage.ets
- **页面类型**: full_screen_page（启动模式: FULL_SCREEN）

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent, color_user_page_bg)
├── TitleBar (id=titleBar, 返回+居中"关于我们", leftIcon=icon_titlebar_back_black)
├── ImageView (id=about_us_iv_icon, icon_app_logo, 88dp×88dp, marginTop=128dp)
├── TextView (id=about_us_tv_name, @string/appName, 16dp bold, 居中)
├── TextView (id=about_us_tv_version, 版本号, 14dp, 居中)
├── ShapeLinearLayout (圆角14dp卡片, white背景, marginHorizontal=20dp, marginTop=20dp)
│   ├── SettingBar (id=about_us_tv_user_agreement, "用户协议", 54dp, 分割线)
│   ├── SettingBar (id=about_us_tv_privacy_agreement, "隐私协议", 54dp, 分割线)
│   └── SettingBar (id=about_us_tv_algorithm_filing, "算法备案公示", 54dp)
└── TextView (id=about_us_tv_record_number, 备案号, 14dp, 底部居中)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏信息页 |
| 标题栏 | TitleBar | titleBar | 返回 + "关于我们" |
| App图标 | ImageView | about_us_iv_icon | 88×88 icon_app_logo |
| 应用名 | TextView | about_us_tv_name | appName, 16dp bold |
| 版本号 | TextView | about_us_tv_version | 动态版本号 |
| 设置卡片 | ShapeLinearLayout | — | 圆角14dp, white |
| 用户协议 | SettingBar | about_us_tv_user_agreement | 可点击跳转 |
| 隐私协议 | SettingBar | about_us_tv_privacy_agreement | 可点击跳转 |
| 算法备案 | SettingBar | about_us_tv_algorithm_filing | 弹出 AppTipsDialog (硬编码内容) |
| 备案号 | TextView | about_us_tv_record_number | 底部居中 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Scroll + Column | 可滚动信息页 |
| 标题栏 | com.hjq.bar.TitleBar | Row 自定义标题栏 | SymbolGlyph(chevron_left) + Text |
| App图标 | ImageView 88×88 | Image + .width(88).height(88) | 直接映射 |
| 设置卡片 | ShapeLinearLayout 圆角14dp | Column + .borderRadius(14) + .backgroundColor(White) | 圆角卡片 |
| 设置项 | SettingBar (自定义控件) | Row(Text + SymbolGlyph(chevron_right)) | 列表行组件 |
| 版本号 | TextView 动态文本 | Text(this.versionName) | 动态版本号 |
| 备案号 | TextView | Text(this.recordNumber) | 动态备案号 |
| 协议跳转 | SettingBar onClick → WebViewActivity | NavPathStack.pushPathByName | FWD-REF: Slice 3 Step 3d |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | Row 自定义标题栏 | L2 |
| com.hjq.shape.layout.ShapeLinearLayout | Column + .borderRadius + .backgroundColor | L2 |
| cn.sanfate.pub.baseui.widget.SettingBar | Row + Text + SymbolGlyph(chevron_right) | L2 |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| versionName | string | AppVersion API | 版本号显示 |
| recordNumber | string | 配置/API | ICP 备案号 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | AboutUsActivity | Intent 跳转 | — |
| OUT | 上一页 | 标题栏返回 → pop | — |
| OUT → WebView | page_0002_WebViewActivity | 点击"用户协议" | url=用户协议URL |
| OUT → WebView | page_0002_WebViewActivity | 点击"隐私协议" | url=隐私协议URL |
| IN-PAGE | AppTipsDialog | 点击"算法备案公示" | 硬编码算法备案内容 (非WebView) |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page
- **ArkTS 方案**: `expandSafeArea` TOP，内容区在安全区内滚动
