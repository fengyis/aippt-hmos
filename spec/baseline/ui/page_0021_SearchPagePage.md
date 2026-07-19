---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.SearchPagePage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/SearchPagePage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_search.xml
  - type: item_layout
    file: app/src/main/res/layout/item_ppt_template.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.AIPptViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt
    language: kotlin
---

# page_0021_SearchPagePage — 搜索页 (复杂度: 6/10)

## 溯源

### 页面归属
- **Activity**: `SearchPagePage` extends `BaseBusinessActivity<PageSearchBinding>`
- **Presenter/ViewModel**: `AIPptViewModel` (shared via `activityViewModels`), manages `searchResultLiveData`, `fetchPptTemplateList()`, `filterKeyWord(keyword: String)`
- **Service/Repository**: `pptViewModel.fetchPptTemplateList()` 获取全量模板列表; `pptViewModel.filterKeyWord(keyword)` 按关键字实时过滤
- **Interceptor**: 无
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`)
- **Util**: `GlideImageUtils.loadRoundImg()` 加载圆角封面; `doAfterTextChanged` (搜索延时过滤); `showKeyboard()` (自动弹出键盘); `toPx()` dp→px 转换

### 页面参数
无（无 Intent extras，通过 `setResult` 回传选中模板）

### 页面功能
PPT 模板搜索页面。从 `RecommendFragment` 右上角搜索图标进入（`startActivityForResult` 方式）。顶部搜索框自动获取焦点并弹出键盘（300ms 延迟），输入关键字实时过滤 `AIPptViewModel` 中的模板列表。模板以 2 列网格展示，点击模板通过 `setResult(RESULT_OK)` 返回选中模板数据给调用方 `RecommendFragment`。

---

- **输出文件**: entry/src/main/ets/pages/SearchPagePage.ets


## 页面结构

```
ConstraintLayout (根容器，背景 @color/white)
├── TitleBar (id: titleBar)
│   ├── leftIcon: icon_titlebar_back_black (返回箭头)
│   ├── background: @color/transparent
│   └── 无 title 文字
├── ShapeEditText (id: ed_search_input)
│   ├── hint: "请输入模版名称"
│   ├── drawableStart: icon_search
│   ├── drawablePadding: 4dp
│   ├── textColor: @color/color_text_color
│   ├── textColorHint: #8F959F
│   ├── textSize: 14dp, maxLines: 1
│   ├── radius: 20dp (圆角)
│   ├── strokeColor: #E8E8E8, strokeSize: 1dp
│   ├── solidColor: @color/transparent (透明背景)
│   ├── paddingHorizontal: 15dp
│   ├── width: 0dp (marginStart: 58dp, marginEnd: 15dp)
│   ├── height: 38dp
│   └── constraint: bottom/start/top 对齐到 TitleBar（搜索框与标题栏在同一行）
└── RecyclerView (id: rv_template_list)
    ├── LayoutManager: GridLayoutManager (spanCount=2)
    ├── divider: 12dp (Grid 方向, includeVisible=true)
    ├── marginHorizontal: 15dp
    ├── marginTop: 15dp
    └── item_ppt_template
        ├── ppt_template_root (id, onClick → setResult + finish)
        ├── ivPptCover: ImageView (封面图, GlideImageUtils.loadRoundImg, 圆角10px)
        └── tvPptName: TextView (模板名称, text=bean.templateName)
