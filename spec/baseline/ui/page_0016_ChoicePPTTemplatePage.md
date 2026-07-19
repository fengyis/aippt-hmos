---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.ChoicePPTTemplatePage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/ChoicePPTTemplatePage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_choice_ppt_template.xml
  - type: fragment
    class: com.aipptzhizuozz.bjh.fragment.RecommendFragment
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/fragment/RecommendFragment.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.fragment.BaseDataBindingFragment
  - type: fragment_layout
    file: app/src/main/res/layout/fragment_recommend.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.AIPptViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt
    language: kotlin
---

# page_0016_ChoicePPTTemplatePage — PPT模板选择 (复杂度: 7/10)

## 溯源

### 页面归属
- **Activity**: `ChoicePPTTemplatePage` extends `BaseBusinessActivity<PageChoicePptTemplateBinding>` — 仅作为 Fragment 容器，布局只有 `FrameLayout` (id: fragment_container)
- **Presenter/ViewModel**: `AIPptViewModel` (shared via `activityViewModels` in RecommendFragment), manages `categoryListLiveData`, `fetchPptTemplateList()`
- **Service/Repository**: `pptViewModel.fetchPptTemplateList()` 获取模板分类列表 (`categoryListLiveData`)
- **Interceptor**: 无直接拦截器（前置拦截在 CreateOutLinePage 已完成）
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`) — 提供 `getLayoutResId()`, `initView()`, `initObserver()`, `createOrShowFragment()`
- **Util**: `createOrShowFragment()` 工具方法; `ViewPagerFragmentAdapter` ViewPager 适配器

### 子 Fragment
- **RecommendFragment** extends `BaseDataBindingFragment<FragmentRecommendBinding>`
  - `ViewPager` + `TabLayout`（MagicIndicator 的 `CommonNavigator` + `LinePagerIndicator`）实现模板分类切换
  - 每个 Tab 对应一个 `RecommendListFragment`（展示该分类的模板列表，RecyclerView 2列Grid）
  - `isPreview` 参数控制"预览模式"（返回按钮隐藏、右上角搜索可见）vs "选择模式"（含步骤进度条）
  - `from` 参数控制步骤标题显示内容
  - `ScaleTransitionPagerTitleView` 标签缩放动画 (minScale=0.85, selected/normal 颜色切换)

### 页面参数
- `pptOutLineData: PptOutLineData?` — 大纲数据（从 CreateOutLinePage 传入，Parcelable）
- `query: String` — 用户输入的PPT主题
- `from: String?` — 来源标识

### 页面功能
PPT 模板选择页面。以 Activity 为载体，嵌入 `RecommendFragment`，通过 ViewPager + Tab 实现分类浏览模板。用户选择模板后进入 PPT 生成预览页面。

---

- **输出文件**: entry/src/main/ets/pages/ChoicePPTTemplatePage.ets


## 页面结构

```
FrameLayout (id: fragment_container, match_parent)  ← page_choice_ppt_template.xml
  └── [RecommendFragment 动态加载, via createOrShowFragment]
      └── FragmentRecommendBinding 布局 (fragment_recommend.xml)
          ├── TitleBar (id: titleBar)
          │   ├── title: "精品模版" (isPreview=true) / "请选择模版" (isPreview=false)
          │   ├── leftView: 返回按钮 (仅 isPreview=true 时 visibleOrGone)
          │   └── rightView: 搜索图标 (仅 isPreview=true 时 visibleOrGone)
          ├── <include id="include_step" layout="layout_ppt_step"> (仅 isPreview=false 可见)
          │   └── 4 步骤进度指示器（与 CreateOutLinePage 共享 layout_ppt_step）
          ├── MagicIndicator (id: tabLayout)
          │   └── CommonNavigator → LinePagerIndicator (底部横线指示器, 高2dp, 宽14dp, 圆角2dp)
          │       └── ScaleTransitionPagerTitleView × N (分类标签, 16dp, 缩放动画 minScale=0.85)
          └── ViewPager (id: viewPager, offscreenPageLimit = fragmentList.size)
              └── [RecommendListFragment × N] (每个分类一个 Tab)
                  └── RecyclerView Grid (2列, 模板封面卡片)
                      └── item_ppt_template
                          ├── root: ppt_template_root (id, onClick)
                          ├── ivPptCover: ImageView (封面图, 圆角)
                          └── tvPptName: TextView (模板名称)
