---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.RefundProgressActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/RefundProgressActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_refund_progress.xml
  page_type: full_screen_page
  package: cn.sanfate.pub.platform.page


# page_0010_RefundProgressActivity — 退款进度 (复杂度: 4/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.RefundProgressActivity`
- **基类**: `BaseBusinessActivity<ActivityRefundProgressBinding>`
- **布局文件**: `activity_refund_progress.xml`
- **入口方法**: `RefundProgressActivity.start(context, operateType, renewId, signPrice, vipDes, canRefund)` — 静态方法
- **ViewModel**: `RenewManageViewModel` — `refundLiveData` (退款结果)
- **生命周期**: `onCreate→initView` (读取 Intent 参数、判断流程) → `initObserver` → `initListener` (点击事件绑定)

- **输出文件**: entry/src/main/ets/pages/RefundProgressActivityPage.ets


## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器)
├── TitleBar (com.hjq.bar.TitleBar, id=titleBar)
│   └── 标题栏，含返回按钮
├── iv_progress (ImageView)
│   └── 进度图标 (icon_refunding / icon_refund_fail)
├── tv_progress (TextView)
│   └── 进度文字: "自动续费取消中..." / "退款进行中..." / "退款成功" / ...
├── tv_refund_percent (TextView "退款成功率100%")
│   └── 退款模式时显示，取消订阅模式时隐藏
├── tv_retry (TextView "重新尝试")
│   └── 失败时显示，重试操作按钮
├── tv_success_operate (TextView "我知道了" / "申请退款")
│   └── 成功后的操作按钮 (operateType=0→"申请退款", operateType=1→"我知道了")
├── tv_success (TextView "退款成功" / "自动续费已关闭")
│   └── 成功结果文字
└── ll_system_chat (LinearLayout, 客服入口)
    ├── TextView "如有问题，请联系客服"
    └── tv_system_chat (TextView, 客服名称/内容, 动态数据)
```

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout | Column (.justifyContent(FlexAlign.Center)) | 垂直居中布局 |
| 标题栏 | com.hjq.bar.TitleBar | 自定义 Row 标题栏组件 | 无直接等价三方库 |
| 进度图标 | ImageView (setImageResource 切换) | Image (if 条件切换资源) | 声明式状态驱动图标切换 |
| 进度状态切换 | Kotlin 多段 visibility 控制 | if/else 分支渲染 (operateType + errorCode) | 多状态 UI 分支 |
| 客服入口 | LinearLayout 水平 | Row (Text + Text) | 简单水平排列 |
| 弹窗 (退款原因) | RenewRefundReasonDialog (DialogFragment) | @CustomDialog + CustomDialogController | DialogFragment → 自定义弹窗 |
| 确认弹窗 | AppTipsDialog (DialogFragment) | @CustomDialog + CustomDialogController | 确认弹窗组件 |
| 客服弹窗 | CustomerServiceDialog (DialogFragment) | @CustomDialog 或 NavDestination 子页面 | DialogFragment 模式转换 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.hjq.bar.TitleBar | 自定义标题栏 | L5 |
| com.hjq.toast.Toaster | promptAction.showToast() | L2 |

## 状态接口

| 状态/数据 | 来源 | 类型 | 说明 |
|----------|------|------|------|
| operateType | Intent extra | number | 0=取消订阅, 1=退款 |
| renewId | Intent extra | string | 续费协议 ID |
| signPrice | Intent extra | string | 套餐价格 |
| vipDec | Intent extra | string | VIP 套餐描述 |
| canRefund | Intent extra | number | 1=可退款 (影响成功后的按钮文案) |
| refundReason | 用户输入 | string | 退款原因 (RenewRefundReasonDialog 返回) |
| errorCode | refundLiveData → BaseBean | number | 0=成功, 非0=失败 |
| errorMsg | refundLiveData → BaseBean | string | 失败时的错误信息 |
| serviceContent | AppContant.userConfig.serviceContent | string | 客服联系文案 (动态) |

**UI 状态机**:

| 状态 | tv_progress | iv_progress | tv_refund_percent | tv_success | tv_retry | tv_success_operate |
|------|------------|-------------|-------------------|------------|----------|--------------------|
| 取消中 (type=0, 进行中) | "自动续费取消中..." | icon_refunding | GONE | GONE | GONE | GONE |
| 退款中 (type=1, 进行中) | "退款进行中..." | icon_refunding | VISIBLE | GONE | GONE | GONE |
| 取消成功 (code=0, type=0) | GONE | GONE | GONE | "自动续费已关闭" | GONE | "申请退款"或"我知道了" |
| 退款成功 (code=0, type=1) | GONE | GONE | GONE | "退款成功" | GONE | "我知道了" |
| 取消失败 (code!=0, type=0) | "自动续费取消失败" | GONE | GONE | GONE | VISIBLE | GONE |
| 退款失败 (code!=0, type=1) | "退款失败" | GONE | GONE | GONE | VISIBLE | GONE |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | RefundProgressActivity | `start(context, operateType, renewId, signPrice, vipDes, canRefund)` | operateType, renewId, signPrice, vipDec, canRefund |
| IN | (来自 ManageRenewActivity) | tv_cancle_renew → 确认弹窗 → start(0) | operateType=0 |
| IN | (来自 ManageRenewActivity) | tv_refund_order → start(1) | operateType=1 |
| OUT → 客服弹窗 | CustomerServiceDialog | tv_system_chat onClick → CustomerServiceDialog().show() | — |
| OUT (返回) | 上一页 (ManageRenewActivity) | tv_success_operate (operateType=1) → finish() | — |
| OUT (返回) | 上一页 | 退款弹窗取消 → finish() | — |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，居中进度展示页面
- **ArkTS 方案**: 标准全屏页面，标题栏 + 内容区居中，底部客服入口在安全区之上
