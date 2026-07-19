---
android_source_anchors:
  activity: com.aipptzhizuozz.bjh.page.HomeActivity
  source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/HomeActivity.kt
  layout_file: app/src/main/res/layout/activity_home.xml
  page_type: full_screen_page
  package: com.aipptzhizuozz.bjh.page
---

# page_0011_HomeActivity — 首页 (ViewPager + 4 Tab) (复杂度: 9/10)

## 溯源

- **Android Activity**: `com.aipptzhizuozz.bjh.page.HomeActivity`
- **基类**: `BaseBusinessActivity<ActivityHomeBinding>`
- **布局文件**: `activity_home.xml`
- **入口方法**: `HomeActivity.openHomePage(activity, fromLaunch, fromGuide)` / `HomeActivity.openHomeFromGuide(activity)`
- **ViewModel**: `HomeViewModel` (登录/用户信息/广告) / `AIPptViewModel` (模板列表) / `MemberCenterViewModel` (支付/会员弹窗)
- **Fragment 子页**:
  - `HomeFragment` (PPT创作, index 0)
  - `RecommendFragment` (模版推荐, index 1)
  - `WorksFragment` (作品, index 2)
  - `MineFragment` (我的, index 3)
- **生命周期**: `onCreate` (华为SDK初始化) → `initView` (ViewPager2配置 + 注册EventBus) → `onResume` (登录检查 + 广告) → `initObserver` (多ViewModel订阅) → `onDestroy` (反注册EventBus)

- **输出文件**: entry/src/main/ets/pages/HomeActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, 全屏)
├── ViewPager2 (id=viewpager_home)
│   ├── Page 0: HomeFragment (PPT创作)
│   ├── Page 1: RecommendFragment (模版推荐)
│   ├── Page 2: WorksFragment (作品)
│   └── Page 3: MineFragment (我的)
└── ll_bottom_tab (LinearLayout, 底部 Tab 栏)
    ├── tv_create_tab (ShapeTextView "PPT创作")
    ├── tv_template_tab (ShapeTextView "模版")
    ├── tv_works_tab (ShapeTextView "作品")
    └── tv_mine_tab (ShapeTextView "我的")
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏根布局 |
| 内容区 | ViewPager2 | viewpager_home | 4 个 Fragment 页面容器 |
| 底部 Tab 栏 | LinearLayout | ll_bottom_tab | 水平 4 个 Tab 按钮 |
| Tab 按钮 | ShapeTextView | tv_create_tab | "PPT创作" Tab |
| Tab 按钮 | ShapeTextView | tv_template_tab | "模版" Tab |
| Tab 按钮 | ShapeTextView | tv_works_tab | "作品" Tab |
| Tab 按钮 | ShapeTextView | tv_mine_tab | "我的" Tab |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column | 主内容 + 底部 Tab 的垂直布局 |
| Tab 容器 | ViewPager2 + Fragment | Tabs + TabContent 或 Swiper | ViewPager2 → Swiper/Tabs |
| 子页面 | Fragment (4个) | @ComponentV2 子组件 或 NavDestination | Fragment → 自定义组件 |
| Tab 切换 | setOnClickListener → setCurrentItem | Tabs.onChange 或 Swiper 绑定 | 声明式 Tab 切换 |
| Tab 选中态 | isSelected 属性 | .fontColor 条件 + 药丸指示器 | 选中/未选中样式 |
| 底部 Tab 栏 | LinearLayout + ShapeTextView | 自定义 Row TabBar (药丸指示器样式) | 保持视觉一致的 Tab 栏 |
| 登录检查 | onResume → isLogin → initUser | aboutToAppear 中检查登录态 | 生命周期映射 |
| EventBus | EventBus @Subscribe 跨组件通信 | emitter 或 @Provider/@Consumer | EventBus → emitter |
| 支付回调 | onActivityResult (Huawei/Honor) | promise/callback 模式 | Android Activity Result → ArkTS Promise |
| 会员弹窗 | CampaignDialog / LimitedGiftDialog (DialogFragment) | @CustomDialog 条件弹出 | DialogFragment → 自定义弹窗组件 |
| 退出确认 | onKeyDown → toast "再按一次退出" | onBackPress → 双击退出提示 | 返回键拦截 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| androidx.viewpager2.widget.ViewPager2 | Swiper 或 Tabs 组件 | L2 |
| com.hjq.shape.view.ShapeTextView | Text + .borderRadius + .backgroundColor | L2 |
| org.greenrobot.eventbus.EventBus | @kit.BasicServicesKit emitter | L2 |
| com.hjq.toast.Toaster | promptAction.showToast() | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| currentTabIndex | 本地状态 | number | 0=PPT创作, 1=模版, 2=作品, 3=我的 |
| isLogin | UserData.isLogin() | boolean | 登录状态 |
| isVip | UserData.isVip() | boolean | VIP 状态 |
| isExit | 本地状态 | boolean | 双击退出标志 |
| lastClickTime | 本地状态 | number | 防快速双击退出 |

**全局事件** (EventBus → emitter):

| 事件名 | 方向 | 触发条件 | 处理 |
|--------|------|---------|------|
| PaySuccessEvent | IN | 支付成功后 | 更新用户信息、关闭弹窗 |
| OnKeyboardShowOrHideEvent | IN | 键盘显示/隐藏 | 隐藏/显示底部 Tab |
| LimitCampaignEvent (sticky) | IN | 限时活动触发 | 显示 CampaignDialog |
| LimitGiftEvent (sticky) | IN | 限时礼包触发 | 显示 LimitedGiftDialog |
| WXPayEvent | IN | 微信支付结果 | 处理支付成功/失败 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | HomeActivity | `openHomePage(activity, fromLaunch, fromGuide)` | fromLaunch, fromGuide |
| IN | (from SplashActivity) | 启动完成后跳转 | — |
| IN | (from GuideActivity) | 引导完成 → `openHomeFromGuide(activity)` | fromGuide=true |
| OUT → 会员中心 | MemberCenterActivitiy | 非VIP首次启动 → `startActivities([homeIntent, centerIntent])` | FROM_FIRST_OPEN_AUTO / FROM_GUIDE_PAGE |
| OUT → 引导页 | GuideActivity | 已注释 (`GuideActivity.openGuidePage(this)`) | — |
| OUT → 登录 | 登录流程 | `onResume → !isLogin → homeViewModel.initUser()` | — |
| OUT → 绑定账号 | VipBindAccountDialog | VIP且未绑定时弹出 | — |
| OUT → 续费协议 | RenewRuleDialog | 限时福利支付前展示 | — |
| OUT (退出) | 退出应用 | 双击返回 → finish() | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，作为应用主首页，全屏展示
- **底部 Tab 栏**: 固定在底部，需考虑安全区（底部系统导航栏区域）避免重叠
- **ArkTS 方案**: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` + 底部 TabBar `.safeAreaPadding({ bottom: ... })`
