<!-- SPDX-License-Identifier: GPL-3.0-only -->

# 依赖与代码关系

## 外部依赖

| 依赖 | 要求 | 用途 |
| --- | --- | --- |
| Windows | x64 | 目标操作系统与系统 API |
| Windows PowerShell | 5.1 或更高 | 执行补丁、恢复、状态和测试脚本 |
| .NET Framework 系统类库 | 随 Windows PowerShell 提供 | SHA-256、UTF-8、JSON、文件与进程检查 |
| GitHub Desktop | 官方 3.6.4 x64 | 被校验和修改的上游目标，不包含在本仓库中 |
| GitHub Desktop 内置 Electron/Node | 随目标程序提供 | 仅使用 `GitHubDesktop.exe --check` 验证生成后的 JavaScript 语法 |

本仓库没有 NuGet、npm、PowerShell Gallery 或其他第三方 PowerShell 模块依赖，也不会打包 GitHub Desktop 本体或上游资源。

```mermaid
flowchart LR
    Windows["Windows x64"] --> PowerShell["Windows PowerShell 5.1+"]
    Framework["Built-in .NET Framework APIs"] --> PowerShell
    PowerShell --> Patch["Chinese patch scripts"]
    Desktop["Official GitHub Desktop 3.6.4 x64"] --> Target["renderer.js target"]
    Patch --> Target
    DesktopNode["GitHub Desktop embedded Node"] -. "syntax check only" .-> Patch
```

## 入口与共享代码关系

```mermaid
flowchart TD
    Manifest["manifest.json\nversion and trusted hashes"] --> Common["Common.ps1\nshared validation and file primitives"]
    Translations["translations.zh-CN.json\ncontext-bound replacements"] --> Common

    Install["Install.ps1"] --> Common
    Restore["Restore.ps1"] --> Common
    Status["Status.ps1"] --> Common
    Hash["Get-PatchedHash.ps1"] --> Common
    Test["Test-Patch.ps1"] --> Common

    Common --> Identity["Assert-TargetIdentity"]
    Common --> Process["Assert-GitHubDesktopStopped"]
    Common --> Translate["Invoke-Translations"]
    Common --> Atomic["Invoke-AtomicReplacement"]

    Install --> Backup["verified independent backup"]
    Install --> Translate
    Translate --> HashCheck["patched SHA-256 and JS syntax"]
    HashCheck --> Atomic

    Restore --> BackupCheck["backup metadata and SHA-256"]
    BackupCheck --> Atomic
    Status --> State["ORIGINAL / PATCHED / UNKNOWN_REFUSED"]
    Test --> Fixture["isolated temporary fixture"]
    Fixture --> Install
    Fixture --> Restore
```

## 安全数据流

```mermaid
flowchart LR
    Detect["从 manifest 定位 3.6.4 x64"] --> Verify["版本、签名、路径和原始哈希校验"]
    Verify --> StopCheck["确认相关进程已退出"]
    StopCheck --> Backup["创建并复核独立备份"]
    Backup --> Generate["按固定上下文生成中文 renderer.js"]
    Generate --> Validate["替换计数、目标哈希、JavaScript 语法"]
    Validate --> Replace["原子替换"]
    Replace --> ReadBack["落盘后 SHA-256 复核"]
```

任何未知版本、未知哈希、重解析点路径、正在运行的目标进程或验证失败都会在写入前停止；恢复流程同样拒绝覆盖未知文件状态。
