---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.WebViewActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/WebViewActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_webview.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0002_WebViewActivity — WebView 页面 (复杂度: 2/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.WebViewActivity`
- **基类**: 推断 BaseActivity
- **布局文件**: `activity_webview.xml`
- **UI 快照**: ui-snapshots/page_0002_WebViewActivity/
- **输出文件**: entry/src/main/ets/pages/WebViewActivityPage.ets
- **页面类型**: full_screen_page（启动模式: INTENT_BASED，由 Intent 传入 URL + title）
- **生命周期**: `onCreate` → 解析 Intent extras (url, title) → WebView.loadUrl() → WebChromeClient 回调

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent, white background)
├── TitleBar (id=titleBar, 返回+居中标题, transparent bg, lineVisible=false)
└── WebView (id=webview, match_parent × 0dp, constraint Top→Bottom titleBar)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏容器 |
| 标题栏 | TitleBar | titleBar | 返回按钮 + 居中标题 |
| 网页容器 | WebView | webview | 加载外部 URL，撑满剩余高度 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column | 垂直布局 |
| 标题栏 | com.hjq.bar.TitleBar | Row 自定义标题栏 | SymbolGlyph(chevron_left) + Text(title) |
| WebView | android.webkit.WebView | Web({ src, controller }) | @kit.ArkWeb 提供 |
| 页面加载 | loadUrl(url) | Web.src 属性绑定 | 声明式 URL 设置 |
| 加载状态 | WebViewClient 回调 | .onPageBegin / .onPageEnd | Web 组件事件 |
| 错误处理 | onReceivedError | .onErrorReceive | Web 组件事件 |
| URL 入参 | Intent.getStringExtra("url") | NavPathStack.getParamByName | FWD-REF: Slice 2 Step 3d |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | Row 自定义标题栏 | L2 |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| pageUrl | string | NavParam (url) | WebView 加载地址 |
| pageTitle | string | NavParam (title) | 标题栏文案 |
| isLoading | boolean | Web 组件 onPageBegin/onPageEnd | 加载中指示器 |
| loadError | boolean | Web 组件 onErrorReceive | 错误提示页 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | WebViewActivity | Intent (url, title) | url, title |
| OUT | 上一页 | 标题栏返回 → pop | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page
- **ArkTS 方案**: `expandSafeArea` TOP，WebView 内容区在安全区内
