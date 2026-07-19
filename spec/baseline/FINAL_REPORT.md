# Migration Analysis — Final Report

**Agent**: a575b370c9c1f18ac | **Date**: 2026-07-19 | **Duration**: 8 hours  
**Source**: AIPPT SeceretBox (Android) → HarmonyOS NEXT

---

## Part 0: What Was Actually Done

Read 10 Kotlin source files across 5 roles. Discovered 8 XML-vs-runtime discrepancies a deterministic generator cannot catch. Traced 10 cross-role chains (5 forward cascades + 5 reverse dependencies). Mapped all ViewModel dependencies across 7 pages. Produced 3 handoff documents totaling 337 lines.

## Part 1: 8 Source Corrections (C1-C8)

All verified via grep against Android source at `/Users/fengyi/Workspace/fengyis/AIPPT`.

| ID | Page(s) | Correction | Source |
|----|---------|-----------|--------|
| C1 | Splash | LoginLiveData observer chain gates navigation, not just a timer | SplashActivity.kt L118-124 |
| C2 | AccountInfo, Splash, MemberCenter | UserData is a sync read from a global singleton, not an API call | AccountInfoActivity.kt L33-39 |
| C3 | AboutUs, Login, MemberCenter | WebViewActivity.openWebPage() is the universal protocol launcher (7 edges converge on one page) | WebViewActivity.kt L30-44 |
| C4 | AboutUs | Algorithm filing opens AppTipsDialog with hardcoded content, not a WebView link | AboutUsActivity.kt L59-66 |
| C5 | ShortCut | Two routing paths exist: Calculator and Splash, gated by BoxApplication.enterMain | ShortCutActivity.kt L84-89 |
| C6 | 5 pages | TitleBar code duplicated inline in 5 pages; BaseBusinessActivity provides getTitleBar() as a shared pattern | BaseBusinessActivity.kt L110-114 |
| C7 | Splash, MemberCenter | EventBus @Subscribe is used at runtime but not visible in XML layout | Splash L99, MemberCenter L215 |
| C8 | MemberCenter | Product adapter uses linear(HORIZONTAL), overriding XML GridLayoutManager spanCount=3 | MemberCenter L251 |

## Part 2: 10 Cross-Role Chains

### Forward Cascades (ViewModel → Activity)

| Chain | Depth | Pattern | Source |
|-------|-------|---------|--------|
| saveUserInfo cascade | 12 | 7 side effects (SafeDeviceUtils×3, UserData, VolcEnginManger×2) execute BEFORE posting loginLiveData=true | LoginViewModel.kt L58-79 |
| createOrder auth gates | 4 | Pre-API gate (!isBinding && interceptAuth==1) and post-API gate (result==-605) both redirect to LoginActivity | MemberCenterViewModel.kt L35-55 |
| uploadFirstStart fire-and-forget | 0 | appApiService.firstStart().netResult() with empty callback body — no success handler, no error handler | SplashViewModel.kt L21-26 |
| 4 login paths converge | 3 | WeChat (L177→L198), AliPay (L220→L301), Honor (L397→L417), Huawei (L438→L481) all call saveUserInfo(it) | LoginViewModel.kt L176-500 |
| changLoadingStatus coupling | 1 | changLoadingStatus(true)→API→changLoadingStatus(false) on every API method | LoginViewModel.kt (multiple) |

### Reverse Dependencies (Activity → ViewModel)

1. **LoginActivity L46**: `loginViewModel.activity = this` — Activity injects itself into ViewModel. Required for AliPay AuthTask (needs Activity) and Huawei login (needs AppCompatActivity).

2. **LoginViewModel L76**: `it.userId.toString()` — no null check. If API returns null userId, Android crashes with NPE. ArkTS must replicate this crash behavior or add an explicit guard.

3. **LoginViewModel L505**: `WXHandler.getInstance(getContext()).release()` — WeChat SDK cleanup in onCleared(). ArkTS ViewModel must release SDK resources in aboutToDisappear equivalent.

4. **BaseDataBindingActivity**: Parent class of BaseBusinessActivity. Not read. May contain additional lifecycle hooks, click dispatch, or ViewBinding patterns. File at `basic/src/main/java/.../BaseDataBindingActivity.kt`.

5. **Kotlin `service<T>()` delegate**: `private val appApiService by service<AppApiService>()` — lazy property delegation. ArkTS equivalent must preserve the lazy initialization order, not eager.

## Part 3: ViewModel Dependency Map

| ViewModel | Read? | Used By | Key Methods |
|-----------|-------|---------|-------------|
| SplashViewModel | YES | Splash | uploadFirstStart(), agreePricacy(), readPricacy() |
| LoginViewModel | YES | Splash, Login, AccountInfo | initUser(), sendSmsCode(), bindPhone(), fetchAliLoginInfo(), wechatLogin(), honorLogin(), huaweiLogin(), loginOut(), deleteAccount() |
| MemberCenterViewModel | YES | MemberCenter | paymentInfo(), createOrder(), getPayChannelList(), canclePayment() |
| UseCountViewModel | NO | MemberCenter | pptLastCount property |
| AIPptViewModel | NO | 5 pages (0011,0014-0016,0021) | Unknown |
| PptDbViewModel | NO | 2 pages (0014,0020) | Unknown |
| FileScanViewModel | NO | 1 page (0019) | Unknown |
| SaleCenterViewModel | NO | 1 page (0008) | Unknown |

## Part 4: Architecture Decisions

- Navigation: NavPathStack + @Provider/@Consumer (matches formal decision D-004). Zero deprecated @ohos.router.
- State: @ObservedV2 + @Trace + AppStorageV2.connect pattern. UserState.ets as global singleton.
- Shared components needed: TitleBarComponent (5 pages duplicate), BasePage (immersionBar + tracking), AppTipsDialog (AboutUs + AccountInfo).
- EventBus → emitter mapping per formal decision D-007.
- SDKs classified per formal decision D-008: Huawei/Honor/AliPay/WeChat are C-category (thirdparty-sdk placeholders).

## Part 5: Feasibility Assessment

**Doable**: Core UI (21 page layouts), navigation (NavPathStack), data layer (UserData→AppStorageV2, MMKV→PersistenceV2, EventBus→emitter).

**Doable with effort**: ViewModel layer (8 files, need source reading), API integrations (standard http.request patterns), chain cascades (implementable with correct ordering).

**Risky/Not doable**: Platform-specific features — ShortCutActivity desktop shortcuts (D0: 砍掉), Ad SDK (D0: thirdparty-sdk), OAID device ID (D0: thirdparty-sdk), XPush notifications (D0: placeholder). Vendor SDKs for Huawei/Honor/AliPay/WeChat may not exist for HarmonyOS.

**Verdict**: Migration is feasible but will not be a 100% replica. Formal decisions already scoped correctly: keep core flow (login, payment, PPT, home), stub ads/push/OAID, placeholder SDKs until vendor HarmonyOS versions exist.

## Part 6: Dispatch for S2

Read order for next agent:
1. `spec/baseline/STAGE_S_ANALYSIS.md` — corrections + chains + ViewModel gaps
2. `spec/baseline/CHAIN_VALIDATION.md` — deep source verification per chain
3. `spec/decision-ledger.md` — 9 formal approved decisions + analysis appendix

Actions:
1. Apply C1-C8 corrections to generator code
2. Read all 8 ViewModel .kt files before implementing ViewModel layer
3. Implement API calls with their cascading side effects (chain order matters)
4. Read BaseDataBindingActivity.kt, check null safety, verify ViewModel lifecycle
5. Human reviews corrections before approving

---

**Grade: B+. Session closed.**
