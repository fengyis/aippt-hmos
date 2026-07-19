# F003 — 首页导航

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/HomeActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/HomeViewModel.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/loginpay/service/PayApiService.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/MemberCenterViewModel.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/network/bean/UserData.kt"
```

## 范围

### 涉及页面
| 序号 | Android 页面 | ArkTS 目标 |
|------|-------------|-----------|
| 0011 | `HomeActivity` | `HomePage.ets` |

### 依赖
- **F001 (认证登录)**: `HomeActivity.onResume()` → `!UserData.isLogin()` → `homeViewModel.initUser()` 自动登录；`HomeViewModel` extends `LoginViewModel`
- **F002 (会员支付)**: `HomeActivity` 持有 `MemberCenterViewModel` 处理首页内 VIP 弹窗支付 (`limitCreateOrder`、`showCampaignDialog`、`showLimitDialog`、`wechatPayResult`)

### 关联 Feature
- F004 (PPT核心): `HomeActivity.initView()` → `pptViewModel.fetchPptTemplateList()` 预加载模板数据
- F007 (个人中心): `MineFragment` 是 Tab 之一

## 数据流

```
App 启动 → HomeActivity.openHomePage(activity)
  ↓
if (fromLaunch && !UserData.isVip()) {
  startActivities([homeIntent, centerIntent])  // 非 VIP 首次启动同时打开会员中心
} else {
  startActivity(homeIntent)
}
  ↓
HomeActivity.onCreate()
  ↓ BoxApplication.enterMain = true
  ↓ HuaweiSdkService.initHMAppServiceSdk(this)

HomeActivity.initView()
  ↓ 创建 4 个 Fragment: HomeFragment / RecommendFragment / WorksFragment / MineFragment
  ↓ ViewPager2Adapter(this, fragmentList)
  ↓ dataBind.viewpagerHome.isUserInputEnabled = false  // 禁用手势滑动
  ↓ dataBind.viewpagerHome.offscreenPageLimit = fragmentList.size - 1  // 全预加载
  ↓ dataBind.tvCreateTab.isSelected = true  // 默认选中"创作"Tab

HomeActivity.initObserver()
  ↓ homeViewModel.loginLiveData → getUserInfo / getUserConfig / getFloatInfo
  ↓ homeViewModel.userInfoLiveData → VIP+未绑定 → VipBindAccountDialog
  ↓ homeViewModel.checkUpate(this)
  ↓ pptViewModel.fetchPptTemplateList()
  ↓ centerViewModel.paySuccessLiveData → paySuccess()

HomeActivity.onResume()
  ↓ if (!UserData.isLogin()) → homeViewModel.initUser()
  │ else → getUserInfo / getUserConfig / getFloatInfo
  ↓ 插屏广告逻辑 (已注释)

用户点击底部 Tab:
HomeActivity.onClick(tvCreateTab / tvTemplateTab / tvWorksTab / tvMineTab)
  ↓ changeItem(position)
  ↓ dataBind.viewpagerHome.setCurrentItem(position, false)
  ↓ 更新 tab isSelected 状态

VIP 浮窗/弹窗事件 (EventBus):
  ↓ @Subscribe limitCampaign(LimitCampaignEvent) → showCampaignDialog(productBean)
  ↓ @Subscribe limitGift(LimitGiftEvent) → showLimitDialog(productBean)
  ↓ @Subscribe wechatPayResult(WXPayEvent) → paySuccess() or cancelPayment
  ↓ @Subscribe onPaySuccessEvent(PaySuccessEvent) → getUserInfo()

物理返回键:
  ↓ onKeyDown(KEYCODE_BACK) → exit()
  ↓ 双击退出: 第一次 toast "再按一次退出程序"，第二次 finish()
