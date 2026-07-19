# F006-works: 作品管理

```yaml
complexity: simple
tier: standard
depth: full
```

## 范围

提供用户已创建的PPT作品和收藏的PPT模板的管理功能，支持作品预览、删除、收藏模板预览。

**涉及页面**：
- `page_0020_WorksPage` — 作品管理容器页面，嵌入 WorksFragment
- `WorksFragment` — 作品列表 Fragment，双Tab（我的创建 / 我的收藏）切换

**依赖**：F004（PPT核心流程——作品来源于PPT生成结果，预览和模板查看依赖 F004 页面）

**源码锚点**：
- `WorksPage.kt`: Activity 容器，接收 type 参数（TAB_TYPE_MY_CREATE=1/TAB_TYPE_MY_COLLECT=2），通过 createOrShowFragment 加载 WorksFragment
- `WorksFragment.kt`: 双 RecyclerView 模式（rvWorks 线性列表 PPTCreateTable + rvCollects 2列网格 PPTCollectTable），TitleBar 管理按钮("管理"/"取消")，删除管理模式（checkbox切换+deleteList），EventBus PptAddSuccessEvent 监听，PptDbViewModel 数据观察

## 数据流

```
WorksPage.openPage(activity, type)
  → intent 传 type 参数
    → createOrShowFragment(flContainer) { WorksFragment.newInstance(type, showTitleBarLeft=true) }
      → WorksFragment.initView()
        → tabType 决定初始 Tab:
          ├─ TAB_TYPE_MY_CREATE (1) → titleBar.title="我的作品", titleBar.rightTitle="管理"
          │   → rvWorks VISIBLE, rvCollects GONE
          │   → pptDBViewModel.findAllPPT() → pptListLiveData → pptListAdapter.models
          └─ TAB_TYPE_MY_COLLECT (2) → titleBar.title="我的收藏", titleBar.rightTitle=""
              → rvWorks GONE, rvCollects VISIBLE
              → pptDBViewModel.queryCollectList() → collectListLiveData → templateAdapter.models

用户点击"管理"按钮（titleBar rightTitle）
  → isDelete = !isDelete
    → changeDeleteView(): titleBar.rightTitle 切换 "管理"/"取消", llDelete VISIBLE/GONE
    → rvWorks.bindingAdapter.toggle(isDelete) 开启/关闭 checkbox 模式

全选操作
  → tvSelectAll.click → checkedAll(true/false)
    → tvSelectAll.text 切换 "全选"/"取消全选"

删除操作
  → tvDelete.click → 收集 isSelected=true 的 PPTCreateTable → pptDBViewModel.deleteList(deleteLists)

用户点击作品项(ppt_item_root)
  → PPTFilePage.previewPPTFile(activity, model, true) → 跳转预览

用户点击收藏项(ppt_template_root)
  → PPTTemplatePreviewPage.previewTemplate(activity, generatePPTTemplateBean()) → 跳转模板预览

EventBus 监听
  → PptAddSuccessEvent → pptDBViewModel.findAllPPT() 刷新列表
```

**关键数据模型**：
- `PPTCreateTable`: id (Long, autoGenerate), taskId (String), title (String), status (String), fileUrl (String?), createTime (Long), isSelected (Boolean, 运行时), coverImgSrc, getFormatTime()
- `PPTCollectTable`: templateId (String, PK), coverUrl (String), title (String), collectTime (Long), detailImageBean(), generatePPTTemplateBean(), getTemplateName()

## 状态管理

| 状态 | 类型 | 来源 | ArkTS 映射 |
|------|------|------|-----------|
| 作品列表 | List\<PPTCreateTable\> | PptDbViewModel.pptListLiveData | `@Local pptList: PPTCreateTable[]` |
| 收藏列表 | List\<PPTCollectTable\> | PptDbViewModel.collectListLiveData | `@Local collectList: PPTCollectTable[]` |
| 加载状态 | Boolean | PptDbViewModel.loadingStatusLiveData | `@Local isLoading: boolean` |
| Tab 类型 | Int | arguments.getInt("type") | `@Local tabType: number` (1=create, 2=collect) |
| 删除模式 | Boolean | isDelete 本地变量 | `@Local isDeleteMode: boolean` |
| 全选状态 | Boolean | isCheckedAll() | `@Local isAllSelected: boolean` |

## 对接点

**入口**：
- 其他页面通过 `WorksPage.openPage(activity, type)` 跳转
- MineFragment 中已注释的入口（fl_my_collect/fl_my_works）原可跳转 WorksPage

