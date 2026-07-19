# F004 — PPT 核心流程

```yaml
complexity: complex
tier: core
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/PPTTemplatePreviewPage.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/CreateOutLinePage.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/ChoicePPTTemplatePage.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/PPTFilePage.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/SearchPagePage.kt"
  - role: service/repository
    path: "app/src/main/java/com/aipptzhizuozz/bjh/api/AIPPTService.kt"
  - role: service/repository
    path: "app/src/main/java/com/aipptzhizuozz/bjh/fragment/RecommendFragment.kt"
  - role: service/repository
    path: "app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/UseCountViewModel.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/network/bean/UserData.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/common/GsonUtil.kt"
```

## 范围

### 涉及页面
| 序号 | Android 页面 | ArkTS 目标 | 说明 |
|------|-------------|-----------|------|
| 0014 | `PPTTemplatePreviewPage` | `PPTTemplatePreviewPage.ets` | 模板预览 + 发起生成PPT |
| 0015 | `CreateOutLinePage` | `CreateOutLinePage.ets` | 大纲创建 + 拖拽排序编辑 |
| 0016 | `ChoicePPTTemplatePage` | `ChoicePPTTemplatePage.ets` | 选择模板页（内嵌 RecommendFragment） |
| 0017 | `PPTFilePage` | `PPTFilePage.ets` | PPT 文件预览 + 分享 + 保存 |
| 0021 | `SearchPagePage` | `SearchPage.ets` | 模板搜索页 |

### 依赖
- **feature-base**: `AIPPTService` (Retrofit API → `@ohos.net.http`)、`PptDbViewModel` (Room DB)、`GsonUtil` 序列化、`XXPermissions` 文件权限
- **F002 (会员支付)**: `CreateOutLinePage.createOutlinePage()` 入口校验无免费次数 → 跳 `MemberCenterActivitiy(FROM_CREATE_OUTLINE)`；`PPTFilePage` 下载/保存文件前 VIP 拦截

### 关联 Feature
- F003 (首页导航): `HomeActivity.initView()` → `pptViewModel.fetchPptTemplateList()` 预加载模板
- F006 (作品管理): `PPTFilePage` 支持从作品页进入 (`isFromWorksPage`)

## 数据流