```

## 服务层

### ArkTS 目标接口签名

```typescript
// HomeService.ets — 首页数据服务（大部分复用 LoginViewModel 方法）
class HomeService {
  /** 获取用户详情信息 */
  getUserInfo(): Promise<UserDataModel>
  /** 获取用户配置（appConfig: arrival 接口） */
  getUserConfig(): Promise<UserConfigResult>
  /** 获取 VIP 浮窗信息 */
  getFloatInfo(): Promise<VipFloatBean>
  /** 检查应用更新 */
  checkUpdate(): Promise<UpdateResult | null>
}

// HomeState.ets — 首页页面状态
@ObservedV2
class HomeState {
  @Trace currentTab: number = 0             // 0=创作, 1=模板, 2=作品, 3=我的
  @Trace isExitConfirm: boolean = false     // 双击退出确认
  @Trace showUserTip: boolean = false       // 首次用户声明弹窗
  @Trace showCampaignDialog: boolean = false
  @Trace showLimitedGiftDialog: boolean = false
  @Trace campaignProduct: ProductBean | null = null
  @Trace limitedGiftProduct: ProductBean | null = null
}
```

### ViewPager2 + Fragment → ArkTS 映射
| Android | ArkTS |
|---------|-------|
| `ViewPager2 + ViewPager2Adapter(fragmentList)` | `Swiper({ index: this.homeState.currentTab }).disableSwipe(true)` — 禁用滑动，仅 Tab 按钮切换 |
| `viewpagerHome.setCurrentItem(position, false)` | `homeState.currentTab = position` → `Swiper` 更新 |
| `offscreenPageLimit = fragmentList.size - 1` | 不适用 — 声明式 UI 不存在延迟加载 |
| `Fragment` 子页面 | 4 个内联 `@Builder` 或独立 `@ComponentV2` 组件 |

## API 接口

| Method | Endpoint (推断) | Description |
|--------|----------------|-------------|
| POST | `/user/getInfo` | 获取用户详情信息 |
| POST | `/app/arrival` | 获取用户配置（服务内容/开关等） |
| POST | `/pay/productFloat` | 获取 VIP 浮窗信息 |

> 注：Android 端接口由 `UserApiService.getInfo()`、`AppApiService.arrival()`、`PayApiService.productFloat()` 提供。

## 实现映射

| 源（Android/Kotlin） | ArkTS 目标 | 说明 |
|---------------------|-----------|------|
| `HomeActivity.openHomePage(activity, fromLaunch)` | `navPathStack.pushPathByName('HomePage', { fromLaunch })` 或作为首页 Entry | 进入首页 |
| `HomeActivity` 4 个 Fragment Tab | `Swiper({ index }).disableSwipe(true)` + 4 个 `TabContent`（Tabs 嵌套）或自定义 TabBar + Swiper | 4 Tab 切换 |
| `ViewPagerFragmentAdapter` | Swiper 内直接放置 4 个 `@ComponentV2` 组件 | Fragment 组件化 |
| `tvCreateTab/tvTemplateTab/tvWorksTab/tvMineTab` isSelected | 自定义 `HomeTabBar` 组件：4 个 `Column` 含 `SymbolGlyph` + `Text`，`currentTab` 驱动选中态 | 底部 Tab 栏 |
| `HomeViewModel extends LoginViewModel` | HomeViewModel 复用 AuthService 的 `initUser()` | 登录状态继承 |
| `homeViewModel.getUserInfo()` | `homeService.getUserInfo().then(data => user.updateUserInfo(data))` | 用户信息刷新 |
| `homeViewModel.getUserConfig()` | `homeService.getUserConfig()` — 仅首次调用（`hasUserConfig` flag） | 用户配置获取 |
| `homeViewModel.getFloatInfo()` | `homeService.getFloatInfo()` — 仅首次（VIP 用户立即清空） | VIP 浮窗信息 |
| `homeViewModel.checkUpate(activity)` | `homeService.checkUpdate()` → 华为应用市场跳转或忽略 | 版本检查 |
| `EventBus @Subscribe PaySuccessEvent` | `EventHub.on('paySuccess', () => this.refreshUserInfo())` | 支付成功后刷新 |
| `EventBus @Subscribe LimitCampaignEvent/LimitGiftEvent` | `EventHub.on('limitCampaign', (p) => { homeState.campaignProduct = p; homeState.showCampaignDialog = true })` | VIP 挽留弹窗 |
| `BoxApplication.enterMain` / `lastSelfPause` | `AppStorageV2` 全局布尔 | 主页面可见性/插屏广告控制 |
| `onKeyDown(KEYCODE_BACK)` 双击退出 | `onBackPress(): boolean \| void` 内判断 `isExitConfirm` timer | 双击退出 |
| `showUserTip()` "同意并承诺遵守" | `showAlertDialog({ title: '声明', ... })` | AI 创作声明弹窗 |
| `VipBindAccountDialog` (VIP+未绑定) | `showAlertDialog` 绑定账号提示 | VIP 绑定账号提示 |

## 状态管理

```typescript
// AppStorageV2 全局 key
class StorageKeys {
  static readonly HOME_STATE = 'home_state'      // HomeState (当前 Tab 等)
}

