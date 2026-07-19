# F007-mine: 个人中心

```yaml
complexity: simple
tier: standard
depth: full
```

## 范围

提供用户个人信息展示、VIP状态、设置入口、客服入口、退出登录等个人中心功能。

**涉及页面**：
- `page_0013_MineActivity` — 个人中心容器页面，嵌入 MineFragment
- `MineFragment` — 个人中心内容 Fragment，展示用户信息、功能入口列表
- `MineViewModel` — 缓存计算/清除 ViewModel

**依赖**：F001（认证登录——依赖 UserData 单例获取用户登录状态和VIP信息）

**源码锚点**：
- `MineActivity.kt`: Activity 容器，通过 createOrShowFragment 加载 MineFragment.newInstance(showTitleBar=true)
- `MineFragment.kt`: 用户信息展示（setUserInfo 方法——UserData.isVip/isBinding 分支逻辑，GlideImageUtils.loadCircle 加载头像，UserData.getInstance().userNickName/userId），13 个点击入口（账户信息/关于/版本更新/清缓存/客服/会员/VIP/反馈/售后/退款/解约/续费/免费次数），cacheSizeLiveData 观察，UseCountViewModel.pptLastCount 展示
- `MineViewModel.kt`: Glide.getPhotoCacheDir 计算缓存大小（Formatter.formatFileSize），clearCache 清除缓存并重新计算

## 数据流

```
MineActivity.openActivity(activity)
  → createOrShowFragment(flFragment) { MineFragment.newInstance(showTitleBar=true) }
    → MineFragment.initView()
      → setUserInfo():
        ├─ UserData.isVip() → vipContent + icon_txt_have_open_vip, hide VIP入口
        └─ !isVip() → "尊享超多权益" + icon_txt_open_vip, show VIP入口
        ├─ UserData.isBinding() → userNickName + userId + 头像(GlideImageUtils.loadCircle)
        └─ !isBinding() → "点击登录" + "登录享受更多权益" + 默认头像
        ├─ mineFreeCount visibleOrGone(!UserData.isVip())
        └─ AppContant.userConfig.showServiceCenter 控制服务中心/账户信息入口显隐

MineFragment.onResume()
  → setUserInfo() 刷新用户状态
  → mineViewModel.computeCacheSize() → cacheSizeLiveData → mineSettingClearCache.rightText
  → mineFreeCount.rightText = "剩余体验次数:${UseCountViewModel.pptLastCount}次"

用户点击入口:
  ├─ 账户信息区 (未登录) → LoginActivity.openLoginPage() → F001
  ├─ 账户信息区 (已登录) → AccountInfoActivity.startAccountInfo() → F001
  ├─ 关于我们 → AboutUsActivity
  ├─ 版本更新 → checkUpate()
  ├─ 清除缓存 → mineViewModel.clearCache() → toast "已清除缓存"
  ├─ 联系客服 → showService(false) → CustomerServiceWebActivity
  ├─ VIP入口 (非VIP) → MemberCenterActivitiy.openMemberCenter(FROM_MINE) → F002
  ├─ 意见反馈 → CustomerServiceWebActivity.openWebPage(feedbackUrl)
  ├─ 售后服务 → CustomerServiceWebActivity.openWebPage(saleCenterUrl)
  ├─ 一键退款 → showRefundConfirmDialog(renewManageViewModel)
  ├─ 一键解约 → showUnsignConfirmDialog(renewManageViewModel)
  ├─ 续费管理 → ManageRenewActivity.openRenew()
  └─ 免费次数 (非VIP) → 同VIP入口 → F002
```

**关键数据模型**：
- `UserData`: 单例，token/uid/nickname/avatar/vipLevel/vipContent/fromChannel/phone, isVip()/isBinding() 查询方法
- `AppContant.userConfig.showServiceCenter`: Int 开关（1=显示服务中心，其他=显示账户信息）

## 状态管理

| 状态 | 类型 | 来源 | ArkTS 映射 |
|------|------|------|-----------|
| 用户昵称 | String | UserData.getInstance().userNickName | `@Local userNickName: string` |
| 用户ID | String | UserData.getInstance().userId | `@Local userId: string` |
| 头像URL | String | UserData.getInstance().headUrl | `@Local avatarUrl: string` |
| VIP状态 | Boolean | UserData.isVip() | `@Local isVip: boolean` |
| 登录状态 | Boolean | UserData.isBinding() | `@Local isLoggedIn: boolean` |
| 缓存大小 | String | MineViewModel.cacheSizeLiveData | `@Local cacheSize: string` |
| 剩余体验次数 | Int | UseCountViewModel.pptLastCount | `@Local pptLastCount: number` |