```
=== 流程 A: 从首页输入主题/导入文档生成 PPT ===

HomePage 创作 Tab → 输入主题文字
  ↓
CreateOutLinePage.createOutlinePage(activity, query, from)
  ↓ gate: UserData.isBinding() + interceptAuth == 1 → LoginActivity 登录拦截
  ↓ gate: !UseCountViewModel.hasFreeCount() → MemberCenterActivitiy 会员拦截
  ↓
CreateOutLinePage.initView()
  ↓ show step 步骤条（输入主题 → 生成大纲 → 选择模板 → 生成PPT）
  ↓ pptViewModel.createPptOutLine(query, filePath)
  ↓ PPTCreatingDialog.show("大纲生成中...", totalTime=30/60s)
  ↓ 调用 AIPPTService.createOutLineByQuery(query) 或 createOutLineByFile(multipart)
  ↓
pptViewModel.pptChaptersLiveData.observe → outLineAdapter.models = chapters
  ↓ RecyclerView 展示章节列表: 第0项=主题(不可编辑), >0=章节(可编辑标题+内容子列表)
  ↓ pptViewModel.pptOutlineCreateSuccLiveData → "大纲生成完毕，点击可编辑操作"

用户编辑大纲后 → 点击"生成PPT"
  ↓ lifecycleScope.launch { checkTextIsCheat(大纲内容) }
  ↓ 敏感内容检查通过
  ↓ if (pptTemplateBean != null) → createPPT(pptTemplateBean)
  │ else → choiceTemplatePage() 跳 ChoicePPTTemplatePage
  ↓
  ↓ PPTTemplatePreviewPage.previewTemplate(this, template, outlineData, query, from)

=== 流程 B: 从首页模板 Tab 选择模板生成 PPT ===

HomePage 模板 Tab → RecommendFragment (ViewPager内嵌)
  ↓ 顶部 MagicIndicator 分类 Tab 筛选
  ↓ 内嵌 ViewPager2 子 Fragment (TemplateListFragment 按分类)
  ↓ Grid 展示 PptTemplateBean 列表
  ↓ 点击模板 item → onItemClick(template)
  ↓ if (isPreview) → PPTTemplatePreviewPage.previewTemplate(template, from=FROM_TEMPLATE)
  │ else → (activity as ChoicePPTTemplatePage).createPPT(template)  — 大纲页选模板
  ↓
  ↓ PPTTemplatePreviewPage 展示模板封面图横向 RecyclerView
  ↓ 步骤条: 选择模板 → 输入主题 → 生成大纲 → 生成PPT
  ↓ 点击"AI生成PPT" → FillPPTQueryDialog 输入主题(query)
  │ → CreateOutLinePage.createOutlinePage(this, query, template, from)
  ↓ 或已有 outlineData → 直接 generatePPt()

=== 流程 C: PPT 生成 + 进度轮询 ===

generatePPt()
  ↓ PPTCreatingDialog.show("PPT生成中，请勿关闭页面...")
  ↓ pptViewModel.createPptByOutline(query, outLineData, pptTemplateBean)
  ↓ AIPPTService.createPptByOutLine(requestBody) → 返回 task sid

进度轮询:
  ↓ 定时器轮询 AIPPTService.queryPptProgress(sid)
  ↓ pptViewModel.pptCreateProgressLiveData.observe → dialog.setProgress(progress)
  ↓ 状态 pending → processing → completed

生成完成:
  ↓ pptViewModel.pptCreateResultLiveData.observe → pptCreateResult
  ↓ pptDbViewModel.insertCreateTable(result) — 入库 Room
  ↓ pptCreatingDialog.dismiss()
  ↓ PPTFilePage.previewPPTFile(this, result) — 跳文件预览页

=== 流程 D: PPT 文件预览 ===

PPTFilePage.initView()
  ↓ parse PptCreateTable → 展示 PPT 封面图 RecyclerView
  ↓ dowLoadPptFile() → pptViewModel.downPptxFile()
  ↓ pptViewModel.pptDownResultLiveData.observe → convertPptxToImages()
  ↓ pptViewModel.pptPreviewResultLiveData.observe → 展示预览图列表
  ↓ 点击"保存PPT" → requestStoragePermission → savePptFile()
  ↓ 分享按钮(onRightClick) → pptViewModel.sharePptFile()
  ↓ VIP 拦截: pptViewModel.vipInterceptLiveData → MemberCenterActivitiy.openMemberCenter()

=== 流程 E: 模板搜索 ===

SearchPagePage — 搜索框输入实时过滤
  ↓ dataBind.edSearchInput.doAfterTextChanged → pptViewModel.filterKeyWord(kw)
  ↓ pptViewModel.searchResultLiveData.observe → 2 列 Grid 展示匹配模板
  ↓ 点击模板 item → setResult(RESULT_OK, template) + finish()
  │ 调用方 (RecommendFragment) 收到 result → PPTTemplatePreviewPage.previewTemplate
```

## 服务层

### ArkTS 目标接口签名

