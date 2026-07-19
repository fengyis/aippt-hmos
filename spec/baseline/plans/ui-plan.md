# UI Conversion Plan

## Context
- Source: spec/baseline/ui-manifest.md
- Style: none
- Total pages: 21
- Batches: 5
- Estimated total agents: 21

## Batch 1: P0 Core Pages + Auth (confidence: medium)
hard_limit: 5
actual_pages: 5

| 序号 | 页面 | Android 来源 | confidence | 可并行 | owning_slice | 预计 agent |
|------|------|-------------|-----------|--------|--------------|-----------|
| 0001 | SplashPage | SplashActivity | medium | — | Slice 10 | 1 |
| 0004 | LoginPage | LoginActivity | medium | 与 0005 并行 | Slice 1 | 1 |
| 0005 | AccountInfoPage | AccountInfoActivity | medium | 与 0004 并行 | Slice 1 | 1 |
| 0006 | MemberCenterPage | MemberCenterActivitiy | medium | — | Slice 2 | 2 |
| 0011 | HomePage | HomeActivity | medium | — | Slice 3 | 2 |

编译检查点: Batch 1 完成后 + Batch handoff

## Batch 2: P0 PPT Core Flow (confidence: medium)
hard_limit: 5
actual_pages: 5

| 序号 | 页面 | Android 来源 | confidence | 可并行 | owning_slice | 预计 agent |
|------|------|-------------|-----------|--------|--------------|-----------|
| 0014 | PPTTemplatePreviewPage | PPTTemplatePreviewPage | medium | — | Slice 4 | 2 |
| 0015 | CreateOutLinePage | CreateOutLinePage | medium | — | Slice 4 | 2 |
| 0016 | ChoicePPTTemplatePage | ChoicePPTTemplatePage | medium | 与 0021 并行 | Slice 4 | 1 |
| 0017 | PPTFilePage | PPTFilePage | medium | — | Slice 4 | 1 |
| 0021 | SearchPage | SearchPagePage | medium | 与 0016 并行 | Slice 4 | 1 |

编译检查点: Batch 2 完成后 + Batch handoff

## Batch 3: P1 Member + WebView + Refund (confidence: medium)
hard_limit: 5
actual_pages: 5

| 序号 | 页面 | Android 来源 | confidence | 可并行 | owning_slice | 预计 agent |
|------|------|-------------|-----------|--------|--------------|-----------|
| 0002 | WebViewPage | WebViewActivity | medium | 与 0008 并行 | Slice 8 | 1 |
| 0008 | CustomerServiceWebPage | CustomerServiceWebActivity | medium | 与 0002 并行 | Slice 8 | 1 |
| 0009 | ManageRenewPage | ManageRenewActivity | medium | 与 0010 并行 | Slice 2 | 1 |
| 0010 | RefundProgressPage | RefundProgressActivity | medium | 与 0009 并行 | Slice 2 | 1 |
| 0012 | GuidePage | GuideActivity | medium | — | Slice 9 | 1 |

编译检查点: Batch 3 完成后 + Batch handoff

## Batch 4: P1 Works + File + Mine (confidence: medium)
hard_limit: 5
actual_pages: 4

| 序号 | 页面 | Android 来源 | confidence | 可并行 | owning_slice | 预计 agent |
|------|------|-------------|-----------|--------|--------------|-----------|
| 0013 | MinePage | MineActivity | medium | — | Slice 7 | 1 |
| 0018 | FileUploadPage | FileUploadPage | medium | 与 0019 并行 | Slice 5 | 1 |
| 0019 | FileListPage | FileListPage | medium | 与 0018 并行 | Slice 5 | 1 |
| 0020 | WorksPage | WorksPage | medium | — | Slice 6 | 1 |

编译检查点: Batch 4 完成后 + Batch handoff

## Batch 5: P2 Low Priority (confidence: medium)
hard_limit: 5
actual_pages: 2

| 序号 | 页面 | Android 来源 | confidence | 可并行 | owning_slice | 预计 agent |
|------|------|-------------|-----------|--------|--------------|-----------|
| 0003 | AboutUsPage | AboutUsActivity | medium | 与 0007 并行 | Slice 10 | 1 |
| 0007 | ShortCutPage | ShortCutActivity | medium | 与 0003 并行 | Slice 10 | 1 |

编译检查点: Batch 5 完成后

## Summary
- P0 pages: 8 (Batch 1-2)
- P1 pages: 11 (Batch 1-4, note: 0005+0021 grouped with P0 batches for Slice co-location)
- P2 pages: 2 (Batch 5)
- Total agents: 21
- Source precision: 133/133 ACs verified against 26 Kotlin source files (C4-pre complete)
