<!-- SPDX-License-Identifier: GPL-3.0-only -->

# 源码发布说明

本仓库只发布补丁源码、翻译与验证数据，不发布 GitHub Desktop 本体或修改后的上游 bundle。

## 发布门禁

1. 从已审核并提交的干净分支运行 `scripts/Test-Licensing.ps1`。
2. 在清单精确支持的官方 GitHub Desktop 安装上运行 `scripts/Test-Patch.ps1`，记录安装、幂等、恢复、拒绝路径及源安装未改变的结果。
3. 确认仓库中不存在 `.asar`、`.nupkg`、`.exe`、`.dll`、`.node`、`.pak`、source map、备份或 `resources/app` 上游文件。
4. 运行 `scripts/New-SourceArchive.ps1` 生成源码 ZIP；记录脚本输出的提交、条目数和 SHA-256。
5. 独立列出 ZIP 内容，确认包含根 `LICENSE`、`LICENSE_POLICY.md`、`ASSET_LICENSES.md`、`THIRD_PARTY_NOTICES.md`、`CONTRIBUTING.md` 及 `LICENSES/` 下的许可证原文。
6. 发布说明必须明确当前及未来项目原创源码/功能材料使用 `GPL-3.0-only`，未来逐项确认的自有美术、音频和品牌素材使用 `LicenseRef-EeryFrank-Assets-Permission-Required`，上游 GitHub Desktop 内容保持 MIT，以及历史项目 MIT 和截至 `c4069d88b2fdce86d5b825a48b739aa5067c4ff2`（含）的 LGPL 授权均不撤回。
7. 如果 `ASSET_LICENSES.md` 出现新条目，逐项复核 SHA-256、来源、完整权利链和书面许可；未完成不得发布。

GitHub 自动生成的源码快照也会包含已跟踪的许可证文件，但正式发布仍应优先使用脚本生成并验证过哈希的源码 ZIP。任何测试成功都不能替代用户界面的实际人工检查；若尚未完成，应明确标记 `NEEDS_MANUAL_VALIDATION`。
