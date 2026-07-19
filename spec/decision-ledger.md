# Migration Decisions — AIPPT

> 由 a2h-spec Phase C C4-pre / grill #1 产出（2026-07-19）。
> **唯一事实源**：a2h-execute / a2h-verify 执行时以本文件为准；与 baseline 报告冲突处以本文件覆盖。
> 决策类目映射：C0–C16，详见 `migration-decision-categories.md`。

---

## 决策索引

| D-编号 | 类目 | 一行结论 | 状态 |
|--------|------|---------|------|
| D-001 | C0 | 产出定位：可上线产品，10 feature 全量迁移 | approved |
| D-002 | C2 | P0 优先（F001/F002/F003/F004）→ P1 标准（F005/F006/F007/F008）→ P2 完整（F009/F010）；P0 batch 1 先行 | approved |
| D-003 | C4 | 深色模式免迁移（Android 无 values-night/）；i18n 中文 baseline + 按需英文 | approved |
| D-004 | C6 | 导航架构：21 Activity → 单 Navigation + NavPathStack；Fragment 子页 → NavDestination / @ComponentV2 | approved |
| D-005 | C12 | Feature tier 分配：core(F002,F004) / standard(其余 8 个)；stub→full 升级 4 个 (F006/F007/F009/F010) | approved |
| D-006 | C13 | ViewPager2 + Fragment → Swiper + @ComponentV2（禁用手势滑动用 `disableSwipe(true)`）；RecyclerView → List+LazyForEach / Grid；BindingAdapter → Repeat | approved |
| D-007 | C14 | MMKV → PersistenceV2.globalConnect；EventBus → emitter / EventHub；Room DB → RDB + Repository 模式 | approved |
| D-008 | C15 | 权限：MANAGE_EXTERNAL_STORAGE → WRITE_USER_STORAGE + DocumentViewPicker；微信/支付宝支付 → 三方 SDK 待厂商适配（F002 标 thirdparty-sdk placeholder） | approved |
| D-009 | C16 | F009 (引导页) AC 偏离预算 −55%：6-step wizard 结构性重复，不拆细 — 依赖 visual-verify wizard 合同按步骤验证 | approved |

---

## 生命周期

| 阶段 | 行为 |
|------|------|
| 初次 grill（a2h-spec Step C4.8） | 生成本文件，写入 D0 + D-001–D-009 |
| 增量 grill | append 新 D-编号到同一文件 |
| 决策被推翻 | 原条目 `superseded`，新增 D 编号 |

---

## 状态

- 本轮 grill 时间：2026-07-19
- 状态：`approved`
- 审批人：用户
- 上游 spec 版本：baseline 21 pages / 10 features / 143 ACs

---

## D0 产出定位

**定位**：可上线产品（完整复刻 Android 端功能）

**核心流程**（必须真实跑通）：
- F001：登录/账号信息
- F002：会员支付/续费/退款
- F003：首页 4-Tab 导航
- F004：PPT 核心流程（大纲生成→选模板→生成→预览→分享保存）

**留桩范围**：
- F002 华为/荣耀支付 SDK (`HomeActivity.kt` L27-28 import + L123 `initHMAppServiceSdk` + L324 `handlePayResult` — 活跃但 HMOS SDK 待厂商适配；fallback 微信/支付宝)
- F010 开屏/插屏/激励广告 (`TopOnSdkUtil` — 插屏加载已注释但 rewardAd 仍活跃；整体 thirdparty-sdk)
- F010 OAID 设备标识 (EventBus `OaidResultEvent` — 隐私合规相关，thirdparty-sdk placeholder)
- F010 信鸽推送 (EventBus sticky events `LimitCampaignEvent`/`LimitGiftEvent` — Marked placeholder)

