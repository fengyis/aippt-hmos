# 公共约定（common）

> 本文档汇总所有 API 端点共用的公共约定：通道、签名、公参、响应信封、业务状态码、共享响应体。
> 各 `apis/*.md` 通过引用本文档避免重复展开。

---

## 通道与 BaseURL

| 名称 | URL | 环境 | 定义位置 |
|------|-----|------|---------|
| mHttpUrl (主站 API) | `http://dev-api.whiap.cn` | 开发 | `ContextConstant.kt:102` |
| apiBaseUrl (PPT 生成) | `https://zwapi.xfyun.cn` | 生产 | `AIPPTService.kt:32` |

- 主站所有业务接口走 `mHttpUrl`（用户/支付/产品/系统/广告/推送/反作弊等）
- PPT 生成走独立的讯飞 API（独立 baseUrl + 独立认证体系）
- 开发环境默认 `http://dev-api.whiap.cn`，生产环境通过动态配置切换

---

## 签名头 / 鉴权头

> 数据来源：RequestInterceptor 源码推断

### 主站鉴权

每次请求由 `RequestInterceptor` 自动注入以下 Header：

| Header 名 | 说明 | 生成方式 |
|-----------|------|---------|
| `token` | 登录 Token | 用户登录后由服务端下发，持久化在 MMKV `UserData.SP_TOKEN` |
| `ss` | HMAC-SHA256 请求签名 | 对请求体 + 时间戳做 HMAC-SHA256 (密钥 `z27vsnfeeb4nuxkjzfcd35nqvpx7xwd9`) |
| `tt` | 请求时间戳 | 当前毫秒时间戳 |
| `Content-Type` | `application/json; charset=utf-8` | 默认 JSON 请求 |

### 讯飞 PPT API 鉴权 (AIPPTService 专用)

| 参数 | 说明 | 来源 |
|------|------|------|
| `appId` | `4fe117ca` | 讯飞开放平台分配 | 
| `secret` | （已配置） | 讯飞开放平台分配 |
| 签名算法 | XXTEA 加密请求体 | `XXTeaUtils` 自实现，密钥 `f3224b4afb454344867954d0a4d38bf1` |

> ⚠ `appId` / `secret` / `XXTEA_KEY` 含凭证信息，不在此落值。

---

## 公共请求参数（platformInfo）

> 数据来源：源码 `platformInfo` 参数推断

所有主站接口请求体中自动合并 `platformInfo` 对象，字段如下：

| 字段 | 类型 | 说明 | 来源 |
|------|------|------|------|
| `user_id` | String | 用户 ID | `UserData.userId` |
| `user_channel` | String | 用户渠道 | 安装来源 |
| `from_channel` | String | 来源渠道 | 当前页面/场景标识 |
| `base_type` | String | 基础类型 | `ContextConstant.getBaseType()` |
| `new_user` | Int | 是否新用户 | 首次启动判断 |
| `phone_brand` | String | 手机品牌 | `Build.BRAND` |
| `phone_model` | String | 手机型号 | `Build.MODEL` |
| `version_code` | Int | App 版本号 | 包信息 |
| `os_version` | String | 系统版本 | `Build.VERSION` |
| `city_id` | String | 城市 ID | 定位信息（如有） |
| `province_id` | String | 省份 ID | 定位信息（如有） |
| `event_log_time` | Long | 事件时间戳 | 当前毫秒 |
| `event_name` | String | 事件名称 | 调用方指定 |

> ⚠ HMOS 侧对应：`deviceInfo.brand` / `deviceInfo.productModel` / `deviceInfo.osFullName` → `@kit.BasicServicesKit`；OAID → `identifier.getOAID()` (`@kit.AdsKit`)。

---

## 响应信封

所有主站接口使用统一响应格式 `BaseBean`：

| 字段 | 类型 | 说明 |
|------|------|------|
| `code` | Int | 业务状态码，0 = 成功 |
| `msg` | String | 提示信息（成功/失败原因） |
| `data` | Object | 业务数据体，根据端点不同映射到具体 Bean |

RxJava 层（`NetworkDispatchExt`）统一处理：code ≠ 0 时抛 `ApiException(code, msg)`，上层 ViewModel 统一 catch。

---

## 业务状态码

> 数据来源：源码 `ApiException` 状态码常量推断（部分）

| 状态码 | 常量名 | 含义 | 处理建议 |
|--------|--------|------|---------|
| 0 | — | 成功 | 正常处理 data |
| 1000 | `ApiException.UNKNOWN` | 未知错误 | 通用错误提示 |
| -605 | `LOGIN_INTERCEPT_CODE` | 未登录拦截 | 跳转登录页 |
| 60000 | `ERR_CODE_PAY_RESULT_USER_CANCEL` | 用户取消支付 | 提示支付已取消 |
| -100 | `ERR_CODE_ACTIVITY_FINISH` | Activity 已销毁 | 忽略结果 |
| -101 | `ERR_CODE_OPEN_PAY_PANNEL_FAIL` | 拉起支付面板失败 | 提示重试 |
| -102 | `ERR_CODE_OPEN_PAY_UNSUPPORT` | 不支持该支付方式 | 提示换支付方式 |
| -1 | `ERR_CODE_PAY_RESULT_FAIL` | 支付失败 | 提示支付失败 |
| -9 | `ERR_CODE_PAY_RESULT_PAGE_NULL` | 支付页面为空 | 订单异常 |
| -11 | `ERR_CODE_PAY_RESULT_THROW_EX` | 支付过程异常 | 提示重试 |
| -12 | `ERR_CODE_PAY_RESULT_UNSUPPORT` | 支付方式不支持 | 引导换支付方式 |

---

## 共享响应体（多端点复用）

### BaseBean — 通用响应

所有返回类型为 `Observable<BaseBean>` 的端点使用（仅 code/msg/data 三层）。

### UserData — 用户信息

> 被端点复用：initUser / bindAli / bindMobile / bindWx / getInfo / closeAccount / logout / bindHonor / bindHuawei / bindMobileByToken

| 字段 (JSON) | 类型 | 说明 |
|-------------|------|------|
| `token` | String | 登录 Token，持久化到 MMKV |
| `userId` | String | 用户 ID |
| `username` | String | 用户名 |
| `thirdPartyAuth` | Object | 三方认证信息（微信/支付宝/华为等绑定状态） |
| `vipLevel` | Int | VIP 等级（-10 = 默认未登录） |

### PptOutLineResBean — PPT 大纲响应

> 被端点复用：createOutLineByQuery / createOutLineByFile

共享于两种情况：文本查询生成大纲 和 文件上传生成大纲。

---

## 抓包状态标记说明

| 标记 | 含义 |
|------|------|
| ⬜ static-only | 仅从源码静态推断，未抓包验证（本 skill 产出默认状态） |
| ✅ verified | 已抓包，与 static 一致（由 `arkts-network-troubleshoot` 回填后刷新） |
| ⚠️ mismatch | 已抓包，与 static 有差异（差异明细见其 `api-contract-diff.md`） |
