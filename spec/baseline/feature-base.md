# Feature Base: 共享基础设施

## Style Configuration
style_set: none

## 数据模型

所有共享实体定义：

### UserData (用户数据)
- 来源: `cn.sanfate.pub.platform` (平台SDK)
- 字段: token, uid, nickname, avatar, vipLevel, fromChannel, phone
- 单例模式: `UserData.getInstance()`

### PPTTemplateBean (PPT模板)
- 来源: `com.aipptzhizuozz.bjh.bean.PPTTemplateResBean`
- 字段: id (String), coverUrl (String), title (String), category (String), tags (List), colorScheme (String), isCollected (Boolean)
- 序列化: Gson (`@SerializedName`)

### PptChapter (PPT大纲章节)
- 来源: `com.aipptzhizuozz.bjh.bean.PPTOutLineResBean`
- 字段: chapterId (String), title (String), content (String), order (Int), pageCount (Int)
- 可拖拽排序

### PptProgressData (生成进度)
- 来源: `com.aipptzhizuozz.bjh.bean.PPTProgressResBean`
- 字段: taskId (String), status (String: pending/processing/completed/failed), progress (Int: 0-100)

### PptResultData (生成结果)
- 来源: `com.aipptzhizuozz.bjh.bean.PPTResultResBean`
- 字段: fileUrl (String), previewUrl (String), pageCount (Int), fileSize (Long)

### ProductBean (会员产品)
- 来源: `cn.sanfate.pub.platform` (平台SDK)
- 字段: productId, name, price, originalPrice, period, periodUnit, benefits (List)

### ScanFileBean (扫描文件)
- 来源: `com.aipptzhizuozz.bjh.bean.ScanFileBean`
- 字段: filePath (String), fileName (String), fileIcon (Int, drawable resId), fileDes (String, 描述/时间), timeCategory (String, 分组标签如"今天"/"昨天"/"本周"), showCategory (Boolean, 是否显示分类标签)
- 文件: `app/src/main/java/com/aipptzhizuozz/bjh/bean/ScanFileBean.kt`

### VipFloatBean (VIP浮窗)
- 来源: `cn.sanfate.pub.platform.viewmodel.HomeViewModel`
- 字段: showType, title, content, actionUrl

### 事件模型
- **PaySuccessEvent**: paySucc (Boolean)
- **LimitCampaignEvent**: productBean (ProductBean?)
- **LimitGiftEvent**: productBean (ProductBean?)
- **OaidResultEvent**: (空事件，OAID 获取完成信号)

## 数据库

### Room Database: DBPPTFactory
- 来源: `com.aipptzhizuozz.bjh.db.DBPPTFactory`
- 数据库名: `PPT_DB`

#### PPTCollectTable (收藏表)
```kotlin
@Entity(tableName = "ppt_collect")
data class PPTCollectTable(
    @PrimaryKey val templateId: String,
    val coverUrl: String,
    val title: String,
    val collectTime: Long
)
```

#### PPTCreateTable (创建记录表)
```kotlin
@Entity(tableName = "ppt_create")
data class PPTCreateTable(
    @PrimaryKey(autoGenerate = true) val id: Long,
    val taskId: String,
    val title: String,
    val status: String,
    val fileUrl: String?,
    val createTime: Long
)
```

#### DAO 接口
- **PPTCollectDao**: insert, delete, queryAll, isCollected(templateId)
- **PPTCreateDao**: insert, update, queryAll, queryByTaskId

### ArkTS 迁移目标
- Room → `@ohos.data.relationalStore` (RDB)
- DAO → Repository 模式
- LiveData 观察 → `@State` / `@StorageLink`

## 网络层

### HttpClient
- 来源: `com.aipptzhizuozz.bjh.api.ServiceExt`
- Retrofit + OkHttp (单例)
- Base URL: 由 `pptTemplateUrl` / `createOutlineUrl` / `pptProgressUrl` 等常量定义

### API Endpoints (AIPPTService)
| Method | Path | Description |
|--------|------|-------------|
| POST | `pptTemplateUrl` | 获取PPT模板列表 |
| POST | `createOutlineUrl` | 生成PPT大纲 |
| POST | `createOutlineByDocUrl` | 从文档创建大纲 (Multipart) |
| POST | `createPptByOutLineUrl` | 从大纲生成PPT |
| GET | `pptProgressUrl` | 查询生成进度 |
| GET | `{dynamic}` | 通用GET (收藏/作品列表等) |