**直接砍掉范围**：
- Android 端已注释功能：插屏广告加载 (`loadInterstitialAd` L144 已注释；`TopOnSdkUtil.INTERSTITIAL_AD_PLACEMENT_ID` 仍引用) → 广告整体留桩 thirdparty-sdk
- `PPTTemplatePreviewPage` 收藏按钮 (`tvCollect` L96+L225-227 已注释) → 不迁移
- `WorksFragment` 文本 Tab 按钮 (`tvMyCreate`/`tvMyCollect` L137-142+L192-196 已注释) → 不迁移
- `ChoicePPTTemplatePage` 旧 Fragment 生命周期管理 (L55-72 已注释，替换为 `createOrShowFragment`) → 不迁移
- `AIPptFileLoadViewModel` 旧 Apache POI 渲染路径 (L398-414 已注释) → 不迁移
- `ShortCutActivity`: AndroidManifest L116 注册但属平台 SDK 透明页快捷方式 → F010 迁移页面壳，桌面快捷方式功能 HMOS 无等价 API 砍掉

---

## D 编号决策

### D-001 产出定位 C0
- **类目**：C0 产出定位
- **背景**：21 页面 / 10 feature 全量 spec 已生成，143 ACs 均有 源→标 追踪
- **候选项**：A. MVP（仅 P0）B. 可上线产品（全量 10 feature）
- **选定**：B — 可上线产品
- **依据**：feature-index.md 拓扑排序已产出执行顺序
- **影响范围**：全部 10 Feature / 21 页面 / 143 ACs
- **类型**：`具体决策`

### D-002 迁移批次 C2
- **类目**：C2 迁移范围取舍
- **背景**：121 页面按优先级分为 3 批
- **候选项**：A. 全量一次性 B. 按 P0→P1→P2 分批
- **选定**：B — 分批推进
- **依据**：ui-manifest.md Batch 1(P0: 8页) → Batch 2(P1: 11页) → Batch 3(P2: 2页)
- **影响范围**：Plan 阶段 batch 编排
- **类型**：`具体决策`

### D-003 横切能力 C4
- **类目**：C4 横切能力
- **背景**：Android 端检测结果
- **候选项**：A. i18n+深色全量 B. 仅 i18n
- **选定**：B — i18n 中/阿双语，深色模式免迁移
- **依据**：Android `values-night/` 不存在（全部 6 模块仅 `values/` 单一目录）→ 深色免迁移；Android 仅 `values/` 无语言限定 → 默认中文，HMOS 端后续按需追加 `en_US` 英文资源
- **影响范围**：resource 层 (`string.json` base 中文，按需追加 en_US)
- **类型**：`具体决策`

### D-004 导航架构 C6
- **类目**：C6 路由方案
- **背景**：Android 端 21 个独立 Activity + Fragment 子页
- **候选项**：A. 保留多 Page 独立路由 B. 单 Navigation + NavPathStack
- **选定**：B — 单 Navigation + NavPathStack
- **依据**：HarmonyOS API 12+ 推荐 Navigation；Fragment 子页转 NavDestination/子组件
- **影响范围**：全部 21 页面
- **类型**：`架构决策`

### D-005 Feature tier 分配 C12
- **类目**：C12 复杂度分档
- **背景**：C4-pre 对 10 个 feature 逐项判定 tier/depth
- **候选项**：A. 保持原 peripheral/stub 不变 B. 升级有 UI 页面的 feature 到 standard/full
- **选定**：B — 4 个升级 (F006/F007/F009/F010: peripheral/stub → standard/full)
- **依据**：F006 有 UI 页 0020 + fan-in；F007 有 UI 页 0013 + fan-in；F009 7 文件 wizard 模式；F010 3 UI 页
- **影响范围**：F006/F007/F009/F010 feature specs
- **类型**：`具体决策`

### D-006 UI 组件映射 C13
- **类目**：C13 Android→ArkUI 组件迁移
- **背景**：Android ViewPager2/RecyclerView/BindingAdapter 体系
- **候选项**：A. 逐组件手写 B. 统一映射策略
- **选定**：B — 统一映射：ViewPager2→Swiper+disableSwipe, RecyclerView→List+LazyForEach/Grid, BindingAdapter→Repeat
- **依据**：ArkUI 声明式 API 最佳实践
- **影响范围**：F003(HomeViewPager), F004(多 RecyclerView), F006(双 RecyclerView), F009(Guide ViewPager2)
- **类型**：`架构决策`

