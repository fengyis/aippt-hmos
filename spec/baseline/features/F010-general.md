# F010: 通用页面

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/SplashActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/AboutUsActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/ShortCutActivity.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/SplashViewModel.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/platform/dialog/LaunchAgreementDialog.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/common/mmkv/MMKVUtil.java"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/platform/util/SafeDeviceUtils.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/common/UrlContant.kt"
```

## 范围
涉及页面: SplashActivity (page_0001), AboutUsActivity (page_0003), ShortCutActivity (page_0007)
依赖: F001 (认证登录——LoginViewModel.initUser(), UserData 单例)

### SplashActivity（启动页）
- 核心职责: 冷启动入口，隐私协议检查、OAID 初始化、广告开屏、用户初始化，最终跳转首页或引导页
- 布局: activity_splash (App Logo + ProgressBar + 广告容器 + 进度条动画)

### AboutUsActivity（关于我们）
- 核心职责: 展示 App 版本信息，提供隐私协议/用户协议/算法备案公示入口
- 布局: activity_about_us (App 图标 + 版本号 + 隐私协议/用户协议/算法备案链接)

### ShortCutActivity（快捷方式）
- 核心职责: 处理桌面快捷方式点击、本地通知点击；透明主题弹窗风格
- 布局: activity_short_cut (透明主题，无直接用户可见内容)

## 数据流

### SplashActivity 数据流
```
SplashActivity.initSplash()
  ├─ MMKVUtil.KEY_HAS_AGREE_AGREEMENT == 0 ?
  │   ├─ YES → showPrivacyDialog() → LaunchAgreementDialog
  │   │   ├─ AGREE → loadData(fromAgreement=true) → agreePrivacy() → initThridSdk()
  │   │   └─ DISAGREE → finish()
  │   └─ NO → loadData(fromAgreement=false)
  │
  ├─ loadData():
  │   ├─ hotLaunch==false → progressLoad() (动画进度条 0→50→80→100)
  │   ├─ MMKVUtil.KEY_OAID 已缓存 → loginViewModel.initUser()
  │   ├─ MMKVUtil.KEY_OAID 为空 → 等待 OaidResultEvent (EventBus)
  │   └─ hotLaunch==true → enterApp()
  │
  ├─ enterApp():
  │   ├─ TopOnSdkUtil.canShowSplashAd() → 加载+展示开屏广告
  │   └─ 无广告 / 广告关闭 → gotoHome()
  │
  └─ gotoHome():
      ├─ MMKV_KEY_SHOW_GUIDE==false → GuideActivity.openGuidePage()
      └─ MMKV_KEY_SHOW_GUIDE==true → HomeActivity.openHomePage()
```
- SplashViewModel: `uploadFirstStart()` 首次启动上报 / `agreePricacy()` 同意隐私上报 / `readPricacy()` 查看隐私上报
- LoginViewModel.loginLiveData → observe → BDConvertUtils.initBDConvert() + SafeDeviceUtils.runChenck() + enterApp()
- EventBus: `@Subscribe uploadOaidEvent(OaidResultEvent)` → OAID 就绪后调用 `loginViewModel.initUser()`
- reLaunch: 静态方法 `SplashActivity.reLaunch(activity)` 通过 ComponentName 重启启动页

### AboutUsActivity 数据流
```
AboutUsActivity.initView()
  └─ 展示 App 图标 + 版本号（ContextConstant.getVersionName()）

AboutUsActivity.onClick():
  ├─ aboutUsTvPrivacyAgreement → WebViewActivity.openWebPage(隐私协议, UrlContant.getPrivacyAgreementUrl())
  ├─ aboutUsTvUserAgreement → WebViewActivity.openWebPage(用户协议, UrlContant.getUserAgreementUrl())
  ├─ aboutUsIvIcon → 连续点击 >5 次 → Toast 显示 userId
  └─ aboutUsTvAlgorithmFiling → AppTipsDialog 展示算法备案公示(讯飞星火)
```

### ShortCutActivity 数据流
```
ShortCutActivity.onResume():
  ├─ notification_onclick_channel==1 → EventUpload.uploadLocalPush("2")
  ├─ BoxApplication.enterMain==false → SplashActivity.reLaunch(this, false)
  └─ BoxApplication.enterMain==true → BoxApplication.instance.openCaclulator(this) + 设置 back2FrontNeedPassword
  └─ onStop() → 延迟 1s → finish()（透明页自动关闭）
