---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.WorksPage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/WorksPage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_works.xml
  - type: fragment
    class: com.aipptzhizuozz.bjh.fragment.WorksFragment
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/fragment/WorksFragment.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.fragment.BaseDataBindingFragment
  - type: fragment_layout
    file: app/src/main/res/layout/fragment_work.xml
  - type: item_layout
    file: app/src/main/res/layout/item_works_ppt_list.xml
  - type: item_layout
    file: app/src/main/res/layout/item_ppt_template.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.PptDbViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/PptDbViewModel.kt
    language: kotlin
  - type: db_entity
    class: com.aipptzhizuozz.bjh.db.aippt.PPTCreateTable
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/db/aippt/PPTCreateTable.kt
    language: kotlin
  - type: db_entity
    class: com.aipptzhizuozz.bjh.db.aippt.PPTCollectTable
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/db/aippt/PPTCollectTable.kt
    language: kotlin
---

# page_0020_WorksPage — 作品页 (复杂度: 8/10)

## 溯源

### 页面归属
- **Activity**: `WorksPage` extends `BaseBusinessActivity<PageWorksBinding>` — 仅作为 Fragment 容器，布局只有 `FrameLayout` (id: fl_container)
- **Presenter/ViewModel**: `PptDbViewModel` (from `ViewModelProvider` in WorksFragment), manages DB CRUD: `findAllPPT()`, `queryCollectList()`, `deleteList(deleteLists: List<PPTCreateTable>)`, LiveData: `pptListLiveData`, `collectListLiveData`, `loadingStatusLiveData`
- **Service/Repository**: `pptDBViewModel.findAllPPT()` 查询所有创建的作品; `pptDBViewModel.queryCollectList()` 查询收藏模板; `pptDBViewModel.deleteList(list)` 批量删除选中作品
- **Interceptor**: 无
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`); `BaseDataBindingFragment` (`cn.sanfate.pub.baseui.fragment`)
- **Util**: `GlideImageUtils.loadRoundImg()` 加载圆角封面; `EventBus.getDefault()` (org.greenrobot.eventbus) 事件总线订阅 `PptAddSuccessEvent`; `bindingAdapter.toggle(Boolean)` 切换管理/正常模式; `isCheckedAll()` / `checkedAll(Boolean)` 全选逻辑

### 数据模型
- `PPTCreateTable` — 创建作品实体: `id`, `title`, `coverImgSrc`, `getFormatTime()`, `isSelected`, `templateIndexId`
- `PPTCollectTable` — 收藏模板实体: `detailImageBean()` → `titleCoverImage`, `getTemplateName()`, `generatePPTTemplateBean()` → `PptTemplateBean`
- `PptAddSuccessEvent` — EventBus 事件（新增作品成功）

### 页面参数
- `type: Int` — `WorksFragment.TAB_TYPE_MY_CREATE` (1) 或 `TAB_TYPE_MY_COLLECT` (2)
- `showTitleBarLeft: Boolean` — 是否显示左返回按钮（从 Tab 入口进入时为 true）

### 页面功能
作品管理页面。显示用户创建的 PPT 作品列表（我的作品, 支持管理模式批量删除）和收藏的 PPT 模板列表（我的收藏, 2列Grid）。底部管理操作栏（全选/删除）；EventBus 监听新增作品事件自动刷新。

---

- **输出文件**: entry/src/main/ets/pages/WorksPage.ets


## 页面结构

```
FrameLayout (id: fl_container, match_parent)  ← page_works.xml
  └── [WorksFragment 动态加载, via createOrShowFragment]
      └── FragmentWorkBinding 布局 (fragment_work.xml)
          ├── TitleBar (id: titleBar)
          │   ├── title: "我的作品" (create) / "我的收藏" (collect)
          │   ├── leftView: 返回按钮 (showTitleBarLeft=true 时 visibleOrGone)
          │   └── rightTitle: "管理" (create模式) / "" (collect模式)
          ├── [我的作品 Tab 内容] (rv_works visibility=VISIBLE)
          │   ├── RecyclerView (id: rv_works)
          │   │   ├── LayoutManager: LinearLayoutManager (垂直)
          │   │   ├── divider: 20dp (includeVisible=true)
          │   │   └── item_works_ppt_list
          │   │       ├── ppt_item_root (id, onClick → PPTFilePage.previewPPTFile)
          │   │       ├── ivPptCover: ImageView (封面图, GlideImageUtils.loadRoundImg, 圆角10dp)
          │   │       ├── tvPptName: TextView (PPT 标题, text=bean.title)
          │   │       ├── tvPptTime: TextView (格式化时间, text=bean.getFormatTime())
          │   │       └── ivCheck: ImageView (选择框, 管理toggle模式可见, isSelected)
          │   └── TextView (id: tv_empty, text: "我的作品空空如也", 空状态 visibleOrGone)
          ├── [我的收藏 Tab 内容] (rv_collects visibility=GONE)
          │   ├── RecyclerView (id: rv_collects)
          │   │   ├── LayoutManager: GridLayoutManager (spanCount=2)
          │   │   ├── divider: 10dp (Grid方向, includeVisible=true)
          │   │   └── item_ppt_template (复用模板卡片)
          │   │       ├── ppt_template_root (id, onClick → PPTTemplatePreviewPage.previewTemplate)
          │   │       ├── ivPptCover: ImageView (封面图)
          │   │       └── tvPptName: TextView (模板名称)
          │   └── TextView (id: tv_empty, text: "我的收藏空空如也", 空状态)
          └── [管理操作栏] (ll_delete, id)
              ├── visibility: VISIBLE (管理态) / GONE (正常态)
              ├── tv_select_all (id, text: "全选"/"取消全选")
              └── tv_delete (id, text: "删除")
