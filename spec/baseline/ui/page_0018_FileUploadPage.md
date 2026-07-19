---
android_source_anchors:
  - type: activity
    class: com.aipptzhizuozz.bjh.page.FileUploadPage
    source_file: app/src/main/java/com/aipptzhizuozz/bjh/page/FileUploadPage.kt
    language: kotlin
    base_class: cn.sanfate.pub.baseui.activity.BaseBusinessActivity
  - type: layout
    file: app/src/main/res/layout/page_file_upload.xml
---

# page_0018_FileUploadPage — 文件上传引导 (复杂度: 4/10)

## 溯源

### 页面归属
- **Activity**: `FileUploadPage` extends `BaseBusinessActivity<PageFileUploadBinding>` — 无独立 ViewModel，逻辑直接在 Activity 中
- **Presenter/ViewModel**: 无 ViewModel（纯 UI + 权限逻辑页）
- **Service/Repository**: 无 Service（权限检查通过后直接跳转 FileListPage）
- **Interceptor**: `XXPermissions.isGranted(activity, Permission.MANAGE_EXTERNAL_STORAGE)` 存储权限检查
- **Base Class**: `BaseBusinessActivity` (`cn.sanfate.pub.baseui.activity`) — 提供 `getLayoutResId()`, `initListener()`, `onClick()`, `setOnClickListener()`, `dataBind` 模板
- **Util**: `XXPermissions` (hjq 权限库，含 `isGranted` / `with().permission().request()` 链式调用); `AppTipsDialog` / `AppPermissionIntroDialog` (权限申请对话框); `cn.sanfate.pub.common.toast`

### 页面参数
无（无 Intent extras）

### 页面功能
文件上传引导页。展示支持格式（Word/PDF/TXT）和文件大小限制（5MB），引导用户点击上传按钮。权限检查通过后跳转 `FileListPage` 浏览本地文件；权限未授权时显示权限申请对话框。

---

- **输出文件**: entry/src/main/ets/pages/FileUploadPage.ets


## 页面结构

```
ConstraintLayout (根容器，背景 #F2F6FF 浅蓝灰)
├── TitleBar (id: titleBar)
│   ├── title: "上传文档"
│   ├── leftIcon: icon_titlebar_back_black (返回)
│   └── background: @color/white
├── TextView (居中, 背景 mipmap: icon_fileupload_guide)
│   ├── text: "支持Word、PDF、TXT\n上传文件大小不能超过5MB"
│   ├── textColor: #979797
│   ├── textSize: 12dp
│   ├── gravity: center|bottom
│   ├── paddingBottom: 64dp
│   └── marginTop: 89dp (约束于 titleBar 底部)
└── TextView (id: tv_upload_file, 上传按钮)
    ├── text: "点击上传文档"
    ├── textColor: @color/white
    ├── textSize: 18dp, bold
    ├── background: @drawable/app_round_corner_bg (蓝色圆角背景)
    ├── width: match_parent, height: 57dp
    ├── marginHorizontal: 20dp
    ├── marginBottom: 80dp
    └── onClick → requestStoragePermission()
```

### 交互流程
1. 用户点击「点击上传文档」→ `dataBind.tvUploadFile` onClick
2. `requestStoragePermission()` → `XXPermissions.isGranted(this, Permission.MANAGE_EXTERNAL_STORAGE)`
3. 权限已授权 → 直接 `fileListPage()` → `FileListPage.openFileList(this)`
4. 权限未授权 (Android R+) → `AppTipsDialog` 权限说明弹窗 → 用户确认 → `requestPermission()`
5. 权限未授权 (< Android R) → `AppPermissionIntroDialog` 引导弹窗 + `requestPermission()`
6. `requestPermission()` → `XXPermissions.with(this).permission(MANAGE_EXTERNAL_STORAGE).request(callback)`
7. `onGranted` → `appTopPermissionDialog?.dismiss()` → `fileListPage()`
8. `onDenied` → `appTopPermissionDialog?.dismiss()` → toast "拒绝了授权，无法选择文件"


## 转换决策

| Android 组件 | ArkTS 方案 | 说明 |
|---|---|---|
| `ConstraintLayout` (根) | `Column` | 垂直布局：引导区居中 + 底部按钮固定 |
| `TitleBar` | 自定义 `Row` 组件 `AppTitleBar` | 左返回 + 居中标题 "上传文档" |
| `TextView` (引导图+提示) | `Column` → `Image` (引导图) + `Text` (提示文字) | 使用本地资源图片替代 mipmap icon_fileupload_guide |
| `TextView` (上传按钮) | `Button($r('app.string.click_to_upload'))` + `.borderRadius()` + `.backgroundColor()` | 圆角蓝色按钮 (app_round_corner_bg 对应) |
| `AppTipsDialog` (权限) | `getUIContext().showAlertDialog()` | 权限申请说明对话框 (title: "申请所有文件管理权限") |
| `AppPermissionIntroDialog` | `CustomDialog` | Android R 以下版本的全屏权限引导 |
| `XXPermissions` | `@kit.AbilityKit` `abilityAccessCtrl` | 鸿蒙权限管理 API (`checkAccessToken` / `requestPermissionsFromUser`) |

### 布局策略
- 根容器: `Column` (`.width('100%').height('100%')`)
- 引导图区域: `Flex` / `Column` + `.layoutWeight(1)` 居中（引导图 + 提示文字 + 格式限制说明）
- 底部按钮: `Button` 固定在底部, `margin({ bottom: 80 })`, `padding({ left: 20, right: 20 })`

### 权限处理
- Android `MANAGE_EXTERNAL_STORAGE` → 鸿蒙 `ohos.permission.READ_WRITE_DOCUMENT` (如果有文档管理场景)
- 鸿蒙文件选择: 推荐使用 `picker.DocumentViewPicker` 无需存储权限（系统级文件选择器）


## 状态接口

### 输入参数
无（页面无额外参数）

### 页面状态
```typescript
@ComponentV2
struct FileUploadPage {
  @Local isRequestingPermission: boolean = false
  @Local permissionDialogVisible: boolean = false
}
```

### 回调事件
- `onUploadClick()`: 检查/请求存储权限 → 跳转文件列表
- `onBackClick()`: `router.back()` / `navPathStack.pop()`


## 导航关系

### 入口
- `FileUploadPage.openFileUpload(activity: FragmentActivity?)` — 静态工厂方法
- 来源: `HomeActivity` (首页「导入文档」入口)

### 出口
| 目标 | 触发 | 参数 |
|---|---|---|
| `FileListPage` | `fileListPage()` → `FileListPage.openFileList(this)` — 权限通过后 | 无 |
| 返回上一页 | `finish()` / onBackPressed | 无 |

### 导航参数
- 出: `FileListPage.openFileList(activity)` — 无参数传递


## 沉浸式 + 安全区

- **page_type**: `full_screen_page`
- **needs_immersive_safearea**: `true`
- **状态栏**: TitleBar 的 `paddingTop` 使用 `@dimen/dimen_page_marginTop` 适配状态栏
- **导航栏**: 无底部导航栏
- **背景色**: `#F2F6FF`（浅蓝灰色背景）
