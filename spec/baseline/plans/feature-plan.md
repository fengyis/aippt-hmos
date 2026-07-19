# Feature Execution Plan

## Context
- Source: spec/baseline/feature-index.md, spec/baseline/feature-base.md
- Style: none
- Total features (V1): 10
- Total slices: 15 (Slice 0-0e infrastructure + Slice 1-10 feature)
- Base tasks: 8 (Base-0..Base-7)
- Estimated phases: Phase 0 (Base) + Slice 0-0e (infrastructure) + Slice 1-10 (features) + Final Verification

## Dependency Graph

```
base → F001(认证) → F003(首页) → F002(会员)
base → F004(PPT核心) → F006(作品)
base → F005(文件管理)
base → F008(WebView)
F001 → F007(个人中心)
F004 → F002(会员——PPT生成需VIP)
```

## 执行顺序（拓扑排序）

0. Phase 0: Base-0..Base-7 (水平基础设施 — 资源/编译)
1. Serial chain: Slice 0 → 0b → 0c (Database → Models → Data Layer)
   Parallel: Slice 0d (State Manager, depends on 0b) + Slice 0e (Common Components, depends on 0d) → Serial after 0c
2. parallel_group 1: F001, F004, F005, F009 (无相互依赖，depends_on updated to Slice 0e)
3. parallel_group 2: F002, F003, F006, F007, F008, F010 (依赖上层)

## Phase 0: Base 层（水平执行）

所有 Feature Slices 共用的基础设施，必须先完成。

- [ ] Base-0: 资源前置扫描与迁移
  - suggested_skills: [android2hmos_resources_convert]
  - input: 所有 spec 中引用的资源 ID 全集（扫描 spec/baseline/ui/page_*.md、spec/baseline/features/F-*.md、feature-base.md）
  - output: entry/src/main/resources/ 全量资源 + resource-mapping.md
  - acceptance: 缺失资源显式标 MISSING_xxx
  - blocking: true
  - details: 扫所有 spec 中颜色/字符串/图片/媒体引用，调用 android2hmos_resources_convert 批量迁完资源

