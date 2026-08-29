<!-- SPDX-License-Identifier: GPL-3.0-only -->

# 贡献指南

感谢改进补丁源码、翻译、验证规则和文档。提交 Issue 或 Pull Request 前，请先阅读 [`LICENSE_POLICY.md`](LICENSE_POLICY.md)、[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 与 [`SECURITY.md`](SECURITY.md)。

## 贡献许可

提交贡献即表示提交者确认拥有必要权利，并同意按仓库对应范围授权贡献：

- 项目原创 PowerShell 源码、中文翻译、功能数据、CI 配置和原创文档按 `GPL-3.0-only` 授权；
- 未来自有视觉、音频、Logo、图标或其他品牌/创意素材必须先提供可核验的来源、权利证明及书面许可记录，并经维护者逐项登记到 `ASSET_LICENSES.md`；
- 经逐项确认的未来自有素材默认使用 `LicenseRef-EeryFrank-Assets-Permission-Required`。未经修改的素材只可随未经修改的官方发布包一起使用和分发；单独提取、复用、修改、再分发、商业使用或品牌使用必须事先取得书面许可；
- 所有第三方和历史内容不因提交到仓库而自动进入上述许可范围，必须保留其原许可证、来源和适用边界。

不要提交无权再分发的内容。特别是不得提交 GitHub Desktop 安装包、原始或修改后的 bundle、source map、图标、备份、私有仓库信息、凭据或从其他项目提取的受保护内容。

## 翻译数据边界

`translations.zh-CN.json` 中的中文译文和项目编排数据属于项目贡献范围；用于精确匹配的 `original` 英文原文来自受支持的 GitHub Desktop 上游版本，仍按上游 MIT 许可证处理。新增条目必须保持这一边界，不能声称拥有或重新授权上游字符串、产品名称或商标。

## 提交前验证

至少运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Licensing.ps1
```

如本机安装了清单精确支持的官方 GitHub Desktop 版本，再运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Patch.ps1
```

Pull Request 应说明修改范围、验证命令和结果，并确认没有加入上游应用文件、敏感信息或来源不明的素材。贡献者不得把过去的 MIT、LGPL、CC、Apache、C2PA 或第三方许可误写成当前新增内容的自动许可。
