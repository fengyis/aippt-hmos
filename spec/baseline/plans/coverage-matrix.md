# Coverage Matrix

## Summary

| 指标 | 值 | 状态 |
|------|-----|------|
| P0 功能覆盖率 | 4/4 (100%) | ✅ PASS |
| P1 功能覆盖率 | 4/4 (100%) | ✅ PASS |
| P2 功能覆盖率 | 2/2 (100%) | ✅ PASS |
| UI 页面覆盖 | 21/21 (100%) | ✅ PASS |
| Placeholder trigger 白名单率 | 4/4 (100%) | ✅ PASS |
| Complex Feature anchor 完整率 | 2/2 (100%) | ✅ PASS |
| Feature tier/depth 完成率 | 10/10 (100%) | ✅ PASS |
| Slice 覆盖率 | 15/15 (100%) | ✅ PASS |
| 跨 Feature 接口覆盖 | 12/12 (100%) | ✅ PASS |
| AC source precision (C4-pre) | 10/10 features (100%) | ✅ PASS |

## Infrastructure Coverage

| Slice | 内容 | 依赖 | 建議 agent | 状态 |
|-------|------|------|-----------|------|
| Slice 0 | Database — RDB Schema + DAO | Base-7 | 1 (serial, single-schema) | covered |
| Slice 0b | Models — @ObservedV2 data classes | Slice 0 | 1 (serial, batch class gen) | covered |
| Slice 0c | Data Layer — HttpClient + API Service | Slice 0b | 1 (serial, sequential: HttpClient→API) | covered |
| Slice 0d | State Manager — AppStorageV2 + emitter | Slice 0b | 1 (serial, 2 constant files) | covered |
| Slice 0e | Common Components — TitleBar/TabBar/等 | Slice 0d | 2 (TitleBar+TabBar+Dialog 并行; TemplateCard+FileListItem 并行) | covered |

## Feature Coverage

| Feature | Priority | Plan Slice | 涉及页面 | 建議 agent | 状态 |
|---------|----------|-----------|---------|-----------|------|
| F001-auth | P0 | Slice 1 | 0004, 0005 | 2 (LoginPage ‖ AccountInfoPage, shared AuthViewModel) | covered |
| F002-vip | P0 | Slice 2 | 0006, 0009, 0010 | 3 (MemberCenterPage ‖ ManageRenewPage ‖ RefundProgressPage, shared VipViewModel) | covered |
| F003-home | P0 | Slice 3 | 0011 | 2 (HomePage 4-tab complex, HomeViewModel + VIP dialogs) | covered |
| F004-ppt-core | P0 | Slice 4 | 0014, 0015, 0016, 0017, 0021 | 5 (5 pages shared PptViewModel; CreateOutLinePage=max agent) | covered |
| F005-file | P1 | Slice 5 | 0018, 0019 | 2 (FileUploadPage ‖ FileListPage, simple) | covered |
| F006-works | P1 | Slice 6 | 0020 | 1 (single page, dual RecyclerView) | covered |
| F007-mine | P1 | Slice 7 | 0013 | 1 (single page, list-style) | covered |
| F008-webview | P1 | Slice 8 | 0002, 0008 | 2 (WebViewPage ‖ CustomerServiceWebPage, shared WebViewViewModel) | covered |
| F009-guide | P2 | Slice 9 | 0012 | 1 (single page, 6 sub-fragments wizard, sequential) | covered |
| F010-general | P2 | Slice 10 | 0001, 0003, 0007 | 2 (SplashPage=max agent; AboutUsPage ‖ ShortCutPage) | covered |

## UI Page Coverage

ui-plan 覆盖 ui-manifest 全部 21 页（非 skipped）。

## Full Placeholder Matrix

| P-ID | kind | location | trigger_condition | status | resolve_by |
|------|------|----------|-------------------|--------|------------|
| P-S2-1 | thirdparty-sdk | VipViewModel.ets | 微信支付 SDK 入仓 | pending | Slice 2 Step 3c |
| P-S2-2 | thirdparty-sdk | VipViewModel.ets | 支付宝支付 SDK 入仓 | pending | Slice 2 Step 3c |
| P-S2-3 | thirdparty-sdk | VipViewModel.ets | 华为支付 SDK (待厂商适配) | pending | Slice 2 Step 3c |
| P-S10-1 | thirdparty-sdk | SplashPage.ets | TopOnSdk 开屏/插屏/激励广告 | pending | Slice 10 Step 3c |

> P-ID → plan anchor: see `feature-plan.md` Slice 2 YAML block (L154-173) for S2 placeholders_planned; Slice 10 YAML block for S10.

## Wiring Ownership Map

（详情见 feature-plan.md 各 Slice 的 `integration_points` + `wires` + `cross_slice_edits` 字段）

## C4-pre Extraction Quality

| Feature | Complexity | Tier | ACs | Source L-refs | Verified against | Source files checked |
|---------|-----------|------|-----|--------------|-----------------|---------------------|
| F001-auth | simple | standard | 10 | 10/10 | LoginActivity, LoginViewModel, AccountInfoActivity | 3 |
| | _score: 3 files, 824 LOC, decision_count=65.2, complexity_score=0.079, AC_budget=20, actual=10 (−50%, floor-bound)_ | | | | | | |
| F002-vip | complex | core | 13 | 13/13 | MemberCenterActivitiy, ManageRenewActivity, RefundProgressActivity, MemberCenterViewModel | 4 |
| | _score: 5 files, 1309 LOC, decision_count=93.7, complexity_score=0.072, AC_budget=30, actual=13 (−57%, floor-bound; SDK bundling)_ | | | | | | |
| F003-home | simple | standard | 13 | 13/13 | HomeActivity | 1 |
| | _score: 3 files, 663 LOC, decision_count=60.4, complexity_score=0.091, AC_budget=20, actual=13 (−35%, PASS)_ | | | | | | |
| F004-ppt-core | complex | core | 29 | 29/29 | PPTTemplatePreviewPage, CreateOutLinePage, ChoicePPTTemplatePage, PPTFilePage, SearchPagePage, RecommendFragment | 6 |
| | _score: 9 files, 1881 LOC, decision_count=150.2, complexity_score=0.080, AC_budget=30, actual=29 (−3%, PASS)_ | | | | | | |
| F005-file | simple | standard | 12 | 12/12 | FileListPage, FileUploadPage, FileConfirmDialog | 3 |
| | _score: 4 files, ~310 LOC, decision_count≈24, AC_budget=20, actual=12 (−40%, floor-bound; manual estimate)_ | | | | | | |
| F006-works | simple | standard | 11 | 11/11 | WorksFragment | 1 |
| F007-mine | simple | standard | 10 | 10/10 | MineFragment | 1 |
| F008-webview | simple | standard | 12 | 12/12 | WebViewActivity, CustomerServiceWebActivity, WebAppInterface | 3 |
| F009-guide | simple | standard | 9 | 9/9 | GuideActivity | 1 |
| F010-general | simple | standard | 14 | 14/14 | SplashActivity, AboutUsActivity, ShortCutActivity | 3 |
| **Total** | | | **133** | **133/133** | | **26** |
