# Stage S Source Analysis — Agent a575b370c9c1f18ac

**Date**: 2026-07-19 | **Scope**: pages 0001-0007 | **Source root**: `/Users/fengyi/Workspace/fengyis/AIPPT`

---

## 8 Source Corrections (apply to generator code)

| ID | Page | Correction | Source Line |
|----|------|-----------|-------------|
| C1 | Splash | LoginLiveData observer chain gates navigation, not just timer | SplashActivity.kt L118-124 |
| C2 | AccInfo,Splash,MemberCenter | UserData is sync read from singleton, not API call | AccountInfoActivity.kt L33-39 |
| C3 | AboutUs,Login,MemberCenter | WebViewActivity.openWebPage() is universal protocol launcher (7 edges) | WebViewActivity.kt L30-44 |
| C4 | AboutUs | Algorithm filing is AppTipsDialog, not WebView link | AboutUsActivity.kt L59-66 |
| C5 | ShortCut | Two routing paths: Calculator + Splash | ShortCutActivity.kt L84-89 |
| C6 | WebView,AboutUs,Login,AccountInfo,MemberCenter | TitleBar duplicated 5 times — should be shared component | BaseBusinessActivity.kt L110-114 |
| C7 | Splash,MemberCenter | EventBus @Subscribe used (not in XML) | Splash L99, MemberCenter L215 |
| C8 | MemberCenter | Product list is horizontal linear, not Grid | MemberCenter L251 (linear(HORIZONTAL)) |

## 5 Cross-Role Chains (forward cascades)

| Chain | Depth | Pattern | Source |
|-------|-------|---------|--------|
| saveUserInfo cascade | 12 | 7 side effects before LiveData post | LoginViewModel.kt L58-79 |
| createOrder auth gates | 4 | Pre-API + post-API (-605) gates | MemberCenterViewModel.kt L35-55 |
| uploadFirstStart fire-and-forget | 0 | Empty netResult callback | SplashViewModel.kt L21-26 |
| 4 login paths converge | 3 | WeChat/AliPay/Honor/Huawei all call saveUserInfo() | LoginViewModel.kt L176-500 |
| changLoadingStatus coupling | 1 | Loading state on every API method entry+exit | LoginViewModel.kt (multiple) |

## 5 Reverse Dependencies (chains I missed)

1. **LoginActivity L46**: `loginViewModel.activity = this` — Activity injects into ViewModel. AliPay AuthTask needs Activity context.
2. **saveUserInfo null safety**: `it.userId.toString()` no null check (LoginViewModel L76). Crash on null API response.
3. **KViewModel.getContext()**: `WXHandler.getInstance(getContext()).release()` (LoginViewModel L505). WeChat cleanup needs context.
4. **BaseDataBindingActivity**: NOT read. Parent class of BaseBusinessActivity. May have lifecycle hooks.
5. **`service<T>()` delegate**: Kotlin lazy property. ArkTS must match lazy, not eager init.

## ViewModel Files to Read

```
READ:
  app/.../viewmodel/SplashViewModel.kt
  app/.../viewmodel/LoginViewModel.kt (saveUserInfo cascade origin)
  app/.../viewmodel/MemberCenterViewModel.kt (auth gate)

NOT READ:
  app/.../viewmodel/UseCountViewModel.kt
  com/aipptzhizuozz/bjh/viewmodel/AIPptViewModel.kt
  com/aipptzhizuozz/bjh/viewmodel/PptDbViewModel.kt
  com/aipptzhizuozz/bjh/viewmodel/FileScanViewModel.kt
  .../SaleCenterViewModel.kt
```

## Architecture Decisions

- NavPathStack + @Provider/@Consumer (matches D-004)
- @ObservedV2 + @Trace + AppStorageV2.connect
- UserState.ets as global singleton pattern
- 0 deprecated @ohos.router

## Optimal Pipeline for S2

1. Generator → baseline code (done)
2. Agent → apply C1-C8 corrections to generator code
3. Agent → verify chains against ViewModel source
4. Agent → read BaseDataBindingActivity + check null safety
5. Human → review corrections + approve