```

### 管理模式切换 (changeDeleteView / toggle)
- 点击 TitleBar "管理" → `isDelete = true` → `llDelete` VISIBLE, `rvWorks.bindingAdapter.toggle(true)`
- 点击 "取消" → `isDelete = false` → `llDelete` GONE, `rvWorks.bindingAdapter.toggle(false)`
- 单选: `onChecked(position, checked)` → 更新 bean.isSelected → 更新全选按钮状态
- "全选": `rvWorks.bindingAdapter.checkedAll(true/false)` → 按钮文案 "取消全选"/"全选"
- "删除": 收集 isSelected=true 的项 → `pptDBViewModel.deleteList(selectedList)`

### Tab 切换 (changeTab)
- `TAB_TYPE_MY_CREATE` → rv_works VISIBLE, rv_collects GONE, rightTitle="管理"
- `TAB_TYPE_MY_COLLECT` → rv_works GONE, rv_collects VISIBLE, rightTitle="", `queryCollectList()`


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `FrameLayout` + Fragment 容器 | 页面内嵌 `@ComponentV2 struct WorksContent` | Activity 仅作容器 → 组件直接内联 |
| `WorksFragment` | `@ComponentV2 struct WorksContent` | Fragment 转可复用组件 |
| `TitleBar` (动态 title + rightTitle) | 自定义 `Row` 组件 `AppTitleBar` | 左返回 + 居中标题 + 右操作按钮 |
| `RecyclerView` (rv_works, 垂直) | `List` + `Repeat`/`LazyForEach` | 垂直作品列表 |
| `RecyclerView` (rv_collects, 2列Grid) | `Grid` + `GridItem` + `ForEach` (`columnsTemplate: '1fr 1fr'`) | 2列收藏网格 |
| `item_works_ppt_list` | `@ComponentV2 struct WorksPptItem` | 作品条目：封面 + 标题 + 时间 + 选中框 |
| `item_ppt_template` | 复用 `PptTemplateCard` 组件 | 与 SearchPagePage / RecommendListFragment 共用 |
| `ivCheck` (管理模式) | `Checkbox` / `Toggle` | 管理模式下的多选组件 |
| `tv_empty` (空状态) | `if (list.length === 0) { Text(...) }` | 条件渲染空数据提示 |
| `ll_delete` (批量操作栏) | `Row` 底部固定 + `if (this.isDeleteMode)` | 管理模式下的删除操作栏 |
| `EventBus` (PptAddSuccessEvent) | `emitter` / `AppStorageV2` 共享状态 | 跨页面通知刷新 |
| `BindingAdapter.toggle()` | `@Local isDeleteMode: boolean` + `if` 分支渲染 | 管理模式 UI 切换 |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 标题栏: 固定高度 `Row`
- Tab 切换: 自定义 `Row` 按钮组 (我的作品 / 我的收藏)，切换内容区可见性
- 列表区: `List` / `Grid` + `.layoutWeight(1)` 填充
- 管理模式底部栏: `Row` 固定在底部, `if (this.isDeleteMode)`
- 空状态: 列表为空时居中显示空提示

### 管理模式状态
```typescript
@Local isDeleteMode: boolean = false
@Local selectedItems: Set<number> = new Set()
@Local isAllSelected: boolean = false
```

### 数据绑定策略
- `pptDBViewModel.pptListLiveData` → `@Local worksList: PPTCreateTable[]`
- `pptDBViewModel.collectListLiveData` → `@Local collectList: PPTCollectTable[]`
- `isDelete` 切换 → toggle 模式（显示/隐藏选择框 + 底部操作栏）
- EventBus → `aboutToAppear` 注册 `emitter.on`, `aboutToDisappear` 取消订阅


## 状态接口

### 输入参数
```typescript
class WorksPageParams {
  type: number = 1  // WorksTabType.MY_CREATE (1) 或 WorksTabType.MY_COLLECT (2)
  showBackButton: boolean = true
}

