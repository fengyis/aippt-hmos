# Chain Validation — Source-Traced
## Agent a575b370c9c1f18ac | 2026-07-19

### Chain 1: saveUserInfo Cascade (depth 12)
Source: LoginViewModel.kt L58-79
Verified: SafeDeviceUtils.useItemConfig(L60) → SafeDeviceUtils.tqv(L63) → uploadResult×2(L66-73) → UserData.saveUserInfo(L75) → VolcEnginManger×2(L76-77) → loginLiveData=true(L49)
Risk: If ArkTS posts state before side effects, Splash observer fires prematurely.

### Chain 2: createOrder Auth Gates (depth 4)
Source: MemberCenterViewModel.kt L35-55
Verified: Gate1 pre-API (!isBinding && interceptAuth==1) L35-37. Gate2 post-API (-605) L48-52.
Risk: Two different failure conditions, different timing.

### Chain 3: uploadFirstStart Fire-and-Forget (depth 0)
Source: SplashViewModel.kt L21-26
Verified: appApiService.firstStart().netResult() with EMPTY callback body. No observable effect.
Impl: http.request() with no .then()/.catch(). Must not throw unhandled rejection.

### Chain 4: Login Path Convergence (depth 3)
Source: LoginViewModel.kt L176-500
Verified: WeChat(L177→L198), AliPay(L220→L301), Honor(L397→L417), Huawei(L438→L481) all call saveUserInfo(it).
Impl: ONE shared saveUserInfo ArkTS method, not 4 copies.

### Chain 5: Loading State Coupling (depth 1)
Source: LoginViewModel.kt (multiple methods)
Verified: changLoadingStatus(true) → API → changLoadingStatus(false) on every method.
Impl: Loading state managed at METHOD level, not page level.
