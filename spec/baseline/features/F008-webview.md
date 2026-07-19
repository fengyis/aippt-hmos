# F008-webview: WebView容器

```yaml
complexity: simple
tier: standard
depth: full
```

## 范围

提供通用 WebView 容器页面，支持加载远程 URL、JS Bridge 双向通信、文件上传（WebView 文件选择）、外部链接跳转、标题动态设置。

**涉及页面**：
- `page_0002_WebViewActivity` — 通用 WebView 页面（隐私协议、用户协议、VIP协议等）
- `page_0008_CustomerServiceWebActivity` — 客服 WebView 页面（JS Bridge、文件上传）

**依赖**：feature-base（网络层、UrlContant URL 工厂、UserData token）

**源码锚点**：
- `WebViewActivity.kt`: WebSettings 全套配置（javaScriptEnabled/zoom/domStorage/mixedContent/textZoom/cacheMode），DownloadListener 拦截下载转外部浏览器，协议阅读埋点（readAgreement → uploadEvent），isAgreementUrl 判断
- `CustomerServiceWebActivity.kt`: 在 WebViewActivity 基础上增加 WebChromeClient.onShowFileChooser（文件选择上传），XXPermissions 文件权限申请，WebAppInterface JS Bridge 注入("moorJsCallBack")，immersionBar 沉浸式处理，OnActivityCallback 处理文件选择回调
- `WebAppInterface.kt`: 6 个 @JavascriptInterface 方法：onCloseEvent（关闭页面回调）、showToast、callPhone（拨打电话）、callRefund（一键退款）、unsubscribe（取消订阅）、contactService（联系客服）

## 数据流

```
WebViewActivity.openWebPage(activity, url, title)
  → intent 传 url + title
    → initWebSetting(): 配置 WebSettings → dataBind.webview.loadUrl(url)
    ├─ 是协议URL(isAgreementUrl) → readAgreement("read") + 滚动监听 readAgreement("scroll")
    └─ DownloadListener → 下载链接跳转外部浏览器(ACTION_VIEW)
  → onDestroy → webview.destroy()

CustomerServiceWebActivity.openWebPage(activity, url, title, fitWindow)
  → intent 传 url + title + fitWindow
    → immersionBar: fitWindow?statusBarColor("#0178FF"):keyboardEnable
    → initWebSetting(): 配置 WebSettings
      → WebAppInterface(this, renewManageViewModel) 创建 + closeResult=finish()
      → addJavascriptInterface(webAppInterface, "moorJsCallBack")
      → webChromeClient.onShowFileChooser:
        ├─ 已授权 → openSystemFileChooser(activity, params, callback)
        │   → params.createIntent() + ACTION_OPEN_DOCUMENT + MIME_TYPES 过滤
        │   → startActivityForResult → 收集 uri(s) → callback.onReceiveValue(uris)
        └─ 未授权 → showPermissionDialog → AppTipsDialog
            → requestFilePermission: XXPermissions.request(MANAGE_EXTERNAL_STORAGE)
              ├─ onGranted → openSystemFileChooser
              └─ onDenied → callback.onReceiveValue(emptyList) + toast
    → loadUrl(url)
  → onDestroy → webview.destroy() + webAppInterface.onCleaned()

JS Bridge 调用链:
  JS "moorJsCallBack.onCloseEvent()" → WebAppInterface.onCloseEvent() → closeResult?.invoke() → finish()
  JS "moorJsCallBack.callRefund()" → WebAppInterface.callRefund() → showRefundConfirmDialog()
  JS "moorJsCallBack.contactService()" → WebAppInterface.contactService() → showService()
```

**关键接口/模型**：
- `WebAppInterface`: closeResult (lambda), activity (FragmentActivity?), renewManageViewModel (SaleCenterViewModel)
- `OnActivityCallback`: onActivityResult(resultCode, Intent?) → 收集文件 URI 回调
- URL 来源：UrlContant.getFeedBackUrl(token), UrlContant.getSaleCenterUrl(token), UrlContant.getVipAgreementUrl() 等

## 状态管理

| 状态 | 类型 | 来源 | ArkTS 映射 |
|------|------|------|-----------|
| 页面URL | String | intent.getStringExtra("url") | `@Local url: string` (通过路由参数传入) |
| 页面标题 | String | intent.getStringExtra("title") | `@Local pageTitle: string` |
| 加载状态 | Boolean | WebView 加载回调 | `@Local isLoading: boolean` |
| 文件上传回调 | ValueCallback | WebChromeClient.onShowFileChooser | `@Local uploadCallback: Function` |
| 权限状态 | Boolean | XXPermissions.isGranted | `@Local hasFilePermission: boolean` |
| fitWindow 模式 | Boolean | intent.getBooleanExtra("fitWindow") | `@Local fitWindow: boolean` |

## 对接点

**入口**：
- 协议页面：App 启动引导、VIP 页面等通过 `WebViewActivity.openWebPage(activity, url, title)` 打开
- 客服页面：MineFragment、MemberCenter 等通过 `CustomerServiceWebActivity.openWebPage(activity, url, title, fitWindow)` 打开

