# AIPPT

> Android → HarmonyOS 迁移工作区：AIPPT。
> 源项目：/Users/fengyi/Workspace/fengyis/AIPPT（传统 View 体系，含 XML 布局）。
> Spec baseline 在 `spec/baseline/`；项目决策历史在 `spec/decision-ledger.md`。
> **模型**: DeepSeek (via ANTHROPIC_BASE_URL)；常规 deepseek-chat，复杂分析切 deepseek-v4-pro。

## Progress

| Layer | Status | Details |
|-------|--------|---------|
| a2h-spec | Done | 10 features, 133 ACs, 100% source-traceable |
| a2h-plan | Done | 15 slices, 4 plans, 27 agents |
| Code gen | Done | 56 .ets files, 22 pages, 10 ViewModels, 7 components |
| Build | Next | Open DevEco → generate project → overlay ets/ |
| Wire | Next | 48 FWD-REF markers → real API calls |
| Verify | Next | a2h-verify visual comparison |

**Quick commands**:
```bash
cd /Users/fengyi/Workspace/fuxi-ailabs/aippt_experiments/aippt-hmos/EXP
git push origin master    # push to github.com/fengyis/aippt-hmos
open -a DevEco-Studio     # IDE project setup
```

## 决策来源与禁止交互（HARD-GATE）

唯一事实源：`spec/decision-ledger.md`。快速定位用其顶部「决策索引」段（D-编号一行结论速查）；**涉及某类目时按类目 / D-编号 grep 取完整决策正文**（背景/候选/依据/影响/运行期验证项），无需通读全文。

凡涉及以下**迁移决策类目（C0–C16）**判断，先 grep ledger 对应类目，再做任何操作：
- 范围取舍（页面/功能要不要做、是否本轮）
- 技术替代方案（平台无对等能力、SDK 留桩/降级/砍）
- UX 行为差异（系统组件 vs 应用内、后台行为、降级兜底）
- 工程配置（签名/entitlement/密钥策略）

执行规则：
- ledger 命中 → 按之执行，不再询问用户
- ledger 未命中 → fail-fast，把缺口写入 `spec/migration-report.md` 的「决策缺口」段，
  禁止交互式追问；由下一轮 grill 补齐
- 与其他文档（旧报告 / CLAUDE.md 旧描述）冲突时，ledger 优先

> **适用范围**：迁移决策类目 C0–C16。普通代码实现层面的不清晰按下方通用准则处理。

## 通用行为准则

降低常见 LLM 编码错误的行为准则。**取舍**：偏向谨慎而非速度；琐碎任务用判断力。

### 1. 极简优先

**只写解决问题所需的最少代码，不要任何揣测性扩展。**

- 不写超出需求的功能
- 不为单次使用的代码做抽象
- 不引入未被要求的"灵活性"或"可配置性"
- 不为不可能发生的场景做错误处理
- 写了 200 行能用 50 行的，重写

> **迁移场景例外**：与 spec / Android 源一致优先于代码量；**不主动 simplify 已 spec 出来的内容**。忠实复刻（C12 类目）的决议优先于本原则——Android 原版 200 行的 8 tab 页面在 spec 里就是 8 tab，不要"优化"成 3 tab。

自检："高级工程师会觉得这过度复杂吗？"——如是，简化。

### 2. 外科手术式改动

**只动你必须动的；只清理你自己造成的混乱。**

编辑已有代码时：
- 不要"顺手优化"相邻代码、注释或格式
- 不要重构没坏的东西
- **优先 match HarmonyOS / ArkTS 最佳实践**，不要 match Android 风格、也不要 match 偶然的早期 ArkTS 产物风格——pipeline 生成代码以最佳实践为准
- 若发现无关的死代码，提及它，不要删除

当你的改动产生孤儿（orphans）时：
- 移除**你的改动**导致变得未使用的 import / 变量 / 函数
- 不要删除既有的死代码，除非被要求

**自检**：每一行被改的代码都应能直接追溯到 **plan / ledger / spec / 当前 task**——迁移场景下"用户的请求"通常只是"执行"，真正的事实源是 plan + ledger，不要尝试追溯到用户对话中某一句话。

### 3. 暴露矛盾，不取折中

代码库中两种模式相互矛盾时，**选其一**（更新的 / 更经验证的），说明选择理由，把另一个标记待清理。

**不要把矛盾的模式糅在一起取折中**——和稀泥不是解法，等于又造出第三种与前两种都冲突的模式。

### 4. 先读后写

添加代码前，先读：**exports / 直接调用方 / 共享工具**。

"看起来正交"是危险信号——你以为不相关的东西，常常其实有关联。如果不确定代码为何这样组织，**先弄清楚**（查代码 / 读注释 / 看测试）**再动手**。

### 5. 每个关键步骤后设检查点

每完成一个有意义的步骤，**先总结**再继续：做了什么 / 已验证什么 / 还剩什么。

**不要从一个你自己说不清楚的状态继续推进**。如果失去线索，停下来**重新陈述**当前状态，再决定下一步。

### 6. 遵循代码库既有约定

即使你不同意，也要**遵循代码库的约定**。代码库内部的规范性高于个人喜好。

### 7. 失败要响亮（Fail Loud）

- 如果有任何东西被**静默跳过**，标注"已完成"就是**错的**

---

**这套准则在以下指标改善时表明它在起作用**：diff 中无关改动减少、因过度复杂而重写的次数减少、静默跳过的"完成"声明被显式失败取代。

> **适用范围**：通用代码实现层面（编码风格 / 修改纪律 / 矛盾处理 / 状态自检 / 失败暴露）。
> 迁移决策类目（C0–C16，含范围 / SDK 选型 / UX 退化 / 签名密钥 / 忠实度等）由上方决策段优先约束，按 ledger 走、不询问。
> 成功标准（编译 PASS / visual-verify PASS / ledger 合规）由 a2h-execute / a2h-verify skill HARD-GATE 内置，CLAUDE.md 不重复。

> 《决策来源与禁止交互（HARD-GATE）》《HarmonyOS 知识查询优先级》（如存在）《通用行为准则》三个标题段由 a2h-spec Step C4.8b 自动同步：**请勿重命名这三个标题、勿手工编辑段内内容**；规则演进请回到 a2h-spec 修改模板后重跑。