```typescript
// PptService.ets — PPT AI 服务层
class PptService {
  /** 获取 PPT 模板列表 */
  fetchTemplateList(params?: TemplateListQuery): Promise<PptTemplateResBean[]>
  /** 通过 query 文本生成大纲 */
  createOutlineByQuery(query: string): Promise<PptOutLineResBean>
  /** 通过上传文档生成大纲 (Multipart) */
  createOutlineByFile(filePath: string): Promise<PptOutLineResBean>
  /** 根据大纲生成 PPT */
  createPptByOutline(query: string, outlineSid: string, outline: object, templateId: string): Promise<PptResultResBean>
  /** 查询 PPT 生成进度 */
  queryProgress(sid: string): Promise<PptProgressResBean>
  /** 下载 PPT 文件 */
  downloadPptFile(url: string): Promise<string>  // 返回沙箱路径
  /** 生成 Xunfei API 签名头 */
  generateAuthHeaders(): Record<string, string>
  /** 敏感内容检测 */
  checkTextSafe(text: string): Promise<boolean>
}

// PptDbService.ets — PPT 本地持久化服务层
class PptDbService {
  /** 收藏模板 */
  addCollect(template: PptTemplateBean): Promise<void>
  /** 取消收藏 */
  removeCollect(templateId: string): Promise<void>
  /** 查询是否已收藏 */
  isCollected(templateId: string): Promise<boolean>
  /** 查询所有收藏 */
  queryAllCollects(): Promise<PPTCollectRecord[]>
  /** 插入创建记录 */
  insertCreateRecord(record: PPTCreateRecord): Promise<void>
  /** 查询所有创建记录 */
  queryAllCreateRecords(): Promise<PPTCreateRecord[]>
  /** 按 taskId 查询 */
  queryByTaskId(taskId: string): Promise<PPTCreateRecord | null>
}

// PptSessionState.ets — PPT 页面共享状态
@ObservedV2
class PptSessionState {
  @Trace query: string = ''
  @Trace outlineSid: string = ''
  @Trace chapters: PptChapter[] = []
  @Trace selectedTemplate: PptTemplateBean | null = null
  @Trace templateList: PptTemplateBean[] = []
  @Trace isLoading: boolean = false
  @Trace isCreatingOutline: boolean = false
  @Trace isCreatingPpt: boolean = false
  @Trace pptProgress: number = 0
  @Trace pptTaskId: string = ''
  @Trace pptResult: PptResultData | null = null
  @Trace searchKeyword: string = ''
  @Trace searchResults: PptTemplateBean[] = []
  @Trace filterStyle: TemplateFilterStyle | null = null
  @Trace from: string = ''
}

// PptFileState.ets — PPT 文件预览状态
@ObservedV2
class PptFileState {
  @Trace pptRecord: PPTCreateRecord | null = null
  @Trace previewImages: string[] = []
  @Trace isDownloading: boolean = false
  @Trace isFromWorksPage: boolean = false
}
```

### RecyclerView 多场景 → ArkTS 映射
| Android 场景 | ArkTS |
|-------------|-------|
| `CreateOutLinePage.outLineAdapter` — 线性列表(主题+章节) | `List()` + `ForEach(chapters, (ch: PptChapter, i) => { PptChapterItem({ chapter: ch, index: i }) })` — 支持拖拽排序用 `onItemDragStart/onItemDrop` |
| `RecommendFragment` 模板 Grid 2 列 | `Grid().columnsTemplate('1fr 1fr')` + `ForEach(templates, ...)` → `TemplateCard` |
| `PPTTemplatePreviewPage.rvCovers` 横向封面图 | `List().listDirection(Axis.Horizontal).space(13)` + `ForEach(covers, ...)` → `Image` 组件 |
| `SearchPagePage.rvTemplateList` Grid 2 列搜索结果 | 同上 Grid |
| `TemplateFilterStyleBean/ColorBean` 顶部分类筛选 | `Tabs({ barPosition: BarPosition.Start, barMode: BarMode.Scrollable })` + `TabContent` |
| `item_ppt_outline_content` 章节子内容 | `ListItem` 内嵌第二个 `List` 或直接 `Column` 展开子内容 |

## API 接口

| Method | Endpoint | Description | Auth |
|--------|---------|-------------|------|
| POST | `https://zwapi.xfyun.cn/api/ppt/v2/template/list` | 获取模板列表 | Xunfei Signature |
| POST | `https://zwapi.xfyun.cn/api/ppt/v2/createOutline` | 通过 query 生成大纲 | Xunfei Signature |
| POST | `https://zwapi.xfyun.cn/api/ppt/v2/createOutlineByDoc` | 通过上传文档生成大纲 (Multipart) | Xunfei Signature |
| POST | `https://zwapi.xfyun.cn/api/ppt/v2/createPptByOutline` | 根据大纲生成 PPT | Xunfei Signature |
| GET | `https://zwapi.xfyun.cn/api/ppt/v2/progress?sid={sid}` | 查询 PPT 生成进度 | Xunfei Signature |
| GET | `{dynamic downUrl}` | 下载 PPT 文件 (Streaming) | — |