**出口**：
- 作品项点击 → `PPTFilePage.previewPPTFile()` → F004 预览
- 收藏项点击 → `PPTTemplatePreviewPage.previewTemplate()` → F004 模板预览
- TitleBar 左侧返回 → `requireActivity().finish()`

**功能点**：
| 功能点 | Android 实现 | ArkTS 目标 |
|--------|-------------|-----------|
| 双Tab列表切换 | tabType 控制 rvWorks/rvCollects 显隐 | Tabs + TabContent (我的创建/我的收藏) |
| 作品线性列表 | BRV BindingAdapter + linear + divider | List + LazyForEach + @ComponentV2 item |
| 收藏网格列表 | BRV BindingAdapter + grid(2) + divider | Grid(columnsTemplate:'1fr 1fr') + @ComponentV2 item |
| 删除管理模式 | titleBar.rightTitle 切换 + toggle(checkbox) | isDeleteMode 控制 checkbox 显隐 + 批量操作栏 |
| 数据刷新 | PptAddSuccessEvent (EventBus) → findAllPPT() | emitter.on('PPT_ADD_SUCCESS') → 重新查询 |
| 空状态 | tvEmpty.visibleOrGone(list.isEmpty()) | emptyList → 显示"我的作品/收藏空空如也" |

## 验收标准

| # | 标准 | 源（Android） | 标（ArkTS） |
|---|------|-------------|-----------|
| 1 | 默认显示"我的创建"Tab | WorksFragment L84-85: `titleBar.title = if (tabType == TAB_TYPE_MY_CREATE) "我的作品" else "我的收藏"` | Tabs 默认 index=0，标题"我的作品" |
| 2 | 切换到"我的收藏"显示收藏网格 | WorksFragment L182-204 `changeTab(TAB_TYPE_MY_COLLECT)`: rvWorks GONE, rvCollects VISIBLE, `queryCollectList()` | TabContent 切换 + Grid 2列展示 |
| 3 | "管理"按钮切换删除模式 | WorksFragment L101-108 `onRightClick`: `isDelete = !isDelete; changeDeleteView()`; L206-217 `changeDeleteView()` | 点击管理 → isDeleteMode=true → 底部操作栏显示 |
| 4 | 删除模式下显示 checkbox | WorksFragment L237-238: `ivCheck.visibility = if (toggleMode) VISIBLE else GONE` | isDeleteMode=true → item 左侧显示 Checkbox |
| 5 | "全选"/"取消全选"联动 | WorksFragment L145-153: `checkedAll(true/false)` + `tvSelectAll.text` 切换 + `isChecked` | 全选按钮切换 selectedAll boolean + forEach 更新 |
| 6 | 删除选中项，无选中时 toast"请选择要删除的项目" | WorksFragment L121-134: 收集 `isSelected=true` 项 → `deleteList(deleteLists)`; L128-130: `if (deleteLists.isEmpty()) { "请选择要删除的项目".toast(); return }` | 批量删除 API 调用 + 列表刷新; 空选中时 `promptAction.showToast($r('app.string.select_item_first'))` |
| 7 | 点击作品进入预览 | WorksFragment L261-266 `onClick(R.id.ppt_item_root)`: `PPTFilePage.previewPPTFile(activity, model, true)` | NavPathStack.pushPathByName('PPTFilePage', params) |
| 8 | 点击收藏模板进入模板预览 | WorksFragment L293-298 `onClick(R.id.ppt_template_root)`: `PPTTemplatePreviewPage.previewTemplate(activity, generatePPTTemplateBean())` | NavPathStack.pushPathByName('PPTTemplatePreview', params) |
| 9 | 新增作品后自动刷新列表 | WorksFragment L314-317 `@Subscribe pptAddSuccessEvent`: `pptDBViewModel.findAllPPT()` | emitter 监听 + reloadList() |
| 10 | 空列表显示空状态文案 | WorksFragment L86-87: `tvEmpty.text = if (tabType == TAB_TYPE_MY_CREATE) "我的作品空空如也" else "我的收藏空空如也"`; L169-170: `tvEmpty.visibleOrGone(list.isEmpty())` | listEmpty → Text($r('app.string.works_empty')) |
| 11 | 管理模式下列表为空时 toast"作品列表为空" | WorksFragment L103-105: `if (pptListAdapter?.models?.isEmpty() == true) { "作品列表为空".toast(); return }` | `if (isDeleteMode && list.length === 0) { promptAction.showToast($r('app.string.works_list_empty')) }` |
