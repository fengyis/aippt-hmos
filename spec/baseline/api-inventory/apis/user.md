# 用户认证与账号接口（UserApiService）

> Service：`UserApiService` | 文件：`network/src/main/java/cn/sanfate/pub/network/api/UserApiService.kt`
> 端点数：11 | 通道：`mHttpUrl` | 公共约定见 [../common.md](../common.md)
> 认证：Token + HMAC-SHA256 签名 | runtime：⬜ static-only

## 端点速览

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/user/initUser` | initUser | ⬜ |
| POST | `/user/bindAli` | bindAli | ⬜ |
| POST | `/user/bindMobileBySmsCode` | bindMobile | ⬜ |
| POST | `/user/bindWx` | bindWx | ⬜ |
| POST | `/user/getInfo` | getInfo | ⬜ |
| POST | `/user/closeAccount` | closeAccount | ⬜ |
| POST | `/user/logout` | logout | ⬜ |
| POST | `/user/bindHonor` | bindHonor | ⬜ |
| POST | `/user/bindHuawei` | bindHuawei | ⬜ |
| POST | `/user/bindMobileByToken` | bindMobileByToken | ⬜ |
| POST | `/system/needCheckPackage` | getPackageList | ⬜ |
| POST | `/system/upInstalledApp` | uploadAppList | ⬜ |

---

## 1. initUser — 初始化用户档案

- **方法**：`POST /user/initUser`
- **Service**：`UserApiService.initUser`（UserApiService.kt:16）
- **认证**：Token → 见 [common.md](../common.md)
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 用户初始化信息（设备指纹 + 安装来源） |
| _(公共)_ | — | — | + platformInfo → 见 common.md |

**响应参数**：`UserData`

| 字段 | 类型 | 说明 |
|------|------|------|
| token | String | 登录 Token |
| userId | String | 用户 ID |
| username | String | 用户名 |
| thirdPartyAuth | Object | 三方认证信息 |
| vipLevel | Int | VIP 等级 |

→ 完整 UserData 字段见 [common.md](../common.md) §共享响应体。

---

## 2. bindAli — 绑定支付宝

- **方法**：`POST /user/bindAli`
- **Service**：`UserApiService.bindAli`（UserApiService.kt:22）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 支付宝授权 code/token |
| _(公共)_ | — | — | + platformInfo |

**响应参数**：`UserData` → 见 common.md

---

## 3. bindMobile — 短信验证码绑定手机号

- **方法**：`POST /user/bindMobileBySmsCode`
- **Service**：`UserApiService.bindMobile`（UserApiService.kt:28）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 手机号 + 短信验证码 |

**响应参数**：`UserData` → 见 common.md

> 配合 `POST /system/sendSmsCode` 使用（先发验证码，再绑定）。

---

## 4. bindWx — 绑定微信

- **方法**：`POST /user/bindWx`
- **Service**：`UserApiService.bindWx`（UserApiService.kt:34）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 微信 OAuth authorization_code |

**响应参数**：`UserData` → 见 common.md

> 微信登录流程：客户端调微信 SDK 获取 code → 后端 `POST /user/bindWx` 交换 token。

---

## 5. getInfo — 获取用户信息

- **方法**：`POST /user/getInfo`
- **Service**：`UserApiService.getInfo`（UserApiService.kt:40）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 空请求体（或仅含公共参数） |

**响应参数**：`UserData` → 见 common.md

---

## 6. closeAccount — 注销账号

- **方法**：`POST /user/closeAccount`
- **Service**：`UserApiService.closeAccount`（UserApiService.kt:46）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 注销确认信息 |

**响应参数**：`UserData` → 见 common.md

---

## 7. logout — 退出登录

- **方法**：`POST /user/logout`
- **Service**：`UserApiService.logout`（UserApiService.kt:52）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 退出请求 |

**响应参数**：`UserData` → 见 common.md

---

## 8. bindHonor — 绑定荣耀账号

- **方法**：`POST /user/bindHonor`
- **Service**：`UserApiService.bindHonor`（UserApiService.kt:58）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 荣耀授权 token |

**响应参数**：`UserData` → 见 common.md

---

## 9. bindHuawei — 绑定华为账号

- **方法**：`POST /user/bindHuawei`
- **Service**：`UserApiService.bindHuawei`（UserApiService.kt:64）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 华为授权 token |

**响应参数**：`UserData` → 见 common.md

---

## 10. bindMobileByToken — 运营商一键登录

- **方法**：`POST /user/bindMobileByToken`
- **Service**：`UserApiService.bindMobileByToken`（UserApiService.kt:70）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 运营商返回的 Token（阿里一键登录/华为一键登录） |

**响应参数**：`UserData` → 见 common.md

> 迁移关注点：阿里一键登录 SDK → 需鸿蒙版或华为 Account Kit 替代。

---

## 11. getPackageList / uploadAppList — 安全风控

- **getPackageList** — `POST /system/needCheckPackage`（UserApiService.kt:76）
  - 检查是否需要上报应用安装列表（安全风控），返回 `PackageListBean`
- **uploadAppList** — `POST /system/upInstalledApp`（UserApiService.kt:82）
  - 上报已安装应用列表，返回 `BaseBean`

> ⚠ HMOS 侧受限：应用安装列表收集在 HarmonyOS 中不可用，需重新设计风控方案。
