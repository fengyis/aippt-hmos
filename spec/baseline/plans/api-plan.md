# API Migration Plan

## Context
- Source: spec/baseline/api-inventory (api-inventory.json + 4 per-service docs + common.md)
- Style: none
- Total services: 10
- Total endpoints: 56
- Base layers: `api-inventory/common.md` (公共约定)
- Estimated phases: Layer 0 (HttpClient+共通) + Layer 1-3 (per-service 按依赖序)

## Common Infrastructure (Layer 0)

> 所有 API service 共享，必须先于任何 per-service 迁移完成。

### Step 0a: HttpClient + Response Envelope
- suggested_skills: [arkts-data-layer]
- input: api-inventory/common.md + feature-base.md Network 段
- Retrofit+OkHttp → `@kit.NetworkKit` `http.createHttp()`
- `BaseBean<T>` → `class BaseResponse<T> { code: number; msg: string; data: T }`
- Response interceptor: code ≠ 0 → throw `ApiException(code, msg)`
- output: `entry/src/main/ets/network/HttpClient.ets`
- agent: 1 (sequential)

### Step 0b: Auth Header Injection
- suggested_skills: [arkts-data-layer]
- input: api-inventory/common.md §鉴权头
- 主站: `token`(登录Token/Mmkv) + `ss`(HMAC-SHA256签名: `z27vsnfeeb4nuxkjzfcd35nqvpx7xwd9`) + `tt`(时间戳) + `Content-Type`
- 讯飞: `appId=4fe117ca` + XXTEA 加密请求体(密钥 `f3224b...`) — **迁移难点**: XXTEA 非标准算法，需 `cryptoFramework` 自实现或确认讯飞 HTTP 鉴权替代
- output: `entry/src/main/ets/network/AuthInterceptor.ets`
- agent: 1 (complex, XXTEA self-implementation)

### Step 0c: PlatformInfo 公参注入
- suggested_skills: [arkts-data-layer]
- input: api-inventory/common.md §公共请求参数
- 14-field `platformInfo` 对象自动注入所有主站请求体
- deviceInfo (`@kit.BasicServicesKit`) + OAID (`@kit.AdsKit identifier.getOAID()`)
- output: `entry/src/main/ets/network/PlatformInfoProvider.ets`
- agent: 1 (sequential)

## Per-Service Migration

> 每个 service 按依赖序逐层迁移。HMAC-SHA256/XXTEA 已在 Layer 0b 实现，service 层只做请求封装+响应类型映射。

### Service 1: AIPPTService (讯飞 API)
- Priority: P0 (PPT 核心流程依赖)
- Endpoints: 5 (`template/list`, `createOutline`, `createOutlineByDoc`, `createPptByOutline`, `progress`)
- source: `AIPPTService.kt`
- agent: 1 (5 endpoints, sequential; outline→ppt→progress 异步链单 agent 完成)
- 异步任务流程: `createOutline → createPptByOutline → queryPptProgress(轮询)` → 完成

### Service 2: UserApiService
- Priority: P0 (登录/用户信息依赖)
- Endpoints: 12 (`initUser`, `bindAli`, `bindMobile`, `bindWx`, `bindHuawei`, `bindHonor`, `getInfo`, `closeAccount`, `logout`, `bindMobileByToken`, `userKeep`, `initThirdToken`)
- source: `UserApiService.kt` (Retrofit)
- agent: 2 (auth核心接口 `initUser/bindAli/bindWx/logout/closeAccount` + 辅助接口 `getInfo/userKeep/initThirdToken` 并行)

### Service 3: PayApiService
- Priority: P0 (支付流程依赖)
- Endpoints: 13 (productList, createOrder, cancelOrder, productFloat, wxPayResult, aliPayResult, huaweiPayResult, honorPayResult, limitGiftQuery, limitCampaignQuery, renewInfo, cancelRenew, refundRenew)
- source: `PayApiService.kt` + `pay/src/main/.../PayApiService.kt`
- agent: 2 (product/order 接口 + renew/refund 接口 并行; 支付回调 4 接口占位 thirdparty-sdk)
- placeholders: P-S2-1(微信)/P-S2-2(支付宝)/P-S2-3(华为) → 支付 SDK 回调接口留桩

