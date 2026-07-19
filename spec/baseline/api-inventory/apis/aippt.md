# AI PPT 生成接口（AIPPTService — 讯飞 API）

> Service：`AIPPTService` | 文件：`app/src/main/java/com/aipptzhizuozz/bjh/api/AIPPTService.kt`
> 端点数：5 | 通道：`https://zwapi.xfyun.cn` | 公共约定见 [../common.md](../common.md)
> 认证：自定义 — appId + secret + XXTEA 加密签名，通过 HeaderMap 注入
> runtime：⬜ static-only

## 端点速览

| 方法 | 路径 | 接口名 | runtime |
|------|------|--------|:--:|
| POST | `/api/ppt/v2/template/list` | requestPptTemplateList | ⬜ |
| POST | `/api/ppt/v2/createOutline` | createOutLineByQuery | ⬜ |
| POST | `/api/ppt/v2/createOutlineByDoc` | createOutLineByFile | ⬜ |
| POST | `/api/ppt/v2/createPptByOutline` | createPptByOutLine | ⬜ |
| GET | `/api/ppt/v2/progress` | queryPptProgress | ⬜ |

**异步任务流程**：`createOutline → createPptByOutline → queryPptProgress (轮询) → 完成`

---

## 认证机制（讯飞专属）

本 Service 不走主站 Token 认证，使用独立的讯飞开放平台鉴权：

1. 请求体通过 **XXTEA 算法**加密（密钥 `f3224b4afb454344867954d0a4d38bf1`）
2. 每请求通过 `@HeaderMap` 注入：`appId=4fe117ca` + 加密签名
3. ⚠ **迁移难点**：XXTEA 不是标准加密算法，HMOS 端需用 `cryptoFramework` (`@kit.CryptoArchitectureKit`) 自实现；或者确认讯飞是否提供 HTTP 鉴权替代方案。

---

## 1. requestPptTemplateList — 获取 PPT 模板列表

- **方法**：`POST /api/ppt/v2/template/list`（REST）
- **Service**：`AIPPTService.requestPptTemplateList`（AIPPTService.kt:70）
- **runtime**：⬜ static-only

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| headerMap | MutableMap | 是 | 自定义鉴权 Header（appId/secret/签名） |
| requestBody | RequestBody | 是 | 模板查询条件（分类/分页等） |

**响应参数**：`PptTemplateResBean`

| 字段 | 类型 | 说明 |
|------|------|------|
| *(待 Bean 读取)* | — | Bean 定义位于 `app` 模块，需读取源码获取字段 |

---

## 2. createOutLineByQuery — 根据查询词生成大纲

- **方法**：`POST /api/ppt/v2/createOutline`（REST）
- **Service**：`AIPPTService.createOutLineByQuery`（AIPPTService.kt:79）
- **特殊标注**：`@FormUrlEncoded`

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| headerMap | MutableMap | 是 | 鉴权 Header |
| query | String | 是 | 用户输入的 PPT 主题查询词（如"产品介绍PPT"） |

**响应参数**：`PptOutLineResBean` → 见 [common.md](../common.md) §共享响应体

---

## 3. createOutLineByFile — 上传文档生成大纲

- **方法**：`POST /api/ppt/v2/createOutlineByDoc`（REST）
- **Service**：`AIPPTService.createOutLineByFile`（AIPPTService.kt:90）
- **特殊标注**：**multipart** 文件上传

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| headerMap | MutableMap | 是 | 鉴权 Header |
| parts | List\<Part\> | 是 | 文件 multipart 上传体（WORD/PDF 文档） |

**响应参数**：`PptOutLineResBean`

> ⚠ **迁移关注点**：HMOS 端 multipart 上传用 `http.request()` + `multiFormDataList`，或 rcp multipart。

---

## 4. createPptByOutLine — 根据大纲生成 PPT

- **方法**：`POST /api/ppt/v2/createPptByOutline`（REST）
- **Service**：`AIPPTService.createPptByOutLine`（AIPPTService.kt:99）

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| headerMap | MutableMap | 是 | 鉴权 Header |
| requestBody | RequestBody | 是 | 大纲数据 + 模板选择 + 配置参数 |

**响应参数**：`PptResultResBean`（含 `sid` 字段，用于后续进度轮询）

---

## 5. queryPptProgress — 轮询 PPT 生成进度

- **方法**：`GET /api/ppt/v2/progress`（REST）
- **Service**：`AIPPTService.queryPptProgress`（AIPPTService.kt:105）
- **特殊标注**：**唯一 GET 请求**，异步任务轮询

**请求参数**

| 参数 | 类型 | 必需 | 说明 |
|------|------|:--:|------|
| headerMap | MutableMap | 是 | 鉴权 Header |
| sid | String | 是 | PPT 任务 ID（来自 createPptByOutLine 返回值） |

**响应参数**：`PptProgressResBean`

| 字段 | 类型 | 说明 |
|------|------|------|
| *(待 Bean 读取)* | — | 含 progress/status 字段；status=completed 时可获取 PPT 下载地址 |

**轮询流程**：
```
1. createPptByOutline 返回 sid
2. 启动定时轮询 queryPptProgress(sid)
3. status=processing → 继续等待
4. status=completed → 停止轮询，展示结果
5. status=failed → 展示错误信息
```
