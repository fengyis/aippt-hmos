---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.FileListPage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/FileListPage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_file_list.xml
  - type: item_layout
    file: app/src/main/res/layout/item_scan_file.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.FileScanViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/FileScanViewModel.kt
    language: kotlin
  - type: dialog
    class: com.aipptzhizuozz.bjh.dialog.FileConfirmDialog
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/dialog/FileConfirmDialog.kt
    language: kotlin
  - type: bean
    class: com.aipptzhizuozz.bjh.bean.ScanFileBean
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/bean/ScanFileBean.kt
    language: kotlin
---

# page_0019_FileListPage — 文件列表 (复杂度: 7/10)

## 溯源

### 页面归属
- **Activity**: `FileListPage` extends `BaseBusinessActivity<PageFileListBinding>`
- **Presenter/ViewModel**: `FileScanViewModel` (from `ViewModelProvider`), manages file scanning: `scanAllDirectory()`, `searchFile(keyword: String)`, LiveData: `loadingStatusLiveData`, `mediaFileListLiveData`
- **Service/Repository**: `fileScanViewModel.scanAllDirectory()` 扫描全部本地文件; `fileScanViewModel.searchFile(keyword)` 按文件名搜索过滤
- **Interceptor**: 无
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`)
- **Util**: `doAfterTextChanged` (搜索关键字实时监听); `replaceSpan` + `ColorSpan` (关键字高亮, hightLightColor=#1E81FF)

### Bean
- `ScanFileBean`:
  - `fileName: String` — 文件名称
  - `filePath: String` — 文件绝对路径
  - `fileIcon: Int` — 文件类型图标资源ID (setImageResource)
  - `fileDes: String` — 文件描述/时间信息
  - `timeCategory: String` — 时间分类标签 (如"今天"/"昨天"/"本周")
  - `showCategory: Boolean` — 是否显示分类标签

### 页面功能
本地文件浏览与搜索页面。扫描本地文件并展示在 RecyclerView 中，按时间分组（分类标签 `timeCategory`），支持关键词搜索高亮（关键字蓝色 `#1E81FF`）。点击文件条目弹出 `FileConfirmDialog` 确认后进入 PPT 大纲生成流程。

---

- **输出文件**: entry/src/main/ets/pages/FileListPage.ets


## 页面结构

```
ConstraintLayout (根容器，背景 @color/white)
├── ImageView (id: iv_close_page)
│   ├── src: icon_titlebar_back_black (返回箭头)
│   ├── marginStart: 20dp
│   └── onClick → finish()
├── ShapeEditText (id: ed_search_input)
│   ├── hint: "请输入文件名称"
│   ├── drawableStart: icon_search (左侧搜索图标)
│   ├── drawablePadding: 4dp
│   ├── textColor: @color/color_text_color
│   ├── textColorHint: #8F959F
│   ├── textSize: 14dp, maxLines: 1
│   ├── radius: 20dp (圆角)
│   ├── solidColor: @color/color_F7F7F7
│   ├── paddingHorizontal: 15dp
│   ├── width: 0dp (约束到 iv_close_page 右侧 + 父容器右侧)
│   ├── height: 38dp, marginTop: 45dp, marginHorizontal: 15dp
│   └── doAfterTextChanged → fileScanViewModel.searchFile(keyword)
└── RecyclerView (id: rv_file_list)
    ├── LayoutManager: LinearLayoutManager (垂直)
    ├── marginTop: 15dp
    └── item_scan_file
        ├── root: item_scan_file_root (id, onClick → FileConfirmDialog)
        ├── ivFiletype: ImageView (文件类型图标, setImageResource fileBean.fileIcon)
        ├── tvFilename: TextView (文件名, 搜索关键字高亮 via replaceSpan + ColorSpan(#1E81FF))
        ├── tvFiletime: TextView (文件描述/时间, text=fileBean.fileDes)
        └── tvCategoryName: TextView (时间分类标签, visibleOrGone(showCategory), text=timeCategory)
```