enum WorksTabType {
  MY_CREATE = 1,
  MY_COLLECT = 2
}
```

### ViewModel 状态 (PptDbViewModel 迁移)
```typescript
@ObservedV2
class WorksState {
  @Trace worksList: PPTCreateTable[] = []
  @Trace collectList: PPTCollectTable[] = []
  @Trace isLoading: boolean = false
  @Trace currentTab: WorksTabType = WorksTabType.MY_CREATE
  @Trace emptyMessage: string = ''
}
```

### 作品模型
```typescript
@ObservedV2
class PPTCreateTable {
  @Trace id: number = 0
  @Trace title: string = ''
  @Trace coverImgSrc: string = ''
  @Trace isSelected: boolean = false
  @Trace formattedTime: string = ''
}
```

### 回调事件
- `onTabChange(tab: WorksTabType)`: `changeTab(tab)` — 切换「我的作品」/「我的收藏」
- `onManageClick()`: `isDelete = !isDelete` → `changeDeleteView()` 进入/退出管理模式
- `onSelectAllClick()`: `pptListAdapter.checkedAll(!isCheckedAll)` → 更新按钮文案
- `onDeleteClick()`: 收集选中项 → `pptDBViewModel.deleteList(selectedList)` → 退出管理模式
- `onWorkItemClick(pptTable: PPTCreateTable)`: 非管理模式 → `PPTFilePage.previewPPTFile(activity, model, true)`
- `onCollectItemClick(collectTable: PPTCollectTable)`: `PPTTemplatePreviewPage.previewTemplate(activity, generatePPTTemplateBean())`
- `onCheckItem(itemId: number, checked: boolean)`: 管理模式 → 更新 isSelected → 更新全选状态
- `onBackClick()`: `requireActivity().finish()`


## 导航关系

### 入口
- `WorksPage.openPage(activity, type)` — 静态工厂方法
- 来源: `HomeActivity` / `MineActivity` (我的作品/我的收藏 Tab 入口)

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `PPTFilePage` | `PPTFilePage.previewPPTFile(activity, model: PPTCreateTable, true)` — 作品点击 | pptFile(PPTCreateTable), isFromWorksPage=true |
| `PPTTemplatePreviewPage` | `previewTemplate(activity, generatePPTTemplateBean())` — 收藏点击 | pptTemplateBean (PptTemplateBean) |

### 导航参数
- 入: Bundle { "type" (Int) }
- 出: `PPTFilePage.previewPPTFile(activity, ppTcreateTable, isFromWorksPage=true)`


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: 系统默认状态栏（WorksFragment 内 TitleBar 使用标准布局）
- **导航栏**: 无底部导航栏
- **背景色**: 白色
