# F002 — 会员支付

```yaml
complexity: complex
tier: core
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/MemberCenterActivitiy.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/ManageRenewActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/RefundProgressActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/MemberCenterViewModel.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/loginpay/viewmodel/BaseMemberViewModel.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/loginpay/service/PayApiService.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/RenewManageViewModel.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/MemberCenterViewModel.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/network/bean/UserData.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/loginpay/bean/ProductBean.kt"
```

## 范围

### 涉及页面
| 序号 | Android 页面 | ArkTS 目标 |
|------|-------------|-----------|
| 0006 | `MemberCenterActivitiy` | `MemberCenterPage.ets` |
| 0009 | `ManageRenewActivity` | `ManageRenewPage.ets` |
| 0010 | `RefundProgressActivity` | `RefundProgressPage.ets` |

### 依赖
- **feature-base**: `UserData` 单例、`PayApiService` 网络层、`BaseBusinessActivity` 基类、`EventBus` 事件系统（`PaySuccessEvent`、`LimitCampaignEvent`、`LimitGiftEvent`）、`MMKVUtil` 持久化
- **F001 (认证登录)**: 会员中心下单前须校验登录态 `UserData.isBinding() + interceptAuth == 1 → LoginActivity.openLoginPage`

### 关联 Feature
- F003 (首页导航): `HomeActivity` 持有 `MemberCenterViewModel` 处理首页 VIP 弹窗支付 (`limitCreateOrder`、`showCampaignDialog`、`showLimitDialog`)
- F004 (PPT核心): `CreateOutLinePage.createOutlinePage()` 无免费次数时跳 `MemberCenterActivitiy.openMemberCenter(FROM_CREATE_OUTLINE)`

## 数据流

```
用户进入会员中心
  ↓
MemberCenterActivitiy.onClick → MemberCenterActivitiy.openMemberCenter(activity, payFrom)
  ↓ gate: UserData.isVip() → "已经是会员了" 直接 return
  ↓
MemberCenterActivitiy.initView()
  ↓ EventBus.getDefault().register(this) — 监听 WXPayEvent, PaySuccessEvent
  ↓ centerViewModel.paymentInfo(payFrom)
  ↓ MemberCenterViewModel.getVipProductList(payFrom)
  ↓ PayApiService 返回 product list
  ↓
MemberCenterActivitiy.showPaymentInfo(paymentBean)
  ↓ 构建 RecyclerView adapter（横向滚动产品卡片）
  ↓ 区分托收产品(retainProductBean)和限时优惠产品(limitProductBean)
  ↓ 选中默认产品，触发 VIP 动画序列（firstVipAnimator → ... → eightVipAnimator）

用户选择产品 + 支付方式（微信/支付宝）
  ↓
MemberCenterActivitiy.onClick(R.id.btnGotoPay) → createOrder()
  ↓ precheck: ivAgreementCheck.isSelected（协议勾选）
  ↓ 未勾选 → PayAgreementDialog.show()
  ↓ 托收商品 → RenewRuleDialog.show() 展示续费规则
  ↓
MemberCenterViewModel.createOrder(activity, payFrom, productId, paymentChannel, productType)
  ↓ gate: UserData.isBinding() + interceptAuth == 1 → LoginActivity.openLoginPage
  ↓ BaseMemberViewModel.createPreOrder(...)
  ↓ 拉起对应支付 SDK（微信/支付宝/华为/荣耀）
  ↓

支付结果回调:
  ├─ 微信: EventBus @Subscribe wechatPayResult(WXPayEvent)
  ├─ 支付宝: PayResult? (sdk callback)
  ├─ 华为: onActivityResult(PayContants.HUAWEI_PAY_REQUEST_CODE) → HuaweiSdkService.handlePayResult
  └─ 荣耀: onActivityResult(PayContants.HONOR_PAY_REQUEST_CODE) → HonorSdkService.handlePayResult
  ↓ paySuccess()
  ↓ UserData.getInstance().vipLevel = 2
  ↓ EventBus.getDefault().post(PaySuccessEvent(true))
  ↓ finish()

续费管理:
ManageRenewActivity.onResume → renewManageViewModel.requestRenewInfo()
  ↓ 展示签约状态(signStatus):
  │   签约中 → 显示续费信息 + "取消续费"按钮
  │   未签约 + canRefund=1 → "申请退款"按钮
  │   未签约 + 非VIP → "购买VIP"按钮
  ├─ 取消续费 → showPermissionDialog(0) → RefundProgressActivity.start(operateType=0, ...)
  └─ 申请退款 → showPermissionDialog(1) → RefundProgressActivity.start(operateType=1, ...)

退款进度:
RefundProgressActivity → operateType=0: renewViewModel.cancelRenew(renewId)
                       operateType=1: RenewRefundReasonDialog → renewViewModel.refundRenew(renewId, reason)
  ↓ observe refundLiveData
  ↓ success → 展示成功状态 / fail → 展示失败 + 重试

退出会员中心（未支付）:
MemberCenterActivitiy.finishActivity()
  ↓ 未 VIP + 非审核态:
  │   limitProductBean存在 + 退出次数 ≤ 1 → postSticky(LimitGiftEvent)
  │   否则 retainProductBean存在 + (退出次数 > 1 或 ppt 次数 ≤ 0) → postSticky(LimitCampaignEvent)
  ↓ HomeActivity 收到 sticky event 展示挽留弹窗
```

