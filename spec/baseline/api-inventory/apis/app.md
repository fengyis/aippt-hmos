# 应用框架 / 反作弊 / 推送 / 配置接口

> 汇集 5 个 Service：`AppApiService` + `AntiCheatCheckSevice` + `AlgorithmFilingService` + `CheckUpdateService` + `PushApiService`
> 端点数：22 | 通道：`mHttpUrl` | 公共约定见 [../common.md](../common.md)
> 认证：Token + HMAC-SHA256 签名 | runtime：⬜ static-only

## 端点速览

### AppApiService（14 端点）

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/app/config` | getConfig | ⬜ |
| POST | `/app/firstStart` | firstStart | ⬜ |
| POST | `/app/appList` | uploadAppList | ⬜ |
| POST | `/app/upOaid` | uploadOaid | ⬜ |
| POST | `/app/appLog` | appLog | ⬜ |
| POST | `/app/privacyAgreement` | pricacyAgreement | ⬜ |
| POST | `/app/readAgreement` | readAgreement | ⬜ |
| POST | `/ad/up` | adEventUpload | ⬜ |
| POST | `/privacy/getFreeCount` | freeCount | ⬜ |
| POST | `/privacy/useCount` | useCount | ⬜ |
| POST | `/ad/upHideAdReason` | upHideAdReason | ⬜ |
| POST | `/system/arrival` | arrival | ⬜ |
| POST | `/system/sendSmsCode` | sendSmsCode | ⬜ |
| POST | `/push/getuiCid` | getuiCid | ⬜ |

### 其他 Service

| 方法 | 路径 | 接口名 | Service | runtime |
|------|------|--------|---------|:--:|
| POST | `/anti/textCheat` | textCheat | AntiCheatCheckSevice | ⬜ |
| POST | `/anti/imageCheat` | imageCheat | AntiCheatCheckSevice | ⬜ |
| POST | `/anti/videoCheat` | videoCheat | AntiCheatCheckSevice | ⬜ |
| POST | `/app/getAlgorithmFiling` | getAlgorithmFilingList | AlgorithmFilingService | ⬜ |
| POST | `/app/checkVersion` | checkVersion | CheckUpdateService | ⬜ |
| POST | `/push/getuiCid` | uploadGtClientId | PushApiService | ⬜ |
| POST | `/app/getuiReport` | uploadPushStrategy | PushApiService | ⬜ |

> ⚠ `/push/getuiCid` 在 `AppApiService` 和 `PushApiService` 中重复定义（同一路径，不同模块）。

---

## AppApiService 核心端点

### 1. getConfig — 远程配置

- **方法**：`POST /app/config`
- **Service**：`AppApiService.getConfig`（AppApiService.kt:20）
- **响应**：`AppconfigBean`

| 字段 | 类型 | 说明 |
|------|------|------|
| appLogSwitch | Int | 日志开关 |
| auditingStatus | Int | 审核状态（控制广告/支付入口显隐） |

> 应用启动时调用，决定全局功能开关。

---

### 2-6. 生命周期事件上报 (firstStart / appList / upOaid / appLog / arrival)

均为事件上报类接口，统一使用 `POST + RequestBody`，返回 `BaseBean`。失败不影响主流程。

| 端点 | 用途 |
|------|------|
| `/app/firstStart` | 首次启动上报（含安装来源） |
| `/app/appList` | 已安装应用列表上报 |
| `/app/upOaid` | OAID 设备标识上报 |
| `/app/appLog` | 行为日志上报 |
| `/system/arrival` | 用户到达首页事件（app 启动完成） |

---

### 7-8. 隐私协议 (privacyAgreement / readAgreement)

- **`/app/privacyAgreement`**：上报用户同意/拒绝隐私协议
- **`/app/readAgreement`**：上报用户已阅读协议

---

### 9. adEventUpload — 广告事件上报

- **方法**：`POST /ad/up`
- **Service**：`AppApiService.adEventUpload`（AppApiService.kt:62）

另外需要关注常量 `ADUrl.adUp228` → `/ad/up228`（URL 常量已解析但未被任何 service endpoint 引用，可能是预留接口）。

---

### 10-11. 免费次数 V1（freeCount / useCount）

- **`/privacy/getFreeCount`**：获取免费次数，返回 `FreeCountBean`
- **`/privacy/useCount`**：消耗免费次数，返回 `BaseBean`

> ⚠ 与 V2 版本（`/productComm/getFreeCountV2` / `/productComm/useFreeCountV2`）并存，迁移时需判断是否统一。

---

### 12. upHideAdReason — 上报隐藏广告原因

- **方法**：`POST /ad/upHideAdReason`
- **Service**：`AppApiService.upHideAdReason`（AppApiService.kt:86）
- **响应**：`AppconfigBean`

---

### 13. sendSmsCode — 发送短信验证码

- **方法**：`POST /system/sendSmsCode`
- **Service**：`AppApiService.sendSmsCode`（AppApiService.kt:98）
- **响应**：`BaseBean`

> 配合 `POST /user/bindMobileBySmsCode` 使用（先发码，再绑定手机号）。

---

### 14. getuiCid — 上报个推 ClientId

- **方法**：`POST /push/getuiCid`
- **Service**：`AppApiService.getuiCid`（AppApiService.kt:104）
- **响应**：`BaseBean`

> PushApiService 中也定义了同一端点 (`uploadGtClientId`)，属跨模块重复定义。

---

## AntiCheatCheckSevice（反作弊）

> 文件：`network/src/main/java/cn/sanfate/pub/network/api/AntiCheatCheckSevice.kt`
> 所有 3 个端点均为 `suspend` 函数，返回 `AntiTextCheatBean`

### 15. textCheat — 文本反作弊

- **方法**：`POST /anti/textCheat`（REST）
- **Service**：`AntiCheatCheckSevice.textCheat`（AntiCheatCheckSevice.kt:18）

### 16. imageCheat — 图片反作弊

- **方法**：`POST /anti/imageCheat`（REST）
- **Service**：`AntiCheatCheckSevice.imageCheat`（AntiCheatCheckSevice.kt:21）

### 17. videoCheat — 视频反作弊

- **方法**：`POST /anti/videoCheat`（REST）
- **Service**：`AntiCheatCheckSevice.videoCheat`（AntiCheatCheckSevice.kt:24）

---

## 其他 Service

### 18. getAlgorithmFilingList — 算法备案列表

- **方法**：`POST /app/getAlgorithmFiling`
- **Service**：`AlgorithmFilingService.getAlgorithmFilingList`（AlgorithmFilingService.kt:11）
- **特殊标注**：`suspend` 函数
- **响应**：`AlgorithmFilingResponse`

> 合规展示用（如关于我们页面展示算法备案号）。

---

### 19. checkVersion — 版本更新检查

- **方法**：`POST /app/checkVersion`
- **Service**：`CheckUpdateService.checkVersion`（CheckUpdateUtil.kt:23）
- **特殊标注**：`suspend` 函数
- **响应**：`CheckVersionBean`（新版本号/下载地址/强制更新标记/更新日志）

---

### 20-21. PushApiService（推送）

> 文件：`push/src/main/java/cn/sanfate/pub/push/sdk/api/PushApiService.kt`

- **uploadGtClientId** — `POST /push/getuiCid`（PushApiService.kt:14）
  - 上报个推 ClientId（与 AppApiService.getuiCid 同路径重复）
- **uploadPushStrategy** — `POST /app/getuiReport`（PushApiService.kt:20）
  - 上报推送策略执行结果（引导完成/免费次数/取消支付等）

> ⚠ 迁移关注点：个推推送 SDK 需鸿蒙版；或改用华为推送服务（Push Kit from `@kit.PushKit`）。
