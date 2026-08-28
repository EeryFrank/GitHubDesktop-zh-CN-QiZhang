<!-- SPDX-License-Identifier: LGPL-3.0-or-later -->

# 贡献指南

感谢改进补丁源码、翻译、验证规则和文档。提交 Issue 或 Pull Request 前，请先阅读 [`LICENSE_POLICY.md`](LICENSE_POLICY.md)、[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) 与 [`SECURITY.md`](SECURITY.md)。

## 贡献许可

提交贡献即表示提交者确认拥有必要权利，并同意按仓库对应范围授权贡献：

- 项目原创 PowerShell 源码、中文翻译、功能数据、CI 配置和原创文档按 `LGPL-3.0-or-later` 授权；
- 将来放入许可证政策指定原创素材目录、且具有完整来源证明的视觉或音频素材按 `CC-BY-SA-4.0` 授权；
- Logo、图标、品牌素材以及所有第三方内容不因提交到仓库而自动进入上述许可范围，必须先提供单独、兼容且明确的授权说明。

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

Pull Request 应说明修改范围、验证命令和结果，并确认没有加入上游应用文件、敏感信息或来源不明的素材。
