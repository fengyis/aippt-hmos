---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.MemberCenterActivitiy
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/MemberCenterActivitiy.kt
  layout_file: app/src/main/platform-res/layout/activity_member_center.xml
  package: cn.sanfate.pub.platform.page
  page_type: full_screen_page
  needs_immersive_safearea: true
---

# page_0006_MemberCenterActivitiy — 会员中心 (RecyclerView + 支付) (复杂度: 7/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.MemberCenterActivitiy`
- **基类**: `BaseBusinessActivity` (推断自 fragment_tags: CommonRequestInterceptor, SplashActivity.AdvertLoad)
- **布局文件**: `activity_member_center.xml`
- **UI 快照**: ui-snapshots/page_0006_MemberCenterActivitiy/
- **输出文件**: entry/src/main/ets/pages/MemberCenterActivityPage.ets
- **页面类型**: full_screen_page（启动模式: FULL_SCREEN）
- **特殊组件**: RecyclerView（产品网格列表）、BannerViewPager（VIP权益轮播）、TickerView（滚动数字）、支付方式选择（微信/支付宝）、营销弹窗（Campaign 1/2 + Mask）
- **生命周期**: `onCreate` (初始化 Banner + 产品列表) → `onResume` (刷新定价) → 支付回调 → `onDestroy`

## 页面结构

基于 view.xml 层级还原：

