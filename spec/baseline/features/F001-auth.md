# F001 — 认证登录

```yaml
complexity: complex
tier: standard
depth: full

android_source_anchors:
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/viewmodel/LoginViewModel.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/LoginActivity.kt"
  - role: presenter/viewmodel
    path: "app/src/main/java/cn/sanfate/pub/platform/page/AccountInfoActivity.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/network/api/UserApiService.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/event/track/api/AppApiService.kt"
  - role: service/repository
    path: "app/src/main/java/cn/sanfate/pub/loginpay/service/PayApiService.kt"
  - role: interceptor
    path: "app/src/main/java/cn/sanfate/pub/network/KViewModel.kt"
  - role: base_class
    path: "app/src/main/java/cn/sanfate/pub/baseui/activity/BaseBusinessActivity.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/network/bean/UserData.kt"
  - role: util
    path: "app/src/main/java/cn/sanfate/pub/common/GsonUtil.kt"
```

## 范围

### 涉及页面
| 序号 | Android 页面 | ArkTS 目标 |
|------|-------------|-----------|
| 0004 | `LoginActivity` | `LoginPage.ets` |
| 0005 | `AccountInfoActivity` | `AccountInfoPage.ets` |

### 依赖
- **feature-base**: 共享基础设施 — `UserData` 单例模式、`UserApiService`、`AppApiService` 网络层、`BaseBusinessActivity` 基类、`GsonUtil` 序列化

### 关联 Feature
- F003 (首页导航): 首页 `onResume` 触发 `homeViewModel.initUser()` 登录状态检查
- F002 (会员支付): 下订单前 `MemberCenterViewModel.createOrder()` 校验 `UserData.isBinding() + interceptAuth` 未登录跳转 `LoginActivity`
- F004 (PPT核心): `CreateOutLinePage.createOutlinePage()` 入口校验 `UserData.isBinding() + interceptAuth`

## 数据流

```
用户输入手机号 + 验证码
  ↓
LoginActivity.onClick(R.id.btn_login)
  ↓ precheck: checkPrivacy() — cbPrivacy 必须勾选
LoginViewModel.bindPhone(phone, smsCode)
  ↓
UserApiService.bindMobile(requestBody)
  ↓ netResult { success → saveUserInfo(it); loginLiveData.value = true }
  ↓
LoginActivity.initObserver: loginLiveData → finish() 关闭页面
  ↓
UserData.getInstance() 持有当前用户 token/vipLevel/fromChannel 等全局状态

三方登录（支付宝/微信/荣耀/华为）:
LoginActivity.onClick(R.id.iv_ali_login / iv_wechat_login / iv_honor_login / iv_huawei_login)
  ↓
LoginViewModel.fetchAliLoginInfo() / wechatLogin() / honorLogin() / huaweiLogin()
  ↓ SDK 授权回调
UserApiService.bindAli / bindWx / bindHonor / bindHuawei
  ↓
saveUserInfo(it) → loginLiveData = true

登出:
AccountInfoActivity.onClick(R.id.tv_login_out)
  ↓ showOperateTips("确定要退出登录吗?")
LoginViewModel.loginOut()
  ↓
UserApiService.logout(requestBody)
  ↓ saveUserInfo(it) → loginLiveData = true → finish()

账号注销:
AccountInfoActivity.onClick(R.id.tv_delete_account)
  ↓ showOperateTips → showAgainConfirmDialog (两步确认)
LoginViewModel.deleteAccount()
  ↓
UserApiService.closeAccount(requestBody)
```

### 验证码倒计时（60秒）
```
LoginViewModel.sendSmsCode(phone)
  ↓ phoneCodeLiveData = true
LoginActivity.countDown()
  ↓ CountDownTimer(60s, 1s)
60s 后恢复按钮文字为 "获取验证码"
```

## 服务层

### ArkTS 目标接口签名

```typescript
// AuthService.ets — 认证服务层
class AuthService {
  /** 发送短信验证码 */
  sendSmsCode(phoneNumber: string): Promise<BaseResult<void>>
  /** 手机号+验证码登录 */
  bindPhone(phoneNumber: string, smsCode: string): Promise<UserDataModel>
  /** 第三方绑定 — 支付宝 */
  bindAliCode(authCode: string): Promise<UserDataModel>
  /** 第三方绑定 — 微信 */
  bindWechat(accessToken: string, openId: string): Promise<UserDataModel>
  /** 第三方绑定 — 荣耀 */
  bindHonor(authJson: string): Promise<UserDataModel>
  /** 第三方绑定 — 华为 */
  bindHuawei(authorizationCode: string): Promise<UserDataModel>
  /** 初始化用户（无登录态时） */
  initUser(): Promise<UserDataModel>
  /** 退出登录 */
  logout(): Promise<void>
  /** 注销账号 */
  deleteAccount(): Promise<void>
  /** 获取支付宝授权 URL（须在 SDK 授权完成后调用 bindAliCode） */
  fetchAliAuthUrl(): Promise<string>
  /** 校验手机号格式（11 位，1[3-9]\d{9}） */
  validatePhone(phone: string): boolean
}

// LoginState.ets — 登录页面状态
@ObservedV2
class LoginState {
  @Trace phoneNumber: string = ''
  @Trace smsCode: string = ''
  @Trace privacyChecked: boolean = false
  @Trace countdown: number = 0       // 倒计时秒数，0=未开始
  @Trace isLoading: boolean = false
  @Trace loginSuccess: boolean = false
  @Trace errorMessage: string = ''
}
```

