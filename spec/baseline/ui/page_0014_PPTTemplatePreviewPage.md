---
android_source_anchors:
  activity: com.aipptzhizuozz.bjh.page.PPTTemplatePreviewPage
  source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/PPTTemplatePreviewPage.kt
  layout_file: app/src/main/res/layout/page_ppt_template_preview.xml
  item_layout: app/src/main/res/layout/item_ppt_cover.xml
  page_type: full_screen_page
  package: com.aipptzhizuozz.bjh.page
---

# page_0014_PPTTemplatePreviewPage — PPT 模板预览 (RecyclerView) (复杂度: 7/10)

## 溯源

- **Android Activity**: `com.aipptzhizuozz.bjh.page.PPTTemplatePreviewPage`
- **基类**: `BaseBusinessActivity<PagePptTemplatePreviewBinding>`
- **布局文件**: `page_ppt_template_preview.xml`
- **列表项布局**: `item_ppt_cover.xml`
- **入口方法**: `PPTTemplatePreviewPage.previewTemplate(activity, pptTemplateBean, pptOutLineData?, query?, from?)` — 静态方法
- **ViewModel**: `AIPptViewModel` (PPT 创建结果/进度) / `PptDbViewModel` (收藏/数据持久化)
- **生命周期**: `onCreate→initView` (解析 Intent、RecyclerView 配置、步骤指示器) → `initObserver` (创建结果监听) → `onNewIntent` (回退后继续创建流程)

- **输出文件**: entry/src/main/ets/pages/PPTTemplatePreviewPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, 全屏)
├── TitleBar (com.hjq.bar.TitleBar, id=titleBar)
│   └── 标题栏，显示模板名称 (pptTemplateBean.templateName)
├── include Layout (layout_ppt_step, 步骤指示器)
│   └── ConstraintLayout (includeStep.root)
│       ├── shapeView5 (ShapeView, 背景)
│       ├── shape_step1 (ShapeTextView "1")
│       ├── line1 (ShapeView, 连接线)
│       ├── tv_step1 (ShapeTextView "输入主题" / "导入文档" / "选择模版")
│       ├── shape_step2 (ShapeTextView "2")
│       ├── line2 (ShapeView, 连接线)
│       ├── tv_step2 (ShapeTextView "生成大纲")
│       ├── shape_step3 (ShapeTextView "3")
│       ├── line3 (ShapeView, 连接线)
│       ├── tv_step3 (ShapeTextView "选择模版" / "生成大纲")
│       ├── shape_step4 (ShapeTextView "4")
│       └── tv_step4 (ShapeTextView "生成PPT")
├── rv_covers (RecyclerView, id=rv_covers)
│   └── 横向线性布局 (linear)
│       └── item_ppt_cover (卡片项, R.layout.item_ppt_cover)
│           └── ivPptCover (ImageView, 圆角封面图, 3px 圆角)
└── view_bottom (ShapeConstraintLayout, 底部操作栏, id=view_bottom)
    ├── tv_create_ppt_template (TextView "AI生成PPT")
    │   └── 有 outline 时显示
    └── tv_create_ppt (TextView "AI生成PPT")
        └── 无 outline 时显示
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏布局 |
| 标题栏 | com.hjq.bar.TitleBar | titleBar | 显示模板名称 |
| 步骤指示器 | include Layout | includeStep | 4 步创作流程指示 (动态文案) |
| 步骤背景 | ShapeView | shapeView5 | 步骤条背景 |
| 步骤序号 | ShapeTextView | shape_step1-4 | "1"~"4" |
| 连接线 | ShapeView | line1-3 | 步骤间连接线 |
| 步骤文案 | ShapeTextView | tv_step1-4 | 动态步骤名称 |
| 模板列表 | RecyclerView | rv_covers | 横向滚动封面列表 |
| 封面图 | ImageView | ivPptCover | 圆角封面图片 (Glide 加载) |
| 底部操作栏 | ShapeConstraintLayout | view_bottom | 底部操作按钮容器 |
| 操作按钮 | TextView | tv_create_ppt_template | 有 outline 时的生成按钮 |
| 操作按钮 | TextView | tv_create_ppt | 无 outline 时的生成按钮 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column | 标题+步骤+列表+底部=垂直布局 |
| 标题栏 | com.hjq.bar.TitleBar | 自定义 Row 标题栏 | 无直接等价三方库 |
| 步骤指示器 | include layout_ppt_step | 自定义 @ComponentV2 StepIndicator | include → 组件复用 |
| 步骤序号 | ShapeTextView 圆角背景 | Text + .borderRadius + .backgroundColor 条件颜色 | 圆角数字步骤 |
| 连接线 | ShapeView | Divider 或 View + .backgroundColor | 步骤间连接线 |
| 模板列表 | RecyclerView (横向) + BRV | List({ space: 13 }) + Repeat | RecyclerView→List; BRV→Repeat |
| 封面图 | ImageView + Glide | Image(url) | Glide → ArkUI Image 内置加载 |
| 圆角 | GlideImageUtils.loadRoundImg | Image + .borderRadius(n) | 声明式圆角 |
| 底部操作栏 | ShapeConstraintLayout | Row (.justifyContent(FlexAlign.Center)) | 底部固定操作区 |
| 按钮可见性 | Kotlin visibleOrGone(b) | if 条件渲染 | 声明式显隐 |
| PPT 创建弹窗 | PPTCreatingDialog (DialogFragment) | @CustomDialog 显示进度 | 创建进度弹窗 |
| 填写内容弹窗 | FillPPTQueryDialog (DialogFragment) | @CustomDialog + TextInput | 填写主题弹窗 |
| onNewIntent | 重新解析 Intent 更新 UI | @Monitor 监听参数变化 或 NavDestination.onReady | 页面参数更新 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | 自定义标题栏 | L5 |
| com.drake.brv (BRV RecyclerView 封装) | List + Repeat (ArkUI 原生) | L2 |
| com.hjq.shape (ShapeView/ShapeTextView) | Column/Row/Text + borderRadius + backgroundColor | L2 |
| Glide (GlideImageUtils) | Image 组件内置图片加载 | L2 |
| GsonUtil | 自定义 JSON 解析 (@ohos.util) | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| pptTemplateBean | Intent extra "jsonStr" → GsonUtil | PptTemplateBean | 模板数据（含 coverList、templateName、templateIndexId、detailImageBean） |
| pptOutLineData | Intent extra "outlineJson" → GsonUtil | PptOutLineData | 大纲数据（outline 字段决定按钮显隐） |
| query | Intent extra "query" | string | 用户输入的查询主题 |
| from | Intent extra "from" | string | 来源标识（控制步骤指示器文案） |
| coverList | pptTemplateBean.getCoverList() | string[] | 模板封面图 URL 列表 |
| isCreatingPPT | 本地状态 | boolean | PPT 创建中状态（控制弹窗显示） |
| createProgress | pptCreateProgressLiveData | number | 创建进度百分比 |

