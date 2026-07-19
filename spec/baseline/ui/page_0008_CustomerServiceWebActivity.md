---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.CustomerServiceWebActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/CustomerServiceWebActivity.kt
  layout_file: app/src/main/res/layout/activity_webview_customer_service.xml
  page_type: full_screen_page
  package: cn.sanfate.pub.platform.page


# page_0008_CustomerServiceWebActivity — 客服 WebView 页面 (复杂度: 4/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.CustomerServiceWebActivity`
- **基类**: `BaseBusinessActivity<ActivityWebviewCustomerServiceBinding>`
- **布局文件**: `activity_webview_customer_service.xml`
- **入口方法**: `CustomerServiceWebActivity.openWebPage(activity, url, title, fitWindow)` — 静态方法，从任意 Activity 跳入
- **ViewModel**: `SaleCenterViewModel` (via `fastLiveDataObserver`)
- **JS 桥接**: `WebAppInterface` (注入名 `moorJsCallBack`，含 `closeResult` 回调触发 `finish()`)
- **生命周期**: `onCreate` → `initView` (沉浸式设置 + WebSettings) → `initObserver` → `onDestroy` (webview.destroy + webAppInterface.onCleaned)

- **输出文件**: entry/src/main/ets/pages/CustomerServiceWebActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器)
├── TitleBar (com.hjq.bar.TitleBar, id=titleBar)
│   └── 标题栏，显示 title 参数值，含返回按钮
└── WebView (id=webview)
    └── 加载 url 参数指定的外部网页
        ├── JavaScript 支持 (javaScriptEnabled=true)
        ├── 文件上传 (WebChromeClient.onShowFileChooser → 系统文件选择器)
        ├── 下载拦截 (DownloadListener → ACTION_VIEW Intent)
        └── WebAppInterface JS 桥接 (moorJsCallBack.closeResult → finish)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏布局 |
| 标题栏 | com.hjq.bar.TitleBar | titleBar | 显示标题和返回按钮 |
| WebView | android.webkit.WebView | webview | 加载外部客服页面 URL |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column | 简单垂直布局，无需 RelativeContainer |
| 标题栏 | com.hjq.bar.TitleBar 三方库 | 自定义 Row + SymbolGlyph(返回) + Text(标题) | 无直接等价三方库，使用系统组件自建 |
| WebView | android.webkit.WebView | Web 组件 | @kit.ArkWeb 提供等价 Web 组件 |
| WebSettings | WebSettings 全局配置 | Web 组件属性 .javaScriptAccess()/.domStorageAccess() 等 | ArkTS Web 属性链直接映射 |
| JS 桥接 | addJavascriptInterface | Web 组件 .javaScriptProxy() | ArkWeb 提供等价 JS Proxy 机制 |
| 文件上传 | WebChromeClient.onShowFileChooser | Web 组件 onShowFileSelector 回调 | 系统文件选择器通过 photoAccessHelper 实现 |
| 沉浸式 | ImmersionBar 三方库 | 窗口全屏 + safeArea 处理 | ArkUI 原生支持沉浸式/安全区 |
| 关闭页面 | WebAppInterface.closeResult → finish() | Web JS 回调触发 router.back() | Navigation 体系下 pop 等价 finish |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | 自定义标题栏组件 | L5 |
| com.gyf.immersionbar | 窗口全屏 + expandSafeArea | L2 |
| com.hjq.permissions.XXPermissions | @kit.AbilityKit 权限 API | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| url | Intent extra `PARAMS_URL` | string | 要加载的网页 URL |
| title | Intent extra `PARAMS_TITLE` | string | 标题栏文字 |
| fitWindow | Intent extra `PARAMS_FITWINDOW` | boolean | 是否启用沉浸式状态栏 |

**接口定义** (`openWebPage`):
```
输入: activity: Activity, url: string, title: string = "", fitWindow: boolean = false
输出: startActivity → CustomerServiceWebActivity
```

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | CustomerServiceWebActivity | `openWebPage()` 静态方法 | url, title, fitWindow |
| OUT (返回) | 上一页 | WebAppInterface.closeResult → finish() | — |
| OUT (返回) | 上一页 | TitleBar 返回按钮 → finish() | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，且源码中使用 ImmersionBar 控制状态栏 (`setFitsSystemWindows` / `statusBarColor("#0178FF")`)
- **fitWindow 模式**: 当 fitWindow=true 时启用沉浸式状态栏（状态栏颜色 #0178FF），WebView 内容延伸到状态栏下方
- **ArkTS 方案**: `window.setWindowSystemBarProperties()` + `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])`