```

## 状态管理
- **Android**: MMKVUtil 持久化（隐私同意标志、首次启动标志、OAID 缓存、引导完成标志）、EventBus（OAID 就绪事件）、ViewModel+LiveData（登录状态观察）
- **ArkTS 迁移**:
  - MMKVUtil → PersistenceV2.globalConnect 持久化（隐私同意/首次启动/引导完成/令牌刷新跳过标志）
  - EventBus OaidResultEvent → emitter.emit('OAID_READY') 或 @Provider/@Consumer
  - LoginViewModel.loginLiveData → AppStorageV2.connect(AuthState, 'auth', ...) 全局登录状态
  - ProgressBar 动画 → animateTo 或 Progress 组件 + @Local progress 变量

## 对接点
- **SplashActivity → GuideActivity**: `GuideActivity.openGuidePage()`（当引导未完成）
- **SplashActivity → HomeActivity**: `HomeActivity.openHomePage()`（当引导已完成）
- **SplashActivity → LaunchAgreementDialog**: `LaunchAgreementDialog().show(supportFragmentManager)` 隐私协议弹窗
- **ShortCutActivity → SplashActivity**: `SplashActivity.reLaunch()`（App 未进入主界面时重启）
- **AboutUsActivity → WebViewActivity**: `WebViewActivity.openWebPage()` 打开隐私协议/用户协议网页
- **AboutUsActivity → AppTipsDialog**: 算法备案公示弹窗

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | 首次启动显示隐私协议弹窗（LaunchAgreementDialog），同意后 `loadData(fromAgreement=true)` 进入加载流程，拒绝后 `finish()` 退出 | `SplashActivity.initSplash()` L104-115: `KEY_HAS_AGREE_AGREEMENT == 0` → `showPrivacyDialog()` L146-153: AGREE→loadData(true), DISAGREE→finish | `PersistenceV2` 读 `agreed_privacy` → false → `showAlertDialog` → confirm: loadData(true), cancel: `appTerminate()` |
| 2 | 非首次启动（已同意隐私）直接调用 `loadData(fromAgreement=false)` 进入加载流程 | `SplashActivity.initSplash()` L113: else `loadData(false)` | `PersistenceV2` 读 `agreed_privacy` → true → 直接 loadData(false) |
| 3 | 启动页展示进度条动画 0→50→80→100（`progressLoad()`），动画结束后如无开屏广告则跳转首页 | `SplashActivity.loadData()` L161 `progressLoad()` | `animateTo` 驱动 `@Local progress: number` 0→50→80→100; `onFinish` → if (!adShowing) gotoHome |
| 4 | OAID 获取完成后通过 EventBus `OaidResultEvent` 自动调用 `loginViewModel.initUser()` | `SplashActivity` `@Subscribe uploadOaidEvent(OaidResultEvent)` → `loginViewModel.initUser()` | `emitter.on('OAID_READY')` → `authService.initUser()` |
| 5 | 登录成功后自动触发 `BDConvertUtils.initBDConvert()` 和 `SafeDeviceUtils.runChenck()` | `SplashActivity.initObserver()` L117-123: `loginLiveData.observe` → `BDConvertUtils.initBDConvert()` + `SafeDeviceUtils.runChenck()` + `enterApp()` | `EventHub.on('loginSuccess')` → `bdConvertService.init()` + `safeDevice.check()` + `enterApp()` |
| 6 | 引导未完成（`MMKV_KEY_SHOW_GUIDE==false`）时跳转 GuideActivity，已完成时跳转 HomeActivity | `SplashActivity.gotoHome()` L127-131: `MMKVUtil.decodeBool(MMKV_KEY_SHOW_GUIDE, false)` → false: `GuideActivity.openGuidePage()`, true: `HomeActivity.openHomePage()` | `PersistenceV2` 读 `show_guide` → false: `pushPathByName('GuidePage')`, true: `pushPathByName('HomePage')` |
| 7 | 启动页禁止系统返回键关闭（`onBackPressed` 空实现） | `SplashActivity`: onBackPressed 不调 super, 空实现 | `onBackPress(): true` 返回 true 拦截，不做任何操作 |
| 8 | 关于我们页面展示 App 版本号（`ContextConstant.getVersionName()`） | `AboutUsActivity.initView()`: 版本号展示 | `Text(bundleInfo.versionName)` 或 `$r('app.string.version_format', versionCode)`) |
| 9 | 点击隐私协议/用户协议链接跳转 WebViewActivity 打开对应网页 | `AboutUsActivity.onClick()`: `aboutUsTvPrivacyAgreement` → `WebViewActivity.openWebPage(UrlContant.getPrivacyAgreementUrl())`; `aboutUsTvUserAgreement` → `WebViewActivity.openWebPage(UrlContant.getUserAgreementUrl())` | `Button.onClick` → `navPathStack.pushPathByName('WebViewPage', { url: PRIVACY_URL })` / `{ url: USER_AGREEMENT_URL }` |
| 10 | 连续点击 App 图标 5 次以上显示 userId Toast | `AboutUsActivity.onClick()`: `aboutUsIvIcon` 累计点击 >5 → toast userId | `clickCount++` → `if (clickCount > 5) { promptAction.showToast(userId) }` |
| 11 | 点击"算法备案公示"弹出 AppTipsDialog 显示讯飞星火备案信息 | `AboutUsActivity.onClick()`: `aboutUsTvAlgorithmFiling` → `AppTipsDialog` | `Text.onClick` → `showAlertDialog({ title: '算法备案公示', message: '讯飞星火...' })` |
| 12 | 快捷方式页在 App 未启动（`enterMain==false`）时重新唤起 `SplashActivity.reLaunch()` | `ShortCutActivity.onResume()`: `BoxApplication.enterMain==false` → `SplashActivity.reLaunch(this)` | `AppStorageV2` 读 `enterMain` → false → `navPathStack.clear().pushPathByName('SplashPage', { hotLaunch: false })` |
| 13 | 快捷方式页在 App 已运行时打开计算器，并设置 `back2FrontNeedPassword` | `ShortCutActivity.onResume()`: `enterMain==true` → `BoxApplication.instance.openCaclulator(this)` + set `back2FrontNeedPassword` | `enterMain==true` → `startAbility('calculator')` + `AppStorageV2.set('needPassword', true)` |
| 14 | 快捷方式页在 `onStop` 后延迟 1s 自动 `finish()`（透明页自关闭） | `ShortCutActivity.onStop()` → 延迟 1s → `finish()` | `aboutToDisappear()` → `setTimeout(() => navPathStack.pop(), 1000)` |