### 鉴权算法 (`ApiAuthAlgorithm.getSignature`)
```typescript
// Xunfei API 签名
const appId = '4fe117ca'
const secret = 'NzA1NTIxYWRkMjJlZWM5YThmYmIwZDg5'

function generateSignature(appId: string, secret: string, timestamp: number): string {
  return md5(appId + timestamp.toString() + secret)
}

function generateHeaderMap(): Record<string, string> {
  const timestamp = Math.floor(Date.now() / 1000)
  return {
    'appId': appId,
    'timestamp': timestamp.toString(),
    'signature': generateSignature(appId, secret, timestamp)
  }
}
```

## 实现映射

| 源（Android/Kotlin） | ArkTS 目标 | 说明 |
|---------------------|-----------|------|
| `CreateOutLinePage.createOutlinePage(activity, query, template, filePath, from)` | `navPathStack.pushPathByName('CreateOutLinePage', { query, templateJson, filePath, from })` | 导航到大纲编辑页 |
| `AIPPTService.createOutLineByQuery(query)` | `pptService.createOutlineByQuery(query)` | AI 生成大纲 |
| `AIPPTService.createOutLineByFile(parts)` | `pptService.createOutlineByFile(filePath)` — multipart 上传文档 | 文档生成大纲 |
| `AIPPTService.createPptByOutLine(requestBody)` | `pptService.createPptByOutline(query, outlineSid, outline, templateId)` | 大纲生成 PPT |
| `AIPPTService.queryPptProgress(sid)` | `pptService.queryProgress(sid)` + 定时轮询 (`setInterval`) | 生成进度轮询 |
| `AIPPTService.download(url)` — Streaming GET | `request.agent.download(context, url)` / `http.createHttp().request(url, ...)` | PPT 文件下载 |
| `PPTCreatingDialog` — 生成进度弹窗 | `@CustomDialog` + `Progress({ type: ProgressType.Linear })` | 生成进度弹窗 |
| `CreateOutLinePage` RecyclerView 大纲列表 + 拖拽排序 | `List()` + `onItemDragStart`/`onItemDrop` 实现拖拽重排 | 可拖拽大纲编辑 |
| `RecommendFragment` MagicIndicator分类Tab | `Tabs({ barPosition: BarPosition.Start, barMode: BarMode.Scrollable })` | 模板分类筛选 |
| `TemplateCard` + Glide 图片加载 | `Image(coverUrl).borderRadius(N).objectFit(ImageFit.Cover)` | 模板卡片封面 |
| `PPTTemplatePreviewPage` 封面横向滑动 | `List().listDirection(Axis.Horizontal).space(13)` | 模板预览封面 |
| `FillPPTQueryDialog` — 输入主题弹窗 | `@CustomDialog` + `TextInput({ placeholder: '请输入PPT主题' })` | 主题输入弹窗 |
| `SearchPagePage` 搜索过滤 | `TextInput.onChange(kw => pptState.searchKeyword = kw)` → 本地过滤 | 实时搜索过滤 |
| `PPTFilePage` 文件预览图 Grid | `Grid().columnsTemplate('1fr')` + `ForEach(images, ...)` | 预览图列表 |
| `PPTFilePage.sharePptFile()` | `systemShare.share({ title, filePath })` | 分享 PPT |
| `PPTFilePage.savePptFile()` | `fileIo.copyFile(sandboxPath, savePath)` + `picker.save()` | 保存 PPT 到本地 |
| `XXPermissions` 文件权限 | `abilityAccessCtrl.createAtManager().requestPermissionsFromUser(ctx, ['ohos.permission.WRITE_USER_STORAGE'])` | 文件保存权限 |
| `UseCountViewModel.hasFreeCount()` — 免费次数校验 | `UserDataModel.freeCount > 0` or AppStorageV2 全局计数字段 | 免费次数门禁 |
| `checkTextIsCheat(text)` — 敏感内容检测 | `pptService.checkTextSafe(text)` | 内容安全检测 |

## 状态管理