### Service 4: AppApiService
- Priority: P1 (应用配置/系统功能)
- Endpoints: 14 (arrival, getFloatInfo, checkUpdate, uploadEvent, feedback, shortCutDetail, getShortCutList, assistFriend, getQuestionList, getQuestionDetail, checkQuestion, feedShare, readAgreement, privacyAgreementDetail)
- source: `AppApiService.kt` + `AppContant.kt`
- agent: 2 (核心配置 arrival/getFloatInfo/checkUpdate + 辅助 feedback/shortCut/等 并行)

### Service 5-10: 辅助 Service
- Priority: P2 (独立功能，不阻塞主流程)
- CoinIonApiService: 3 endpoints, agent=1
- FreeCountV2ApiService: 2 endpoints, agent=1
- AntiCheatCheckSevice: 3 endpoints, agent=1
- PushApiService: 2 endpoints, agent=1 (推送 → P-S10-1 thirdparty-sdk)
- AlgorithmFilingService: 1 endpoint, agent=1
- CheckUpdateService: 1 endpoint, agent=1

## Migration Order

```
Layer 0: 0a(HttpClient) → 0b(AuthHeader) → 0c(PlatformInfo)
   ↓
Layer 1 (P0, parallel): AIPPTService + UserApiService
   ↓
Layer 2 (P0, depends Layer 1): PayApiService
   ↓
Layer 3 (P1, parallel): AppApiService + CoinIonApiService + FreeCountV2ApiService + AntiCheatCheckSevice
   ↓
Layer 4 (P2, parallel): PushApiService + AlgorithmFilingService + CheckUpdateService
```

## Agent Summary

| Layer | Services | Endpoints | Agents | Notes |
|-------|----------|-----------|--------|-------|
| 0 (Common) | HttpClient + Auth + PlatformInfo | — | 3 | Serial, must finish first |
| 1 (P0) | AIPPTService, UserApiService | 17 | 3 (1+2) | Parallel |
| 2 (P0) | PayApiService | 13 | 2 | 4 payment endpoints thirdparty-sdk placeholder |
| 3 (P1) | AppApiService + 3 aux | 22 | 5 (2+1+1+1) | Parallel |
| 4 (P2) | PushService + 2 aux | 4 | 3 (1+1+1) | Parallel |
| **Total** | **10 services** | **56** | **16** | |

## Placeholders

| P-ID | Service | Endpoint(s) | Kind | Resolve |
|------|---------|-------------|------|---------|
| P-S2-1 | PayApiService | wxPayResult | thirdparty-sdk | 微信 HMOS SDK 入仓后接线 |
| P-S2-2 | PayApiService | aliPayResult | thirdparty-sdk | 支付宝 HMOS SDK 入仓后接线 |
| P-S2-3 | PayApiService | huaweiPayResult | thirdparty-sdk | 华为 HMOS SDK 厂商适配后接线 |
| P-S10-1 | PushApiService | pushDevice/pushMessage | thirdparty-sdk | 推送 SDK 入仓后接线 |

## Runtime Verification

| Item | Trigger | Action |
|------|---------|--------|
| XXTEA 加密兼容性 | 首次调用 createOutline 返回非 200 | 检查讯飞 HTTP 鉴权替代方案; 或 cryptoFramework 自实现 XXTEA |
| HMAC-SHA256 签名 | 主站任一接口返回 -605(未登录) | 检查 ss Header 生成逻辑: body + timestamp + HMAC-SHA256(key) |
| 明文 HTTP 拦截 | `http://dev-api.whiap.cn` 请求失败 | module.json5 配置 `cleartextTraffic: true` 白名单 |
