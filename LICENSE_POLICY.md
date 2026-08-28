<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->
<!-- License-Migration: existing-MIT-grants-not-revoked -->
<!-- Trademark-Policy: no-trademark-rights-granted -->

# 许可证范围政策

本文件说明仓库内不同内容的许可证边界。它不会修改任何第三方许可证，也不会授予任何商标权。

## 当前版本与历史 MIT 授权

自本许可证迁移提交起，本项目自有内容的当前版本和后续修改按本文件列出的许可证发布。迁移前已经在 MIT 许可证下获得的历史版本和副本继续保留当时的授权；本项目不撤回或缩减已经授予的 MIT 权利。迁移前使用的完整 MIT 文本保存在 [`LICENSES/MIT-legacy-project.txt`](LICENSES/MIT-legacy-project.txt)，仅用于记录历史授权，不表示迁移后的新增内容继续双重授权。

## LGPL-3.0-or-later 范围

以下项目原创内容按 [`LGPL-3.0-or-later`](LICENSE) 授权：

- `scripts/**/*.ps1` 中的补丁、验证、恢复、审计和归档源码；
- `.github/workflows/**`、`.gitattributes`、`.gitignore` 等项目构建与 CI 配置；
- `manifest.json` 中由本项目编排的清单结构、补丁标识和验证数据；
- `translations.zh-CN.json` 中由本项目编排的结构、条目标识、模式、中文译文及相关功能数据；
- `README.md`、`SECURITY.md`、`CONTRIBUTING.md`、`docs/**`、本政策和第三方告知文件中的项目原创文字与图表。

`translations.zh-CN.json` 是混合来源数据。每个 `original` 字段用于精确匹配 GitHub Desktop 3.6.4 上游英文界面原文；这些上游字符串、GitHub 产品名称及其他上游标识不因出现在本仓库而被重新授权，仍受 GitHub Desktop 上游 MIT 许可证及适用商标规则约束。上游 MIT 原文保存在 [`LICENSES/MIT-GitHub-Desktop.txt`](LICENSES/MIT-GitHub-Desktop.txt)。文件中的 SPDX 或许可证元数据只声明本项目有权授权的原创部分。

## 未来原创美术与音频

仓库当前没有按 Creative Commons 许可证发布的原创美术或音频。将来新增且确认由本项目有权授权的原创视觉、动画、字体或音频素材，只有放入以下明确目录并且没有文件级例外声明时，才默认按 [`CC-BY-SA-4.0`](LICENSES/CC-BY-SA-4.0.txt) 授权：

- `assets/original/**`
- `docs/assets/original/**`
- `art/original/**`

`branding/**` 目录以及文件名或用途明确属于 Logo、图标、项目标识或其他品牌素材的文件，默认不进入 CC-BY-SA-4.0 范围。此类文件在加入仓库前必须带有单独、明确的分发条款。路径规则不能替代来源证明；来源不明、第三方生成限制不明或包含第三方元素的素材不得标记为本项目原创 CC 内容。

## 第三方内容、依赖与商标

第三方代码、字符串、运行环境、服务、名称和素材始终保留其各自许可证与权利边界。详细清单见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。本仓库不包含或再分发 GitHub Desktop 的 bundle、安装包、图标或其他上游应用文件。

“GitHub”和“GitHub Desktop”仅用于准确说明兼容对象。本项目与 GitHub, Inc. 没有隶属、授权或背书关系；LGPL、CC 或历史 MIT 文本均不授予 GitHub 名称、Logo、Octocat 或其他商标权利。

## 贡献

贡献内容必须遵守 [`CONTRIBUTING.md`](CONTRIBUTING.md) 的来源与许可要求。提交者只能贡献自己有权按对应范围授权的内容；第三方内容必须单独标明来源、许可证和适用范围。