```

### 交互流程
1. 进入页面 → `dataBind.edSearchInput.postDelayed({ edSearchInput.showKeyboard() }, 300)` 自动弹出键盘
2. `pptViewModel.fetchPptTemplateList()` → `searchResultLiveData` 初始展示全量模板
3. 搜索框输入 → `doAfterTextChanged { pptViewModel.filterKeyWord(it.toString()) }` → `searchResultLiveData` 实时过滤
4. 点击模板卡片 → `setResult(RESULT_OK, Intent().putExtras(Bundle().apply { putParcelable("pptTemplateBean", bean) }))` → `finish()`
5. 返回 → `RecommendFragment.searchPagePageLauncher` 回调 `onActivityResult` 接收结果


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `ConstraintLayout` (根) | `Column` | 垂直布局：搜索栏 + 模板网格列表 |
| `TitleBar` (仅返回箭头，无 title) | 自定义 `Row` 组件 `AppTitleBar` | 仅左返回按钮，右侧搜索框扩展 |
| `ShapeEditText` | `TextInput` + `.borderRadius(20)` + `.border({ width: 1, color: '#E8E8E8' })` | 圆角边框搜索框 + 左侧搜索图标 |
| `GridLayoutManager(2)` | `Grid` + `.columnsTemplate('1fr 1fr')` | 2列等宽自适应网格 |
| `RecyclerView` (rv_template_list) | `Grid` + `GridItem` + `ForEach` | 2列模板网格 |
| `item_ppt_template` | 复用 `@ComponentV2 struct PptTemplateCard` | 与 RecommendListFragment 共用 |
| `GlideImageUtils.loadRoundImg` | `Image(url)` + `.borderRadius(10)` + `.objectFit(ImageFit.Cover)` | 网络封面图加载 |
| `startActivityForResult` / `setResult` | `pushPathByName('SearchPagePage')` + `onPop` / `onResult` 回调 | 搜索选择后通过导航栈回传结果 |
| `showKeyboard()` | `focusControl.requestFocus('searchInput')` | 自动聚焦搜索框并弹出键盘 |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 搜索栏行: `Row` → 返回按钮 + `TextInput` (圆角边框, 透明背景) + 搜索图标
- 列表区: `Grid` + `.layoutWeight(1)` + `columnsTemplate('1fr 1fr')` + `.columnsGap(12).rowsGap(12)` + `.padding({ left: 15, right: 15 })`
- 自动聚焦: `aboutToAppear()` → `setTimeout(() => focusControl.requestFocus('searchInput'), 300)`

### 搜索结果回传策略
```typescript
// 使用 NavPathStack 的 pop 携带结果
this.navPathStack.pop({ pptTemplateBean: selectedTemplate })
// 或使用 onPop 回调在调用方接收
```

### 数据绑定策略
- `pptViewModel.searchResultLiveData` → `@Local templates: PptTemplateBean[]`
- `searchKeyword` → `@Local keyword: string`
- `TextInput.onChange` → `AIPptViewModel.filterKeyWord(value)` → `searchResultLiveData` 更新


## 状态接口

### 输入参数
无

### ViewModel 状态
```typescript
@ObservedV2
class SearchState {
  @Trace templates: PptTemplateBean[] = []
  @Trace isLoading: boolean = false
  @Trace searchKeyword: string = ''
}
```

### PptTemplateBean 模型
```typescript
@ObservedV2
class PptTemplateBean {
  @Trace templateName: string = ''
  @Trace detailImageBean: DetailImageBean | null = null
  @Trace templateIndexId: string = ''
}
```

### 回调事件
- `onSearchChange(keyword: string)`: `AIPptViewModel.filterKeyWord(keyword)` 实时过滤
- `onTemplateClick(template: PptTemplateBean)`: `setResult(RESULT_OK, template)` → `navPathStack.pop({ pptTemplateBean: template })`
- `onBackClick()`: finish / pop (无结果返回)

### 结果回传
调用方 `RecommendFragment` 通过 `searchPagePageLauncher` (ActivityResultLauncher) 接收:
```typescript
// ArkTS 等价: pushPathByName 返回 Promise<Object>
const result = await this.navPathStack.pushPathByName('SearchPagePage', undefined)
if (result?.pptTemplateBean) {
  // 处理选中的模板
}
```


## 导航关系

### 入口
- `SearchPagePage.getIntent(activity)` — 静态工厂方法 (返回普通 Intent)
- 来源: `RecommendFragment` (右上角搜索图标, via `searchPagePageLauncher.launch(getIntent(activity))`)
- 来源: 其他需要模板搜索的页面（通过相同模式启动）

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| 返回 RecommendFragment | `setResult(RESULT_OK, Intent().putExtras(Bundle().apply { putParcelable("pptTemplateBean", bean) }))` + `finish()` | pptTemplateBean (Parcelable) |
| 返回 (无结果) | `onBackPressed()` / finish | 无 |

### 导航参数
- 入: 无
- 出: Activity Result { extras: { "pptTemplateBean" (PptTemplateBean) } }


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: TitleBar 的 `layout_marginTop` 使用 `@dimen/dimen_page_marginTop` 适配状态栏
- **导航栏**: 无底部导航栏
- **背景色**: `@color/white`
- **键盘处理**: 进入时自动弹出键盘（300ms 延迟），搜索框与 TitleBar 在同一水平线（约束对齐）