```typescript
// AppStorageV2 全局 key
class StorageKeys {
  static readonly PPT_SESSION = 'ppt_session'      // PptSessionState
}

@ObservedV2
class PptTemplateBean {
  @Trace templateIndexId: string = ''
  @Trace templateName: string = ''
  @Trace coverUrl: string = ''
  @Trace category: string = ''
  @Trace tags: string[] = []
  @Trace colorScheme: string = ''
  @Trace detailImageBean: DetailImageBean | null = null
  static fromJson(json: object): PptTemplateBean { /*...*/ }
  getCoverList(): string[] { return this.detailImageBean?.coverList ?? [] }
}

@ObservedV2
class PptChapter {
  @Trace chapterId: string = ''
  @Trace chapterTitle: string = ''
  @Trace chapterContents: PptChapter[] | null = null
  @Trace order: number = 0
}

@ObservedV2
class PptOutLineData {
  @Trace sid: string = ''
  @Trace outline: PptChapter[] | null = null
}

// Room DB → RDB 表结构
interface PPTCollectRecord {
  templateId: string   // PRIMARY KEY
  coverUrl: string
  title: string
  collectTime: number
}

interface PPTCreateRecord {
  id: number           // AUTO_INCREMENT PRIMARY KEY
  taskId: string
  title: string
  status: string       // pending/processing/completed/failed
  fileUrl: string | null
  createTime: number
}
```

## 对接点

| UI 页面 @Local / @Param | 对应 ArkTS 页面 | 数据类型 | 说明 |
|------------------------|---------------|---------|------|
| `pptSession: PptSessionState` | `CreateOutLinePage.ets` | `@Local PptSessionState` | 大纲编辑状态 |
| `chapters: PptChapter[]` | `CreateOutLinePage.ets` | `@Local` (from PptSessionState) | 可拖拽排序的大纲章节 |
| `query: string` | `CreateOutLinePage.ets`, `PPTTemplatePreviewPage.ets` | `@Param` (路由参数) | 用户输入的主题 |
| `selectedTemplate: PptTemplateBean` | `PPTTemplatePreviewPage.ets`, `CreateOutLinePage.ets` | `@Param` (路由参数, JSON) | 选中模板 |
| `templates: PptTemplateBean[]` | `RecommendFragment` 组件, `SearchPage.ets` | `@Local` | 模板列表 |
| `searchKeyword: string` | `SearchPage.ets` | `@Local` (TextInput onChange) | 搜索关键词 |
| `pptProgress: number` | `PPTTemplatePreviewPage.ets` (PPTCreatingDialog) | `@Local` | 生成进度 0-100 |
| `pptFileState: PptFileState` | `PPTFilePage.ets` | `@Local PptFileState` | 文件预览状态 |
| `previewImages: string[]` | `PPTFilePage.ets` | `@Local` (from PptFileState) | 预览图列表 |
| `from: string` | 全流程页面 | `@Param` (路由参数) | 来源标识，控制步骤条展示 |
| `isFromWorksPage: boolean` | `PPTFilePage.ets` | `@Param` (路由参数) | 是否从作品页进入 |
| `filterStyle: TemplateFilterStyle` | `RecommendFragment` 组件 | `@Local` | 当前筛选条件 |

## 验收标准

