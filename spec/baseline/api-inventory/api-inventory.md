# API Inventory - AIPPT

> **扫描时间**：2026-07-19 | **平台**：Android | **技术栈**：Retrofit+OkHttp+RxJava 多模块项目
> **phase4 模式**：candidate（spec 尚未生成，本文件作为 a2h-spec 输入源）
> **下游消费方**：a2h-spec Phase C（Step C1 源码分析 / Step C2 功能拆分 / Step C3-C4 feature 生成）

## 概览

| 项目 | 数值 |
|------|------|
| Service 类 | 10 |
| 总端点 | 56 |
| 第三方 API | 5 (讯飞/微信/火山引擎/图片CDN/主站API) |
| HTTP 模块 | app, basic, common, network, pay, push, event-track, aliauth |
| 主站 Base URL | `http://dev-api.whiap.cn` |
| PPT 生成 Base URL | `https://zwapi.xfyun.cn` |
| 认证方式 | Token + HMAC-SHA256 签名(ss/tt) + XXTEA 加密(PPT 专用) |
| 响应信封 | BaseBean(code + msg + data) |
| 所有请求均使用 | POST + JSON Body（除 PPT 进度查询用 GET） |

## 文档导航

| 文档 | 端点数 | 内容 |
|------|:--:|------|
| [common.md](common.md) | — | 公共约定：通道/签名/公参/响应信封/共享响应体/业务状态码 |
| [apis/user.md](apis/user.md) | 11 | 用户认证与账号 (UserApiService: initUser, bind*, getInfo, logout...) |
| [apis/pay.md](apis/pay.md) | 18 | VIP支付与金币经济 (PayApiService + CoinIonApiService + FreeCountV2ApiService) |
| [apis/aippt.md](apis/aippt.md) | 5 | AI PPT 生成 (AIPPTService: 模板/大纲/生成/进度, 讯飞API) |
| [apis/app.md](apis/app.md) | 22 | 应用框架/反作弊/推送/配置 (AppApiService + AntiCheat + AlgorithmFiling + CheckUpdate + Push) |

## Base URL

| 名称 | URL | 环境 | 用途 |
|------|-----|------|------|
| mHttpUrl | `http://dev-api.whiap.cn` | 开发 | 主站业务 API（用户/支付/配置等） |
| apiBaseUrl | `https://zwapi.xfyun.cn` | 生产 | 讯飞 PPT 生成 API |
| DEFAULT_IMAGE_HOST | `https://foc.guiizhen.cn/` | 生产 | 图片 CDN |

## 网络层架构摘要

```
[App 业务层]
  └─ ViewModel / Activity / Fragment
       └─ Retrofit Service 接口 (10 个)
            └─ OkHttp Client
                 ├─ RequestInterceptor（Token 注入 + HMAC-SHA256 签名头 ss/tt）
                 ├─ XXTEA 加密（仅 AIPPTService 的请求体）
                 └─ RxJava Observable 响应包装
```

### 认证机制

- **Token 认证**：用户登录后由服务端下发 Token，存储在 `UserData.SP_TOKEN`
- **签名头 ss**：HMAC-SHA256 请求签名，防止篡改，通过 `RequestInterceptor` 每请求自动注入
- **签名头 tt**：请求时间戳，配合 ss 使用
- **公参 platformInfo**：设备品牌/型号/系统版本/渠道号等，所有请求自动附带
- **XXTEA 加密**：AIPPTService 专用，加密请求体后附 `appId`+`secret` 调用讯飞 API

### 响应信封

所有主站接口统一响应格式：
```json
{
  "code": 0,        // 业务状态码，0=成功
  "msg": "success", // 提示信息
  "data": { ... }   // 业务数据体
}
```

## 第三方 API

| Provider | 域名 | 用途 | 认证方式 |
|----------|------|------|---------|
| 讯飞 (iFlytek) | zwapi.xfyun.cn | AI PPT 生成 (模板/大纲/生成/进度) | appId + secret + XXTEA 签名 |
| 微信 Open Platform | api.weixin.qq.com | 微信 OAuth2 登录 | OAuth2 authorization_code |
| 火山引擎 | gator.volces.com | 应用埋点数据上报 | API-Key (SDK 封装) |
| 图片 CDN | foc.guiizhen.cn | 用户图片/模板图片托管 | 无认证 (公开 CDN) |
| 主站业务 API | dev-api.whiap.cn | 全部业务接口 | Token + HMAC-SHA256 |

## Feature 候选建议（供 spec 生成参考）

> 本项目 spec 尚未生成，以下候选基于扫描结果聚类推断，供 a2h-spec 后续决定 F0xx 划分时参考。
> **这些是候选**，spec 作者可采纳 / 调整 / 重划。

### 候选 F-user: 用户认证与账号
- 路径前缀：`/user/*`、`/system/sendSmsCode`、`/system/arrival`
- 端点数：13
- 第三方依赖：WeChat OAuth, AliPay Auth, Huawei Account, Honor Account
- 迁移关注点：多家三方账号绑定(微信/支付宝/华为/荣耀)认证流程不同；运营商一键登录 Token 流程；Gson @SerializedName → ArkTS 无等价机制需手写字段映射

