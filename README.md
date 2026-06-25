# CodexVisual

<p align="center">
  <img src="assets/menubar.svg" alt="CodexVisual menu bar screenshot" width="520">
</p>

## English

CodexVisual is a lightweight macOS menu bar app for checking your remaining Codex quota at a glance.

It focuses on one thing: showing the remaining 5-hour quota and 7-day quota in the menu bar.

```text
Codex 67 / 95%
```

The first number is the remaining 5-hour quota. The second number is the remaining 7-day quota.

### Download

[Download CodexVisual.dmg](https://github.com/orangeshushu/CodexVisual/releases/latest/download/CodexVisual.dmg)

Open `CodexVisual.dmg`, then drag `CodexVisual.app` into Applications.

### Features

- Shows Codex quota directly in the macOS menu bar.
- Uses the compact `Codex 67 / 95%` format for easier scanning.
- Shows menu details in English or Chinese, with a manual language selector.
- Reads the latest local `codex.rate_limits` event from `~/.codex/logs_2.sqlite`.
- Polls local Codex logs every 60 seconds and caches the latest successful reading.
- Does not call external APIs and does not read `auth.json`.
- Includes scripts for building, installing, uninstalling, and creating a DMG package.

### English Menu

<p align="center">
  <img src="assets/menu-english.png" alt="CodexVisual English menu screenshot" width="520">
</p>

### Why CodexVisual

CodexVisual is intentionally small and focused. Compared with [steipete/CodexBar](https://github.com/steipete/CodexBar), CodexVisual is lighter and only targets Codex quota visibility.

### Data Freshness

CodexVisual is not using an official live quota API. It refreshes by polling local Codex log events every 60 seconds. If Codex has not recently emitted a `codex.rate_limits` event, the app keeps showing the latest cached reading.

### Accounts and Quotas

CodexVisual reads quota events from the local Codex log database. If you sign in to Codex with a different account, the displayed quota will change after Codex writes a new `codex.rate_limits` event for that account. Until then, CodexVisual may still show the latest cached reading from the previous account.

### Build

```bash
./scripts/build_app.sh
```

The app will be generated at:

```text
build/CodexVisual.app
```

### Run

```bash
open build/CodexVisual.app
```

Click the menu bar item to see the refresh interval and the latest local reading time.

### Install, Uninstall, and DMG

Download the latest DMG directly: [CodexVisual.dmg](https://github.com/orangeshushu/CodexVisual/releases/latest/download/CodexVisual.dmg).

Create a macOS DMG package:

```bash
./scripts/create_dmg.sh
```

The DMG will be generated at:

```text
build/CodexVisual.dmg
```

For a public release that opens normally on other Macs, build the DMG with a Developer ID certificate and notarize it:

```bash
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/create_dmg.sh
NOTARY_PROFILE=codexvisual-notary ./scripts/notarize_dmg.sh
```

Create the notarization profile once with:

```bash
xcrun notarytool store-credentials codexvisual-notary --apple-id you@example.com --team-id TEAMID --password xxxx-xxxx-xxxx-xxxx
```

The public GitHub release should upload the stapled `build/CodexVisual.dmg`.

Install or uninstall directly:

```bash
./scripts/install.sh
./scripts/uninstall.sh
```

The app is installed to `~/Applications/CodexVisual.app`. Uninstalling stops the menu bar process and removes the app plus cached data under `~/Library/Application Support/CodexVisual`.

---

## 中文

CodexVisual 是一个轻量的 macOS 菜单栏小程序，用来快速查看 Codex 额度还剩多少。

它只专注一件事：在菜单栏显示 Codex 的 5 小时额度和 7 天额度剩余百分比。

```text
Codex 67 / 95%
```

第一个数字是 5 小时额度剩余，第二个数字是 7 天额度剩余。

### 下载

[下载 CodexVisual.dmg](https://github.com/orangeshushu/CodexVisual/releases/latest/download/CodexVisual.dmg)

打开 `CodexVisual.dmg` 后，把 `CodexVisual.app` 拖到 Applications。

### 功能

- 在 macOS 菜单栏直接显示 Codex 额度。
- 使用更容易扫读的 `Codex 67 / 95%` 格式。
- 菜单详情支持英文和中文，并提供手动语言选择。
- 从本地 `~/.codex/logs_2.sqlite` 读取最新的 `codex.rate_limits` 事件。
- 每 60 秒轮询一次本地 Codex 日志，并缓存最近一次成功读取的数据。
- 不访问外网，也不读取 `auth.json`。
- 提供构建、安装、卸载和 DMG 打包脚本。

### 为什么叫 CodexVisual

CodexVisual 是一个更轻量、更单一用途的菜单栏工具。相比 [steipete/CodexBar](https://github.com/steipete/CodexBar)，CodexVisual 只针对 Codex 的本地额度状态展示，不做额外的工作流管理。

### 数据刷新

CodexVisual 不是通过官方实时额度 API 获取数据。它每 60 秒读取一次本地 Codex 日志。如果 Codex 最近没有写入新的 `codex.rate_limits` 事件，应用会继续显示最近一次缓存到的额度数据。

### 账号和额度

CodexVisual 读取的是本地 Codex 日志中的额度事件。如果你在 Codex 中切换到另一个账号，上面的额度会在 Codex 写入新的 `codex.rate_limits` 事件后随之变化。在新事件出现之前，CodexVisual 可能会继续显示上一个账号最近一次缓存到的额度。

### 构建

```bash
./scripts/build_app.sh
```

构建后应用位于：

```text
build/CodexVisual.app
```

### 运行

```bash
open build/CodexVisual.app
```

点击菜单栏项目可以查看刷新间隔和最后一次本地读取时间。

### 安装、卸载和 DMG

直接下载最新版 DMG：[CodexVisual.dmg](https://github.com/orangeshushu/CodexVisual/releases/latest/download/CodexVisual.dmg)。

生成 macOS DMG 安装包：

```bash
./scripts/create_dmg.sh
```

DMG 位于：

```text
build/CodexVisual.dmg
```

如果要发布给其他用户正常双击打开，需要使用 Developer ID 证书签名，并完成 Apple 公证：

```bash
CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/create_dmg.sh
NOTARY_PROFILE=codexvisual-notary ./scripts/notarize_dmg.sh
```

公证凭据只需要创建一次：

```bash
xcrun notarytool store-credentials codexvisual-notary --apple-id you@example.com --team-id TEAMID --password xxxx-xxxx-xxxx-xxxx
```

GitHub Release 应上传完成 staple 之后的 `build/CodexVisual.dmg`。

也可以直接用脚本安装或卸载：

```bash
./scripts/install.sh
./scripts/uninstall.sh
```

安装位置是 `~/Applications/CodexVisual.app`。卸载会停止菜单栏进程，并删除 app 与 `~/Library/Application Support/CodexVisual` 下的缓存。
