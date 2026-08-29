<!-- SPDX-License-Identifier: GPL-3.0-only -->
<!-- License-Migration: existing-MIT-and-LGPL-grants-not-revoked -->
<!-- Asset-Policy: unmodified-only-inside-unmodified-official-package; separate-use-requires-prior-written-permission -->
<!-- Trademark-Policy: no-trademark-rights-granted -->

# 许可证范围政策

本文件说明仓库内不同内容的许可证边界。它不会修改任何第三方许可证，不会撤回已经取得的许可，也不会授予任何商标权。

## 当前版本、未来修改与历史授权

自本次许可证政策更新起，本项目有权授权的当前源码、功能材料及后续修改按本文件列出的许可证发布。

历史授权不可追溯撤销：

- 迁移前已经按 MIT 许可证取得的项目历史版本和副本继续保留当时的授权。完整文本保存在 [`LICENSES/MIT-legacy-project.txt`](LICENSES/MIT-legacy-project.txt)。
- 截至提交 `c4069d88b2fdce86d5b825a48b739aa5067c4ff2`（含）已经按 `LGPL-3.0-or-later` 取得的项目版本和副本继续保留当时的授权。完整文本保存在 [`LICENSES/LGPL-3.0-or-later.txt`](LICENSES/LGPL-3.0-or-later.txt)。

这些历史文件只记录既有授权，不表示本次政策更新后的新增内容自动获得 MIT、LGPL 或多重授权。

## GPL-3.0-only 范围

以下项目原创内容的当前版本和未来修改按 [`GPL-3.0-only`](LICENSE) 授权：

- `scripts/**/*.ps1` 中的补丁、验证、恢复、审计和归档源码；
- `.github/workflows/**`、`.gitattributes`、`.gitignore` 等项目构建与 CI 配置；
- `manifest.json` 中由本项目编排的清单结构、补丁标识和验证数据；
- `translations.zh-CN.json` 中由本项目编排的结构、条目标识、模式、中文译文及相关功能数据；
- `README.md`、`SECURITY.md`、`CONTRIBUTING.md`、`docs/**`、本政策、素材清单和第三方告知中的项目原创文字与图表。

`translations.zh-CN.json` 是混合来源数据。每个 `original` 字段用于精确匹配 GitHub Desktop 3.6.4 上游英文界面原文；这些上游字符串、GitHub 产品名称及其他上游标识不因出现在本仓库而被重新授权，仍受 GitHub Desktop 上游 MIT 许可证及适用商标规则约束。上游 MIT 原文保存在 [`LICENSES/MIT-GitHub-Desktop.txt`](LICENSES/MIT-GitHub-Desktop.txt)。该文件的 `projectContentLicense` 元数据只声明本项目有权授权的原创部分。

## 未来自有美术、音频与品牌素材

仓库当前没有项目自有美术、音频或品牌媒体资产，也没有任何当前文件被指定适用 `LicenseRef-EeryFrank-Assets-Permission-Required`。当前状态与未来逐文件清单见 [`ASSET_LICENSES.md`](ASSET_LICENSES.md)。

未来新增且确认由本项目有权授权的视觉、动画、字体、音频、Logo、图标或其他品牌/创意素材，默认使用 [`LicenseRef-EeryFrank-Assets-Permission-Required`](LICENSES/LicenseRef-EeryFrank-Assets-Permission-Required.txt)，但只有在 `ASSET_LICENSES.md`、相邻元数据或文件级声明中逐项明确指定后才适用。目录路径和仓库中存在许可证正文均不会自动分配该许可。

该许可仅允许未经修改的素材随未经修改的官方发布包一起使用和分发。单独提取、复用、修改、再分发、商业使用或品牌使用必须事先取得书面许可。加入任何素材前还必须完成来源与权利审查；第三方内容和已按 MIT、CC、Apache、C2PA 或其他条款发布的历史内容继续保留原条款，本政策不会替换或缩减其既有授权。

仓库保留的 [`LICENSES/CC-BY-SA-4.0.txt`](LICENSES/CC-BY-SA-4.0.txt) 是上一版政策和可能的历史授权记录，不是未来素材的默认许可证；仓库当前没有文件被清单指定为 CC BY-SA 4.0。

## 第三方内容、依赖与商标

第三方代码、字符串、运行环境、服务、名称和素材始终保留其各自许可证与权利边界。详细清单见 [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)。本仓库不包含或再分发 GitHub Desktop 的 bundle、安装包、图标或其他上游应用文件。

“GitHub”和“GitHub Desktop”仅用于准确说明兼容对象。本项目与 GitHub, Inc. 没有隶属、授权或背书关系；GPL、LicenseRef、历史 MIT/LGPL/CC 文本均不授予 GitHub 名称、Logo、Octocat 或其他商标权利。

## 贡献

贡献内容必须遵守 [`CONTRIBUTING.md`](CONTRIBUTING.md) 的来源与许可要求。提交者只能贡献自己有权按对应范围授权的内容；第三方内容必须单独标明来源、许可证和适用范围。素材贡献必须先提供可核验的来源与权利证据，并取得维护者书面确认后再进入 `ASSET_LICENSES.md`。
