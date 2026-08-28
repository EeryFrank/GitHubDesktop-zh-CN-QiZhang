<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# 源码发布说明

本仓库只发布补丁源码、翻译与验证数据，不发布 GitHub Desktop 本体或修改后的上游 bundle。

## 发布门禁

1. 从已审核并提交的干净分支运行 `scripts/Test-Licensing.ps1`。
2. 在清单精确支持的官方 GitHub Desktop 安装上运行 `scripts/Test-Patch.ps1`，记录安装、幂等、恢复、拒绝路径及源安装未改变的结果。
3. 确认仓库中不存在 `.asar`、`.nupkg`、`.exe`、`.dll`、`.node`、`.pak`、source map、备份或 `resources/app` 上游文件。
4. 运行 `scripts/New-SourceArchive.ps1` 生成源码 ZIP；记录脚本输出的提交、条目数和 SHA-256。
5. 独立列出 ZIP 内容，确认包含根 `LICENSE`、`LICENSE_POLICY.md`、`THIRD_PARTY_NOTICES.md`、`CONTRIBUTING.md` 及 `LICENSES/` 下的许可证原文。
6. 发布说明必须明确当前项目内容使用 LGPL、未来原创素材政策使用 CC、上游 GitHub Desktop 内容保持 MIT，以及历史 MIT 授权不撤回。

GitHub 自动生成的源码快照也会包含已跟踪的许可证文件，但正式发布仍应优先使用脚本生成并验证过哈希的源码 ZIP。任何测试成功都不能替代用户界面的实际人工检查；若尚未完成，应明确标记 `NEEDS_MANUAL_VALIDATION`。
