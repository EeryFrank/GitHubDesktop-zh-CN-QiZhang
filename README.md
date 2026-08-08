# GitHub Desktop 3.6.3 简体中文安全补丁（非官方）

这是一个适用于 **Windows x64 / GitHub Desktop 3.6.3** 的非官方简体中文补丁。项目与 GitHub, Inc. 没有隶属、授权或背书关系。

补丁仓库只包含 PowerShell 源码、中文翻译表与哈希清单，不包含也不再分发 GitHub Desktop 本体、原版或修改后的 JavaScript bundle、安装包、图标或其他官方资源。

## 当前范围

- 只修改 `app-3.6.3\resources\app\renderer.js`，不修改任何 EXE、DLL、更新器、安装包、source map 或 Chromium 资源。
- 当前包含 187 个经过固定上下文约束的翻译条目，共替换 257 处常用界面文本。
- 目标原文件必须精确匹配官方 3.6.3 x64 的 SHA-256；任何未知版本或未知文件状态都会直接停止。
- 安装前创建独立备份；支持重复安装无操作、哈希受控的一键恢复与隔离副本测试。
- 不联网、不提权、不读取 GitHub 凭据、仓库内容或用户数据，也不会强制结束进程。

本补丁不会禁用 GitHub Desktop 自动更新。更新到其他版本后汉化失效是预期行为，新版本必须使用新的独立哈希清单。

## 安全设计

安装器在写入前会验证：

1. 安装目录名、`package.json` 版本和 Windows x64 产品信息；
2. `GitHubDesktop.exe` 与 `package.json` 的固定 SHA-256；
3. `GitHubDesktop.exe` 的有效 Authenticode 签名及 GitHub 签名证书指纹；
4. 原版或已知补丁版 `renderer.js` 的固定 SHA-256；
5. GitHub Desktop、Update 与 Squirrel 相关进程已经退出；
6. 每条翻译的精确匹配次数；
7. 生成文件的固定补丁后 SHA-256；
8. 使用已验证的 GitHubDesktop.exe Electron Node 模式执行 `--check` 语法检查。

备份默认位于：

```text
%LOCALAPPDATA%\GitHubDesktop-zh-CN-patch\backups\3.6.3\
```

日志默认位于同一状态根目录的 `logs` 子目录。日志只记录版本、路径、状态、计数和哈希，不读取或记录凭据。

## 使用方法

要求：官方未修改的 GitHub Desktop 3.6.3 Windows x64、Windows PowerShell 5.1 或更高版本。

先保存当前工作，并从 GitHub Desktop 菜单或系统托盘正常退出。脚本不会使用 `taskkill`。

在本仓库目录中检查状态：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Status.ps1
```

先运行完全隔离的安装/重复安装/恢复/重复恢复测试：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Test-Patch.ps1
```

安装补丁：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Install.ps1
```

恢复官方原文件：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Restore.ps1
```

脚本默认定位 `%LOCALAPPDATA%\GitHubDesktop\app-3.6.3`。高级用户可以显式传入 `-InstallRoot` 与 `-StateRoot`；所有路径仍会经过版本、哈希与重解析点检查。

## 已验证基线

| 项目 | 值 |
| --- | --- |
| 目标版本 | GitHub Desktop 3.6.3 / Windows x64 |
| 原版 `renderer.js` | `1CEA63703B9A65374F2E85B847BF84C387FCF211694ED2661ECFD924CA7C237B` |
| 补丁后 `renderer.js` | `69B3065CD99D0B8401C885EC5AF36BA67C56C0674C8142D8AA737D6A5FE1AA6C` |
| 翻译 | 187 条 / 257 处替换 |
| 隔离测试 | 安装、幂等安装、恢复、幂等恢复、Node 语法检查均通过 |

哈希仍以 [manifest.json](manifest.json) 为机器可读权威清单。

## 限制

- 这是核心界面汉化，不保证每一条动态文本、Git 输出、远程响应或 Copilot 内容均为中文。
- 分支名、路径、提交消息、仓库内容和用户输入不会被翻译。
- 修改资源文件后，安装目录不再与官方安装包逐字一致；EXE 本身没有被修改，其签名仍应保持有效。
- 自动更新可能创建新版本目录并恢复英文界面；不要把 3.6.3 补丁套用到其他版本。
- 若当前文件既不是清单中的原版也不是本补丁版本，安装与恢复都会拒绝覆盖。此时应先确认版本或从 GitHub 官方渠道重新安装。

## 开源与商标

本项目自有的补丁器和翻译表按 [MIT License](LICENSE) 开源。GitHub Desktop 上游许可与商标边界见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。本许可证不授予 GitHub 名称、Logo、Octocat 或其他商标权利。