## 对接点

**入口**：
- 首页 Tab 中"Mine"Tab（MineActivity 作为独立 Activity 启动）
- 其他页面通过 `MineActivity.openActivity(activity)` 进入

**出口**（所有导航目标）：
- 未登录 → LoginActivity (F001)
- 已登录 → AccountInfoActivity (F001)
- VIP入口 → MemberCenterActivity (F002)
- 客服/反馈/售后 → CustomerServiceWebActivity (F008)
- 续费 → ManageRenewActivity (F002)
- 关于 → AboutUsActivity (F010)
- 版本更新 → 外部应用市场

**功能点**：
| 功能点 | Android 实现 | ArkTS 目标 |
|--------|-------------|-----------|
| VIP状态展示 | UserData.isVip() + vipContent/vipStatusIcon | AppStorageV2 userState.isVip → 条件渲染 |
| 登录状态展示 | UserData.isBinding() + headUrl/nickname | AppStorageV2 authState.isLoggedIn → 头像+昵称/登录引导 |
| 缓存计算 | Glide.getPhotoCacheDir().length() + Formatter.formatFileSize | @kit.CoreFileKit stat 缓存目录 + 格式化大小 |
| 设置列表 | LinearLayout + SettingItemView (mineSettingXxx) | List + ListItem + custom list item |
| 客服入口 | showService(false) → CustomerServiceWebActivity | NavPathStack.pushPathByName + 传入URL |

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | 已登录时显示用户头像和昵称 | `MineFragment.initView()` L97-101: `if (UserData.isBinding()) { tvUserName.text = userNickName; GlideImageUtils.loadCircle(...) }` | isLoggedIn=true → Image(avatarUrl) + Text(nickname) |
| 2 | 未登录时显示"点击登录"引导，点击触发登录 | `MineFragment.onClick()` L159-162: `if (!UserData.isBinding()) { showLoginDialog() }`; `initView()` L97-101 else branch 默认未登录头像 | isLoggedIn=false → 登录引导UI + icon_default_user_avater_unlogin |
| 3 | VIP用户显示VIP状态标识（徽章+文案） | `MineFragment.setUserInfo()` L86-93: `if (UserData.isVip()) { tvMineVipOpen... }` | isVip=true → VIP徽章 + vipContent文案 |
| 4 | 非VIP用户显示VIP开通入口 + 剩余体验次数 | `MineFragment.setUserInfo()` L93-95: `tvMineVipOpen.visibility = if (isVip()) GONE else VISIBLE; mineFreeCount.visibleOrGone(!isVip())` | isVip=false → VIP开通按钮引导 |
| 5 | 显示缓存大小，onResume 时计算更新 | `MineFragment.onResume()` L147-150: `mineViewModel.computeCacheSize()`; `initOberver()` L77: `cacheSizeLiveData.observe` 更新 rightText | onResume → 计算缓存 + 更新显示 |
| 6 | 清除缓存功能（Glide 缓存 + toast） | `MineFragment.initListener()` L180-185: `clearCache()` → `mineViewModel.clearCache()` → toast "已清除缓存" | 删除缓存目录 + promptAction.showToast |
| 7 | 点击"关于我们"跳转 AboutUsActivity | `MineFragment.onClick()` L170-175: `startActivity(Intent(requireActivity(), AboutUsActivity::class.java))` | NavPathStack.pushPathByName('AboutUs') |
| 8 | 点击"联系客服"打开 CustomerServiceWebActivity | `MineFragment.onClick()` L186-188: `mineSettingCustomerService → requireActivity().showService(false)` | NavPathStack.pushPathByName('CustomerService', {url}) |
| 9 | 非VIP点击剩余体验次数跳转 MemberCenterActivitiy(FROM_MINE) | `MineFragment.onClick()` L190-195: `mineFreeCount / ivVipEnter → MemberCenterActivitiy.openMemberCenter(activity, FROM_MINE, true)` | NavPathStack.pushPathByName('MemberCenter', {from: 'mine'}) |
| 10 | 服务中心入口显隐受远程配置 `showServiceCenter` 开关控制 | `MineFragment.setUserInfo()` L115-121: `llServiceCenter.visibility = when (showServiceCenter) { 1 -> VISIBLE else -> GONE }` | remote config → showServiceCenter → 条件渲染 |