```
ConstraintLayout (根容器, match_parent × match_parent, white)
├── NestedScrollView (可滚动内容区)
│   └── ShapeConstraintLayout (id=cl_center_top, 顶部圆角20dp)
│       ├── BannerViewPager (id=vip_banner, aspectRatio=360:241)
│       ├── TitleBar (id=titleBar, 关闭按钮, title="会员中心", 叠加Banner)
│       ├── RecyclerView (id=rv_product_list, 水平滚动, 源码: linear(HORIZONTAL) 覆盖 XML GridLayoutManager)
│       │   └── item_product_info (产品卡片组件)
│       ├── TextView (id=tv_renew_tips, 续费提示, 11dp)
│       ├── TextView (id=iv_center_tip, "权益对比", 16dp bold)
│       └── ImageView (bg_vip_equity, 权益对比图, 322:230)
├── ShapeConstraintLayout (id=cl_center_bottom, 底部固定支付区)
│   ├── ShapeConstraintLayout (id=splay_pay)
│   │   ├── [微信支付] TextView(tv_wechat_pay) + ImageView(iv_wechat_check)
│   │   └── [支付宝]   TextView(tv_ali_pay)   + ImageView(iv_ali_check)
│   ├── ShapeTextView (id=btn_goto_pay, "立即开通", 渐变圆角37dp)
│   ├── ImageView (id=iv_agreement_check, 协议勾选)
│   └── TextView (id=tv_pay_agrement, 协议文案, 12dp)
├── ConstraintLayout (id=ll_masked, 半透明蒙层, gone)
├── ConstraintLayout (id=ll_campaign1, 活动弹窗1, gone)
│   ├── ImageView (iv_campaign1_bg)
│   ├── TextView (tv_title, 活动标题)
│   ├── ConstraintLayout (ll_campaign1_inner)
│   │   ├── ImageView (iv_masked_price_bg)
│   │   ├── TickerView (rollingTextView, "598")
│   │   └── TextView (tv_masked_price_lev, "￥")
│   └── TextView (tv_limit_tip, 限时倒计时)
└── ImageView (id=iv_campaign2, 活动弹窗2, 280dp, gone)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|------|------|
| 根容器 | ConstraintLayout | — | 全屏根布局 |
| 滚动容器 | NestedScrollView | — | 可滚动内容区 |
| 内容卡片 | ShapeConstraintLayout | cl_center_top | 顶部圆角20dp白色卡片 |
| Banner 轮播 | BannerViewPager | vip_banner | VIP 权益 Banner 轮播 |
| 标题栏 | TitleBar | titleBar | 关闭按钮 + 居中标题 |
| 产品列表 | RecyclerView | rv_product_list | 水平滚动 (源码: linear(HORIZONTAL), 非 Grid) |
| 产品卡片 | item_product_info | — | 价格/原价/标签/推荐角标 |
| 续费提示 | TextView | tv_renew_tips | 续费说明文案 |
| 分区标题 | TextView | iv_center_tip | "权益对比" |
| 权益图 | ImageView | — | bg_vip_equity 长图 |
| 支付区容器 | ShapeConstraintLayout | cl_center_bottom | 底部固定，顶部描边 |
| 支付方式 | ShapeConstraintLayout | splay_pay | 微信/支付宝横向排列 |
| 支付按钮 | ShapeTextView | btn_goto_pay | 渐变背景, tag=recharge_buy_btn |
| 协议勾选 | ImageView | iv_agreement_check | 选中/未选中态切换 |
| 协议文案 | TextView | tv_pay_agrement | 含可点击协议链接 |
| 蒙层 | ConstraintLayout | ll_masked | 半透明黑色蒙层 |
| 活动弹窗1 | ConstraintLayout | ll_campaign1 | 居中营销弹窗 |
| 滚动数字 | TickerView | rollingTextView | 活动价格数字动画 |
| 活动弹窗2 | ImageView | iv_campaign2 | 第二套营销弹窗 |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout (white bg) | Column | 垂直布局（Scroll 区 + 底部固定栏） |
| 可滚动区 | NestedScrollView | Scroll + Column | 内容超出时滚动 |
| 卡片容器 | ShapeConstraintLayout (顶部圆角20dp) | Column + .borderRadius({ topLeft: 20, topRight: 20 }) | 圆角裁剪 |
| Banner 轮播 | BannerViewPager (com.zhpan.bannerview) | Swiper + Image | 原生轮播组件等价 |
| 标题栏叠加 | TitleBar 叠加在 Banner 上层 | Row 自定义标题栏，zIndex 控制层叠 | SymbolGlyph(xmark) + Text 居中 |
| 产品列表 | RecyclerView + LinearLayoutManager (horizontal) | List({ space: 10 }).listDirection(Axis.Horizontal) + LazyForEach | 水平滚动列表（源码 linear(HORIZONTAL) 覆盖 XML Grid） |
| 产品卡片 | item_product_info item layout | @ComponentV2 ProductCard | 独立组件，含价格/原价/标签 |
| 续费提示 | TextView (11dp, #9A9B98) | Text().fontSize(11).fontColor('#9A9B98') | 直接映射 |
| 支付区固定 | ShapeConstraintLayout (底部约束) | Column (主布局内) | 无需绝对定位 |
| 支付选择 | ShapeConstraintLayout 横向 | Row + 条件 Image | 微信/支付宝图标+选中标记 |
| 支付按钮 | ShapeTextView 渐变圆角37dp | Button + .linearGradient | #3C2AF8 → #C83DFF leftToRight |
| 协议勾选 | ImageView selector → checked/uncheck | Image 条件渲染 | select_pay_method_checked / uncheck |
| 营销蒙层 | ConstraintLayout (black50, gone) | 绝对定位半透明 Stack，if 控制 | 条件渲染 |
| 活动弹窗 | ConstraintLayout 居中弹窗 | 绝对定位 Column，if 控制 | .position + .translate |
| 滚动数字 | TickerView (com.robinhood.ticker) | Text + animateTo 数字滚动 | animateTo 驱动数字变更 |
| 第二弹窗 | ImageView 居中图片 | Image 条件渲染 | 直接映射 |

**三方库依赖**:

| Android 库 | 迁移方案 | Level |
|-----------|---------|-------|
| com.zhpan.bannerview.BannerViewPager | Swiper 组件 | L2 |
| com.robinhood.ticker.TickerView | Text + animateTo | L5 (自研) |
| com.hjq.shape.view.ShapeTextView | Button + .borderRadius + .linearGradient | L2 |
| com.hjq.shape.layout.ShapeConstraintLayout | Column/Row + .border + .borderRadius | L2 |
| com.hjq.bar.TitleBar | Row 自定义标题栏 | L2 |

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| productList | ProductItem[] | 商品列表 API | RecyclerView 产品网格 |
| selectedProductIndex | number | 用户点击 | 当前选中产品高亮 |
| bannerList | BannerItem[] | Banner API | 轮播 Banner |
| selectedPayMethod | string | 用户选择 | 'wechat' / 'alipay' 切换 |
| isAgreementChecked | boolean | 用户勾选 | 协议确认（支付按钮前置条件） |
| isMaskVisible | boolean | 营销逻辑 | 蒙层显隐 |
| isCampaign1Visible | boolean | 营销逻辑 | 活动弹窗1显隐 |
| isCampaign2Visible | boolean | 营销逻辑 | 活动弹窗2显隐 |
| campaignPrice | string | 营销配置 | 活动价格（如"598"） |
| campaignTitle | string | 营销配置 | 活动标题（如"五一特惠"） |
| campaignLimitTip | string | 营销配置 | 限时倒计时文案 |
| isLoading | boolean | 网络请求 | 页面加载骨架屏/loading |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | MemberCenterActivitiy | Intent 跳转 | — |
| OUT | 上一页 | 标题栏关闭按钮 → pop | — |
| OUT → 支付 | 微信/支付宝 SDK | 点击"立即开通" | selectedProductIndex, payMethod |
| OUT → WebView | page_0002_WebViewActivity | 点击"会员服务协议" | url=会员协议URL |
| OUT → WebView | page_0002_WebViewActivity | 点击"自动续订协议" | url=续订协议URL |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: true
- **判定依据**: page_type=full_screen_page，会员中心页全屏展示
- **顶部 Banner 区**: 需延伸到状态栏区域，TitleBar 需考虑安全区偏移
- **底部支付栏**: 固定在底部，margin 需考虑安全区（底部系统导航栏）
- **ArkTS 方案**: `expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])` + 支付栏 `.safeAreaPadding({ bottom: ... })`
