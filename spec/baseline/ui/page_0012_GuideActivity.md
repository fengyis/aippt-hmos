---
android_source_anchors:
  activity: com.aipptzhizuozz.bjh.page.GuideActivity
  source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/GuideActivity.kt
  layout_file: app/src/main/res/layout/activity_guide.xml
  page_type: full_screen_page
  package: com.aipptzhizuozz.bjh.page


# page_0012_GuideActivity — 引导页 (ViewPager + 6 步骤) (复杂度: 6/10)

## 溯源

- **Android Activity**: `com.aipptzhizuozz.bjh.page.GuideActivity`
- **基类**: `BaseBusinessActivity<ActivityGuideBinding>`
- **布局文件**: `activity_guide.xml`
- **入口方法**: `GuideActivity.openGuidePage(activity: Activity)` — 静态方法
- **Fragment 子页** (6 个引导步骤):
  - `GuideStatusFragment` (step_0, index 0) — 引导状态页
  - `GuideDifficulty1Fragment` (step_1, index 1) — 难度选择 1
  - `GuideDifficulty2Fragment` (step_2, index 2) — 难度选择 2
  - `GuideDifficulty3Fragment` (step_3, index 3) — 难度选择 3
  - `GuideDetailsFragment` (step_4, index 4) — 引导详情页
  - `GuideInitFragment` (step_5, index 5) — 引导初始页
- **生命周期**: `onCreate → initView` (ViewPager2 + MMKV 标记 + onProgress) → `initListener` (返回按钮) → `goToPage` (前进) / `goBack` (后退)

- **输出文件**: entry/src/main/ets/pages/GuideActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, 全屏)
├── ImageView (背景图, index 0)
├── ViewPager2 (id=viewPager)
│   ├── Page 0: GuideStatusFragment (引导状态)
│   ├── Page 1: GuideDifficulty1Fragment (难度选择1)
│   ├── Page 2: GuideDifficulty2Fragment (难度选择2)
│   ├── Page 3: GuideDifficulty3Fragment (难度选择3)
│   ├── Page 4: GuideDetailsFragment (引导详情)
│   └── Page 5: GuideInitFragment (引导初始)
├── iv_back (ImageView, id=iv_back)
│   └── 返回按钮 (step_0 / step_5 时 INVISIBLE, 其他步骤 VISIBLE)
└── sb_change (SeekBar, id=sb_change)
    └── 进度条: step_0→20, step_1→40, step_2→60, step_3→80, step_4→100, step_5→GONE(progress=120)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏引导布局 |
| 背景图 | ImageView | — | 引导背景图片 |
| 步骤容器 | ViewPager2 | viewPager | 6 个引导步骤 Fragment 切换 |
| 返回按钮 | ImageView | iv_back | 返回上一步 (step_0/step_5 隐藏) |
| 进度条 | SeekBar | sb_change | 6 步进度指示 (20→40→60→80→100→GONE) |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Stack (背景 + Swiper + 控件层叠) | 背景层 + 内容层叠布局 |
| 步骤切换 | ViewPager2 (禁用手势) | Swiper (.disableSwipe(true)) | ViewPager2 禁用手势 → Swiper 禁用手势 |
| Fragment 页面 | 6 个 Fragment | 6 个 @ComponentV2 子组件 | Fragment → 自定义组件 |
| 步骤导航 | `goToPage(fragment)` → setCurrentItem(index+1) | SwiperController.changeIndex() | 编程式页面切换 |
| 返回按钮 | ImageView + visibility 控制 | if 条件渲染 (currentIndex !== 0 && currentIndex !== 5) | 条件显示返回按钮 |
| 进度条 | SeekBar (.progress 值切换) | Progress({ type: ProgressType.Linear })  | 进度展示 |
| 引导标记 | MMKVUtil.encodeBool | Preferences 持久化 | MMKV → Preferences |
| 背景图 | ImageView | Image (.objectFit(ImageFit.Cover)) | 全屏背景 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| androidx.viewpager2.widget.ViewPager2 | Swiper (.disableSwipe(true)) | L2 |
| cn.sanfate.pub.common.mmkv.MMKVUtil | @kit.ArkData Preferences | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| currentStepIndex | 本地状态 | number | 0-5 对应 6 个引导步骤 |
| showBackButton | 计算属性 | boolean | currentIndex !== 0 && currentIndex !== 5 |
| progressValue | 计算属性 | number | {0:20, 1:40, 2:60, 3:80, 4:100, 5:120} |
| showProgressBar | 计算属性 | boolean | currentIndex !== 5 |
| showGuideDone | MMKVUtil.decodeBool | boolean | 引导是否已展示过 |

**Fragment 间通信**:
- `GuideActivity.goToPage(fragment: Fragment)` — Fragment 调用 Activity 方法前进到指定步骤
- `GuideActivity.goBack()` — Fragment 调用 Activity 方法后退

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | GuideActivity | `openGuidePage(activity)` | — |
| IN | (from HomeActivity) | 首次启动时调用 (目前代码已注释) | — |
| OUT → 首页 | HomeActivity | 引导完成后在 Fragment 内部逻辑导航 | — |
| OUT → 完成引导 | 返回上一页 | 最后一步自动完成或系统返回 | — |
| 步骤 0→1 | GuideDifficulty1Fragment | `goToPage(GuideDifficulty1Fragment)` | — |
| 步骤 1→2 | GuideDifficulty2Fragment | `goToPage(GuideDifficulty2Fragment)` | — |
| 步骤 2→3 | GuideDifficulty3Fragment | `goToPage(GuideDifficulty3Fragment)` | — |
| 步骤 3→4 | GuideDetailsFragment | `goToPage(GuideDetailsFragment)` | — |
| 步骤 4→5 | GuideInitFragment | `goToPage(GuideInitFragment)` | — |
| 步骤 N→N-1 | 上一 Fragment | `goBack()` / iv_back onClick | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，引导页需要全屏沉浸式体验，背景图覆盖整个屏幕
- **特殊处理**: 
  - 全屏背景图 + 步骤内容层叠（Stack 布局）
  - 返回按钮需避开安全区顶部区域
  - step_5 (GuideInitFragment) 隐藏进度条，完全沉浸
- **ArkTS 方案**: `window.setWindowSystemBarProperties({ statusBarColor: '#00000000' })` 透明状态栏 + `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` + 返回按钮 `.margin({ top: safeAreaTop })`