### D-007 存储迁移 C14
- **类目**：C14 数据持久化
- **背景**：Android MMKV + EventBus + Room DB 体系
- **候选项**：A. 逐 API 找等价 B. 统一映射策略
- **选定**：B — MMKV→PersistenceV2, EventBus→emitter/EventHub, Room→RDB+Repository
- **依据**：HarmonyOS 原生 API 覆盖所有场景；无三方依赖
- **影响范围**：F002(vip config), F003(home state), F004(ppt db), F006(works db), F009(guide flag), F010(privacy flag)
- **类型**：`架构决策`

### D-008 三方 SDK C15
- **类目**：C15 闭源 SDK 迁移
- **背景**：微信/支付宝/华为/荣耀支付 SDK；讯飞 AI API（有 HMOS SDK）；信鸽推送；开屏广告
- **候选项**：A. 等厂商适配 B. 部分占位+fallback
- **选定**：B — 讯飞 AI API 有 HMOS SDK 直接集成；微信/支付宝支付留 thirdparty-sdk placeholder；华为/荣耀支付 cutoff fallback 微信
- **依据**：讯飞 `AIPPTService.kt` (zwapi.xfyun.cn REST API → HMOS `@kit.NetworkKit` 可直调)；微信 `WXPayEntryActivity` 存在 → thirdparty-sdk；华为 `HomeActivity.kt` L27+L123+L324 (`HuaweiSdkService`) 活跃 → thirdparty-sdk；支付宝 `MemberCenterActivitiy.kt` 引用 → thirdparty-sdk
- **影响范围**：F002(支付 SDK), F004(讯飞 AI), F010(推送/广告)
- **类型**：`具体决策`

### D-009 F009 AC deviation C16
- **类目**：C16 AC 预算偏离
- **背景**：F009-guide AC_budget=20, actual=9 (−55%)
- **候选项**：A. 拆分 6 步 wizard 为独立 AC B. 保留合并
- **选定**：B — 保留 9 ACs，不强行拆分
- **依据**：6-step wizard 模式结构性重复（同质 goToPage/goBack），quality guardrail "禁止为凑预算造填充 AC"
- **影响范围**：F009 / GuideActivity + 6 fragments
- **类型**：`具体决策`

---

## 运行期验证项

### R-001 讯飞 AI API 签名头
- **默认假设**：md5(appId + timestamp + secret) 签名方式在 HMOS 端一致
- **验证触发条件**：首次调用 createOutline / createPptByOutline 返回 401/403
- **触发后动作**：检查签名生成算法（timestamp 格式、密钥一致性）并修正
- **关联类目**：C15

### R-002 微信支付 HMOS SDK
- **默认假设**：微信支付 HMOS SDK 尚未发布，默认 fallback 支付宝
- **验证触发条件**：a2h-execute Slice 2 执行时检查 ohpm registry
- **触发后动作**：如有 → 集成；如无 → 保持 thirdparty-sdk placeholder + 支付宝 only
- **关联类目**：C15

---

## 技术必做项

- **T-001**：`dev-api.xxx.com` / `zwapi.xfyun.cn` 为 HTTPS，HMOS 默认允许；如遇明文 HTTP 端点须在 `module.json5` 配置 `cleartextTraffic`
- **T-002**：Android `MANAGE_EXTERNAL_STORAGE` 在 HMOS 无等价权限；文件操作改用 `DocumentViewPicker` + `fileIo` 沙箱路径
- **T-003**：Android `immersionBar` 库 → HMOS `arkts-immersive-safearea` skill；全屏页（page_type=`full_screen_page`）统一四件套
- **T-004**：Android `ShortCutActivity` 透明页快捷入口 (`AndroidManifest.xml` L116) — Android 桌面快捷方式 / 本地通知点击 → 透明 Activity 路由分发。HMOS 无 `ShortCutManager` API + 无透明页范式。迁移方案：桌面快捷方式 → 砍掉；冷启动路由 → `UIAbility.onNewWant(want)` 替代；`onStop()` 1s 自动 `finish()` → 无需迁移（HMOS Page 生命周期自动管理）