- [ ] Base-1: Models — 所有 entity / DTO 定义
  - suggested_skills: [arkts-data-layer]
  - input: feature-base.md Models 段
  - output: entry/src/main/ets/models/*.ets
  - details: UserData, PptTemplateBean, PptChapter, PptProgressData, PptResultData, ProductBean, ScanFileBean 等

- [ ] Base-2: Database — Schema + DAO
  - suggested_skills: [arkts-data-layer]
  - input: feature-base.md Database 段
  - output: entry/src/main/ets/database/*.ets
  - details: Room(PPTCollectTable+PPTCreateTable) → RDB; PPTCollectDao+PPTCreateDao → Repository

- [ ] Base-3: Network — HttpClient + interceptors
  - suggested_skills: [arkts-data-layer, arkts-network-troubleshoot]
  - input: feature-base.md Network 段
  - output: entry/src/main/ets/network/*.ets
  - details: Retrofit+OkHttp → @ohos.net.http; Token拦截器; AIPPTService → PptApiService

- [ ] Base-4: Events — EventHub 常量 + pub/sub wrapper
  - suggested_skills: [arkts-state-manager]
  - input: feature-base.md Events 段
  - output: entry/src/main/ets/events/*.ets
  - details: EventBus → @ohos.events.emitter; PaySuccessEvent, LimitCampaignEvent 等

- [ ] Base-5: Preferences — SharedPreferences 迁移
  - suggested_skills: [arkts-data-layer]
  - input: feature-base.md Preferences 段
  - output: entry/src/main/ets/preferences/*.ets
  - details: 登录状态/首次启动标记 → @ohos.data.preferences

- [ ] Base-6: 公共组件库
  - suggested_skills: [arkts-component-builder, arkts-pattern-library]
  - input: ui-manifest.md 共享组件表 + feature-base.md 公共组件段
  - output: entry/src/main/ets/components/common/*.ets
  - details: TitleBar, TabBar, LoadingDialog, ConfirmDialog, PermissionDialog, WebViewContainer, TemplateCard, FileListItem

- [ ] Base-7: 编译验证 — Base 层全量编译
  - suggested_agents: [hmos-builder]
  - blocking: true
  - details: 派发 Agent hmos-builder (CALLER=a2h-execute, STAGE_HINT=stage-2-base-7) 全量编译

## Slice 0: Database

```yaml
complexity: simple
tier: core
depth: full
depends_on: [Base-7]
parallel_group: 0

modifies_files:
  - entry/src/main/ets/database/*.ets
cross_slice_edits: []
```

### Step 1: RDB Schema
- suggested_skills: [arkts-data-layer]
- input: feature-base.md Database 段 (PPTCollectTable, PPTCreateTable, PPTCollectDao, PPTCreateDao)
- Room(PPTCollectTable+PPTCreateTable) → RDB `CREATE TABLE` SQL; DAO → Repository
- output: `entry/src/main/ets/database/*.ets`
- evidence: 两张表 SQL 已落盘 + Repository 类已生成

### Step 2: 编译验证
- suggested_agents: [hmos-builder]
- acceptance: 单文件编译 PASS

## Slice 0b: Models

```yaml
complexity: simple
tier: core
depth: full
depends_on: [Slice 0]
parallel_group: 0

modifies_files:
  - entry/src/main/ets/model/*.ets
cross_slice_edits: []
```

### Step 1: Data Model Classes
- suggested_skills: [arkts-data-layer]
- input: feature-base.md Models 段 (UserData, PptTemplateBean, PptChapter, PptProgressData, PptResultData, ProductBean, ScanFileBean, VipFloatBean)
- 全部 Entity → `@ObservedV2` class + `@Trace` 字段 + `fromJson()` + `toJson()`; JSON 序列化走显式映射（不直接 `JSON.stringify` @ObservedV2 实例）
- output: `entry/src/main/ets/model/*.ets`
- acceptance: 所有模型类编译 PASS

### Step 2: 编译验证
- suggested_agents: [hmos-builder]
- acceptance: 单文件编译 PASS

## Slice 0c: Data Layer

```yaml
complexity: complex
tier: core
depth: full
depends_on: [Slice 0b]
parallel_group: 0

modifies_files:
  - entry/src/main/ets/network/HttpClient.ets
  - entry/src/main/ets/network/AuthInterceptor.ets
  - entry/src/main/ets/network/PlatformInfoProvider.ets
  - entry/src/main/ets/service/*.ets
cross_slice_edits: []
```

### Step 1: HttpClient 封装 + API Service
- suggested_skills: [arkts-data-layer, arkts-network-troubleshoot]
- input: feature-base.md Network 段 + api-inventory 全部 endpoint
- HttpClient: `http.createHttp()` 封装 + 通用请求方法 + Token 拦截器 + Xunfei 签名头
- API Service: AIPPTService/PayApiService → 三段式 contract(static/runtime/reconciled)
- output: `entry/src/main/ets/network/HttpClient.ets`, `entry/src/main/ets/service/*.ets`
- acceptance: HttpClient 拦截器链可注入; API 签名与 api-inventory.json `static` 段一致

### Step 2: 编译验证
- suggested_agents: [hmos-builder]
- acceptance: 单文件编译 PASS

## Slice 0d: State Manager

```yaml
complexity: simple
tier: core
depth: full
depends_on: [Slice 0b]
parallel_group: 0

modifies_files:
  - entry/src/main/ets/common/StorageKeys.ets
  - entry/src/main/ets/events/EventConstants.ets
cross_slice_edits: []
```

### Step 1: PersistenceV2 + EventHub 常量
- suggested_skills: [arkts-state-manager]
- input: feature-base.md Preferences 段 + Events 段
- `StorageKeys` 常量类 + `PersistenceV2.globalConnect` 全局 key (隐私同意/引导完成/首次启动等)
- `EventConstants` 类: PaySuccessEvent, LimitCampaignEvent, LimitGiftEvent, OaidResultEvent 等
- output: `entry/src/main/ets/common/StorageKeys.ets`, `entry/src/main/ets/events/EventConstants.ets`
- acceptance: 所有 Persistent key + 事件常量已声明

### Step 2: 编译验证
- suggested_agents: [hmos-builder]
- acceptance: 单文件编译 PASS

## Slice 0e: Common Components

```yaml
complexity: simple
tier: core
depth: full
depends_on: [Slice 0d]
parallel_group: 0

modifies_files:
  - entry/src/main/ets/components/TitleBar.ets
  - entry/src/main/ets/components/TabBar.ets
  - entry/src/main/ets/components/LoadingDialog.ets
  - entry/src/main/ets/components/ConfirmDialog.ets
  - entry/src/main/ets/components/PermissionDialog.ets
  - entry/src/main/ets/components/WebViewContainer.ets
  - entry/src/main/ets/components/TemplateCard.ets
  - entry/src/main/ets/components/PPTCoverImage.ets
  - entry/src/main/ets/components/FileListItem.ets
cross_slice_edits: []
```

### Step 1: 共享 UI 组件
- suggested_skills: [arkts-component-builder, arkts-pattern-library]
- input: ui-manifest.md 共享组件表 (TitleBar, TabBar, LoadingDialog, ConfirmDialog, PermissionDialog, WebViewContainer, TemplateCard/PPTCoverImage, FileListItem)
- 每个组件 → `@ComponentV2 struct` + `@Param/@Event` 接口; `FileListItem` 需含搜索高亮 `StyledString`
- output: `entry/src/main/ets/components/*.ets`
- acceptance: 所有组件独立编译 PASS

### Step 2: 全量编译闸门 (CP-1)
- suggested_agents: [hmos-builder]
- blocking: true
- 派发 Agent hmos-builder (CALLER=a2h-execute, STAGE_HINT=stage-infra-cp1) 全量编译
- acceptance: 编译 exit 0

## Slice 1: F001 — 认证登录

```yaml
complexity: complex
tier: standard
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/LoginActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/AccountInfoActivity.kt"
  - role: viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/LoginViewModel.kt"

placeholders_planned: []

integration_points:
  - [ ] LoginPage @Local loginState ← AuthViewModel.loginLiveData
  - [ ] AccountInfoPage @Local userInfo ← AuthViewModel.userInfo

wires:
  - page: LoginPage
    viewmodel: AuthViewModel
  - page: AccountInfoPage
    viewmodel: AuthViewModel

modifies_files:
  - entry/src/main/ets/pages/LoginPage.ets
  - entry/src/main/ets/pages/AccountInfoPage.ets
  - entry/src/main/ets/viewmodel/AuthViewModel.ets
cross_slice_edits: []

depends_on: [Base-7, Slice 0e]
parallel_group: 1
```

> complexity=complex 理由：auth 关键词命中 + SMS 验证码状态机(60s倒计时) + 支付宝/微信第三方 SDK 回调

### Step 3a: UI 补充
- suggested_skills: [a2h-activity-converter]
- 目标页面: LoginPage (page_0004), AccountInfoPage (page_0005)
- LoginPage: SMS 验证码输入 + 60s 倒计时按钮 + 隐私协议勾选 + 支付宝/微信授权按钮
- AccountInfoPage: userId 展示 + VIP 等级文字 + 退出登录 + 两步注销账号
- evidence: page_0004/0005 status=converted

### Step 3b: ViewModel + 状态管理
- suggested_skills: [arkts-state-manager]
- 三段式（complex）: 源码理解(LoginViewModel) → 差异清单 → ViewModel实现(AuthViewModel)
- 状态机: 手机号校验(L157-171) → SMS倒计时(L160-177) → 登录结果(L81-84)
- output: entry/src/main/ets/viewmodel/AuthViewModel.ets

### Step 3c: 数据层接入
- suggested_skills: [arkts-data-layer]
- UI ← AuthViewModel ← AuthRepository ← API(login/sms/bindAliCode/bindWx/deleteAccount) + Preferences(token)
- 支付宝/微信回调 → AuthViewModel.loginLiveData 更新

### Step 3d/3e: 页面接线 + 切片级验证
- suggested_skills: [arkts-state-manager, hmos_fix_build_errors, arkts-structural-closure]
- 接线: 补 import + 替换 FWD-REF 钩子
- 编译: PASS + 接线闭环
- evidence: LoginPage/AccountInfoPage 编译通过

## Slice 2: F002 — 会员支付

```yaml
complexity: complex
tier: core
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/MemberCenterActivitiy.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/ManageRenewActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/RefundProgressActivity.kt"
  - role: viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/MemberCenterViewModel.kt"
  - role: service
    path: "pay/src/main/java/cn/sanfate/pub/loginpay/service/PayApiService.kt"
  - role: data_model
    path: "app/src/main/java/cn/sanfate/pub/platform/event/PaySuccessEvent.kt"

placeholders_planned:
  - id: P-S2-1
    kind: thirdparty-sdk
    location: entry/src/main/ets/viewmodel/VipViewModel.ets
    trigger_condition: "微信支付 SDK 入仓"
    status: pending
    resolve_by: Slice 2 Step 3c
  - id: P-S2-2
    kind: thirdparty-sdk
    location: entry/src/main/ets/viewmodel/VipViewModel.ets
    trigger_condition: "支付宝支付 SDK 入仓"
    status: pending
    resolve_by: Slice 2 Step 3c
  - id: P-S2-3
    kind: thirdparty-sdk
    location: entry/src/main/ets/viewmodel/VipViewModel.ets
    trigger_condition: "华为支付 SDK (待厂商适配)"
    status: pending
    resolve_by: Slice 2 Step 3c

integration_points:
  - [ ] MemberCenterPage @Local products ← VipViewModel.products
  - [ ] MemberCenterPage @Local vipLevel ← VipViewModel.vipLevel
  - [ ] ManageRenewPage @Local renewPlans ← VipViewModel.renewPlans
  - [ ] RefundProgressPage @Local refundStatus ← VipViewModel.refundStatus

wires:
  - page: MemberCenterPage
    viewmodel: VipViewModel
  - page: ManageRenewPage
    viewmodel: VipViewModel
  - page: RefundProgressPage
    viewmodel: VipViewModel

modifies_files:
  - entry/src/main/ets/pages/MemberCenterPage.ets
  - entry/src/main/ets/pages/ManageRenewPage.ets
  - entry/src/main/ets/pages/RefundProgressPage.ets
cross_slice_edits:
  - file: entry/src/main/ets/pages/HomePage.ets
    handler: HomePage.onVipEntryClick
    resolve_by: Slice 2 Step 3d

depends_on: [Base-7, Slice 1, Slice 4]
parallel_group: 2
```

### Step 3a: UI 补充
- suggested_skills: [a2h-activity-converter]
- 目标页面: MemberCenterPage (0006), ManageRenewPage (0009), RefundProgressPage (0010)

### Step 3b: ViewModel + 状态管理
- suggested_skills: [arkts-state-manager]
- 三段式（complex）: 源码理解(MemberCenterViewModel) → 差异清单 → VipViewModel
- output: entry/src/main/ets/viewmodel/VipViewModel.ets, source-notes.md

### Step 3c: 数据层接入
- suggested_skills: [arkts-data-layer]
- UI ← VipViewModel ← VipRepository ← API + PaySDK(P-S2-1占位)

### Step 3d/3e: 页面接线 + 切片级验证
- suggested_skills: [arkts-state-manager, hmos_fix_build_errors, arkts-structural-closure]
- 接线: 补 import + 替换 FWD-REF 钩子; cross_slice_edits(HomePage VIP入口) 回填

## Slice 3: F003 — 首页导航

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/HomeActivity.kt"
  - role: viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/HomeViewModel.kt"

placeholders_planned: []

integration_points:
  - [ ] HomePage @Local currentTab ← HomeViewModel.currentTab
  - [ ] HomePage @Local floatInfo ← HomeViewModel.floatInfoLiveData

wires:
  - page: HomePage
    viewmodel: HomeViewModel

modifies_files:
  - entry/src/main/ets/pages/HomePage.ets
cross_slice_edits: []

depends_on: [Base-7, Slice 1, Slice 2]
parallel_group: 2
```

### Step 3a: UI 补充 → Step 3b/3c → Step 3d/3e
(标准 4 步流程，与上述 Slice 同构)

## Slice 4: F004 — PPT核心流程

```yaml
complexity: complex
tier: core
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/PPTTemplatePreviewPage.kt"
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/CreateOutLinePage.kt"
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/ChoicePPTTemplatePage.kt"
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/PPTFilePage.kt"
  - role: presenter
    path: "app/src/main/java/com/aipptzhizuozz/bjh/page/SearchPagePage.kt"
  - role: service
    path: "app/src/main/java/com/aipptzhizuozz/bjh/api/AIPPTService.kt"
  - role: viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt"
  - role: viewmodel
    path: "app/src/main/java/com/aipptzhizuozz/bjh/viewmodel/AIPptFileLoadViewModel.kt"

placeholders_planned: []

integration_points:
  - [ ] ChoicePPTTemplatePage @Local templates ← PptViewModel.templates
  - [ ] PPTTemplatePreviewPage @Local templateDetail ← PptViewModel.selectedTemplate
  - [ ] CreateOutLinePage @Local outline ← PptViewModel.outline
  - [ ] CreateOutLinePage @Local chapters ← PptViewModel.chapters
  - [ ] PPTFilePage @Local pptResult ← PptViewModel.pptResult
  - [ ] SearchPage @Local searchResults ← PptViewModel.searchResults

wires:
  - page: ChoicePPTTemplatePage
    viewmodel: PptViewModel
  - page: PPTTemplatePreviewPage
    viewmodel: PptViewModel
  - page: CreateOutLinePage
    viewmodel: PptViewModel
  - page: PPTFilePage
    viewmodel: PptViewModel
  - page: SearchPage
    viewmodel: PptViewModel

modifies_files:
  - entry/src/main/ets/pages/ChoicePPTTemplatePage.ets
  - entry/src/main/ets/pages/PPTTemplatePreviewPage.ets
  - entry/src/main/ets/pages/CreateOutLinePage.ets
  - entry/src/main/ets/pages/PPTFilePage.ets
  - entry/src/main/ets/pages/SearchPage.ets
cross_slice_edits: []

depends_on: [Base-7, Slice 0e]
parallel_group: 1
```

(标准 complex 三段式 4 步流程)

## Slice 5: F005 — 文件管理

```yaml
complexity: simple
tier: standard
depth: full
depends_on: [Base-7, Slice 0e]
parallel_group: 1

modifies_files:
  - entry/src/main/ets/pages/FileUploadPage.ets
  - entry/src/main/ets/pages/FileListPage.ets
  - entry/src/main/ets/viewmodel/FileListViewModel.ets
cross_slice_edits: []
```

(标准 simple 4 步流程，页面: FileUploadPage(0018), FileListPage(0019))

## Slice 6: F006 — 作品管理

```yaml
complexity: simple
tier: standard
depth: full
depends_on: [Slice 4]
parallel_group: 2

modifies_files:
  - entry/src/main/ets/pages/WorksPage.ets
cross_slice_edits: []
```

(标准 simple 4 步流程，页面: WorksPage(0020)，ACs=11 已通过 C4-pre 验证)

## Slice 7: F007 — 个人中心

```yaml
complexity: simple
tier: standard
depth: full
depends_on: [Slice 1]
parallel_group: 2

modifies_files:
  - entry/src/main/ets/pages/MinePage.ets
cross_slice_edits: []
```

(标准 simple 4 步流程，页面: MinePage(0013)，ACs=10 已通过 C4-pre 验证)

## Slice 8: F008 — WebView容器

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/WebViewActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/CustomerServiceWebActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/WebAppInterface.kt"

placeholders_planned: []

wires:
  - page: WebViewPage
    viewmodel: WebViewViewModel
  - page: CustomerServiceWebPage
    viewmodel: WebViewViewModel

modifies_files:
  - entry/src/main/ets/pages/WebViewPage.ets
  - entry/src/main/ets/pages/CustomerServiceWebPage.ets
cross_slice_edits:
  - file: entry/src/main/ets/pages/CustomerServiceWebPage.ets
    source: Slice 2 VipViewModel (SaleCenterViewModel)
    handler: WebAppInterface 构造注入 renewManageViewModel → JS bridge 续费/退款操作
    resolve_by: Slice 2 Step 3d

depends_on: [Base-7, Slice 0e, Slice 2]
parallel_group: 2
```

### Step 3a: UI 补充
- suggested_skills: [a2h-activity-converter]
- 目标页面: WebViewPage (page_0002), CustomerServiceWebPage (page_0008)
- evidence: page_0002/0008 status=converted

### Step 3b: ViewModel + JS Bridge
- suggested_skills: [arkts-state-manager]
- WebViewViewModel + WebAppInterface(JS proxy) + `port.onMessage` 回调(onCloseEvent/callPhone)
- output: entry/src/main/ets/viewmodel/WebViewViewModel.ets

### Step 3c: 数据层接入
- suggested_skills: [arkts-data-layer, arkts-webview]
- Web({ src: url, controller }) + WebSettings → ArkUI Web 属性映射
- P-S2-x: Slice 2 VipViewModel 接线（cross_slice_edits 回填）

### Step 3d/3e: 页面接线 + 切片级验证
- suggested_skills: [hmos_fix_build_errors, arkts-structural-closure]
- 接线: 补 import + 替换 FWD-REF 钩子; cross_slice_edits(VipViewModel → WebAppInterface) 回填
- 编译: PASS + 接线闭环

## Slice 9: F009 — 引导页

```yaml
complexity: simple
tier: standard
depth: full
depends_on: [Slice 0e]
parallel_group: 1

modifies_files:
  - entry/src/main/ets/pages/GuidePage.ets
cross_slice_edits: []
```

(标准 simple 4 步流程，页面: GuidePage(0012)，ACs=9 已通过 C4-pre 验证)

## Slice 10: F010 — 通用页面

```yaml
complexity: simple
tier: standard
depth: full

android_source_anchors:
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/SplashActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/AboutUsActivity.kt"
  - role: presenter
    path: "app/src/main/java/cn/sanfate/pub/platform/page/ShortCutActivity.kt"
  - role: viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/SplashViewModel.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/platform/dialog/LaunchAgreementDialog.kt"

modifies_files:
  - entry/src/main/ets/pages/SplashPage.ets
  - entry/src/main/ets/pages/AboutUsPage.ets
  - entry/src/main/ets/pages/ShortCutPage.ets
  - entry/src/main/ets/viewmodel/SplashViewModel.ets
cross_slice_edits: []

placeholders_planned:
  - id: P-S10-1
    kind: thirdparty-sdk
    location: entry/src/main/ets/pages/SplashPage.ets
    trigger_condition: "TopOnSdk 开屏/插屏/激励广告"
    status: pending
    resolve_by: Slice 10 Step 3c

depends_on: [Slice 1]
parallel_group: 2
```

(标准 simple 4 步流程，页面: SplashPage(0001), AboutUsPage(0003), ShortCutPage(0007)，ACs=14 已通过 C4-pre 验证)

## Checkpoints (编译闸门)

> 每个闸门必须在对应 Slice 全部完成后跑通编译，FAIL → 阻断后续 Slice。

| 闸门 | 触发条件 | 检查内容 | 建议工具 |
|------|---------|---------|---------|
| CP-0 | Base-7 完成后 | 资源 + 项目骨架编译 PASS | hmos-builder |
| CP-1 | Slice 0e 完成后 | DB Schema + Models + Data Layer + State + Components 全量编译 | hmos-builder |
| CP-2 | parallel_group 1 完成后 (S1+S4+S5+S9) | Auth + PPT + File + Guide 页面级编译 | hmos-builder |
| CP-3 | parallel_group 2 第一批 (S2+S8) 完成后 | 会员支付 + WebView 编译; 需微信/支付宝 SDK placeholder 占位不报错 | hmos-builder |
| CP-4 | parallel_group 2 其余完成后 (S3+S6+S7+S10) | 首页 + 作品 + Mine + 通用页面 全量编译 | hmos-builder |
| CP-FINAL | 全部 Slice 完成后 | Final Structural Closure + 全量编译 exit 0 | arkts-structural-closure + hmos-builder |

## Final Verification

- [ ] FV-1: Final Structural Closure（a2h-execute §6）
  - suggested_skills: [arkts-structural-closure]
  - acceptance: `final_state == PASS`

- [ ] FV-2: 终态全量编译
  - suggested_agents: [hmos-builder]
  - acceptance: 编译 exit 0

- [ ] FV-3: 133 ACs (@spec/baseline/features/ 10 feature specs) 全量验收
  - suggested_skills: [a2h-verify]
  - acceptance: 所有 feature `status=verified`
