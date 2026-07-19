---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.CreateOutLinePage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/CreateOutLinePage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_create_ppt_outline.xml
  - type: include_layout
    file: app/src/main/res/layout/layout_ppt_step.xml
  - type: item_layout
    file: app/src/main/res/layout/item_ppt_outline.xml
  - type: item_layout
    file: app/src/main/res/layout/item_ppt_outline_content.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.AIPptViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt
    language: kotlin
  - type: dialog
    class: com.aipptzhizuozz.bjh.dialog.PPTCreatingDialog
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/dialog/PPTCreatingDialog.kt
    language: kotlin
---

# page_0015_CreateOutLinePage — PPT大纲生成 (复杂度: 8/10)

## 溯源

### 页面归属
- **Activity**: `CreateOutLinePage` extends `BaseBusinessActivity<PageCreatePptOutlineBinding>`
- **Presenter/ViewModel**: `AIPptViewModel` (from `ViewModelProvider`), manages outline creation state via LiveData: `pptChaptersLiveData`, `pptOutlineCreateSuccLiveData`, `pptOutlineErrorLiveData`, `loadingStatusLiveData`, `pptOutLineLiveData`
- **Service/Repository**: `pptViewModel.createPptOutLine(query, filePath)` 发起大纲生成请求; `pptViewModel.saveOutline2File()` 保存大纲到文件; `pptViewModel.outlineIsCreating()` 检查生成状态
- **Interceptor**: `UserData.isBinding()` + `UserData.getInstance().interceptAuth` 登录拦截; `UseCountViewModel.hasFreeCount()` 免费次数拦截; `checkTextIsCheat()` 敏感内容校验（调用 `cn.sanfate.pub.network.api.checkTextIsCheat`）
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`) — 提供 `getLayoutResId()`, `initView()`, `initObserver()`, `initListener()`, `onClick()`, `onLeftClick()`, `setOnClickListener()`, `dataBind` 模板
- **Util**: `EventExt.pptThemeEvent()`, `EventExt.pptSaveEvent()`, `GsonUtil.beanToJson/jsonToBean`, `ResourceUtils.getResString()`

### 页面参数
- `query: String` — 用户输入的PPT主题（非空）
- `filePath: String?` — 文件导入模式的文件路径
- `from: String` — 来源标识（`EventExt.FROM_TEXT_BOX_CONTENT` / `EventExt.FROM_FILE_IMPORT` / `EventExt.FROM_TEMPLATE`）
- `jsonStr: String` — 可选的 PPT 模版 JSON（若从模版入口进入）

### 页面功能
PPT 大纲生成与编辑页面。用户输入主题后，AI 生成 PPT 章节大纲（RecyclerView 多类型 item），支持主题编辑、章节内容展开/编辑、重新生成、保存本地、进入选模版/生成PPT流程。包含步骤进度指示器（输入主题→生成大纲→选择模版→生成PPT）。

---

- **输出文件**: entry/src/main/ets/pages/CreateOutLinePage.ets


## 页面结构

```
ConstraintLayout (根容器，背景 #color_page_bg)
├── TitleBar (id: titleBar)
│   ├── leftIcon: icon_titlebar_back_black (返回)
│   └── title: "大纲生成" (居中, bold, titleSize)
├── <include id="include_step" layout="layout_ppt_step">
│   └── ConstraintLayout (步骤进度指示器)
│       ├── ShapeView (id: shapeView5, 步骤背景横条)
│       ├── ShapeTextView (id: shape_step1, text="1", 步骤数字圆点)
│       ├── ShapeView (id: line1, 步骤连线)
│       ├── ShapeTextView (id: tv_step1, text="输入主题", 步骤标题)
│       ├── ShapeTextView (id: shape_step2, text="2")
│       ├── ShapeView (id: line2)
│       ├── ShapeTextView (id: tv_step2, text="生成大纲")
│       ├── ShapeTextView (id: shape_step3, text="3")
│       ├── ShapeView (id: line3)
│       ├── ShapeTextView (id: tv_step3, text="选择模版")
│       ├── ShapeTextView (id: shape_step4, text="4")
│       └── ShapeTextView (id: tv_step4, text="生成PPT")
├── ShapeFrameLayout (圆角15dp, 白色背景, 圆角容器)
│   └── RecyclerView (id: rv_outlines, 垂直 LinearLayoutManager)
│       ├── 多类型 item:
│       │   ├── item_ppt_outline (主题/章节)
│       │   │   ├── tvOutlineLabel (Text: "主题"/"章节")
│       │   │   ├── tvOutlineTitle (可编辑 TextInput, pos=0 时 16dp bold)
│       │   │   ├── lineTop (分割线)
│       │   │   └── rvOutlineContent (内嵌 RecyclerView, 子章节列表)
│       │   └── item_ppt_outline_content (子章节内容)
│       │       └── tvOutlineContent (可编辑 TextInput, 带序号前缀)
├── TextView (id: tv_ai_tips, text="本内容由AI生成", visibility=gone)
└── ShapeConstraintLayout (id: view_bottom, 高90dp, 顶部圆角, 白色背景)
    ├── TextView (id: tv_stop_create, text="停止生成", 全宽50dp圆角按钮)
    ├── TextView (id: tv_recreate_outline, text="重新生成", drawableTop: icon_recreate)
    ├── TextView (id: tv_save_outline, text="保存本地", drawableTop: icon_save_local)
    ├── TextView (id: tv_create_ppt, text="选择PPT模板/生成PPT", 194dp*50dp圆角按钮)
    └── Group (id: group_next, 控制 tv_create_ppt + tv_recreate_outline + tv_save_outline 可见性)
```

### 关键状态
1. **生成中**: `tv_stop_create` visible, `group_next` gone, `tv_ai_tips` gone, `PPTCreatingDialog` 显示（含30/60秒倒计时）
2. **生成完成**: `tv_stop_create` gone, `group_next` visible, `tv_ai_tips` visible
3. **底部键盘弹起**: `view_bottom` gone（via `immersionBar.keyboardEnable` 监听）
4. **从模版入口** (`FROM_TEMPLATE`): `tv_create_ppt` text="生成PPT"（直接生成，跳过选模版）

---

## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `ConstraintLayout` (根) | `Column` + `RelativeContainer` | 页面整体垂直布局，底部栏固定、中间列表填充 |
| `TitleBar` (com.hjq.bar) | 自定义 `Row` 组件 `AppTitleBar` | 左返回 + 居中标题；使用 `SymbolGlyph` 返回箭头 |
| `layout_ppt_step` (include) | 抽取为独立 `@ComponentV2 struct StepIndicator` | 4 步骤进度指示器，带圆形数字 + 连线 + 文字 |
| `ShapeFrameLayout` (圆角容器) | `Column` + `.borderRadius(15)` + `.backgroundColor(Color.White)` | ArkUI 内置圆角不需要 ShapeView |
| `RecyclerView` (rv_outlines) | `List` + `Repeat`/`LazyForEach` | 多类型 item，需迁移 `BindingAdapter` 多类型注册逻辑 |
| `item_ppt_outline` | `@ComponentV2 struct OutlineChapterItem` | 含标签 Text + 标题 TextInput（可编辑）+ 内嵌子列表 |
| `item_ppt_outline_content` | `@ComponentV2 struct OutlineContentItem` | 单行可编辑 TextInput（子章节，带序号前缀） |
| `TextView` (按钮样式) | `Button` + `.borderRadius()` + `.backgroundColor()` | 圆角按钮统一用 `Button` |
| `ImageView` (drawableTop) | `Row` → `SymbolGlyph` icon + `Text` 下方 | 图标置于文字上方（垂直 Row 排列） |
| `Group` (visibility 批量控制) | `if` 条件渲染 | V2 声明式 UI 直接用 `if (this.isCompleted)` 控制 |
| `PPTCreatingDialog` | `CustomDialog` / `bindSheet` | 大纲生成中的进度对话框 |
| `AppTipsDialog` | `getUIContext().showAlertDialog()` | 确认退出/权限拦截弹窗 |
| `AppPermissionIntroDialog` | `CustomDialog` | 文件存储权限引导弹窗 |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 步骤区: 固定高度 `StepIndicator` 组件
- 列表区: `List({ scroller: this.outlineScroller })` + `.layoutWeight(1)` 填充剩余空间
- 底部栏: `Row` 固定在底部，键盘弹起时隐藏
- 键盘监听: 使用 `window.on('keyboardHeightChange')` 控制底部栏可见性

### 数据绑定策略
- `AIPptViewModel` → `@ObservedV2 class OutlineState` + `@Trace` 属性
- `RecyclerView Adapter` (多类型) → `Repeat<IOutlineItem>` + `virtualScroll`
- `Chapter` Model: `@ObservedV2 class Chapter { @Trace chapterTitle: string; @Trace chapterContents: Chapter[] }`
- `TextWatcher` → `TextInput.onChange` 回调更新 `chapter.chapterTitle`


## 状态接口

### 输入参数
```typescript
class CreateOutlineParams {
  query: string = ''
  filePath: string = ''
  from: string = ''
  pptTemplateBeanJson: string = ''
}
```

### ViewModel 状态 (AIPptViewModel 迁移)
```typescript
@ObservedV2
class CreateOutlineState {
  @Trace chapters: Chapter[] = []
  @Trace isCreating: boolean = false
  @Trace isCompleted: boolean = false
  @Trace isLoading: boolean = false
  @Trace errorMessage: string = ''
  @Trace fromSource: string = ''  // FROM_TEXT_BOX_CONTENT / FROM_FILE_IMPORT / FROM_TEMPLATE
}
```

### 步骤标题映射（根据 from 来源）
```
FROM_TEXT_BOX_CONTENT / FROM_TEXT_BOX_CONTENT_LONG:
  step1="输入主题", step2="生成大纲" selected, step3="选择模版", step4="生成PPT"
FROM_FILE_IMPORT:
  step1="导入文档", step2="生成大纲" selected, step3="选择模版", step4="生成PPT"
FROM_TEMPLATE:
  step1="选择模版", step2="输入主题", step3="生成大纲" selected, step4="生成PPT"
```

### 状态流转
```
loading → creating (显示 PPTCreatingDialog, 30/60秒倒计时)
  → completed → 显示大纲列表 + 底部操作栏 (group_next visible)
  → error → toast 错误信息 + finish
```

### 回调事件
- `onStopCreate()`: showInterceptDialog → finish
- `onRecreateOutline()`: `pptViewModel.createPptOutLine(query, filePath)` 重新生成
- `onSaveOutline()`: requestStoragePermission → `pptViewModel.saveOutline2File()`
- `onCreatePPT()`: `checkTextIsCheat()` → createPPT(pptTemplateBean) / choiceTemplatePage()
- `onChapterTitleChange(chapterIndex, text)`: 更新 chapter 标题
- `onContentChange(chapterIndex, contentIndex, text)`: 更新子章节内容


## 导航关系

### 入口
- `CreateOutLinePage.createOutlinePage(activity, query, pptTemplateBean, filePath, from)` — 静态工厂方法，含登录/免费次数拦截
- 来源入口: `HomeActivity` (文字输入/长按)、`FileListPage` (文件导入确认)、`MineActivity` (模版进入)

### 拦截逻辑（调用方前置检查，在 createOutlinePage 方法内）
1. `UserData.isBinding() == false && interceptAuth == 1` → 跳转 `LoginActivity.openLoginPage(activity)`
2. `UseCountViewModel.hasFreeCount() == false` → 跳转 `MemberCenterActivitiy.openMemberCenter(activity, FROM_CREATE_OUTLINE, true)`

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `LoginActivity` | `LoginActivity.openLoginPage(activity)` | 无 |
| `MemberCenterActivitiy` | `MemberCenterActivitiy.openMemberCenter(activity, FROM_CREATE_OUTLINE, true)` | fromType=FROM_CREATE_OUTLINE |
| `ChoicePPTTemplatePage` | `choiceTemplatePage()` — tv_create_ppt 点击 (无模版) | pptOutLineData, query, from |
| `PPTTemplatePreviewPage` | `createPPT(pptTemplateBean)` — 有模版直跳或 tv_create_ppt 点击 | pptTemplateBean, pptOutLineData, query, from |
| 返回上一页 | `onBackPressed()` / `finish()` | 有拦截确认对话框 (AppTipsDialog) |

### 导航参数
- 出: `ChoicePPTTemplatePage.choiceTemplatePage(activity, pptOutLineData, query, from)`
- 出: `PPTTemplatePreviewPage.previewTemplate(activity, pptTemplateBean, pptOutLineData, query, from)`


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: 沉浸式，TitleBar 的 `paddingTop` 使用 `@dimen/dimen_page_marginTop` 适配状态栏高度
- **导航栏**: 无底部导航栏，布局延伸到底部
- **键盘处理**: `immersionBar { keyboardEnable(true) }` — 键盘弹起时 `view_bottom` 隐藏，收起时恢复；ArkTS 端使用 `window.on('keyboardHeightChange')` 监听
- **背景色**: `@color/color_page_bg`（浅色背景）
