# CodexVisual

<p align="center">
  <img src="assets/menubar.png" alt="CodexVisual menu bar screenshot" width="520">
</p>

## English

CodexVisual is a lightweight macOS menu bar app for checking your remaining Codex quota at a glance.

It focuses on one thing: showing the remaining 5-hour quota and 7-day quota in the menu bar.

```text
Codex 67 / 95%
```

The first number is the remaining 5-hour quota. The second number is the remaining 7-day quota.

### Features

- Shows Codex quota directly in the macOS menu bar.
- Uses the compact `Codex 67 / 95%` format for easier scanning.
- Reads the latest local `codex.rate_limits` event from `~/.codex/logs_2.sqlite`.
- Polls local Codex logs every 60 seconds and caches the latest successful reading.
- Does not call external APIs and does not read `auth.json`.
- Includes scripts for building, installing, uninstalling, and creating a DMG package.

### Why CodexVisual

CodexVisual is intentionally small and focused. Compared with [steipete/CodexBar](https://github.com/steipete/CodexBar), CodexVisual is lighter and only targets Codex quota visibility.

### Data Freshness

CodexVisual is not using an official live quota API. It refreshes by polling local Codex log events every 60 seconds. If Codex has not recently emitted a `codex.rate_limits` event, the app keeps showing the latest cached reading.

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

Create a macOS DMG package:

```bash
./scripts/create_dmg.sh
```

The DMG will be generated at:

```text
build/CodexVisual.dmg
```

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

### 功能

- 在 macOS 菜单栏直接显示 Codex 额度。
- 使用更容易扫读的 `Codex 67 / 95%` 格式。
- 从本地 `~/.codex/logs_2.sqlite` 读取最新的 `codex.rate_limits` 事件。
- 每 60 秒轮询一次本地 Codex 日志，并缓存最近一次成功读取的数据。
- 不访问外网，也不读取 `auth.json`。
- 提供构建、安装、卸载和 DMG 打包脚本。

### 为什么叫 CodexVisual

CodexVisual 是一个更轻量、更单一用途的菜单栏工具。相比 [steipete/CodexBar](https://github.com/steipete/CodexBar)，CodexVisual 只针对 Codex 的本地额度状态展示，不做额外的工作流管理。

### 数据刷新

CodexVisual 不是通过官方实时额度 API 获取数据。它每 60 秒读取一次本地 Codex 日志。如果 Codex 最近没有写入新的 `codex.rate_limits` 事件，应用会继续显示最近一次缓存到的额度数据。

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

生成 macOS DMG 安装包：

```bash
./scripts/create_dmg.sh
```

DMG 位于：

```text
build/CodexVisual.dmg
```

也可以直接用脚本安装或卸载：

```bash
./scripts/install.sh
./scripts/uninstall.sh
```

安装位置是 `~/Applications/CodexVisual.app`。卸载会停止菜单栏进程，并删除 app 与 `~/Library/Application Support/CodexVisual` 下的缓存。