### 交互流程
1. 进入页面 → `fileScanViewModel.scanAllDirectory()` 扫描全部文件 → `AppLoadDialog` 显示 "文件扫描中..."
2. `mediaFileListLiveData` 更新 → `fileListAdapter.models = it` → 展示文件列表
3. 搜索框输入 → `doAfterTextChanged` → `fileScanViewModel.searchFile(keyword)` → 过滤 + 关键字高亮重构
4. 点击文件 item → `FileConfirmDialog.newInstance(filePath).show(supportFragmentManager)` → 确认后通过 EventExt 进入 CreateOutLinePage


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `ConstraintLayout` (根) | `Column` | 顶部搜索栏 + 下方文件列表 |
| `ImageView` (iv_close_page) | `SymbolGlyph($r('sys.symbol.xmark'))` 或 `chevron_left` | 关闭/返回按钮 |
| `ShapeEditText` | `TextInput` + `.borderRadius(20)` + `.backgroundColor('#F7F7F7')` | 圆角搜索框 |
| `drawableStart` (搜索图标) | `Row` → `SymbolGlyph($r('sys.symbol.magnifyingglass'))` + `TextInput` | 图标与输入框同行布局 |
| `RecyclerView` (rv_file_list) | `List` + `Repeat`/`LazyForEach` | 垂直文件列表 |
| `item_scan_file` | `@ComponentV2 struct ScanFileItem` | 文件条目：图标 + 文件名(高亮) + 描述 + 分类标签 |
| `replaceSpan` + `ColorSpan` | `Text` 内 `Span` 染色或 `Text` 拼接 | ArkUI `StyledString` / `Span` 组件实现高亮 |
| `FileConfirmDialog` | `CustomDialog` / `getUIContext().showAlertDialog()` | 文件确认对话框 |
| `AppLoadDialog` | `CustomDialog` / `LoadingProgress` | 文件扫描中加载提示 ("文件扫描中...") |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 搜索栏: `Row` → 返回按钮 + `TextInput` (圆角背景) + 搜索图标
- 列表区: `List` + `.layoutWeight(1)`, `.margin({ top: 15 })`

### 搜索关键字高亮策略
```typescript
@Builder highlightFileName(fileName: string, keyword: string) {
  Row() {
    ForEach(splitByKeyword(fileName, keyword), (part: string, index: number) => {
      Text(part)
        .fontColor(part === keyword ? '#1E81FF' : '#182431')
    })
  }
}
```

### 数据绑定策略
- `fileScanViewModel.mediaFileListLiveData` → `@Local fileList: ScanFileBean[]`
- `searchKeyword` → `@Local keyword: string`
- `TextInput.onChange` → `fileScanViewModel.searchFile(value)`


## 状态接口

### 输入参数
无

### ViewModel 状态 (FileScanViewModel 迁移)
```typescript
@ObservedV2
class FileListState {
  @Trace files: ScanFileBean[] = []
  @Trace isLoading: boolean = false
  @Trace searchKeyword: string = ''
  @Trace filteredFiles: ScanFileBean[] = []
}
```

### ScanFileBean 模型
```typescript
@ObservedV2
class ScanFileBean {
  @Trace fileName: string = ''
  @Trace filePath: string = ''
  @Trace fileIcon: Resource = $r('app.media.ic_file_default')
  @Trace fileDes: string = ''
  @Trace timeCategory: string = ''
  @Trace showCategory: boolean = false
}
```

### 回调事件
- `onCloseClick()`: finish → 返回上一页
- `onSearchChange(keyword: string)`: `fileScanViewModel.searchFile(keyword)` 搜索过滤
- `onFileClick(filePath: string)`: 文件存在检查 → 弹出 FileConfirmDialog → 确认后跳转 CreateOutLinePage
- `onBackClick()`: finish

### FileConfirmDialog 确认后流程
- 对话框确认 → `EventExt.pptFileEvent(filePath)` 事件发送 → 跳转 `CreateOutLinePage` (from=`EventExt.FROM_FILE_IMPORT`)


## 导航关系

### 入口
- `FileListPage.openFileList(activity: FragmentActivity?)` — 静态工厂方法
- 来源: `FileUploadPage` (权限通过后)

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `CreateOutLinePage` | FileConfirmDialog 确认 → `EventExt.pptFileEvent(filePath)` → `CreateOutLinePage.createOutlinePage(activity, "", null, filePath, FROM_FILE_IMPORT)` | query="", filePath, from=FROM_FILE_IMPORT |
| 返回上一页 | iv_close_page onClick → finish | 无 |

### 导航参数
- 出: `CreateOutLinePage.createOutlinePage(activity, query="", pptTemplateBean=null, filePath, from=EventExt.FROM_FILE_IMPORT)`


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: 系统默认状态栏（无 TitleBar，搜索框 `marginTop: 45dp` 适配状态栏）
- **导航栏**: 无底部导航栏
- **背景色**: `@color/white`
- **键盘处理**: 搜索框输入时键盘弹起，列表区自适应缩小
