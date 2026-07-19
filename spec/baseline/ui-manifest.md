# UI Manifest

## Style Configuration
style_set: none

## 全局约定
- **导航架构**: 多 Activity 架构（21 个独立 Activity），ArkTS 端需评估是否合并为单 Navigation + NavPathStack 或保留多 Page 独立路由
- **设计令牌**:
  - 主色 (Primary): `#5B3CFF` (purple, `color_text_link`)
  - 按钮渐变: `#3C2AF8` → `#7C25FF` (`color_main_btn_bg_start_color` → `color_main_btn_bg_end_color`)
  - 页面背景: `#F7F7F7` (`color_page_bg`), 用户页背景: `#F1F6FA` (`color_user_page_bg`)
  - 标题色: `#1C1C1C` (`color_title_color`)
  - 正文色: `#333333` (`color_text_color`)
  - 提示文字: `#B0B1B3` (`color_text_hint`)
  - 链接色: `#5B3CFF` (`color_text_link`)
  - 首页 Tab 背景: `#202022` (`color_home_tab_bg`), 未选中: `#D1D5EB`, 选中: `#5B3CFF`
  - 对话框标题: `#172939`, 内容: `#868686`, 确认按钮: `#1C1C1C` 白字, 取消按钮: `#E6E3FF` 黑字
  - Splash 进度条: 背景 `#F5F6FA`, 进度 `#753FF9`
  - 支付链接: `#482CF9`
  - 引导按钮渐变: `#3C2AF8` → `#7C25FF`
  - 主题: `Theme.SeceretBox` (Light, NoActionBar), 启动主题: `Theme.SeceretBox.Launch` (全屏透明状态栏), 透明主题: `Theme.SeceretBox.Transparent`
  - 源文件: `app/src/main/res/values/colors.xml`, `app/src/main/res/values/styles.xml`
- **命名规范**: 页面 `XxxPage.ets`，组件 `XxxComponent.ets`
- **图标方案**: WebP 资源 (`app/src/main/res/mipmap*/`, `app/src/main/res/drawable*/`) + XML drawable selector
- **沉浸式 + 安全区**：本工程全屏页统一采用 arkts-immersive-safearea 四层架构；每页是否需要由 meta.json `page_type` 自动判定

## 页面清单

| 序号 | Android | ArkTS 产出 | 优先级 | confidence | 状态 |
|------|---------|-----------|--------|-----------|------|
| 0001 | SplashActivity | SplashPage.ets | P0 | medium | pending |
| 0002 | WebViewActivity | WebViewPage.ets | P1 | medium | pending |
| 0003 | AboutUsActivity | AboutUsPage.ets | P2 | medium | pending |
| 0004 | LoginActivity | LoginPage.ets | P0 | medium | pending |
| 0005 | AccountInfoActivity | AccountInfoPage.ets | P1 | medium | pending |
| 0006 | MemberCenterActivitiy | MemberCenterPage.ets | P0 | medium | pending |
| 0007 | ShortCutActivity | ShortCutPage.ets | P2 | medium | pending |
| 0008 | CustomerServiceWebActivity | CustomerServiceWebPage.ets | P1 | medium | pending |
| 0009 | ManageRenewActivity | ManageRenewPage.ets | P1 | medium | pending |
| 0010 | RefundProgressActivity | RefundProgressPage.ets | P1 | medium | pending |
| 0011 | HomeActivity | HomePage.ets | P0 | medium | pending |
| 0012 | GuideActivity | GuidePage.ets | P1 | medium | pending |
| 0013 | MineActivity | MinePage.ets | P1 | medium | pending |
| 0014 | PPTTemplatePreviewPage | PPTTemplatePreviewPage.ets | P0 | medium | pending |
| 0015 | CreateOutLinePage | CreateOutLinePage.ets | P0 | medium | pending |
| 0016 | ChoicePPTTemplatePage | ChoicePPTTemplatePage.ets | P0 | medium | pending |
| 0017 | PPTFilePage | PPTFilePage.ets | P0 | medium | pending |
| 0018 | FileUploadPage | FileUploadPage.ets | P1 | medium | pending |
| 0019 | FileListPage | FileListPage.ets | P1 | medium | pending |
| 0020 | WorksPage | WorksPage.ets | P1 | medium | pending |
| 0021 | SearchPagePage | SearchPage.ets | P1 | medium | pending |

### 页面状态生命周期
pending → converted → verified
- pending: 待转换
- converted: UI 已转换，等待验证
- verified: 编译通过 + 切片级功能验证通过
- skipped: 本轮不转换（V2 范围外）

## 转换批次
- **Batch 1 (P0)**: 0001, 0004, 0006, 0011, 0014, 0015, 0016, 0017 (启动 + 登录 + 会员 + 首页 + PPT 核心流程)
- **Batch 2 (P1)**: 0002, 0005, 0008, 0009, 0010, 0012, 0013, 0018, 0019, 0020, 0021 (次级功能页面)
- **Batch 3 (P2)**: 0003, 0007 (辅助页面)

## 共享组件
| 组件 | 用于页面 | Android 来源 |
|------|---------|-------------|
| WebViewContainer | 0002, 0008 | activity_webview.xml, activity_webview_customer_service.xml |
| PPTTemplateCard | 0016, 0020, 0021 | item_ppt_template.xml (0016 RecommendListFragment, 0020 WorksFragment, 0021 SearchPagePage) |
| PPTCoverImage | 0014, 0017 | item_ppt_cover.xml (0014 PPTTemplatePreviewPage, 0017 PPTFilePage) |
| PptChapterItem | 0015 | item_ppt_outline.xml, item_ppt_outline_content.xml |
| FileListItem | 0019 | item_scan_file.xml |
| MemberProductCard | 0006 | item_product_info.xml |
| HomeTabBar | 0011 | activity_home.xml (BottomNavigationView) |
| GuideViewPager | 0012 | activity_guide.xml (ViewPager) |