## 服务层

### ArkTS 目标接口签名

```typescript
// VipService.ets — 会员支付服务层
class VipService {
  /** 获取会员产品列表 */
  fetchProductList(payFrom: string): Promise<ProductListResult>
  /** 创建订单（预下单） */
  createOrder(payFrom: string, productId: string, paymentChannel: number, productType: number): Promise<OrderResult>
  /** 取消支付 */
  cancelPayment(errorCode: string): Promise<void>
  /** 获取支付渠道列表 */
  getPayChannelList(paymentChannel: number): number[]
}

// RenewService.ets — 续费管理服务层
class RenewService {
  /** 查询续费信息 */
  requestRenewInfo(): Promise<RenewInfoResult>
  /** 取消续费 */
  cancelRenew(renewId: string): Promise<BaseResult>
  /** 申请退款 */
  refundRenew(renewId: string, reason: string): Promise<BaseResult>
}

// VipState.ets — 会员页面状态
@ObservedV2
class VipState {
  @Trace products: ProductBean[] = []
  @Trace selectedIndex: number = 0
  @Trace paymentChannel: number = 1       // 1=微信, 2=支付宝
  @Trace agreementChecked: boolean = false
  @Trace isLoading: boolean = false
  @Trace paySuccess: boolean = false
  @Trace renewInfo: RenewInfoResult | null = null
  @Trace refundStatus: RefundStatus = RefundStatus.IDLE  // IDLE/LOADING/SUCCESS/FAILED
  @Trace refundReason: string = ''
}

@ObservedV2
class ProductBean {
  @Trace productId: string = ''
  @Trace showNowPrice: string = ''
  @Trace showBtn: string = '立即开通'
  @Trace showDesc: string = ''
  @Trace selected: boolean = false
  @Trace payMethod: number = 1
  @Trace paymentChannel: number = 1
  @Trace isCt: boolean = false
  extJson: string = ''
  static fromJson(json: object): ProductBean { /*...*/ }
}
```

### RecyclerView adapter → ArkTS 映射
| Android | ArkTS |
|---------|-------|
| `productAdapter = linear(HORIZONTAL).divider.setup { ... }` | `List({ space: 10 }).listDirection(Axis.Horizontal)` + `ForEach(products, (p: ProductBean) => { ProductCard({ product: p }) })` |
| `productAdapter.singleMode = true` | 选中状态由 `ProductBean.selected` + `@Trace` 驱动，点击更新 |
| `productAdapter.getCheckedModels()` | `products.find(p => p.selected)` |
| `model.notifyChange()` | `@Trace` 自动刷新 |
| `TickerView` 数字滚动动画 | `Text` + `animateTo()` 数字变化过渡 |

## API 接口

| Method | Endpoint (推断) | Description |
|--------|----------------|-------------|
| POST | `/pay/productList` | 获取产品列表（按 payFrom 返回不同配置） |
| POST | `/pay/preCreateOrder` | 创建预支付订单 |
| POST | `/pay/cancelOrder` | 取消订单 |
| POST | `/pay/productFloat` | 获取 VIP 浮窗信息（`VipFloatBean`） |
| GET | `/renew/info` | 查询续费签约信息 |
| POST | `/renew/cancel` | 取消自动续费 |
| POST | `/renew/refund` | 申请退款 |

> 注：Android 端接口由 `PayApiService` 和 `cn.sanfate.pub.loginpay` 包提供。

## 实现映射