**出口**：
- 下载链接 → 外部浏览器（Intent.ACTION_VIEW）
- JS `onCloseEvent()` → `finish()` 关闭页面
- JS `callRefund/unsubscribe` → 平台退款/解约弹窗
- JS `callPhone` → 系统拨号

**功能点**：
| 功能点 | Android 实现 | ArkTS 目标 |
|--------|-------------|-----------|
| WebView 加载URL | WebView.loadUrl(url) | Web({ src: url, controller: this.webController }) |
| JS 启用 | setting.javaScriptEnabled = true | Web.javaScriptAccess(true) |
| DOM 存储 | setting.domStorageEnabled = true | Web.domStorageAccess(true) |
| 混合内容 | MIXED_CONTENT_ALWAYS_ALLOW | Web.mixedMode(MixedMode.All) |
| 下载拦截 | DownloadListener → Intent.ACTION_VIEW | Web.onDownloadStart → openLink(下载URL) |
| JS Bridge | addJavascriptInterface(webAppInterface, "moorJsCallBack") | Web.javaScriptProxy(jsProxy, "moorJsCallBack", [...]); port.onMessage 回调 |
| 文件上传 | WebChromeClient.onShowFileChooser → startActivityForResult | 系统文件选择器 PhotoViewPicker/DocumentViewPicker + controller.runJavaScript |
| 文件权限 | XXPermissions.request(MANAGE_EXTERNAL_STORAGE) | ohos.permission.READ/WRITE_USER_STORAGE 权限请求 |
| 拨打电话 | AppContant.callPhone(activity, phoneNumber) | @kit.TelephonyKit makeCall(phoneNumber) |
| 沉浸式状态栏 | immersionBar { statusBarColor("#0178FF") } | window.setWindowSystemBarProperties + 安全区适配 |
| 协议阅读埋点 | uploadEvent("read_agreement", jsonObj) | 自定义埋点 API 调用 |

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | WebView 加载指定 URL，URL 为空直接 return | `WebViewActivity.openWebPage()` L30-44: `if (url.isNullOrBlank()) return`; `initWebSetting()` L118: `webview.loadUrl(url)` | Web({ src: this.url }).javaScriptAccess(true) |
| 2 | 动态设置标题栏（从 Intent extras 读取 title） | `WebViewActivity.initView()` L58: `setTitle(title)`; L48: `val title = intent.getStringExtra(PARAMS_TITLE)` | NavDestination 标题绑定 this.pageTitle |
| 3 | JavaScript 可执行 | `WebViewActivity.initWebSetting()` L78: `setting.javaScriptEnabled = true` | Web.javaScriptAccess(true) |
| 4 | DOM Storage 启用 | `WebViewActivity.initWebSetting()` L107: `setting.domStorageEnabled = true` | Web.domStorageAccess(true) |
| 5 | 下载链接拦截后跳转外部浏览器 | `WebViewActivity.initWebSetting()` L110-117: `setDownloadListener { Intent(ACTION_VIEW, uri); startActivity(intent) }` | Web.onDownloadStart → openLink(downloadUrl) |
| 6 | JS 调用原生关闭页面 (onCloseEvent) | `WebAppInterface.kt` L15-17: `@JavascriptInterface fun onCloseEvent()` → `closeResult?.invoke()` → `finish()` | Web.javaScriptProxy → port.onMessage('onCloseEvent') → NavPathStack.pop() |
| 7 | JS 调用原生拨打电话 (callPhone) | `WebAppInterface.kt` L29-32: `@JavascriptInterface fun callPhone(phoneNumber)` → `AppContant.callPhone(activity, phoneNumber)` | javaScriptProxy → makeCall(phoneNumber) |
| 8 | WebView 文件选择上传 | `CustomerServiceWebActivity.kt` L149-157: `webChromeClient = object : WebChromeClient() { override fun onShowFileChooser(...) }` | Web.onShowFileSelector → DocumentViewPicker.select() |
| 9 | 文件选择权限申请（MANAGE_EXTERNAL_STORAGE）| `CustomerServiceWebActivity.kt` L187-218: `XXPermissions.isGranted(MANAGE_EXTERNAL_STORAGE)` → `openSystemFileChooser()` / `XXPermissions.with().permission().request()` | 权限弹窗 → 授权后打开 DocumentPicker |
| 10 | 客服页面沉浸式状态栏 (fitWindow) | `CustomerServiceWebActivity.kt` L80-83: `immersionBar { fitsSystemWindows(true); statusBarColor("#0178FF"); navigationBarColor(...) }` | fitWindow=true → window 沉浸式 + 安全区 paddding |
| 11 | 页面销毁时清理 WebView 资源 | `WebViewActivity.onDestroy()` L122-125: `webview.destroy()`; `webAppInterface.onCleaned()` | aboutToDisappear → webController 释放资源 |
| 12 | 协议阅读埋点（read/scroll） | `WebViewActivity.initView()` L61-67: `isAgreementUrl(url) → readAgreement("read")` + scroll 监听 `readAgreement("scroll")`; `readAgreement()` L138-142: `uploadEvent("read_agreement", jsonObj)` | Web.onPageEnd 回调 → 协议 URL 匹配时上报埋点 |
