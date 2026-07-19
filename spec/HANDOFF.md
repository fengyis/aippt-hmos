# Handoff — Stage S Analysis (Increment S1)

**For**: Next agent | **From**: Agent a575b370c9c1f18ac | **Date**: 2026-07-19

---

## TL;DR (30 seconds)

Read 10 Kotlin files. Found 8 corrections the generator will miss. Traced 5 cross-role chains (deepest: 12-step saveUserInfo cascade). Delivered 3 docs: this one (what to fix), decision-ledger (what was decided), chain-validation (how to verify). Apply C1-C8 to generator code. Read all 8 ViewModels before implementing ViewModel layer. Don't implement API calls without their side-effect cascades.

Android source root: `/Users/fengyi/Workspace/fengyis/AIPPT`
Page source path: `app/src/main/java/cn/sanfate/pub/platform/page/`

---

## What This Contains

The 5-role analysis, 8 source corrections, and 5 cross-role chains produced by reading 10 Kotlin source files. Use this as the gap checklist when working from the generator's code baseline. The 34 FWD-REF inventory from the original analysis was in deleted migration-report.md — consult decision-ledger appendix for gap categories.

---

## 8 Source Corrections (generator will miss these)

| ID | Page | Correction | Source |
|----|------|-----------|--------|
| C1 | Splash | LoginLiveData observer chain gates navigation, not just timer | SplashActivity.kt L118-124 |
| C2 | AccInfo,Splash,MemberCenter | UserData is sync read from singleton, not API call | AccountInfoActivity.kt L33-39 |
| C3 | All | WebViewActivity.openWebPage() is universal protocol launcher (7 edges) | WebViewActivity.kt L30-44 |
| C4 | AboutUs | Algorithm filing is AppTipsDialog, not WebView link | AboutUsActivity.kt L59-66 |
| C5 | ShortCut | Two routing paths: Calculator + Splash | ShortCutActivity.kt L84-89 |
| C6 | All | TitleBar duplicated 5 times — should be shared component | BaseBusinessActivity.kt L110-114 |
| C7 | Splash/Member | EventBus @Subscribe used (not in XML) | Splash L99, MemberCenter L215 |
| C8 | MemberCenter | Product list is horizontal linear, not Grid | MemberCenter L251 (linear(HORIZONTAL)) |

## 5 Cross-Role Chains (implement API calls with cascades)

| Chain | Depth | Pattern |
|-------|-------|---------|
| saveUserInfo cascade | 12 | 7 side effects before LiveData post (SafeDeviceUtils×3, UserData, VolcEnginManger×2) |
| createOrder auth gates | 4 | Pre-API (!isBinding) + post-API (result==-605→LoginActivity) |
| uploadFirstStart | 0 | Fire-and-forget (empty netResult callback) |
| 4 login paths | 3 | WeChat/AliPay/Honor/Huawei all converge on saveUserInfo() |
| changLoadingStatus | 1 | AppLoadDialog on every API method |

## ViewModel Files to Read

```
app/.../viewmodel/SplashViewModel.kt     — read
app/.../viewmodel/LoginViewModel.kt      — read (saveUserInfo cascade origin)
app/.../viewmodel/MemberCenterViewModel.kt — read (auth gate)
app/.../viewmodel/UseCountViewModel.kt   — NOT read
com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt — NOT read
com/aipptzhizuozz/bjh/viewmodel/PptDbViewModel.kt — NOT read
com/aipptzhizuozz/bjh/viewmodel/FileScanViewModel.kt — NOT read
.../SaleCenterViewModel.kt               — NOT read
```

## Key Architecture Decisions

- NavPathStack + @Provider/@Consumer (matches D-004)
- @ObservedV2 + @Trace + AppStorageV2.connect
- UserState.ets as global singleton pattern
- 0 deprecated @ohos.router

## Optimal Pipeline for S2

1. Generator → baseline code (done)
2. Agent → apply C1-C8 corrections to generator code
3. Agent → verify chains against ViewModel source
4. Human → review corrections + approve