### Room/LiveData → ArkTS 映射
| Android | ArkTS |
|---------|-------|
| `LoginViewModel.phoneCodeLiveData` | `LoginState.countdown` / `EventHub.emit('smsSent')` |
| `LoginViewModel.loginLiveData` | `LoginState.loginSuccess` → `navPathStack.pop()` |
| `LoginViewModel.loadingStatusLiveData` | `LoginState.isLoading` |
| `UserData.getInstance()` 单例 | `AppStorageV2.connect(UserDataModel, 'user', () => new UserDataModel())` |
| `CountDownTimer` | `setInterval()` / `@Local countdown` |

## API 接口

| Method | Endpoint (相对路径) | Description | 鉴权 |
|--------|-------------------|-------------|------|
| POST | `/user/init` | 初始化用户信息 | Body 公参 |
| POST | `/user/bindMobile` | 手机号+验证码绑定 | Body 公参 |
| POST | `/user/bindWx` | 微信绑定 | Body 公参 |
| POST | `/user/bindAli` | 支付宝绑定 | Body 公参 |
| POST | `/user/bindHonor` | 荣耀绑定 | Body 公参 |
| POST | `/user/bindHuawei` | 华为绑定 | Body 公参 |
| POST | `/user/logout` | 退出登录 | Body 公参 |
| POST | `/user/closeAccount` | 注销账号 | Body 公参 |
| POST | `/sms/send` | 发送短信验证码 | Body 公参 |
| POST | `/pay/aliAuthUrl` | 获取支付宝授权 URL | Body 公参 |

> 注：Android 端 Retrofit 接口类 `UserApiService` 和 `AppApiService` 由 platform SDK 提供，具体 URL path 需从 `cn.sanfate.pub.network` 包反查或由后端提供 OpenAPI spec。上表路径为推断。

## 实现映射

| 源（Android/Kotlin） | ArkTS 目标 | 说明 |
|---------------------|-----------|------|
| `LoginActivity.openLoginPage(activity)` | `navPathStack.pushPathByName('LoginPage', new NoParam())` | 导航到登录页 |
| `LoginActivity.checkPrivacy()` | `if (!this.loginState.privacyChecked) { toast(...); return }` | 隐私协议勾选校验 |
| `LoginActivity.countDown()` | `startCountdown()` — setInterval 每 1s 递减 `@Local countdown` | 60s 验证码倒计时 |
| `LoginViewModel.sendSmsCode(phone)` | `authService.sendSmsCode(phone)` 后 `loginState.countdown = 60` | 发送验证码 |
| `LoginViewModel.bindPhone(phone, code)` | `authService.bindPhone(phone, code).then(user => loginState.loginSuccess = true)` | 手机号登录 |
| `LoginViewModel.fetchAliLoginInfo()` | `authService.fetchAliAuthUrl().then(url => aliSdk.auth(url)).then(code => authService.bindAliCode(code))` | 支付宝登录 |
| `LoginViewModel.wechatLogin()` | `wxSdk.authorize().then(resp => authService.bindWechat(resp.accessToken, resp.openId))` | 微信登录 |
| `LoginViewModel.honorLogin()` | `honorSdk.login().then(authJson => authService.bindHonor(authJson))` | 荣耀登录 |
| `LoginViewModel.huaweiLogin(activity)` | `huaweiSdk.signIn().then(code => authService.bindHuawei(code))` | 华为登录 |
| `LoginViewModel.loginOut()` | `authService.logout().then(() => { UserDataModel.clear(); loginState.loginSuccess = true })` | 登出 |
| `LoginViewModel.deleteAccount()` | `authService.deleteAccount().then(() => { UserDataModel.clear(); loginState.loginSuccess = true })` | 注销 |
| `AccountInfoActivity` 展示用户信息 | `AccountInfoPage` 绑定 `UserDataModel` 字段 | 用户 ID/VIP 等级/VIP 剩余天数 |
| `AccountInfoActivity.showOperateTips()` | `this.getUIContext().showAlertDialog(...)` | 确认弹窗 |
| `AccountInfoActivity.showAgainConfirmDialog()` | `this.getUIContext().showAlertDialog(...)` 嵌套确认 | 注销二次确认 |
| `cbPrivacy.text` 服务条款+隐私协议 span | `Text() { Span('服务条款').onClick(...); Span(' 和 '); Span('隐私协议').onClick(...) }` | 可点击协议链接 |

## 状态管理