**接口契约**:
```
PptTemplateBean {
  templateIndexId: string    // 模板 ID
  templateName: string        // 模板名称
  detailImageBean: object     // 详情图
  getCoverList(): string[]    // 封面图 URL 列表
}

PptOutLineData {
  outline: object?            // null=无大纲, 非null=已有大纲
}
```

**步骤指示器文案映射** (from 参数 → tv_step1 文案):

| from | tv_step1 | tv_step2 | tv_step3 | tv_step4 |
|------|----------|----------|----------|----------|
| FROM_TEXT_BOX_CONTENT / FROM_TEXT_BOX_CONTENT_LONG | "输入主题" | "生成大纲" | "选择模版" | "生成PPT" |
| FROM_FILE_IMPORT | "导入文档" | "生成大纲" | "选择模版" | "生成PPT" |
| FROM_TEMPLATE | "选择模版" | "输入主题" | "生成大纲" | "生成PPT" |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | PPTTemplatePreviewPage | `previewTemplate(activity, pptTemplateBean, pptOutLineData?, query?, from?)` | pptTemplateBean (JSON), pptOutLineData (JSON), query, from |
| IN | (from ChoicePPTTemplatePage) | 模板选择页点击模板 | from=EventExt.FROM_TEMPLATE |
| IN | (from CreateOutLinePage 回退) | 生成大纲后回退 → onNewIntent | outlineJson (已有大纲) |
| OUT → 生成大纲 | CreateOutLinePage | tv_create_ppt/tv_create_ppt_template onClick (无 outline 时) → FillPPTQueryDialog 填写后 → `createOutlinePage(this, query, pptTemplateBean, from)` | query, pptTemplateBean, from |
| OUT → PPT 文件页 | PPTFilePage | pptCreateResultLiveData → `previewPPTFile(this, pptFileResult)` → finish() | pptFileResult |
| OUT (返回) | 上一页 | TitleBar / 系统返回键 | — |
| OUT → 收藏操作 | (本地数据库) | PptDbViewModel.queryCollect / insertCreateTable | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，模板预览页全屏展示
- **RecyclerView 横向滚动**: 封面图列表全宽展示，左右边缘可能需要安全区 padding
- **底部操作栏**: 固定在底部，避免与系统导航栏重叠
- **ArkTS 方案**: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` + 底部操作栏 `.margin({ bottom: safeAreaBottom })`
