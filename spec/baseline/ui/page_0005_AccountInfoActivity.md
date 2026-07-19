---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.AccountInfoActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/AccountInfoActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_account_info.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0005_AccountInfoActivity — 账户信息 (复杂度: 3/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.AccountInfoActivity`
- **基类**: 推断 BaseActivity
- **布局文件**: `activity_account_info.xml`
- **UI 快照**: ui-snapshots/page_0005_AccountInfoActivity/
- **输出文件**: entry/src/main/ets/pages/AccountInfoActivityPage.ets
- **页面类型**: full_screen_page（启动模式: FULL_SCREEN）
- **生命周期**: `onCreate` → 加载用户信息 (userId/vipLevel/vipTime) → 退出登录/注销账号确认弹窗

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent, color_user_page_bg)
├── TitleBar (id=titleBar, 返回+居中"账号管理")
├── [用户ID行] Row(label: tv_user_id_title + value: tv_user_id)
├── [VIP等级行] Row(label: tv_vip_level_title + btn: tv_update_vip + value: tv_vip_level)
│   └── ShapeTextView (id=tv_update_vip, "升级会员", 渐变背景 rightToLeft, gone)
├── [VIP剩余天数行] Row(label: tv_vip_time_title + value: tv_vip_time)
├── Group (constraint_referenced_ids: vip_level_title/level/time_title/time)
├── TextView (id=tv_login_out, "退出登录", 54dp, round_corner_bg, white)
└── TextView (id=tv_delete_account, "注销账号", 54dp, round_corner_bg_stroke, #172939)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏信息页 |
| 标题栏 | TitleBar | titleBar | 返回 + "账号管理" |
| 用户ID标签 | TextView | tv_user_id_title | "用户ID" |
| 用户ID值 | TextView | tv_user_id | 动态用户ID |
| VIP等级标签 | TextView | tv_vip_level_title | "VIP等级" |
| VIP等级值 | TextView | tv_vip_level | 动态等级名 |
| 升级按钮 | ShapeTextView | tv_update_vip | 渐变 #F4BB6E→#F9DC8B, 圆角20dp |
| VIP天数标签 | TextView | tv_vip_time_title | "VIP剩余天数" |
| VIP天数值 | TextView | tv_vip_time | 动态天数 |
| VIP区控制 | Group | — | 批量显隐VIP信息区 |
| 退出登录 | TextView | tv_login_out | round_corner_bg, white |
| 注销账号 | TextView | tv_delete_account | round_corner_bg_stroke, #172939 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Scroll + Column | 可滚动信息页 |
| 标题栏 | com.hjq.bar.TitleBar | Row 自定义标题栏 | SymbolGlyph(chevron_left) + Text |
| 信息行 | 标签+值水平排列 | Row(Text + Blank + Text) | 左右分布 |
| 升级按钮 | ShapeTextView 渐变圆角 | Button + .linearGradient + .borderRadius(20) | gone→条件渲染 |
| 批量显隐 | Group | if(isVipInfoVisible) 条件渲染 | 声明式控制 |
| 退出登录 | TextView 圆角背景 | Button + .borderRadius(27) + .backgroundColor | 信息行标签 |
| 注销账号 | TextView 描边背景 | Button + .borderRadius(27) + .border | 描边样式 |
| 数据加载 | Kotlin 网络请求 | Service FWD-REF: Slice 5 Step 3d | API 调用 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | Row 自定义标题栏 | L2 |
| com.hjq.shape.view.ShapeTextView | Button + .linearGradient + .borderRadius | L2 |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| userId | string | UserData.getInstance() (同步) | 用户ID显示 |
| vipLevel | string | UserData.getInstance() (同步) | VIP等级（普通/月/年会员） |
| vipRemainingDays | number | UserData.getInstance() (同步) | VIP剩余天数 |
| isVipInfoVisible | boolean | 登录态判断 | VIP区域显隐 |
| isUpgradeVisible | boolean | VIP等级判断 | 升级按钮显隐 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | AccountInfoActivity | Intent 跳转 | — |
| OUT | 上一页 | 标题栏返回 → pop | — |
| OUT → 会员中心 | page_0006_MemberCenterActivitiy | 点击"升级会员" | — |
| OUT → 首页 | page_0011_HomeActivity | 退出登录确认 → popTo(首页) | 清空登录态 |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page
- **ArkTS 方案**: `expandSafeArea` TOP，内容区在安全区内滚动
