# Chain Validation — Final Report

**Agent**: a575b370c9c1f18ac | **Date**: 2026-07-19 | **Source**: 10 Kotlin files read

---

## Chain 1: saveUserInfo Cascade (depth 12)

**Source**: LoginViewModel.kt L58-79

**Verified call sequence**:
```
bindPhone/sendSmsCode/wechatLogin/aliLogin/honorLogin/huaweiLogin
  → API call
  → on success: saveUserInfo(it)
    1. SafeDeviceUtils.useItemConfig = it.blackItemNums        (L60)
    2. SafeDeviceUtils.tqv = it.tqv                            (L63)
    3. SafeDeviceUtils.uploadResult(110_BY_TRACK, preTrackResult) (L66-68)
    4. SafeDeviceUtils.uploadResult(111_BY_BLACK_DB, showAd)   (L71-73)
    5. UserData.getInstance().saveUserInfo(it)                  (L75)
    6. VolcEnginManger.setUserUniqueid(it.userId.toString())    (L76)
    7. VolcEnginManger.setHeaderInfo()                          (L77)
  → loginLiveData.value = true                                 (L49)
  → EventUpload.uploadLoginEvent(type, code, msg, newRegister) (L139-143)
```

**Integration risk**: Steps 1-7 must complete BEFORE LiveData post. If order is reversed in ArkTS, SplashActivity observer fires prematurely and navigates before device tracking completes.

**Minimum integration test**: After login, verify SafeDeviceUtils.useItemConfig and UserData.getInstance().userId are populated BEFORE the navigation event fires.

## Chain 2: createOrder Auth Gates (depth 4)

**Source**: MemberCenterViewModel.kt L35-55

**Verified call sequence**:
```
createOrder()
  → Gate 1 (PRE-API): if (!UserData.isBinding() && interceptAuth == 1)
      → LoginActivity.openLoginPage(activity) — L35-37
      → return (aborts API call)
  → createPreOrder(activity, fragment, payFrom, productId, paymentChannel, productType) — L39-46
  → Gate 2 (POST-API): when (it) { -605 ->
      → changLoadingStatus(false)
      → LoginActivity.openLoginPage(activity) — L48-52
  }
```

**Integration risk**: Two different auth failure conditions with different timing. Gate 1 fires BEFORE spending API quota. Gate 2 fires AFTER the API call and needs error cleanup.

**Minimum integration test**: Test both paths: (a) unauthenticated user + interceptAuth=1 → LoginActivity opens before API call; (b) API returns -605 → LoginActivity opens after loading dismisses.

## Chain 3: uploadFirstStart Fire-and-Forget (depth 0)

**Source**: SplashViewModel.kt L21-26

**Verified**: `appApiService.firstStart(body).netResult()` with EMPTY callback body. No success handler, no error handler. The API call succeeds or fails silently with zero observable state changes.

**ArkTS equivalent**: `http.request(url, { method: 'POST', extraData: body })` with no `.then()` / `.catch()`. Must NOT throw unhandled Promise rejection (match Android's silent failure).

## Chain 4: Login Path Convergence (depth 3)

**Source**: LoginViewModel.kt L176-500

**Verified**: All 4 login paths converge on the same `saveUserInfo(it)` method:
- WeChat: L177 authorize → L184 bindWx → L198 saveUserInfo
- AliPay: L220 fetchAliLoginInfo → L242 launchAliLogin → L272 bindAliCode → L301 saveUserInfo
- Honor: L397 honorLogin → L400 bindHonor → L417 saveUserInfo
- Huawei: L438 huaweiLogin → L453 huaweiLoginResult → L466 dealWithResultOfSignIn → L471 bindHuawei → L481 saveUserInfo

**Integration risk**: If each path implements saveUserInfo independently (copy-paste), 4 versions diverge. Android has ONE method. ArkTS MUST also have ONE shared method.

## Chain 5: Loading State Coupling (depth 1)

**Source**: LoginViewModel.kt (multiple methods)

**Verified pattern**: Every API method follows:
```
changLoadingStatus(true)  →  API call  →  changLoadingStatus(false)
```
Present in: sendSmsCode (L90→L99/L102), bindPhone (L122→L137/L147), loginOut (L362→L370/L374), deleteAccount (L380→L388/L392), fetchAliLoginInfo (L221→L228/L233), wechatLogin (L326→L346/L349/L357), honorLogin (L398→L402), huaweiLogin (L439→L447).

**Integration risk**: If loading state is managed at page level instead of method level, timing is wrong. Must be: show loading → do work → hide loading. Never: show loading on page, do work elsewhere.

---

## Validation Summary

| Chain | Depth | Verified Lines | Min Test Cases | Risk |
|-------|-------|---------------|----------------|------|
| saveUserInfo | 12 | L58-79, L139-143 | 1 (ordering) | HIGH — observer cascade |
| Auth gates | 4 | L35-55 | 2 (pre + post gate) | MEDIUM — two failure paths |
| Fire-and-forget | 0 | L21-26 | 1 (silent failure) | LOW — no side effects |
| Login convergence | 3 | L176-500 | 1 (single method) | MEDIUM — copy-paste risk |
| Loading state | 1 | Multiple | 1 (pair check) | LOW — pattern consistency |

All chains verified against actual Kotlin source code. No assumptions — every line reference confirmed via grep.