| 源（Android/Kotlin） | ArkTS 目标 | 说明 |
|---------------------|-----------|------|
| `MemberCenterActivitiy.openMemberCenter(activity, payFrom)` | `navPathStack.pushPathByName('MemberCenterPage', payFromParam)` | 导航到会员中心 |
| `UserData.isVip()` gate | `user.vipLevel >= 2` → toast "已经是会员了" + return | VIP 状态门禁 |
| `centerViewModel.paymentInfo(payFrom)` | `vipService.fetchProductList(payFrom).then(list => vipState.products = list)` | 加载产品列表 |
| `productAdapter` 横向 RecyclerView | `List().listDirection(Axis.Horizontal).space(10)` + `ProductCard` 组件 | 产品卡片横向滚动 |
| `productAdapter.singleMode = true` + `setChecked` | `ProductBean.selected = true` → `@Trace` 驱动 UI | 单选模式 |
| `changePayMethod(PAY_CHANNEL.WECHAT_PAY.way)` | `vipState.paymentChannel = 1` → `ivWechatCheck.isSelected` = channel == 1 | 支付方式切换 |
| `ivAgreementCheck.isSelected` | `vipState.agreementChecked = !vipState.agreementChecked` (Toggle/Checkbox) | 协议勾选 |
| `PayAgreementDialog` | `this.getUIContext().showAlertDialog({ title: '请先同意协议', ... })` | 协议未勾选弹窗 |
| `RenewRuleDialog` — 托收商品续费规则 | `showAlertDialog` 展示 `agreementDetailItem` 信息 | 续费规则确认弹窗 |
| `MemberCenterViewModel.createOrder(...)` | `vipService.createOrder(payFrom, productId, paymentChannel, productType)` | 发起支付 |
| `EventBus PaySuccessEvent` | `EventHub.emit('paySuccess', {})` 或 `AppStorageV2` 更新触发全局回调 | 支付成功通知 |
| `user.vipLevel = 2` + `EventBus.post(PaySuccessEvent(true))` | `user.vipLevel = 2` → `EventHub.emit('paySuccess')` → 各监听页更新 UI | 支付成功后状态同步 |
| 微信支付 `WXPayEvent` subscriber | `wxPaySdk.pay(orderInfo).then(ok => onPaySuccess()).catch(err => onPayFail(err))` | 微信支付回调 |
| 华为支付 `onActivityResult` | `huaweiPaySdk.pay(orderInfo).then(...)` Promise 封装 | 华为支付回调 |
| VIP 动画序列 `firstVipAnimator → ... → eightVipAnimator` | `animateTo()` 链式调用 + `TransitionEffect` | VIP 限时优惠入场动画（可选迁移，非核心逻辑） |
| `ManageRenewActivity` 续费状态展示 | 3 态 if/else: `signStatus==1`→续费中面板, `canRefund==1`→退款入口, 否则→购买VIP | 续费管理页 |
| `RefundProgressActivity` 进度展示 | `RefundStatus` 枚举驱动 UI 切换（进度中/成功/失败+重试） | 退款进度页 |
| `finishActivity()` 退出挽留 | 暂存 `retainProductBean`/`limitProductBean` → `EventHub.emit('vipRetain', productBean)` | 退出挽留弹窗（HomePage 监听） |
| `MMKVUtil.encodeBool/decodeBool` | `PersistenceV2.globalConnect` 或 `preferences` | VIP 动画已展示标记持久化 |

## 状态管理

```typescript
// AppStorageV2 全局 key
class StorageKeys {
  static readonly USER_DATA = 'user_data'      // UserDataModel (复用 F001)
}

// 支付事件
class PayEventConstants {
  static readonly PAY_SUCCESS = 'paySuccess'
  static readonly LIMIT_CAMPAIGN = 'limitCampaign'   // 限时优惠挽留
  static readonly LIMIT_GIFT = 'limitGift'            // 限时赠品挽留
}

// VIP 持久化配置
@ObservedV2
class VipConfig {
  @Trace vipCenterFullAnimation: boolean = false  // VIP 动画是否已展示
  @Trace vipCenterBackCount: number = 0           // 会员中心退出次数
  @Trace vipCenterRetainShown: string = ''        // 挽留弹窗是否已展示
}

enum RefundStatus { IDLE, LOADING, SUCCESS, FAILED }
```

## 对接点

