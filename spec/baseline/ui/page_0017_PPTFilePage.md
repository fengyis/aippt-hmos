---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.PPTFilePage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/PPTFilePage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_ppt_file_preview.xml
  - type: item_layout
    file: app/src/main/res/layout/item_ppt_cover.xml
  - type: viewmodel
    class: com.aipptzhizuozz.bjh.viewmodel.AIPptFileLoadViewModel
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptFileLoadViewModel.kt
    language: kotlin
  - type: db_entity
    class: com.aipptzhizuozz.bjh.db.aippt.PPTCreateTable
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/db/aippt/PPTCreateTable.kt
    language: kotlin
---

# page_0017_PPTFilePage — PPT文件预览 (复杂度: 6/10)

## 溯源

### 页面归属
- **Activity**: `PPTFilePage` extends `BaseBusinessActivity<PagePptFilePreviewBinding>`
- **Presenter/ViewModel**: `AIPptFileLoadViewModel` (from `ViewModelProvider`), manages PPT file lifecycle: `downPptxFile()`, `convertPptxToImages()`, `savePptFile()`, `sharePptFile()`
- **Service/Repository**: `pptViewModel.downPptxFile()` 下载 PPTX 文件; `pptViewModel.convertPptxToImages(activityPage)` 转换 PPTX 为图片列表; `pptViewModel.savePptFile()` 导出文件; `pptViewModel.sharePptFile()` 系统分享
- **Interceptor**: `pptViewModel.vipInterceptLiveData` → 跳转 `MemberCenterActivitiy.openMemberCenter(this, it)`
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`)
- **Util**: `GlideImageUtils.loadRoundImg()` 加载圆角封面; `GsonUtil.jsonToBean()` JSON 反序列化; `EventExt.pptSaveEvent()` 保存事件上报

### 数据模型
- `PPTCreateTable` — PPT 创建记录实体: `templateIndexId`, `title`, `coverImgSrc`, `detailImageBean()` → `detailImageBean` (含封面图片列表)
- `detailImageBean` — 封面图片列表数据

### 页面参数
- `jsonStr: String` — `PPTCreateTable` 对象的 Gson JSON 序列化
- `isFromWorksPage: Boolean` — 是否从作品页进入（影响返回逻辑）

### 页面功能
PPT 文件预览页面。下载 PPTX 文件 → 转换每页为图片 → RecyclerView 垂直列表展示 PPT 封面页。支持保存到本地和分享。从作品页进入时返回直接跳 HomeActivity。

---

- **输出文件**: entry/src/main/ets/pages/PPTFilePage.ets


## 页面结构

```
ConstraintLayout (根容器，背景 #color_page_bg)
├── TitleBar (id: titleBar)
│   ├── title: pptCreateTable.title（动态设置）
│   ├── leftIcon: icon_titlebar_back_black (返回)
│   ├── rightIcon: icon_share (分享, onClick → sharePptFile)
│   └── background: @color/translate (半透明)
├── RecyclerView (id: rv_covers)
│   ├── LayoutManager: LinearLayoutManager (垂直)
│   ├── divider: 13dp (includeVisible=true)
│   └── item_ppt_cover
│       └── ivPptCover: ImageView (封面图片, GlideImageUtils.loadRoundImg, 圆角3px)
├── TextView (id: tv_ai_tips, text="本内容由AI生成")
│   └── visibility: gone (加载完成后 visible)
└── ShapeConstraintLayout (id: view_bottom, 高90dp, 顶部圆角15dp, 白色背景)
    └── TextView (id: tv_save_ppt, text="保存本地", 全宽50dp圆角按钮)
        └── background: @drawable/app_round_corner_bg (蓝色圆角)
```

### 生命周期
1. **initView**: `parseTemplateBean(intent)` 解析 PPTCreateTable → 校验 templateIndexId + detailImageBean → 初始化 RecyclerView Adapter
2. **initObserver → dowLoadPptFile()**: 隐藏 `view_bottom` → `downPptxFile()` 下载 PPTX
3. **pptDownResultLiveData → convertPptxToImages()**: 下载成功 → `convertPptxToImages(this)` 转换
4. **pptPreviewResultLiveData**: 转化完成 → `pptImageAdapter.models = it` → 显示 `tv_ai_tips` + `view_bottom`
5. **vipInterceptLiveData**: VIP 拦截 → `MemberCenterActivitiy.openMemberCenter(this, it)`


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `ConstraintLayout` (根) | `Column` | 垂直布局：顶部标题栏 + 中间列表 + 底部操作栏 |
| `TitleBar` (动态title+右图标) | 自定义 `Row` 组件 `AppTitleBar` | 左返回 + 动态标题 + 右分享图标 |
| `RecyclerView` (rv_covers, 垂直) | `List` + `Repeat`/`LazyForEach` | 垂直滚动 PPT 页面预览列表 |
| `item_ppt_cover` (ImageView) | `Image(url)` + `.borderRadius(3)` + `.objectFit(ImageFit.Contain)` | 单页 PPT 封面图片 |
| `GlideImageUtils.loadRoundImg` | `Image(url)` + `.borderRadius()` + `.objectFit(ImageFit.Cover)` | 鸿蒙 `Image` 组件原生支持圆角 |
| `tv_ai_tips` | `Text($r('app.string.ai_generated'))` | AI 生成免责声明 |
| `tv_save_ppt` (Button) | `Button` + `.borderRadius()` + `.backgroundColor()` | 保存本地按钮 |
| `ShapeConstraintLayout` (底部栏) | `Row` + `.borderRadius({ topLeft: 15, topRight: 15 })` + `.backgroundColor(Color.White)` | 底部固定操作栏 |
| `AppLoadDialog` | `CustomDialog` / `LoadingProgress` | 加载中提示 ("正在加载PPT内容，请稍后...") |
| `AppTipsDialog` (权限申请) | `getUIContext().showAlertDialog()` | 存储权限申请对话框 |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 列表区: `List` + `.layoutWeight(1)` 填充剩余空间
- 底部栏: `Row` 固定底部，条件渲染 `if (this.isPreviewReady)`
- 加载态: `if (this.isLoading) { LoadingProgress() }`

### 数据绑定策略
- `pptViewModel.pptPreviewResultLiveData` → `@Local pptImageUrls: string[]`
- `pptViewModel.loadingStatusLiveData` → `@Local isLoading: boolean`
- `pptCreateTable` → `@Local pptInfo: PPTCreateInfo`
- ViewModel 方法: `aboutToAppear()` 调用 `downLoadAndConvert()`


## 状态接口

### 输入参数
```typescript
class PPTFileParams {
  pptCreateTableJson: string = ''  // PPTCreateTable 序列化
  isFromWorksPage: boolean = false
}
```

### ViewModel 状态 (AIPptFileLoadViewModel 迁移)
```typescript
@ObservedV2
class PPTFileLoadState {
  @Trace pptImageUrls: string[] = []
  @Trace isLoading: boolean = false
  @Trace isPreviewReady: boolean = false
  @Trace pptTitle: string = ''
  @Trace errorMessage: string = ''
  @Trace vipInterceptType: number = 0  // VIP 拦截 fromType
}
```

### 状态流转
```
init → isLoading=true → download PPTX → convert to images → isPreviewReady=true
  → pptImageUrls 填充 → 显示列表 + 底部栏
  → download error → toast + finish
  → convert error → finish
  → vipIntercept → pushPathByName('MemberCenterActivitiy')
```

### 回调事件
- `onSaveClick()`: requestStoragePermission → `pptViewModel.savePptFile()`
- `onShareClick()`: TitleBar 右上角分享 → `pptViewModel.sharePptFile()`
- `onBackClick()`: isFromWorksPage ? `HomeActivity.openHomePage(this)` : finish


## 导航关系

### 入口
- `PPTFilePage.previewPPTFile(activity, pptFile: PPTCreateTable, isFromWorksPage: Boolean)` — 静态工厂方法
- 来源: `WorksPage` (作品列表点击), `PPTTemplatePreviewPage` (生成完成后查看)

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `MemberCenterActivitiy` | `vipInterceptLiveData` 拦截 | fromType (Int) |
| `HomeActivity` | `onBackPressed()` (isFromWorksPage=true) → `HomeActivity.openHomePage(this)` | 无 |
| 返回上一页 | `onBackPressed()` (isFromWorksPage=false) / `finish()` | 无 |

### 导航参数
- 入: Intent extras { "jsonStr" (String, PPTCreateTable JSON), "isFromWorksPage" (Boolean) }
- `HomeActivity.openHomePage(activity)` 清除栈回到首页


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: TitleBar 的 `layout_marginTop` 使用 `@dimen/dimen_page_marginTop` 适配状态栏
- **导航栏**: 无底部导航栏
- **背景色**: `@color/color_page_bg`（浅色背景）