| # | 验收条件 | 源 | 标 |
|---|---------|----|----|
| AC-1 | 创建大纲入口校验：未登录 → 跳 `LoginPage`；无免费次数 → 跳 `MemberCenterPage` | `CreateOutLinePage.createOutlinePage()` L66-77 | `CreateOutLinePage` aboutToAppear gate check |
| AC-2 | 大纲生成中显示进度弹窗"大纲生成中，请勿退出..."，生成完成后弹窗关闭、显示"大纲生成完毕，点击可编辑操作" | `recreateOutline()` L376-393 | `@CustomDialog` 生成中 → pptSession.isCreatingOutline → 完成关闭 |
| AC-3 | 大纲列表展示：第 0 项=主题（灰显，不可编辑），>0=章节（可编辑标题），每章节含可编辑子内容列表 | `outLineAdapter.onBind` L159-213 | `PptChapterItem` 组件：`index==0` → 锁定，`index>0` → `TextInput` 可编辑 |
| AC-4 | 大纲生成完成后点击"生成PPT" → 先执行 `checkTextSafe()` 敏感内容检测 → 通过后选择模板/直接生成 | `CreateOutLinePage.onClick(R.id.tv_create_ppt)` L279-301 | `pptService.checkTextSafe(outlineJson)` → 通过 → push ChoicePPTTemplatePage / PPTTemplatePreviewPage |
| AC-5 | 模板列表 Grid 2 列展示，含封面图 + 模板名称 | `RecommendFragment.initViewPager()` L126-140: `fragmentList.add(RecommendListFragment.newInstance(it) { callback })`，RecommendListFragment 内 Grid 布局 | `Grid().columnsTemplate('1fr 1fr')` + `TemplateCard` 组件 |
| AC-6 | 模板分类 MagicIndicator Tab 筛选，横向滚动 | `RecommendFragment.initViewPager()` L142-177: `CommonNavigator` + `ScaleTransitionPagerTitleView`(minScale=0.85) + `LinePagerIndicator`(2dp高14dp宽) | `Tabs({ barPosition: BarPosition.Start, barMode: BarMode.Scrollable })` |
| AC-7 | 模板预览页：横向封面图滑动 + 步骤条 + 点击"AI生成PPT"弹出主题输入弹窗或直接生成 | `PPTTemplatePreviewPage` L100-116 (cover RecyclerView), L136-170 (`updateStep()`), L179-195 (`onClick`) | `List().listDirection(Axis.Horizontal)` + `StepIndicator` + `FillQueryDialog` |
| AC-8 | PPT 生成中显示进度弹窗"PPT生成中，请勿关闭页面..."，进度条实时更新 | `PPTTemplatePreviewPage.generatePPt()` L239-243: `PPTCreatingDialog.newInstance("PPT生成中，请勿关闭页面...")`; `initObserver()` L212-214: `pptCreateProgressLiveData.observe { setProgress(it) }` | `@CustomDialog` + `Progress({ type: ProgressType.Linear, value: pptProgress })` |
| AC-9 | PPT 生成完成后自动跳转文件预览页 (`PPTFilePage`)，同时入库创建记录 | `PPTTemplatePreviewPage.initObserver()` L216-220: `pptCreateResultLiveData.observe { insertCreateTable(it); pptCreatingDialog?.dismiss(); PPTFilePage.previewPPTFile(this, it); finish() }` | `pptDbService.insertCreateRecord(result)` → `navPathStack.replacePathByName('PPTFilePage', record)` |
| AC-10 | 文件预览页：展示封面图网格 + 下载 PPT 文件 + 展示预览图列表 | `PPTFilePage.initObserver()` L184-211: `loadingStatusLiveData` L184-190, `pptDownResultLiveData` L192-199 (`convertPptxToImages`), `pptPreviewResultLiveData` L201-211 (adapter models + show tips) | `pptFileState.previewImages` → `Grid` 展示 |
| AC-11 | 文件预览页点击"保存PPT"→ 请求文件权限 → 授权后保存到本地 | `requestStoragePermission()` L119-152 | `abilityAccessCtrl.requestPermissionsFromUser(ctx, ['ohos.permission.WRITE_USER_STORAGE'])` → `fileIo.copyFile` |
| AC-12 | 搜索页输入框实时过滤模板，2 列 Grid 展示结果，点击模板 item 返回结果给调用方 | `SearchPagePage` L41-43 (`edSearchInput.doAfterTextChanged` → `filterKeyWord`), L52-78 (`templateAdapter.grid(2).setup` + `onBind` + `onClick` → `setResult + finish`) | `TextInput.onChange` → `pptService.filterTemplates(kw)` → 点击 → pop with result |
| AC-13 | 敏感内容检测失败 toast"大纲内容涉及敏感内容"，阻止生成 | `textIsCheat` → toast L291-292 | `pptService.checkTextSafe(text)` → if (true) toast → stop |
| AC-14 | 文件预览页 VIP 拦截：非 VIP 用户下载预览时弹出会员中心 | `pptViewModel.vipInterceptLiveData.observe` L214-216 | `EventHub.on('vipIntercept')` → `navPathStack.pushPathByName('MemberCenterPage')` |
| AC-15 | 大纲编辑页点击"保存本地"触发文件存储权限申请：未授权时弹出权限说明弹窗（Android 11+ 用 AppTipsDialog，低版本用 AppPermissionIntroDialog），授权后调用 `saveOutline2File()` 保存大纲到文件，拒绝后 toast"拒绝了授权，文件保存失败" | `CreateOutLinePage.requestStoragePermission()` L305-338, `onGranted` L343-349, `onDenied` L352-359 | `abilityAccessCtrl.requestPermissionsFromUser(ctx, ['ohos.permission.WRITE_USER_STORAGE'])` → `@CustomDialog` 权限说明弹窗 → `fileIo.writeTextFile(sandboxPath, outlineText)` → 失败 toast |
| AC-16 | 文件导入路径：CreateOutLinePage 收到 `filePath` 参数时，使用 60 秒超时（vs 文本输入 30 秒），调用 `createPptOutLine(query="", filePath)` 从文档生成大纲；若 `query` 和 `filePath` 均为空则直接 `finish()` | `CreateOutLinePage.initView()` L123-125, `recreateOutline()` L377-393: `if (filePath.isNotEmpty()) totalTime = 60`, `pptViewModel.createPptOutLine(query, filePath)` | route param `filePath` → `if (!filePath) totalTime = 60` → `pptService.createOutlineByFile(filePath)` → `@CustomDialog` 60s 倒计时; `if (!query && !filePath) router.back()` |
| AC-17 | 步骤条标题根据 `from` 参数动态切换：FROM_FILE_IMPORT→"导入文档"，FROM_TEXT_BOX_CONTENT→"输入主题"，FROM_TEMPLATE→"选择模版"+"输入主题"+"生成大纲"(三步点亮) | `CreateOutLinePage.initView()` L135-154: `when(from)` 分支设置 `tvStep1`/`tvStep2`/`tvStep3` 文字及 `isSelected` | `StepIndicator` 组件绑定 `@Param from: string`，`switch(from)` 设置各步文字和选中态 |
| AC-18 | 文件预览页点击分享按钮触发系统分享 PPT 文件 | `PPTFilePage.onRightClick(titleBar)` L100-103 → `pptViewModel.sharePptFile()` | `systemShare.share({ title: pptTitle, filePath: sandboxPath })` 或 `@kit.ShareKit` 分享面板 |
| AC-19 | 文件预览页返回行为：若从作品页进入(`isFromWorksPage=true`)，返回时跳转 `HomeActivity` 而非回退到上一页 | `PPTFilePage.onBackPressed()` L232-237: `if (!isFromWorksPage) { HomeActivity.openHomePage(this) } finish()` | `NavPathStack.popToName('HomePage')` 或 `navPathStack.clear().pushPathByName('HomePage')`；若 `isFromWorksPage=false` 则普通 `pop()` |
| AC-20 | 大纲生成失败时 toast 错误信息并自动关闭页面 | `CreateOutLinePage.initObserver()` L228-231: `pptViewModel.pptOutlineErrorLiveData.observe { it.toast(); finish() }` | `pptState.errorMessage` → `promptAction.showToast(message)` + `router.back()` |
| AC-21 | 返回按钮/物理返回拦截：大纲生成中弹出「停止生成将退出该页面并丢失该大纲内容，确认退出吗？」确认弹窗；编辑态弹出「退出将会丢失该大纲内容，确认退出吗？」确认弹窗 | `CreateOutLinePage.onBackPressed()` L417-423: `if (outlineIsCreating()) showInterceptDialog("停止生成将退出该页面并丢失该大纲内容，确认退出吗？") else showInterceptDialog("退出将会丢失该大纲内容，\n确认退出吗？")` | `onBackPress` 拦截 → `getUIContext().showAlertDialog({ message: isCreating ? $r('...stop_create') : $r('...exit_loss') })` → 确认 `pop()` / 取消无操作 |
| AC-22 | 「生成PPT」按钮文案根据是否预选模板动态切换：有模板→"生成PPT"，无模板→"选择PPT模版" | `CreateOutLinePage.initView()` L128: `dataBind.tvCreatePpt.text = if (pptTemplateBean == null) "选择PPT模版" else "生成PPT"` | `Button(pptTemplateBean ? $r('app.string.generate_ppt') : $r('app.string.select_template'))` 或 `@Computed get buttonLabel()` |
| AC-23 | 模板选择页双模式：预览模式(`isPreview=true`)标题"精品模版"、隐藏返回按钮和步骤条、显示搜索图标、点击模板→previewTemplate；选择模式(`isPreview=false`)标题"请选择模版"、显示返回按钮和步骤条、隐藏搜索图标、点击模板→createPPT | `RecommendFragment.initView()` L74-77: `titleBar.title`, `leftView.visibleOrGone(!isPreview)`, `rightView.visibleOrGone(isPreview)`, `includeStep.root.visibleOrGone(!isPreview)`; 点击回调分支 L131-136: `if (isPreview) previewTemplate else createPPT` | `@Param isPreview: boolean` → `if`: title=`$r(...)`, backButton visibility, `StepIndicator` visibility, searchIcon visibility; `@Event onTemplateClick` 回调根据 `isPreview` 路由 |
| AC-24 | 模板搜索结果回传路由：RecommendFragment 接收 SearchPagePage 返回的 `PptTemplateBean`，预览模式→`previewTemplate(activity, it, from)`，选择模式→`(activity as ChoicePPTTemplatePage).createPPT(it)` | `RecommendFragment` L39-49: `searchPagePageLauncher` ActivityResultCallback → `if (isPreview) previewTemplate else createPPT` | `pushPathByName('SearchPagePage')` onResult → `if (isPreview) navPathStack.pushPathByName('PPTTemplatePreviewPage', { template, from }) else @Event onSelectTemplate(template)` |
| AC-25 | 文件预览页动态标题：展示 PPT 名称（`pptCreateTable.title`）在标题栏；数据缺失时（`templateIndexId` 为空或 `detailImageBean` 为 null）自动关闭页面 | `PPTFilePage.initView()` L71-80: `if (templateIndexId.isEmpty()) finish(); title = pptCreateTable.title; if (detailImageBean == null) finish();` | `@Param pptCreateTableJson: string` → parse → `if (!data.templateIndexId) router.back()`; `this.titleBarTitle = data.title`; if parse fails → `promptAction.showToast($r('app.string.data_load_failed'))` + `router.back()` |
| AC-26 | 模板预览页从大纲编辑页返回时自动触发 PPT 生成：`onNewIntent` 收到完成的 `PptOutLineData` 后自动调用 `generatePPt()`，无需用户再次点击 | `PPTTemplatePreviewPage.onNewIntent()` L123-133: `if (pptOutLineData.outline != null) { tvCreatePpt.text = "AI生成PPT"; updateStep(); generatePPt() }` | `onNewParam` 接收更新的 `pptOutLineData` → `if (outline) { this.stepState = "generating"; generatePPt() }` |
| AC-27 | PPT 生成失败时关闭进度弹窗、toast 错误信息、恢复底部操作栏 | `PPTTemplatePreviewPage.initObserver()` L206-210: `pptViewModel.pptCreateFailLiveData.observe { pptCreatingDialog?.dismiss(); it.toast(); viewBottom.visibility = View.VISIBLE }` | `pptState.isCreatingPpt = false` → `@CustomDialog.close()` + `promptAction.showToast(errorMsg)` + `viewBottom` 重新显示 |
| AC-28 | 模板预览页根据是否有已生成大纲切换按钮：无大纲时显示「生成PPT」按钮（点击弹出 FillPPTQueryDialog 输入主题），有大纲时显示「AI生成PPT」按钮（点击直接 generatePPt）；步骤条根据 `pptOutLineData.outline` 是否为空控制步骤点亮状态 | `PPTTemplatePreviewPage.initView()` L93-95: `tvCreatePptTemplate.visibleOrGone(!b); tvCreatePpt.visibleOrGone(b)`; `onClick()` L180-195; `updateStep()` L160-168: `if (outline == null) step2 selected else steps 3&4 selected` | `if (!pptState.outline) { Button($r('...generate_ppt')) → FillQueryDialog } else { Button($r('...ai_generate_ppt')) → generatePPt() }`; `StepIndicator` 绑定 `outline` 状态控制高亮步数 |
| AC-29 | 搜索页进入时自动聚焦搜索框并弹出键盘（300ms 延迟） | `SearchPagePage.initView()` L48-50: `dataBind.edSearchInput.postDelayed({ showKeyboard() }, 300)` | `aboutToAppear()` → `setTimeout(() => focusControl.requestFocus('searchInput'), 300)` |