| UI 页面 @Local / @Param | 对应 ArkTS 页面 | 数据类型 | 说明 |
|------------------------|---------------|---------|------|
| `vipState: VipState` | `MemberCenterPage.ets` | `@Local VipState` | 会员中心页面状态 |
| `products: ProductBean[]` | `MemberCenterPage.ets` | `@Local` (from VipState) | 产品列表 |
| `selectedIndex: number` | `MemberCenterPage.ets` | 由 ProductBean.selected 驱动 | 选中的产品 |
| `paymentChannel: number` | `MemberCenterPage.ets` | `@Local` | 当前支付方式（1=微信/2=支付宝） |
| `agreementChecked: boolean` | `MemberCenterPage.ets` | `@Local` (Checkbox/Toggle) | 协议勾选状态 |
| `payFrom: string` | `MemberCenterPage.ets` | `@Param` (路由参数) | 支付来源标识 |
| `renewInfo: RenewInfoResult` | `ManageRenewPage.ets` | `@Local` | 续费管理状态 |
| `refundStatus: RefundStatus` | `RefundProgressPage.ets` | `@Local` | 退款进度状态 |
| `operateType: number` | `RefundProgressPage.ets` | `@Param` (路由参数 0=取消续费 1=退款) | 操作类型 |
| `vipConfig: VipConfig` | `HomePage.ets` (跨页) | `PersistenceV2.globalConnect` | 挽留弹窗配置 |

## 验收标准

| # | 验收条件 | 源 | 标 |
|---|---------|----|----|
| AC-1 | 已是 VIP 用户进入会员中心 toast"已经是会员了"直接 return 不跳转 | `MemberCenterActivitiy.openMemberCenter()` L136-139 | `MemberCenterPage` pushPath 前 gate: `user.vipLevel >= 2 → toast + return` |
| AC-2 | 产品列表横向滚动展示，每项显示价格/原价/周期信息 | `productAdapter = linear(HORIZONTAL).setup { ... }` L249-309 | `List().listDirection(Axis.Horizontal)` + `ProductCard` 组件 |
| AC-3 | 点击产品卡片选中（单选模式），不可取消选中（已选中不移除） | `onClick(R.id.bg_product) { if (!model.selected) setChecked(...) }` L287-298 | `product.selected = true`（不处理 false），`@Trace` 自动刷新 |
| AC-4 | 支付方式切换：点击微信/支付宝对应选中高亮 | `changePayMethod(pay)` L553-557 | `vipState.paymentChannel = pay` → Radio/Check icon 条件渲染 |
| AC-5 | 协议未勾选时点击"立即开通"弹出 `PayAgreementDialog` | `createOrder()` L381-390 | if (!`agreementChecked`) → `showAlertDialog` |
| AC-6 | 托收商品（签约自动续费）下单前展示 `RenewRuleDialog` | `createOrder()` L393-408 | if (`product.payMethod != 1`) → `showAlertDialog` 展示续费规则 |
| AC-7 | 支付成功 → `vipLevel = 2` → `EventHub.emit('paySuccess')` → `finish()` | `paySuccess()` L610-614 | `user.vipLevel = 2` → `EventHub.emit(PayEventConstants.PAY_SUCCESS)` → `navPathStack.pop()` |
| AC-8 | 续费管理页：签约中状态显示续费信息（到期时间/价格/支付方式/扣款方式）+ 取消续费按钮 | `ManageRenewActivity.initObserver()` L40-64 | `ManageRenewPage` 3 态 if/else 分支 |
| AC-9 | 取消续费确认弹窗 → RefundProgressPage(operateType=0) → 调用 `cancelRenew` | `showPermissionDialog(0)` L89-110 | AlertDialog confirm → push RefundProgressPage(renewId, operateType: 0) |
| AC-10 | 退款理由选择弹窗 → 填写理由后调用 `refundRenew` (operateType=1) | `showUpdateDialog()` L86-117 | `RenewRefundReasonDialog` → push RefundProgressPage(renewId, operateType: 1, reason) |
| AC-11 | 退款/取消成功后显示相应成功文字 + 操作按钮（"我知道了"/"申请退款"） | `refundSuccess()` L133-164 | `refundStatus == SUCCESS` → 成功 UI + 按 operateType 切换按钮文字 |
| AC-12 | 退款/取消失败显示失败原因 + "重试"按钮 | `refundSuccess()` L153-163 | `refundStatus == FAILED` → 失败 UI + retryButton.onClick → `operate()` |
| AC-13 | 未登录用户下单时跳转登录页 | `MemberCenterViewModel.createOrder()` L35-38 | if (!`user.isBinding` && `user.interceptAuth == 1`) → `navPathStack.pushPathByName('LoginPage')` |