### 候选 F-pay: VIP 支付与订阅
- 路径前缀：`/pay/*`、`/product/*`
- 端点数：13
- 第三方依赖：支付宝支付, 微信支付, 华为支付, 荣耀支付, OPPO 支付
- 迁移关注点：订单轮询 queryOrderStatus；自动续费签约/取消/退款流程；多家支付渠道 SDK 适配；微信 H5 支付兜底方案

### 候选 F-coin: 金币经济与免费配额
- 路径前缀：`/asset/*`、`/productComm/*`、`/privacy/*`
- 端点数：7
- 第三方依赖：无
- 迁移关注点：金币扣除+退款幂等性；免费配额 V1/V2 两套并存需统一

### 候选 F-aippt: AI PPT 生成
- 路径前缀：`/api/ppt/v2/*`（讯飞 API）
- 端点数：5
- 第三方依赖：讯飞 (iFlytek) PPT API
- 迁移关注点：XXTEA 加密算法移植(CryptoArchitectureKit 自实现)；异步任务模式(create→poll→result)；Multipart 文件上传；自定义签名 Header 注入

### 候选 F-app: 应用框架与配置
- 路径前缀：`/app/*`、`/system/`、`/ad/*`
- 端点数：14
- 第三方依赖：火山引擎埋点
- 迁移关注点：OAID 设备标识获取(HMOS 需 APP_TRACKING_CONSENT 权限)；应用安装列表收集(HMOS 受限)；火山引擎埋点 SDK 需厂商适配；个推推送 SDK 需鸿蒙版

### 候选 F-anti: 内容反作弊
- 路径前缀：`/anti/*`
- 端点数：3
- 第三方依赖：无
- 迁移关注点：文本/图片/视频三类检测需 HMOS 端对接相同后端

---

## HarmonyOS 等价物提示

> 来源：框架 API 命中 —— 本 skill 静态映射表 references/framework-kit-mapping.md（2.5a，无条件）。
> 项目未提供 `hmos_references_file` → 2.5b 跳过。
> 下游 a2h-plan grill #2 Step 0 应优先读本段，避免对已有信息重复问用户。
> **本提示不是 contract** —— `api-inventory.json` 各 entry 未因此新增字段，提示仅在 markdown 中存在。

### 已命中（框架映射）

| 扫描识别 | HarmonyOS 提示 | 来源 |
|---------|---------------|------|
| Retrofit + OkHttp + Interceptor | rcp 会话+拦截器 (`@kit.RemoteCommunicationKit`，API 12+)；或 NetworkKit `http.createHttp().request()` | framework-kit-mapping.md §1 |
| HMAC-SHA256 签名拦截器 (javax.crypto.Mac) | `cryptoFramework.createMac('SHA256')` (`@kit.CryptoArchitectureKit`) | framework-kit-mapping.md §3 |
| XXTEA 加密自实现 | `cryptoFramework.createCipher` (`@kit.CryptoArchitectureKit`) — 需自实现 XXTEA 算法 | framework-kit-mapping.md §3 |
| Gson @SerializedName ×47+ 字段 | 无等价机制 —— 字段名≠JSON key 时必须手写 FIELD_MAP 镜像（迁移高风险点） | framework-kit-mapping.md §2 |
| RxJava Observable → 异步改写 | async/await + Promise 模式（Retrofit→rcp/http 全量重写调用链） | framework-kit-mapping.md §1 |
| SharedPreferences / MMKV | `preferences` (`@kit.ArkData`) | framework-kit-mapping.md §4 |
| Room / SQLite (本地缓存) | `relationalStore` (`@kit.ArkData`) | framework-kit-mapping.md §4 |
| OAID 获取 | `identifier.getOAID()` (`@kit.AdsKit`)，需 `ohos.permission.APP_TRACKING_CONSENT` | framework-kit-mapping.md §5 |
| ANDROID_ID | 无 1:1 等价 —— 首启 `util.generateRandomUUID()` 持久化复用 | framework-kit-mapping.md §5 |
| Multipart 文件上传 (OkHttp) | NetworkKit `http.request()` + `multiFormDataList` 或 rcp multipart | framework-kit-mapping.md §1 |
| SSE (PPT 进度轮询 — 实为轮询非 SSE) | GET 轮询可用 NetworkKit `http` — 非真 SSE，无迁移难点 | — |

### 未命中（hmos-references.md 中无对应记录，后续 plan grill #2 阶段二补问）

- 个推推送 SDK (Getui) — 需鸿蒙版或替代推送方案
- 阿里一键登录 SDK (PhoneNumberAuthService) — 需鸿蒙版或华为 Account Kit 替代
- 火山引擎埋点 SDK (Volcano Engine) — 需厂商适配或自建埋点替换
- 微信 Open SDK (登录+支付) — 需联系微信团队获取鸿蒙 alpha 包
- 支付宝 SDK (支付) — 官方未发布鸿蒙版，可用 H5 收银台
