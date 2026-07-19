---
android_source_anchors:
  activity: cn.sanfate.pub.platform.page.ShortCutActivity
  source_file: app/src/main/java/cn/sanfate/pub/platform/page/ShortCutActivity.kt
  layout_file: app/src/main/platform-res/layout/activity_short_cut.xml
  package: cn.sanfate.pub.platform.page
  page_type: modal_overlay
  needs_immersive_safearea: false
---

# page_0007_ShortCutActivity — 快捷方式 (透明中转) (复杂度: 1/10)

## 溯源

- **Android Activity**: `cn.sanfate.pub.platform.page.ShortCutActivity`
- **基类**: FragmentActivity (透明主题)
- **布局文件**: `activity_short_cut.xml` (空透明 ConstraintLayout)
- **UI 快照**: ui-snapshots/page_0007_ShortCutActivity/
- **输出文件**: entry/src/main/ets/pages/ShortCutActivityPage.ets
- **页面类型**: modal_overlay（透明主题，无 UI）
- **启动模式**: MODAL_OVERLAY — 桌面快捷方式入口，启动后立即路由到 SplashActivity
- **生命周期**: `onCreate` / `onResume` → 解析快捷方式参数 → `startActivity(SplashActivity)` → `finish()`

## 页面结构

```
ConstraintLayout (根容器, match_parent, transparent, 空布局无子组件)
```

**组件清单**:

| 组件 | 类型 | ID | 用途 |
|------|------|----|------|
| 根容器 | ConstraintLayout | — | 透明空容器（无 UI） |

## 转换决策

| 决策项 | Android 实现 | ArkTS 转换方案 | 理由 |
|--------|-------------|---------------|------|
| 页面容器 | ConstraintLayout (transparent, 空) | Column (transparent, 空) | 透明全屏 |
| 路由转发 | Intent (ShortCut→SplashActivity) → finish() | aboutToAppear → pushPathByName → popSelf | FWD-REF: Slice 7 Step 3d |
| 快捷方式注册 | AndroidManifest short-cut intent-filter | module.json5 skills 配置 | 系统级快捷方式注册 |

**三方库依赖**: 无

## 状态接口

| @Local 变量 | 类型 | 来源 | 关联功能 |
|------------|------|------|---------|
| （无 UI 状态变量） | — | — | 纯路由转发 |

## 导航关系

| 方向 | 目标 | 触发方式 | 参数 |
|------|------|---------|------|
| IN | ShortCutActivity | 桌面快捷方式 Intent | shortcutId, extra params |
| OUT → Splash | page_0001_SplashActivity | BoxApplication.enterMain==false → SplashActivity.reLaunch | 透传快捷方式参数 |
| OUT → Calculator | 计算器页面 | BoxApplication.enterMain==true → openCalculator | 已进入主页时的快捷方式 |

## 沉浸式 + 安全区

- **needs_immersive_safearea**: false
- **判定依据**: page_type=modal_overlay，透明主题无 UI
- **ArkTS 方案**: 无需安全区处理