---

## spec 卫生检查结论

| 检查项 | 结果 |
|--------|------|
| 是否存在多套 spec 树并存 | PASS — 仅 `spec/baseline/` 单一树 |
| feature 编号体系全仓一致 | PASS — F001–F010 连续无空洞 |
| 文档之间 / 文档内部无自相矛盾 | PASS — feature-index 映射验证一致 |
| 文档声称完成度与代码现状一致 | PASS — 21 pages / 10 features / 143 ACs |
| 计数类指标跨文档无漂移 | PASS — AC 计数与 C4-pre 一致 |
| 无残留已被推翻的描述 | PASS — F009/F010 已从 checklist 升级到 table |
| verify / handoff 报告非过时 | N/A — 尚未进入 verify 阶段 |

---

## 审批记录

| 日期 | 阶段 | 审批结果 | 备注 |
|------|------|---------|------|
| 2026-07-19 | spec grill #1 | approved | 10 features / 143 ACs / 21 pages / CLAUDE.md created |

---

## Appendix: Stage S Source Analysis (Agent a575b370c9c1f18ac)

### 5-Role Coverage (10 Kotlin files read)

| Role | Key Classes | Pages |
|------|------------|-------|
| Presenter | SplashViewModel, LoginViewModel, MemberCenterViewModel, UseCountViewModel | 4/7 |
| Service | HuaweiSdkService, HonorSdkService, TopOnSdkUtil, BDConvertUtils, VolcEnginManger, WXHandler | 7/7 |
| Interceptor | CommonRequestInterceptor, LaunchAgreementDialog, PayAgreementDialog, RenewRuleDialog | 6/7 |
| Base | BaseBusinessActivity, TitleBarAction, ToastAction | 7/7 |
| Util | MMKVUtil, UserData(singleton), SafeDeviceUtils, UrlContant, EventBus, ContextConstant, AppContant | 7/7 |

### 8 Source Corrections (XML-only analysis would miss)

| ID | Finding | Source |
|----|---------|--------|
| C1 | Splash has loginLiveData observer chain (not just timer) | SplashActivity.kt L118-124 |
| C2 | UserData is sync read, not API call | AccountInfoActivity.kt L33-39 |
| C3 | WebViewActivity.openWebPage() = universal protocol launcher (7 edges) | WebViewActivity.kt L30-44 |
| C4 | Algorithm filing is AppTipsDialog, not WebView link | AboutUsActivity.kt L59-66 |
| C5 | ShortCutActivity has 2 routing paths (Calculator + Splash) | ShortCutActivity.kt L84-89 |
| C6 | TitleBar duplicated across 5 pages (BaseBusinessActivity provides) | BaseBusinessActivity.kt L110-114 |
| C7 | EventBus used in Splash + MemberCenter (not in XML) | Splash L99, MemberCenter L215 |
| C8 | Product adapter is horizontal List, not Grid | MemberCenter L251 (linear(HORIZONTAL) overrides XML GridLayoutManager) |

### 5 Cross-Role Chains (from ViewModel source)

| Chain | Depth | Key Finding |
|-------|-------|------------|
| saveUserInfo cascade | 12 | 7 side effects before LiveData post |
| createOrder auth gates | 4 | Double gate (pre + post API) |
| uploadFirstStart | 0 | Fire-and-forget (empty callback) |
| 4 login paths | 3 | All converge on saveUserInfo() |
| changLoadingStatus | 1 | AppLoadDialog on every API method |

### ViewModel Files Not Read (Feature Pipeline scope)

`SplashViewModel.kt`, `LoginViewModel.kt`, `MemberCenterViewModel.kt` read. NOT read: `UseCountViewModel.kt`, `AIPptViewModel.kt`, `PptDbViewModel.kt`, `FileScanViewModel.kt`, `SaleCenterViewModel.kt`. 0008-0021 page Kotlin sources also not read.

### Process Notes

3 supervisor review rounds needed. Agent self-review insufficient for defect detection. Optimal pipeline: generator (baseline) → agent (corrections + chains) → human (approval).