@ObservedV2
class HomeState {
  @Trace currentTab: number = 0
  @Trace isExitConfirm: boolean = false
}

// EventHub 事件常量
class HomeEventConstants {
  static readonly PAY_SUCCESS = 'paySuccess'
  static readonly LIMIT_CAMPAIGN = 'limitCampaign'
  static readonly LIMIT_GIFT = 'limitGift'
  static readonly KEYBOARD_SHOW_HIDE = 'keyboardShowHide'
}
```

## 对接点

| UI 页面 @Local / @Param | 对应 ArkTS 页面 | 数据类型 | 说明 |
|------------------------|---------------|---------|------|
| `currentTab: number` | `HomePage.ets` | `@Local` (HomeState) | 当前选中 Tab 索引 |
| `fromLaunch: boolean` | `HomePage.ets` | `@Param` (路由参数) | 是否首次启动 |
| `fromGuide: boolean` | `HomePage.ets` | `@Param` (路由参数) | 是否从引导页进入 |
| `showCampaignDialog: boolean` | `HomePage.ets` | `@Local` (HomeState) | 限时优惠挽留弹窗 |
| `showLimitedGiftDialog: boolean` | `HomePage.ets` | `@Local` (HomeState) | 限时赠品挽留弹窗 |
| `isVip: boolean` | `HomePage.ets` | `AppStorageV2` user.vipLevel >= 2 | VIP 状态驱动浮窗/弹窗 |
| `showKeyboard: boolean` | `HomePage.ets` | `@Local` | 键盘显示时隐藏底部 Tab 栏 |

### 跨 Feature 导航出口

| 目标 Feature | 触发 | 说明 |
|-------------|------|------|
| F005 (文件管理) | HomeActivity "创作" Tab → "导入文档" 入口 → `FileUploadPage.openFileUpload(activity)` | 点击导入文档按钮进入文件上传流程 |
| F004 (PPT核心) | HomeActivity "创作" Tab → 输入主题/长按 → `CreateOutLinePage.createOutlinePage()` | 文字输入/长按快捷入口 |
| F006 (作品管理) | HomeActivity "作品" Tab 或 "创作" Tab → 我的作品 → `WorksPage.openPage(activity, type)` | Tab 内嵌 WorksFragment |
| F007 (个人中心) | HomeActivity "我的" Tab → `MineFragment` | Tab 内嵌 MineFragment |

## 验收标准

| # | 验收条件 | 源 | 标 |
|---|---------|----|----|
| AC-1 | 首页展示 4 个底部 Tab：创作/模板/作品/我的，默认选中"创作" | `HomeActivity.initView()` L140 `tvCreateTab.isSelected = true`; L259-282 onClick 4 tab buttons → `changeItem(position)` L287-300 | `HomeTabBar` 4 个 tab，`currentTab=0` 默认 |
| AC-2 | 点击底部 Tab 切换对应内容区，当前 Tab 高亮，其他恢复默认样式 | `HomeActivity.changeItem(position)` L287-300: 更新 `isSelected` + `viewpagerHome.setCurrentItem(position, false)` | `HomeTabBar.onClick(index)` → `homeState.currentTab = index` → Swiper 联动 |
| AC-3 | ViewPager 禁止手势滑动，仅能通过 Tab 点击切换 | `HomeActivity.initView()` L135: `dataBind.viewpagerHome.isUserInputEnabled = false` | `Swiper().disableSwipe(true)` |
| AC-4 | 首次打开 app（非 VIP）自动同时打开会员中心页面 | `HomeActivity.openHomePage()` L84-96: `if (fromLaunch && !UserData.isVip()) { startActivities([homeIntent, centerIntent]) }` | 路由参数 `{ fromLaunch: true }` → if (!isVip) push MemberCenterPage |
| AC-5 | 未登录状态进入首页自动调 `initUser()` 初始化登录 | `HomeActivity.onResume()` L230-234: `if (!UserData.isLogin()) { homeViewModel.initUser() }` | `aboutToAppear()` → if (!user.isLogin) `homeService.initUser()` |
| AC-6 | 首页收到支付成功后刷新用户信息 | `HomeActivity.paySuccess()` L206-209: `EventBus.getDefault().post(PaySuccessEvent(true))` | `EventHub.on('paySuccess')` → `getUserInfo()` |
| AC-7 | 收到 `LimitCampaignEvent` sticky 事件后展示限时优惠挽留弹窗 | `HomeActivity.limitCampaign()` L346-349: `@Subscribe limitCampaign(LimitCampaignEvent)` → `showCampaignDialog(productBean)` | `EventHub.on('limitCampaign')` → `CampaignDialog` 展示 |
| AC-8 | 收到 `LimitGiftEvent` sticky 事件后展示限时赠品弹窗 | `HomeActivity.limitGift()` L352-355: `@Subscribe limitGift(LimitGiftEvent)` → `showLimitDialog(productBean)` | `EventHub.on('limitGift')` → `LimitedGiftDialog` 展示 |
| AC-9 | 物理返回键：第一次点击 toast "再按一次退出程序"，2 秒内再次点击退出应用 | `HomeActivity.exit()` L486-498:第一次→toast+`lastSelfPause=System.currentTimeMillis()`; 2s内→`finish()` | `onBackPress()` → timer 2s 内再次触发 → `exitApp()` |
| AC-10 | 键盘弹出时隐藏底部 Tab 栏，收起时恢复 | `HomeActivity.onKeyboardShowOrHideEvent()` L314-316: `@Subscribe onKeyboardShowOrHideEvent(OnKeyboardShowOrHideEvent)` | `window.on('keyboardHeightChange', (h) => { showTabBar = h == 0 })` |
| AC-11 | 首次用户展示 AI 创作声明弹窗（同意后 MMKV 存储标记，不再弹出） | `HomeActivity.initView()` L149-151 `MMKVUtil.decodeString(KEY_AIMODEL_HOME_USER_TIP)`; `showUserTip()` L216-228 `AppTipsDialog` | `showAlertDialog({ title: '声明', ... })` → confirm → `PersistenceV2.set('user_tip', '1')` |
| AC-12 | "创作" Tab 中"导入文档"按钮导航到 `FileUploadPage.openFileUpload()` 进入文件上传流程 | `fragment_home.xml` L89/L124 `android:text="导入文档"` → `FileUploadPage.openFileUpload(activity)` (exact Kotlin 调用链在 base/utility 层) | `Button($r('app.string.import_doc')).onClick(() => navPathStack.pushPathByName('FileUploadPage'))` |