### 请求拦截器
- OkHttp Interceptor 链: 日志拦截 → 鉴权头注入 → 公参注入
- 鉴权方式: Token Header

### ArkTS 迁移目标
- Retrofit → `@ohos.net.http` + 自定义请求封装
- OkHttp Interceptor → 自定义拦截器中间件
- Gson 序列化 → 手写 JSON.parse + 类型映射

## 事件系统

### Android 端
- **EventBus** (org.greenrobot.eventbus): 全局事件总线
  - PaySuccessEvent: 支付成功通知
  - LimitCampaignEvent: 限时活动触发
  - LimitGiftEvent: 限时赠品触发
  - OaidResultEvent: OAID 获取完成
- **LiveData / MutableLiveData**: ViewModel 层数据观察
  - loginLiveData, floatInfoLiveData, userInfoLiveData, changeRecommendTab 等

### ArkTS 迁移目标
- EventBus → `@ohos.events.emitter` (系统 EventHub) 或 自定义 EventBus 实现
- LiveData → `@State` / `@Observed` + `@ObjectLink` / `AppStorageV2`

## 偏好设置

- Android 端未检测到显式 SharedPreferences 使用（可能封装在 platform SDK 内部）
- VIP/登录状态可能通过 MMKV 或 DataStore 管理
- ArkTS → `@ohos.data.preferences`

## 权限声明

| Android Permission | HarmonyOS Permission | 用途 |
|-------------------|---------------------|------|
| INTERNET | ohos.permission.INTERNET | 网络访问 |
| ACCESS_NETWORK_STATE | ohos.permission.GET_NETWORK_INFO | 网络状态 |
| ACCESS_WIFI_STATE | ohos.permission.GET_WIFI_INFO | WiFi状态 |
| READ/WRITE_EXTERNAL_STORAGE | ohos.permission.READ/WRITE_USER_STORAGE | 文件读写 |
| MANAGE_EXTERNAL_STORAGE | — (HMOS 无等价) | 全文件管理 |
| VIBRATE | ohos.permission.VIBRATE | 振动 |
| INSTALL_SHORTCUT | ohos.permission.INSTALL_SHORTCUT | 快捷方式 |
| SET_WALLPAPER | ohos.permission.SET_WALLPAPER | 壁纸 |

## 公共组件库

| 组件 | ArkTS 实现 | 说明 |
|------|-----------|------|
| TitleBar | 自定义 `@Component` | 通用标题栏（返回 + 标题 + 右侧按钮） |
| TabBar | `Tabs` + `TabContent` | 首页4Tab导航 |
| LoadingDialog | `CustomDialogController` | 通用加载对话框 |
| ConfirmDialog | `CustomDialogController` | 通用确认对话框 |
| PermissionDialog | `CustomDialogController` | 权限申请对话框 |
| WebViewContainer | `Web` 组件封装 | 内嵌网页容器 |
| TemplateCard | 自定义 `@Component` | PPT模板卡片 |
| FileListItem | 自定义 `@Component` | 文件列表项 |

## 跨栈映射基线（Source→ArkTS）

| 源（Android/Kotlin） | ArkTS 目标 | 难度 | 说明 |
|---------------------|-----------|------|------|
| Retrofit + Gson | @ohos.net.http + 手写JSON | 中 | 无注解处理器，手写请求封装+类型映射 |
| Room + LiveData | RDB + @State/@Observed | 中 | 手动 SQL + 状态管理 |
| EventBus | @ohos.events.emitter | 低 | 系统级事件 API |
| Glide/ImageLoader | Image 组件 + 第三方 | 低 | HMOS Image 原生支持网络图 |
| RecyclerView + Adapter | List + ForEach + LazyForEach | 低 | 声明式替代 |
| ViewPager + Fragment | Swiper + @Component | 低 | 页面组件替代 |
| WebView | Web 组件 | 低 | 系统内置 |
| BottomNavigationView | Tabs(BarPosition.End) | 低 | 系统内置 |
| SharedPreferences | @ohos.data.preferences | 低 | 系统 API |
