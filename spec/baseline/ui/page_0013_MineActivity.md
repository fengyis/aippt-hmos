---
android_source_anchors:
  activity: com.aipptzhizuozz.bjh.page.MineActivity
  source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/MineActivity.kt
  layout_file: app/src/main/res/layout/activity_mine.xml
  page_type: full_screen_page
  package: com.aipptzhizuozz.bjh.page


# page_0013_MineActivity — 我的 (含 MineFragment) (复杂度: 5/10)

## 溯源

- **Android Activity**: `com.aipptzhizuozz.bjh.page.MineActivity`
- **基类**: `BaseBusinessActivity<ActivityMineBinding>`
- **布局文件**: `activity_mine.xml`
- **入口方法**: `MineActivity.openActivity(activity: Activity?)` — 静态方法
- **Fragment 子页**: `MineFragment.newInstance(true)` — 带返回箭头模式 (`createOrShowFragment`)
- **生命周期**: `onCreate → initView` (createOrShowFragment 添加 MineFragment)

- **输出文件**: entry/src/main/ets/pages/MineActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, 全屏)
└── FrameLayout (id=fl_fragment)
    └── MineFragment (含返回箭头模式, newInstance(true))
        ├── 用户头像 + 昵称
        ├── 账号信息入口 (rl_account_info)
        ├── VIP 会员入口
        ├── 续费管理入口
        ├── 退款进度入口
        ├── 分享入口
        ├── 关于我们入口
        ├── 联系客服入口
        └── 其他功能入口...
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 全屏根布局 |
| Fragment 容器 | FrameLayout | fl_fragment | 承载 MineFragment |

> **注意**: page_0013 的 view.xml 极其简单（仅 ConstraintLayout + FrameLayout），因为 UI 完全由 MineFragment 承载。实际 UI 结构与 HomeActivity Tab 3 中的 MineFragment（无返回箭头模式）共享同一 Fragment 类，通过 `newInstance(boolean hasBackArrow)` 控制是否显示返回箭头。

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout + FrameLayout | NavDestination 页面 | 独立 Activity → 独立 NavDestination |
| Fragment 容器 | FrameLayout + createOrShowFragment | 直接嵌入 MineComponent | Fragment → @ComponentV2 子组件 |
| 返回箭头 | MineFragment 参数 hasBackArrow=true | NavDestination 自带返回箭头 | Navigation 框架自动提供 |
| MineFragment 复用 | 同一 Fragment 类在 HomeActivity Tab + MineActivity 两种场景 | 同一 @ComponentV2 组件在两个位置使用（@Param hasBackArrow） | 组件复用模式 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| cn.sanfate.pub.platform.fragment.MineFragment | 自定义 @ComponentV2 组件 | L5 (自研) |
| cn.sanfate.pub.platform.util.createOrShowFragment | 组件直嵌或 Navigation 路由 | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| hasBackArrow | MineFragment.newInstance(true) | boolean | true=显示返回箭头 (MineActivity 场景) |

**MineFragment 内部功能入口** (来自 meta.json navigation_targets):

| 功能入口 | 跳转目标 | 说明 |
|---------|---------|------|
| 账号信息 | AccountInfoActivity | 查看/编辑账号信息 |
| VIP 会员 | MemberCenterActivitiy | 会员中心 |
| 续费管理 | ManageRenewActivity | 续费管理页 |
| 退款进度 | RefundProgressActivity | 退款/取消续费进度 |
| 分享 | 分享功能 | 应用分享 |
| 关于我们 | AboutUsActivity | 关于页面 |
| 联系客服 | CustomerServiceDialog 或 CustomerServiceWebActivity | 客服入口 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | MineActivity | `openActivity(activity)` | — |
| OUT → 账号信息 | AccountInfoActivity | MineFragment 内 rl_account_info 点击 | — |
| OUT → 会员中心 | MemberCenterActivitiy | MineFragment 内 VIP 入口点击 | — |
| OUT → 续费管理 | ManageRenewActivity | MineFragment 内续费管理入口点击 | — |
| OUT → 退款进度 | RefundProgressActivity | MineFragment 内退款入口点击 | — |
| OUT → 关于我们 | AboutUsActivity | MineFragment 内关于入口点击 | — |
| OUT → 客服 | CustomerServiceDialog / CustomerServiceWebActivity | MineFragment 内客服入口点击 | — |
| OUT (返回) | 上一页 | NavDestination 返回箭头 / 系统返回键 | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，个人中心页面全屏展示
- **MineFragment 内部**: 顶部用户头像区域可能需要沉浸式效果
- **ArkTS 方案**: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])` + 顶部内容区域使用安全区 padding
