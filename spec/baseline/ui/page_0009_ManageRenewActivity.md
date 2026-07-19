---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.ManageRenewActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/ManageRenewActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_renew_manage.xml
  page_type: full_screen_page
  package: cn.sanfate.pub.platform.page


# page_0009_ManageRenewActivity — 续费管理 (复杂度: 3/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.ManageRenewActivity`
- **基类**: `BaseBusinessActivity<ActivityRenewManageBinding>`
- **布局文件**: `activity_renew_manage.xml`
- **入口方法**: `ManageRenewActivity.openRenew(activity: FragmentActivity)` — 静态方法
- **ViewModel**: `RenewManageViewModel` — `renewInfoLiveData` (订阅信息) / `loadingStatusLiveData` (加载状态)
- **生命周期**: `onCreate→initObserver` → `onResume` (requestRenewInfo) → `onClick` 处理三个按钮

- **输出文件**: entry/src/main/ets/pages/ManageRenewActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器)
├── TitleBar (com.hjq.bar.TitleBar, id=titleBar)
│   └── 标题栏，含返回按钮 + "续费管理" 标题
├── LinearLayout (内容区)
│   └── ScrollView
│       └── LinearLayout (垂直滚动内容)
│           ├── ll_renew_not (空状态容器, 未续费时显示)
│           │   ├── ImageView (空状态图标)
│           │   └── TextView "暂时还没有订阅信息"
│           ├── ll_renewing (续费中信息容器, signStatus=1 时显示)
│           │   ├── ImageView (状态图标)
│           │   ├── LinearLayout (订阅状态行)
│           │   │   ├── ShapeView (装饰)
│           │   │   ├── TextView "订阅中"
│           │   │   └── ShapeView (装饰)
│           │   ├── RelativeLayout (服务到期时间行)
│           │   │   ├── TextView "本次服务到期时间"
│           │   │   └── tv_time (到期时间, 动态数据)
│           │   ├── RelativeLayout (套餐价格行)
│           │   │   ├── TextView "套餐价格"
│           │   │   └── tv_price (价格, 动态数据)
│           │   ├── RelativeLayout (支付方式行)
│           │   │   ├── TextView "支付方式"
│           │   │   └── tv_way (支付方式, 动态数据)
│           │   ├── RelativeLayout (扣款方式行)
│           │   │   ├── TextView "扣款方式"
│           │   │   └── tv_from (扣款方式, 动态数据)
│           │   └── View (分割线)
│           ├── TextView "服务承诺"
│           └── LinearLayout (服务承诺列表)
│               ├── LinearLayout (安心畅享)
│               │   ├── ImageView
│               │   ├── TextView "安心畅享"
│               │   └── TextView "会员权益不间断"
│               ├── LinearLayout (续费提醒)
│               │   ├── ImageView
│               │   ├── TextView "续费提醒"
│               │   └── TextView "扣款前1天提醒"
│               └── LinearLayout (取消无忧)
│                   ├── ImageView
│                   ├── TextView "取消无忧"
│                   └── TextView "随时可取消自动续费"
└── ll_bottom_operate (底部操作栏)
    ├── tv_buy_vip (TextView "立即开通")
    ├── tv_cancle_renew (TextView "取消订阅")
    └── tv_refund_order (TextView "申请退款")
```

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column | 垂直布局结构 |
| 标题栏 | com.hjq.bar.TitleBar | 自定义 Row 标题栏组件 | 无直接三方库等价物 |
| 可滚动内容区 | ScrollView + LinearLayout | Scroll + Column | 标准垂直滚动列表 |
| 订阅状态切换 | Kotlin 代码控制 ll_renewing/ll_renew_not visibility | if/else 条件渲染 (signStatus) | ArkTS 声明式条件渲染 |
| 信息行 | RelativeLayout (label + value) | Row (Text + Text) | 简单左右排列，无需 RelativeContainer |
| 服务承诺卡片 | LinearLayout 嵌套 (图标+标题+副标题) | Row (SymbolGlyph + Column(标题, 副标题)) | 列表项标准结构 |
| 底部操作栏 | LinearLayout 水平布局 | Row (.justifyContent(FlexAlign.SpaceEvenly)) | 三个操作按钮水平分布 |
| 按钮可见性 | Kotlin 动态设置 visibility | if 条件渲染 (signStatus / canRefund / isVip) | 数据驱动 UI 显示 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | 自定义标题栏 | L5 |
| com.hjq.shape.view.ShapeView | Column/Row + .borderRadius + .backgroundColor | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| signStatus | renewInfoLiveData | number | 1=续费中, 其他=未续费 |
| vipEndTime | renewInfoLiveData → tvTime | string | 服务到期时间 |
| signPrice | renewInfoLiveData → tvPrice | string | 套餐价格 |
| paymentMethod | renewInfoLiveData → tvWay | string | 支付方式 (微信/支付宝等) |
| deductionMethod | renewInfoLiveData → tvFrom | string | 扣款方式 |
| canRefund | renewInfoLiveData | number | 1=可退款, 0=不可退款 |
| isVip | UserData.isVip() | boolean | 当前用户是否 VIP |
| loadingStatus | loadingStatusLiveData | boolean | 加载中状态 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | ManageRenewActivity | `openRenew(activity)` | — |
| OUT → 会员中心 | MemberCenterActivitiy | tv_buy_vip onClick → `openMemberCenter(this, FROM_RENEW_VIP)` | FROM_RENEW_VIP |
| OUT → 退款进度 | RefundProgressActivity | tv_cancle_renew → 确认弹窗 → `start(context, 0, renewId, signPrice, vipDes, canRefund)` | operateType=0 |
| OUT → 退款进度 | RefundProgressActivity | tv_refund_order → `start(context, 1, renewId, signPrice, vipDes, canRefund)` | operateType=1 |
| OUT (返回) | 上一页 | TitleBar / 系统返回键 | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，全屏内容展示
- **底部操作栏**: 固定在底部，需考虑安全区（底部导航栏区域）
- **ArkTS 方案**: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` + 底部操作栏使用 `safeAreaPadding` 避免被系统导航栏遮挡