```

### RecommendFragment 双模式
1. **预览模式** (`isPreview = true`): leftView 隐藏, rightView 搜索可见, StepIndicator 隐藏, title=精品模版
2. **选择模式** (`isPreview = false`): leftView 可见, rightView 隐藏, StepIndicator 显示, title=请选择模版

### RecommendListFragment (每个分类 Tab)
- 接收分类名称参数，调用 ViewModel 获取该分类下的模板列表
- RecyclerView 2 列 Grid 展示 `PptTemplateBean` 列表
- 点击: 调用回调 lambda `(PptTemplateBean) -> Unit`


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `FrameLayout` + Fragment 容器模式 | `@ComponentV2 struct ChoiceTemplatePage` 内嵌 `RecommendContent` | Activity 仅作容器 → 直接页面内嵌子组件 |
| `RecommendFragment` + ViewPager | `@ComponentV2 struct RecommendContent` + `Tabs` | Fragment + ViewPager 转为 Tabs 组件 |
| `TitleBar` | 自定义 `Row` 组件 `AppTitleBar` | 左返回/右搜索/居中标题 |
| `layout_ppt_step` (include) | 复用 `StepIndicator` 组件 | 共享步骤组件（与 page_0015 共用） |
| `MagicIndicator` + `CommonNavigator` | `Tabs` + `.barMode(BarMode.Scrollable)` + 自定义指示器 | 顶部横向滚动分类标签 |
| `ScaleTransitionPagerTitleView` | `Tabs.onChange` + `animateTo` 缩放动画 | 标签选中态缩放 |
| `LinePagerIndicator` | `Tabs` 自带下划线指示器 / 自定义 `.tabBar` | 底部横线指示器 |
| `ViewPager` (子 Fragment) | `TabContent` 每个 Tab 内嵌列表组件 | 每个分类对应一个 Tab |
| `RecommendListFragment` | `@ComponentV2 struct TemplateCategoryList` | 单一分类的模板网格列表 |
| `RecyclerView` (2列 Grid) | `Grid` + `GridItem` + `ForEach` (`columnsTemplate: '1fr 1fr'`) | 2列网格展示模板卡片 |
| `item_ppt_template` | `@ComponentV2 struct PptTemplateCard` | 封面图 Image + 模板名 Text |
| `GlideImageUtils.loadRoundImg` | `Image(url)` + `.borderRadius()` | 网络图片加载与圆角 |
| `searchPagePageLauncher` (startActivityForResult) | `pushPathByName('SearchPagePage')` + onPop 回调 | 结果通过返回栈回调传回 |

### 布局策略
- 页面整体: `Column` (`.width('100%').height('100%')`)
- 标题栏: 固定高度 `Row`
- 步骤进度条: `if (!this.isPreview) { StepIndicator(...) }`
- 分类 Tab: `Tabs({ barPosition: BarPosition.Start, index: this.currentCategoryIndex })` + `.barMode(BarMode.Scrollable)`
- 内容区: `TabContent()` → 内嵌 `TemplateCategoryList` 组件
- 使用 `@Provider() navPathStack: NavPathStack` 用于导航

### 数据绑定策略
- `pptViewModel.categoryListLiveData` → `@Local categories: string[]`
- ViewModel `fetchPptTemplateList()` → `aboutToAppear()` 调用
- `RecommendListFragment` → `TemplateCategoryList({ category: string, isPreview: boolean })`
- 模板点击回调上抛: `@Event onTemplateClick: (bean: PptTemplateBean) => void`


## 状态接口

### 输入参数
```typescript
class ChoiceTemplateParams {
  pptOutLineDataJson: string = ''  // PptOutLineData 序列化
  query: string = ''
  from: string = ''
  isPreview: boolean = true
}
```

### RecommendFragment 状态
```typescript
@ObservedV2
class RecommendState {
  @Trace categories: string[] = []         // from categoryListLiveData
  @Trace currentCategoryIndex: number = 0  // Tabs index
  @Trace isLoading: boolean = false
}
```

### TemplateCategoryList 状态（每个分类独立）
```typescript
@ObservedV2
class CategoryTemplateState {
  @Trace categoryLabel: string = ''
  @Trace templates: PptTemplateBean[] = []
  @Trace isLoading: boolean = false
}
```

### 回调事件
- `onTemplateClick(bean: PptTemplateBean)`: 模板卡片点击
  - 预览模式: `PPTTemplatePreviewPage.previewTemplate(activity, bean, from)`
  - 选择模式: `(activity as ChoicePPTTemplatePage).createPPT(bean)`
- `onSearchClick()`: pushPathByName('SearchPagePage') + 监听返回结果
- `onCategoryChange(index: number)`: Tab 切换 → 更新 `currentCategoryIndex`
- `onSearchResult(template: PptTemplateBean)`: SearchPagePage 返回结果处理


## 导航关系

### 入口
- `ChoicePPTTemplatePage.choiceTemplatePage(activity, pptOutLineData, query, from)` — 从 CreateOutLinePage 进入
- `HomeActivity` (直接进入预览模式)

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `PPTTemplatePreviewPage` | `previewTemplate(activity, pptTemplateBean, from)` — 预览模式 | pptTemplateBean, from |
| `PPTTemplatePreviewPage` | `(activity as ChoicePPTTemplatePage).createPPT(pptTemplateBean)` — 选择模式 | pptTemplateBean, pptOutLineData, query, from |
| `SearchPagePage` | `searchPagePageLauncher.launch(SearchPagePage.getIntent(activity))` — 右上角 | 无 (startActivityForResult) |
| 返回上一页 | `activity.finish()` | 无 |

### 导航参数
- 入: Bundle { "pptOutLineData" (Parcelable), "query" (String), "from" (String) }
- 出: `PPTTemplatePreviewPage.previewTemplate(...)` 含全量模板+大纲信息
- SearchPagePage 返回: `onActivityResult` → `result.data.extras.getParcelable<PptTemplateBean>("pptTemplateBean")` → 分支处理


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: 系统默认状态栏（未使用 immersionBar）
- **导航栏**: 无底部导航栏
- **背景色**: 白色（RecommendFragment 布局默认白底）
- **Tab 栏**: 顶部横向滚动分类标签，固定高度约 44vp
