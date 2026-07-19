# Feature Index

## Style Configuration
style_set: none

## 领域模型概览

核心实体:
- **UserData**: 用户信息（token, vipLevel, fromChannel, 基本信息）
- **ProductBean**: 会员产品（价格、周期、权益）
- **PptTemplateBean**: PPT模板（id, 封面图, 分类, 标签, 颜色）
- **PptChapter**: PPT大纲章节（标题、内容、顺序）
- **PptOutLineBean**: PPT大纲（主题、章节列表、风格）
- **PptProgressData**: PPT生成进度（状态、百分比）
- **PptResultData**: PPT生成结果（文件URL、预览图）
- **PPTCollectTable**: 收藏的PPT模板（Room Entity）
- **PPTCreateTable**: 创建的PPT记录（Room Entity）
- **ScanFileBean**: 扫描到的文件（路径、类型、大小）
- **TemplateFilterStyleBean/ColorBean**: 模板筛选条件
- **VipFloatBean**: VIP浮窗信息

关系:
- UserData 1:1 VipFloatBean（用户VIP等级→浮窗配置）
- ProductBean 1:N MemberCenter（同一产品多种展示）
- PptTemplateBean N:N TemplateFilter（多对多筛选关系）
- PptOutLineBean 1:N PptChapter（一个大纲多个章节）
- PptOutLineBean → PptProgressData → PptResultData（创建流程链）
- PPTCollectTable/PptTemplateBean N:1 UserData（用户收藏模板）

## 功能清单

| ID | 功能 | 优先级 | 依赖 | 涉及页面 | 状态 |
|----|------|--------|------|---------|------|
| F001 | 认证登录 | P0 | base | 0004, 0005 | pending |
| F002 | 会员支付 | P0 | base+network | 0006, 0009, 0010 | pending |
| F003 | 首页导航 | P0 | F001, F002 | 0011 | pending |
| F004 | PPT核心流程 | P0 | base+network | 0014, 0015, 0016, 0017, 0021 | pending |
| F005 | 文件管理 | P1 | base | 0018, 0019 | pending |
| F006 | 作品管理 | P1 | F004 | 0020 | pending |
| F007 | 个人中心 | P1 | F001 | 0013 | pending |
| F008 | WebView容器 | P1 | base | 0002, 0008 | pending |
| F009 | 引导页 | P2 | — | 0012 | pending |
| F010 | 通用页面 | P2 | — | 0001, 0003, 0007 | pending |

## 依赖图

```
base → F001(认证) → F003(首页) → F002(会员)
base → F004(PPT核心) → F006(作品)
base → F005(文件管理)
base → F008(WebView)
F001 → F007(个人中心)
F004 → F002(会员——PPT生成需VIP)
```

## 执行顺序（拓扑排序）
1. feature-base (共享基础设施)
2. F001, F004, F005, F008 (可并行 — 无相互依赖)
3. F002, F003, F006, F007 (依赖上层)
4. F009, F010 (次要功能)
