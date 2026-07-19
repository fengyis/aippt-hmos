---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.SplashActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/SplashActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_splash.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0001_SplashActivity — 启动页 (Launcher) (复杂度: 2/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.SplashActivity`
- **基类**: FragmentActivity (Launcher Activity)
- **布局文件**: `activity_splash.xml`
- **UI 快照**: ui-snapshots/page_0001_SplashActivity/
- **输出文件**: entry/src/main/ets/pages/SplashActivityPage.ets
- **页面类型**: full_screen_page（启动模式: LAUNCHER）
- **生命周期**: `onCreate` → 广告加载/倒计时 → 路由判断（首次→GuideActivity, 非首次→HomeActivity）
- **关联服务**: AdvertLoad (fragment_tag), NetworkChangedReceiver

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent × match_parent, bg_launch)
├── LinearLayout (加载进度区, vertical, 底部居中, gone)
│   ├── TextView ("PPT引擎启动中...", #546972, 14dp)
│   └── ProgressBar (id=pb_splash, Horizontal, max=100)
├── LinearLayout (Logo区, vertical, 底部居中, gone)
│   ├── ImageView (icon_app_logo, 63dp × 63dp)
│   └── TextView (@string/appName, #white, 18dp bold)
└── FrameLayout (id=layout_splash_ad, 广告容器, match_parent × match_parent)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏背景 bg_launch |
| 加载进度区 | LinearLayout (vertical) | — | 进度条+文案，gone控制显隐 |
| 加载文案 | TextView | — | "PPT引擎启动中..." |
| 进度条 | ProgressBar | pb_splash | Horizontal, 自定义进度 drawable |
| Logo区 | LinearLayout (vertical) | — | Logo+应用名，gone控制显隐 |
| Logo图 | ImageView | — | 63×63 icon_app_logo |
| 应用名 | TextView | — | @string/appName, white bold |
| 广告容器 | FrameLayout | layout_splash_ad | 动态注入广告 View |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout (bg_launch) | Stack | 层叠布局（背景+进度+Logo+广告） |
| 加载进度区 | LinearLayout vertical (gone) | Column + if 条件渲染 | gone → if(isProgressVisible) |
| 进度条 | ProgressBar Horizontal | Progress({ type: ProgressType.Linear }) | 直接映射 |
| Logo区 | LinearLayout vertical (gone) | Column + if 条件渲染 | gone → if(isLogoVisible) |
| 广告容器 | FrameLayout (match_parent) | Stack + if(isAdVisible) | 广告 SDK 注入容器 |
| 进度驱动 | Kotlin setProgress | @Local loadingProgress + setInterval | Timer-based 进度更新 |
| 路由跳转 | startActivity (Splash→Guide/Home) | NavPathStack.pushPathByName | FWD-REF: Slice 1 Step 3d |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| 广告 SDK (SplashActivity.AdvertLoad) | FWD-REF: Slice 1 Step 3d | — |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| loadingProgress | number | setInterval 定时器 | 进度条 0-100 |
| isProgressVisible | boolean | 本地状态 | 加载进度区显隐 |
| isLogoVisible | boolean | 本地状态 | Logo 区显隐 |
| isAdVisible | boolean | 广告 SDK | 广告容器显隐 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | SplashActivity | Launcher 冷启动 | — |
| OUT → 引导 | page_0012_GuideActivity | loadingComplete && 首次安装 | — |
| OUT → 首页 | page_0011_HomeActivity | loadingComplete && 非首次 | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，Launcher 启动页全屏无状态栏
- **ArkTS 方案**: 全屏启动图延伸到状态栏区域，`expandSafeArea` TOP + BOTTOM
