<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->
<!-- Trademark-Policy: no-trademark-rights-granted -->

# 第三方告知

本项目为独立、非官方兼容补丁。仓库只包含补丁源码、中文翻译与验证数据，不包含或再分发 GitHub Desktop 的安装包、二进制、bundle、source map、包、图标或其他上游应用文件。

## GitHub Desktop

- 上游版权：Copyright (c) GitHub, Inc.
- 上游仓库：<https://github.com/desktop/desktop>
- 精确目标：`release-3.6.4` / `28955b81295df6a3232857c15caba933bd7cd03b`
- 上游许可证：MIT
- 该目标版本的上游 MIT 原文：[LICENSES/MIT-GitHub-Desktop.txt](LICENSES/MIT-GitHub-Desktop.txt)
- 上游原文页面：<https://github.com/desktop/desktop/blob/release-3.6.4/LICENSE>

`translations.zh-CN.json` 的 `original` 字段包含用于精确匹配受支持版本的 GitHub Desktop 英文界面原文。这些上游字符串、GitHub 产品名称及其他上游标识保留其上游 MIT 许可证和权利边界；本项目的 LGPL 许可证只覆盖有权授权的项目原创结构、逻辑、中文译文和功能数据。

## CI 与运行环境

| 组件 | 用途 | 处理方式 |
| --- | --- | --- |
| `actions/checkout@v4` | GitHub Actions 中检出仓库 | 运行时 CI 依赖，保持其上游 MIT 许可证；不打包进本项目源码归档 |
| Windows PowerShell 5.1+ | 执行补丁与测试 | 系统运行环境，不由本项目重新授权 |
| .NET Framework 系统类库 | 哈希、JSON、文件与压缩包处理 | 系统运行环境，不由本项目重新授权 |
| GitHub Desktop 内置 Electron/Node | 对临时生成的 JavaScript 执行 `--check` | 属于用户单独安装的上游应用，不包含在仓库或源码归档中 |

## 商标边界

“GitHub”和“GitHub Desktop”仅用于准确说明兼容对象。本项目与 GitHub, Inc. 没有隶属、授权或背书关系。项目的 LGPL、未来素材 CC 和历史 MIT 许可证均不授予 GitHub 名称、Logo、Octocat 或其他商标权利。相关规则见 GitHub 的开源应用条款：<https://docs.github.com/en/site-policy/github-terms/github-open-source-applications-terms-and-conditions>。

## 历史项目许可证

迁移前的项目版本曾按 MIT 许可证发布。该既有授权不撤回；其原始文本保存在 [LICENSES/MIT-legacy-project.txt](LICENSES/MIT-legacy-project.txt)。它是项目历史记录，不是 GitHub Desktop 上游许可证的替代品。
