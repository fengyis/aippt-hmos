# F009: 引导页

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/GuideActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideStatusFragment.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideDifficulty1Fragment.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideDifficulty2Fragment.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideDifficulty3Fragment.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideDetailsFragment.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/guide/GuideInitFragment.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/fragment/BaseDataBindingFragment.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/common/mmkv/MMKVUtil.java"
  - role: util
    path: "app/src/main/java/com/aipptzhizuozz/bjh/utils/GuideEventUpload.kt"
```

## 范围
涉及页面: GuideActivity (page_0012) 及 6 个子 Fragment: GuideStatusFragment, GuideDifficulty1Fragment, GuideDifficulty2Fragment, GuideDifficulty3Fragment, GuideDetailsFragment, GuideInitFragment
依赖: feature-base (MMKVUtil 持久化、BaseBusinessActivity/BaseDataBindingFragment 基类)
触发条件: 冷启动时 SplashActivity 检查 `MMKV_KEY_SHOW_GUIDE` 标志为 false（首次安装/未完成引导）→ 调用 `GuideActivity.openGuidePage()` 进入

## 数据流
```
GuideActivity (ViewPager2 host)
  ├─ Step 0: GuideStatusFragment → 选择使用场景(6选1 RadioGroup) → goToPage() → 进度 20%
  ├─ Step 1: GuideDifficulty1Fragment → 介绍(下一步/跳过) → goToPage() → 进度 40%
  ├─ Step 2: GuideDifficulty2Fragment → 介绍(下一步/跳过) → goToPage() → 进度 60%
  ├─ Step 3: GuideDifficulty3Fragment → 介绍(下一步/跳过) → goToPage() → 进度 80%
  ├─ Step 4: GuideDetailsFragment → Banner轮播+介绍(下一步/跳过) → goToPage() → 进度 100%
  └─ Step 5: GuideInitFragment → 5秒倒计时动画 → goHomeActivity() → 完成
```
- 进度状态由 `GuideActivity.onProgress()` 集中管理（ProgressBar 进度值 + 返回按钮可见性）
- 导航方法: `goToPage(fragment)` 控制 ViewPager2.setCurrentItem，`goBack()` 回退
- 每个 Fragment 通过 `(activity as? GuideActivity)?.goToPage(this)` 推进流程
- 埋点上报: `GuideEventUpload.pageShowEvent()` / `pageClickEvent()` / `pageQuitEvent()`
- 引导完成: `GuideInitFragment.goHomeActivity()` 调用 `AppLog.profileSet("cup_guid_finish", 1)` 上报火山 → `HomeActivity.openHomeFromGuide(requireActivity())` 进入首页
- 首次显示标志: `MMKVUtil.encodeBool(AppContant.MMKV_KEY_SHOW_GUIDE, true)` 在 `GuideActivity.initView()` 持久化，下次启动跳过

## 状态管理
- **Android**: ViewPager2 当前索引驱动进度条与返回按钮，无 ViewModel（状态在 Activity 内部）
- **ArkTS 迁移**:
  - 用 Swiper + @Local currentIndex 替代 ViewPager2
  - 进度条: @Local progress: number 驱动 Progress 组件
  - 引导完成标志: PersistenceV2 持久化（替代 MMKVUtil）
  - 埋点: 事件上报接口（由网络层统一提供）

## 对接点
- **GuideActivity → SplashActivity**: `GuideActivity.openGuidePage(activity)` 静态方法被 `SplashActivity.gotoHome()` 调用（当 `MMKV_KEY_SHOW_GUIDE==false`）
- **GuideInitFragment → HomeActivity**: 引导完成后调用 `HomeActivity.openHomeFromGuide(activity)` 并 finish GuideActivity
- **Fragment → GuideActivity**: 每个子 Fragment 通过 `(activity as? GuideActivity)?.goToPage(this)` 推进步骤
- **MMKV 持久化**: `MMKVUtil.encodeBool(AppContant.MMKV_KEY_SHOW_GUIDE, true)` 标记引导已展示

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | 首次启动时 SplashActivity 通过 `MMKV_KEY_SHOW_GUIDE` 检查未完成引导标记，调用 `GuideActivity.openGuidePage()` 进入 6 步引导流程 | `GuideActivity.openGuidePage()` L34-36; MMKV 标记检查在 SplashActivity 侧 | `PersistenceV2` 读 `show_guide` → false → `pushPathByName('GuidePage')` |
| 2 | 第 0 步展示 6 种使用场景 RadioGroup 单选项，选择后自动调用 `goToPage()` 进入下一步 | `GuideStatusFragment` → `(activity as GuideActivity).goToPage(this)`; `GuideActivity.goToPage()` L73-76 | `Swiper({ index: 0 })` → `RadioGroup` 6 选项 → 选中回调 → `this.currentIndex = 1` |
| 3 | 第 1~3 步展示介绍内容，点击"下一步"调用 `goToPage()` 进入下一步，"跳过"按钮可跳过后续步骤 | `GuideDifficulty1/2/3Fragment` → goToPage / skip | Scroll/Column 介绍图文 + `Button('下一步')` + `Button('跳过')` → `currentIndex++ / currentIndex=5` |
| 4 | 第 4 步展示 3 张 Banner 自动轮播（Swiper/ViewFlipper），点击"下一步"/"跳过"按钮 | `GuideDetailsFragment` Banner 轮播 + goToPage | `Swiper().autoPlay(true)` 3 张 Banner + `Button('下一步')` + `Button('跳过')` |
| 5 | 第 5 步展示 5 秒倒计时进度动画，完成后自动调用 `goHomeActivity()` 进入首页并 finish | `GuideInitFragment.goHomeActivity()` → `HomeActivity.openHomeFromGuide(activity)` | `Progress({ value: countdown5s })` + `setInterval` → 归零 → `navPathStack.replacePathByName('HomePage', { fromGuide: true })` |
| 6 | 进度条按步骤递进（0→20%→40%→60%→80%→100%→隐藏），最后一步隐藏进度条和返回按钮 | `GuideActivity.onProgress()` L83-114: index 0→20/back INVISIBLE, 1→40, 2→60, 3→80, 4→100, 5→back INVISIBLE + sb GONE | `Swiper.onChange(index)` → `switch(index) { 0: progress=20/backHidden; 1-4: progress; 5: progressGone/backHidden }` |
| 7 | 点击返回按钮 `ivBack` 回退到上一步（`currentItem-1`），进度条同步回退 | `GuideActivity.onClick()` L65-71 → `goBack()` L78-81 → `onProgress()` | `Button(backIcon).onClick(() => { if (currentIndex > 0) currentIndex-- })` |
| 8 | 引导页入口时即持久化 `MMKV_KEY_SHOW_GUIDE = true`，下次冷启动跳过引导 | `GuideActivity.initView()` L49: `MMKVUtil.encodeBool(AppContant.MMKV_KEY_SHOW_GUIDE, true)` | `aboutToAppear()` → `PersistenceV2.globalConnect` 写 `show_guide = true` |
| 9 | 引导流程禁止用户手势滑动，仅通过按钮控制步骤前进/后退 | `GuideActivity.initView()` L51: `viewPager.isUserInputEnabled = false` | `Swiper().disableSwipe(true)` |
