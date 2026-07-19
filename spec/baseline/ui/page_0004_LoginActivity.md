---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.LoginActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/LoginActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_login.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0004_LoginActivity — 登录 (手机号+验证码+三方登录) (复杂度: 5/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.LoginActivity`
- **基类**: 推断 BaseActivity (含 CommonRequestInterceptor)
- **布局文件**: `activity_login.xml`
- **UI 快照**: ui-snapshots/page_0004_LoginActivity/
- **输出文件**: entry/src/main/ets/pages/LoginActivityPage.ets
- **页面类型**: full_screen_page（启动模式: FULL_SCREEN）
- **生命周期**: `onCreate` (初始化华为/荣耀登录SDK) → 手机号输入 → 发送验证码 (倒计时60s) → 登录请求 → 成功跳转/失败提示
- **关联服务**: PhoneNumberAuthService (fragment_tag), MiitHelper, WXHandler
- **三方SDK**: 华为账号 (HuaweiLoginButton), 荣耀账号, 支付宝登录, 微信登录

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent, color_user_page_bg)
├── TitleBar (id=titleBar, 返回箭头+居中标题)
├── TextView (id=tv_login_subtitle, "手机号登录", 24dp bold #0B2936)
├── TextView (id=tv_login_describe, 描述文案, 15dp #707070)
├── ShapeEditText (id=ed_login_phone, 手机号, 圆角15dp, maxLength=11)
│   └── ImageView (id=iv_clear_phone, 清除按钮, marginEnd=15dp)
├── ShapeEditText (id=ed_phone_code, 验证码, 圆角15dp)
│   └── TextView (id=tv_get_phone_code, "获取验证码", 倒计时60s)
├── TextView (id=btn_login, "登录", 57dp高, 圆角背景, #white)
├── CheckBox (id=cb_privacy, "我已阅读并同意 服务条款 和 隐私协议")
├── TextView (id=tv_quick_login, "快捷方式登录", #85949A)
├── Group (constraint_referenced_ids: tv_quick_login, iv_ali_login, iv_wechat_login)
│   ├── HuaweiLoginButton (id=iv_huawei_login, 58×58, gone)
│   ├── ImageView (id=iv_honor_login, 荣耀登录, 58×58, gone)
│   ├── ImageView (id=iv_ali_login, 支付宝登录, 58×58)
│   └── ImageView (id=iv_wechat_login, 微信登录, 58×58)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏表单页 |
| 标题栏 | TitleBar | titleBar | 返回 + 居中标题 |
| 副标题 | TextView | tv_login_subtitle | "手机号登录" |
| 描述 | TextView | tv_login_describe | 首次登录说明 |
| 手机号输入 | ShapeEditText | ed_login_phone | type=phone, maxLength=11, 圆角15dp |
| 清除按钮 | ImageView | iv_clear_phone | 一键清空手机号 |
| 验证码输入 | ShapeEditText | ed_phone_code | type=phone, 圆角15dp |
| 验证码按钮 | TextView | tv_get_phone_code | 60s倒计时，color_text_link |
| 登录按钮 | TextView | btn_login | 57dp, round_corner_bg, white文字 |
| 隐私协议 | CheckBox | cb_privacy | 含可点击协议链接 |
| 快捷登录标题 | TextView | tv_quick_login | 分隔行 |
| 可见性控制 | Group | — | 批量控制快捷登录区显隐 |
| 华为登录 | HuaweiLoginButton | iv_huawei_login | 华为账号一键登录 |
| 荣耀登录 | ImageView | iv_honor_login | 荣耀账号登录 |
| 支付宝登录 | ImageView | iv_ali_login | 支付宝授权登录 |
| 微信登录 | ImageView | iv_wechat_login | 微信授权登录 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Scroll + Column | 可滚动表单页 |
| 标题栏 | com.hjq.bar.TitleBar | Row 自定义标题栏 | SymbolGlyph(chevron_left) + Text |
| 手机号输入 | ShapeEditText (圆角15dp) | TextInput + .borderRadius(15) + .backgroundColor(White) | 带圆角白色输入框 |
| 清除按钮 | ImageView 约束于输入框内 | Stack + Image 条件显示 | 有内容时显示清除图标 |
| 验证码输入 | ShapeEditText | TextInput + maxLength(6) | 数字验证码 |
| 验证码按钮 | TextView 倒计时60s | Text + setInterval 倒计时 | 动态倒计时文案 |
| 登录按钮 | TextView 圆角背景 | Button + .borderRadius(28.5) | 主操作按钮 |
| 协议勾选 | CheckBox + 富文本 | Row(Checkbox + Text) | 支持部分文字可点击跳转 |
| 批量显隐 | Group (constraint_referenced_ids) | if 条件渲染 | 声明式显隐 |
| 三方登录 | 华为/荣耀/支付宝/微信 SDK | FWD-REF: Slice 4 Step 3d | 需对接三方SDK |
| 登录流程 | 短信发送 → 验证 → 登录请求 | Service 层 FWD-REF: Slice 4 Step 3d | 网络请求封装 |
| 协议跳转 | 服务条款/隐私协议链接 | NavPathStack.pushPathByName → WebView | FWD-REF: Slice 4 Step 3d |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | Row 自定义标题栏 | L2 |
| com.hjq.shape.view.ShapeEditText | TextInput + .borderRadius + .backgroundColor | L2 |
| cn.sanfate.pub.loginpay.widget.HuaweiLoginButton | @kit.AccountKit (华为账号) | L2 |
| 荣耀账号登录 SDK | 荣耀开发者服务 | C 类 |
| 支付宝 SDK | 支付宝开放平台 SDK | C 类 |
| 微信 SDK | 微信开放平台 SDK | C 类 |
| 短信验证码 | 云通讯/阿里云短信 | L2 |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| phoneNumber | string | 用户输入 | 手机号（11位数字） |
| smsCode | string | 用户输入 | 验证码（6位数字） |
| isAgreementChecked | boolean | CheckBox | 隐私协议确认 |
| smsCountdown | number | setInterval | 验证码倒计时 60-0 |
| isSmsSending | boolean | 网络请求 | 发送验证码 loading |
| isLoggingIn | boolean | 网络请求 | 登录中 loading |
| isQuickLoginVisible | boolean | 环境检测 | 快捷登录区显隐 |
| isHuaweiLoginVisible | boolean | HMS 检测 | 华为登录按钮显隐 |
| isHonorLoginVisible | boolean | 荣耀服务检测 | 荣耀登录按钮显隐 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | LoginActivity | Intent 跳转（需登录的业务页） | fromPage |
| OUT | 上一页 | 标题栏返回 / 登录成功 → pop | — |
| OUT → 首页 | page_0011_HomeActivity | 登录成功（无来源页时） | — |
| OUT → WebView | page_0002_WebViewActivity | 点击"服务条款"/"隐私协议" | url=协议URL |
| OUT → 三方授权 | 华为/荣耀/支付宝/微信 | 点击三方登录图标 | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，登录页全屏表单
- **ArkTS 方案**: `expandSafeArea` TOP，输入区域保持在安全区内