```typescript
// AppStorageV2 全局 key
class StorageKeys {
  static readonly USER_DATA = 'user_data'        // UserDataModel
}

@ObservedV2
class UserDataModel {
  @Trace userId: number = 0
  @Trace token: string = ''
  @Trace nickname: string = ''
  @Trace avatar: string = ''
  @Trace vipLevel: number = 0                    // 0=普通, 1=VIP?, 2=VIP
  @Trace vipDayRemain: string = ''
  @Trace fromChannel: string = ''
  @Trace phone: string = ''
  @Trace isLogin: boolean = false
  @Trace isBinding: boolean = false
  @Trace interceptAuth: number = 0               // 1=开启登录拦截
  // 内部记账字段（不加 @Trace）
  tqv: string = ''
  preTrack: number = 0
  showAd: number = 0
  blackItemNums: number = 0

  static isVip(): boolean { return this.vipLevel >= 2 }
  static getInstance(): UserDataModel { /* AppStorageV2.connect */ }
  saveUserInfo(data: UserDataModel): void { /* 逐字段赋值 */ }
  clear(): void { /* 重置所有字段 */ }
}
```

## 对接点

| UI 页面 @Local / @Param | 对应 ArkTS 页面 | 数据类型 | 说明 |
|------------------------|---------------|---------|------|
| `loginState: LoginState` | `LoginPage.ets` | `@Local LoginState` | 登录页内部状态 |
| `user: UserDataModel` | `LoginPage.ets`, `AccountInfoPage.ets` | `AppStorageV2.connect` | 全局用户状态 |
| `privacyChecked: boolean` | `LoginPage.ets` | `@Local` (Checkbox onChange) | 隐私协议勾选 |
| `countdown: number` | `LoginPage.ets` | `@Local` | 验证码倒计时显示 |
| `phoneNumber: string` | `LoginPage.ets` | `@Local` (TextInput onChange) | 手机号输入 |
| `smsCode: string` | `LoginPage.ets` | `@Local` (TextInput onChange) | 验证码输入 |
| `isVip: boolean` | `AccountInfoPage.ets` | `AppStorageV2.connect` user.vipLevel >= 2 | VIP 状态显示 |
| `vipDayRemain: string` | `AccountInfoPage.ets` | `AppStorageV2.connect` user.vipDayRemain | VIP 到期时间 |

## 验收标准

| # | 验收条件 | 源 | 标 |
|---|---------|----|----|
| AC-1 | 手机号输入框校验：空值提示"手机号不能为空"，不足 11 位提示"请填写完整的手机号"，格式不匹配提示"手机号码错误" | `LoginViewModel.checkPhone()` L157-171 | `LoginPage.ets` validatePhone → toast |
| AC-2 | 隐私协议未勾选时点击任何登录按钮均 toast"请先同意服务条款和隐私政策" | `LoginActivity.checkPrivacy()` L149-155 | `LoginPage.ets` btnLogin.onClick → if (!privacyChecked) toast |
| AC-3 | 点击"获取验证码"发送成功后按钮置灰、文字变为倒计时秒数（60s），倒计时结束恢复为"获取验证码"且可点击 | `LoginActivity.countDown()` L160-177 | `LoginPage.ets` countdown > 0 ? `${countdown}s` : $r('app.string.get_code') |
| AC-4 | 手机号+验证码登录成功后自动关闭页面回到上一页 | `LoginActivity.kt` L81-84: `loginViewModel.loginLiveData.observe(this) { ... finish() }` | `LoginPage.ets` loginState.loginSuccess → navPathStack.pop() |
| AC-5 | 支付宝授权回调 `resultStatus=9000` + `result_code=200` 后调用 `bindAliCode`，成功 toast"支付宝登录成功" | `LoginViewModel.launchAliLogin()` L242-284 | `AuthService.fetchAliAuthUrl` → aliSdk → `bindAliCode` |
| AC-6 | 微信授权回调 `onComplete(AccessTokenResponse)` 后调用 `bindWx`，成功 toast"微信登录成功" | `LoginViewModel.onComplete()` L334-338 | `AuthService.bindWechat(token, openId)` |
| AC-7 | 登录成功后 `UserData.getInstance().saveUserInfo(it)` 更新全局单例 | `LoginViewModel.saveUserInfo()` L58-79 | `UserDataModel.saveUserInfo(data)` → AppStorageV2 自动同步 |
| AC-8 | AccountInfoPage 展示 userId、VIP 等级文字（"高级会员"/"普通会员"）、VIP 到期时间、升级入口（非 VIP 可见） | `AccountInfoActivity.initView()` L31-39 | `AccountInfoPage.ets` 绑定 `user` 字段，`tvUpdateVip` visibility = !isVip |
| AC-9 | 点击退出登录弹出确认弹窗，确认后调用 `loginOut` 接口、成功后关闭页面 | `AccountInfoActivity.onClick(R.id.tv_login_out)` L64-68 | `AccountInfoPage.ets` AlertDialog confirm → authService.logout → pop |
| AC-10 | 注销账号需两步确认：第一步提示"确定要注销账号吗？"，第二步展示注销影响告知，确认后调用 `deleteAccount` | `AccountInfoActivity.showAgainConfirmDialog()` L91-105 | `AccountInfoPage.ets` 嵌套 AlertDialog → authService.deleteAccount |
