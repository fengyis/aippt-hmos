# F005-file: 文件管理

```yaml
complexity: simple
tier: standard
depth: full
```

## 范围

提供本地文件扫描、上传和选择功能，将用户本地文档（PPT/Word/PDF等）导入到PPT生成流程。

**涉及页面**：
- `page_0018_FileUploadPage` — 文件上传入口页，处理存储权限申请
- `page_0019_FileListPage` — 扫描文件列表页，展示设备上的文档文件
- `FileConfirmDialog` — 文件确认弹窗，确认后将文件路径传入PPT生成流程

**依赖**：feature-base（UserData、ScanFileBean、EventExt、网络层）

**源码锚点**：
- `FileUploadPage.kt`: 权限申请（XXPermissions MANAGE_EXTERNAL_STORAGE）、AppTipsDialog/AppPermissionIntroDialog 双版本权限弹窗、跳转 FileListPage
- `FileListPage.kt`: RecyclerView 文件列表（BindingAdapter + ScanFileBean）、FileScanViewModel 观察、搜索高亮（ColorSpan replaceSpan）、FileConfirmDialog 触发
- `FileConfirmDialog.kt`: DialogFragment 接收 filePath 参数、跳转 CreateOutLinePage（filePath + FROM_FILE_IMPORT）

## 数据流

```
用户点击"上传文件"
  → FileUploadPage.requestStoragePermission()
    → XXPermissions 检查权限
      ├─ 已授权 → FileListPage.openFileList()
      └─ 未授权 → AppTipsDialog(Android11+)/AppPermissionIntroDialog(低版本)
        → XXPermissions.request(MANAGE_EXTERNAL_STORAGE)
          ├─ onGranted → FileListPage.openFileList()
          └─ onDenied → toast 提示拒绝

FileListPage 启动
  → FileScanViewModel.scanAllDirectory() 扫描本地文件
    → loadingStatusLiveData 控制 AppLoadDialog 显隐
    → mediaFileListLiveData 推送 List<ScanFileBean>
      → fileListAdapter.models = it (BindingAdapter 更新)

用户在 FileListPage 搜索
  → edSearchInput.doAfterTextChanged → fileScanViewModel.searchFile(keyword)
    → 列表项文件名高亮: ColorSpan(hightLightColor=#1E81FF) + replaceSpan

用户点击文件项
  → 检查 File.exists()
    → FileConfirmDialog.newInstance(filePath).show()
      → 用户确认 → CreateOutLinePage.createOutlinePage(filePath=..., from=EventExt.FROM_FILE_IMPORT)
```

**关键数据模型**：
- `ScanFileBean`: filePath (String), fileName (String), fileIcon (Int resId), fileDes (String), timeCategory (String), showCategory (Boolean)

## 状态管理

| 状态 | 类型 | 来源 | ArkTS 映射 |
|------|------|------|-----------|
| 加载状态 | Boolean | FileScanViewModel.loadingStatusLiveData | `@Local isLoading: boolean` |
| 文件列表 | List\<ScanFileBean\> | FileScanViewModel.mediaFileListLiveData | `@Local fileList: ScanFileBean[]` |
| 搜索关键词 | String | EditText doAfterTextChanged | `@Local searchKeyword: string` |
| 权限状态 | Boolean | XXPermissions.isGranted | `@Local hasPermission: boolean` |

## 对接点

**入口**：其他页面通过 `FileUploadPage.openFileUpload(activity)` 静态方法进入文件管理流程。

**出口**：
- `FileConfirmDialog` 确认后 → `CreateOutLinePage.createOutlinePage(filePath=..., from=FROM_FILE_IMPORT)` → F004 PPT核心流程
- `FileListPage` 返回上一页 → `finish()`

**功能点**：
| 功能点 | Android 实现 | ArkTS 目标 |
|--------|-------------|-----------|
| 存储权限申请 | XXPermissions.request(MANAGE_EXTERNAL_STORAGE) | @kit.AbilityKit startAbilityForResult + ohos.permission.READ/WRITE_USER_STORAGE |
| 文件扫描 | FileScanViewModel.scanAllDirectory() | @kit.CoreFileKit listFile 递归 + 文件类型过滤 |
| 文件搜索+高亮 | doAfterTextChanged + replaceSpan(ColorSpan) | TextInput onChange + BuilderParam 高亮（Text span） |
| 文件列表 | BRV BindingAdapter + linear + setup | List + Repeat/LazyForEach + @ComponentV2 item |
| 确认弹窗 | FileConfirmDialog (DialogFragment) | @CustomDialog + CustomDialogController |

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | 点击"上传文件"触发存储权限申请 | FileUploadPage.requestStoragePermission() → XXPermissions | hasPermission=false 时弹出权限申请对话框 |
| 2 | 权限已授权时直接进入文件列表 | XXPermissions.isGranted → fileListPage() | 检测权限状态，已授权跳过弹窗 |
| 3 | 权限弹窗拒绝后 toast 提示 | `"拒绝了授权，无法选择文件".toast()` | promptAction.showToast($r('app.string.permission_denied_file')) |
| 4 | 文件扫描时显示加载中 | AppLoadDialog.showAppLoadDialog("文件扫描中...") | loadingStatus=true → 显示 LoadingProgress |
| 5 | 文件列表按时间分类展示 | ScanFileBean.timeCategory + showCategory | List section 分组 + timeCategory header |
| 6 | 搜索输入实时过滤文件 | doAfterTextChanged → searchFile(keyword) | TextInput.onChange + filter 文件列表 |
| 7 | 搜索结果高亮关键词（蓝色#1E81FF） | ColorSpan(hightLightColor) + replaceSpan | Text 内使用 Span 标记搜索词颜色 |
| 8 | 点击文件项弹出确认弹窗 | FileConfirmDialog.newInstance(filePath).show() | CustomDialogController.open() + 传入filePath |
| 9 | 确认后进入PPT生成流程 | CreateOutLinePage.createOutlinePage(filePath=..., from=FROM_FILE_IMPORT) | router/NavPathStack 跳转 CreateOutlinePage |
| 10 | 文件不存在时忽略点击（不弹窗） | `if(!File(filePath).exists()) return@onClick` | fileIo.access(filePath) 检查，不存在则 return |
| 11 | 文件上传引导页显示支持格式和大小限制提示："支持Word、PDF、TXT，上传文件大小不能超过5MB" | `page_file_upload.xml` 居中 TextView, `text="支持Word、PDF、TXT\n上传文件大小不能超过5MB"`, `textColor=#979797`, `textSize=12dp` | `Text($r('app.string.file_upload_format_hint'))` + `.fontColor('#979797').fontSize(12)` 居中展示 |
| 12 | 文件列表每一项根据文件类型显示对应图标（`fileBean.fileIcon` 资源ID映射） | `FileListPage.kt:55`: `binding.ivFiletype.setImageResource(fileBean.fileIcon)` | `Image(fileTypeIconMap[file.fileType])` 或 `SymbolGlyph` 按文件后缀映射（doc→doc, pdf→doc, txt→doc） |
