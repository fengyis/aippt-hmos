# VIP 支付与金币经济接口

> 汇集 3 个 Service：`PayApiService` + `CoinIonApiService` + `FreeCountV2ApiService`
> 端点数：18 | 通道：`mHttpUrl` | 公共约定见 [../common.md](../common.md)
> 认证：Token + HMAC-SHA256 签名 | runtime：⬜ static-only

## 端点速览

### PayApiService（13 端点）

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/product/list` | paymentInfo | ⬜ |
| POST | `/pay/order/preCreate` | createOrder | ⬜ |
| POST | `/pay/order/cancelPayment` | cancelPayment | ⬜ |
| POST | `/pay/order/startUpPayError` | startUpPayError | ⬜ |
| POST | `/product/productFloat` | productFloat | ⬜ |
| POST | `/pay/order/getSignStatus` | renewStatus | ⬜ |
| POST | `/pay/order/unSign` | cancelRenew | ⬜ |
| POST | `/pay/order/refundPeriodOrder` | refundRenew | ⬜ |
| POST | `/system/aliAuthUrl` | getAliAuthUrl | ⬜ |
| POST | `/pay/super/fastRefundOrder` | fastRefundOrder | ⬜ |
| POST | `/pay/super/fastUnSign` | fastUnSign | ⬜ |
| POST | `/product/coinList` | getCoinList | ⬜ |
| POST | `/pay/order/queryOrderStatus` | queryOrderStatus | ⬜ |

### CoinIonApiService（3 端点）

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/productComm/coinPrice` | getCoinIon | ⬜ |
| POST | `/asset/deductCoinV2` | deductCoinV2 | ⬜ |
| POST | `/asset/refundCoin` | refundCoin | ⬜ |

### FreeCountV2ApiService（2 端点）

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/productComm/getFreeCountV2` | getFreeCountV2 | ⬜ |
| POST | `/productComm/useFreeCountV2` | useFreeCountV2 | ⬜ |

---

## PayApiService

### 1. paymentInfo — 获取 VIP 产品列表

- **方法**：`POST /product/list`（REST）
- **Service**：`PayApiService.paymentInfo`（PayApiService.kt:20）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| body | RequestBody | 是 | 产品查询条件（用户 ID + 来源场景 FROM_xxx） |
| _(公共)_ | — | — | + platformInfo → 见 common.md |

**响应参数**：`PaymentBean`（VIP 套餐列表，含产品 ID/名称/价格/时长/优惠信息）

---

### 2. createOrder — 预创建支付订单

- **方法**：`POST /pay/order/preCreate`
- **Service**：`PayApiService.createOrder`（PayApiService.kt:26）

**请求**：产品 ID + 支付渠道(ali/wx/huawei/honor/oppo) + 来源场景码(SCENE_CODE_P01~P08)

**响应**：`OrderInfoBean`（订单号/支付参数/签名，用于调起支付 SDK）

**特殊标注**：支付核心流程入口；preCreate → 调起 SDK → queryOrderStatus 轮询确认

---

### 3. cancelPayment — 取消支付订单

- **方法**：`POST /pay/order/cancelPayment`
- **Service**：`PayApiService.cancelPayment`（PayApiService.kt:32）
- **响应**：`BaseBean`

---

### 4. startUpPayError — 上报启动支付失败

- **方法**：`POST /pay/order/startUpPayError`
- **Service**：`PayApiService.startUpPayError`（PayApiService.kt:38）
- **响应**：`BaseBean`

---

### 5. productFloat — VIP 悬浮活动信息

- **方法**：`POST /product/productFloat`
- **Service**：`PayApiService.productFloat`（PayApiService.kt:44）
- **响应**：`VipFloatBean`（限时优惠/活动浮窗数据）

---

### 6. renewStatus — 查询自动续费签约状态

- **方法**：`POST /pay/order/getSignStatus`
- **Service**：`PayApiService.renewStatus`（PayApiService.kt:51）
- **响应**：`RenewSettingBean`

**特殊标注**：续费签约由三方支付渠道管理，后端记录签约状态。

---

### 7. cancelRenew — 取消自动续费

- **方法**：`POST /pay/order/unSign`
- **Service**：`PayApiService.cancelRenew`（PayApiService.kt:58）
- **响应**：`BaseBean`

---

### 8. refundRenew — 续费订单退款

- **方法**：`POST /pay/order/refundPeriodOrder`
- **Service**：`PayApiService.refundRenew`（PayApiService.kt:65）
- **响应**：`BaseBean`

---

### 9. getAliAuthUrl — 获取支付宝授权 URL

- **方法**：`POST /system/aliAuthUrl`
- **Service**：`PayApiService.getAliAuthUrl`（PayApiService.kt:71）
- **响应**：`AliAuthUrlBean`（支付宝授权跳转 URL）

> 返回的 URL 包含 `alipays://` scheme，用于跳转支付宝 App 授权。

---

### 10-11. fastRefundOrder / fastUnSign — 超级权限操作

- **fastRefundOrder**：`POST /pay/super/fastRefundOrder`（PayApiService.kt:77）
- **fastUnSign**：`POST /pay/super/fastUnSign`（PayApiService.kt:83）
- **响应**：`BaseBean`
- **特殊标注**：超级权限接口，后端需校验特殊权限

---

### 12. getCoinList — 金币充值套餐列表

- **方法**：`POST /product/coinList`
- **Service**：`PayApiService.getCoinList`（PayApiService.kt:89）
- **响应**：`PaymentBean`（金币套餐列表：面值/价格/赠送量）

---

### 13. queryOrderStatus — 订单支付状态查询

- **方法**：`POST /pay/order/queryOrderStatus`
- **Service**：`PayApiService.queryOrderStatus`（PayApiService.kt:102）
- **响应**：`BaseBean`

**特殊标注**：**轮询模式** — 支付 SDK 回调可能不可靠，客户端需轮询此接口确认支付结果。

---

## CoinIonApiService

### 14. getCoinIon — 获取金币价格

- **方法**：`POST /productComm/coinPrice`（REST）
- **Service**：`CoinIonApiService.getCoinIon`（CoinTools.kt:24）
- **特殊标注**：`suspend` 函数，Kotlin 协程调用
- **响应**：`CoinIonListBean`

---

### 15. deductCoinV2 — 扣除金币

- **方法**：`POST /asset/deductCoinV2`（REST）
- **Service**：`CoinIonApiService.deductCoinV2`（CoinTools.kt:30）
- **响应**：`BillBean`（账单记录）
- **特殊标注**：需保证幂等性，防止重复扣费

---

### 16. refundCoin — 退还金币

- **方法**：`POST /asset/refundCoin`（REST）
- **Service**：`CoinIonApiService.refundCoin`（CoinTools.kt:36）
- **响应**：`BillBean`

---

## FreeCountV2ApiService

### 17. getFreeCountV2 — 获取免费配额

- **方法**：`POST /productComm/getFreeCountV2`（REST）
- **Service**：`FreeCountV2ApiService.getFreeCountV2`（FreeCountV2ApiService.kt:23）
- **特殊标注**：`suspend` 函数
- **响应**：`CountConfigListBean`

---

### 18. useFreeCountV2 — 消耗免费配额

- **方法**：`POST /productComm/useFreeCountV2`（REST）
- **Service**：`FreeCountV2ApiService.useFreeCountV2`（FreeCountV2ApiService.kt:29）
- **响应**：`CountConfigBean`

> ⚠ V1/V2 两套并存：AppApiService 还有 freeCount / useCount（V1 `/privacy/*`），需统一迁移。
