# CodexVisual

一个本地 macOS 菜单栏小程序，用来显示 Codex 5 小时额度和 7 天额度的剩余百分比。

它读取 `~/.codex/logs_2.sqlite` 中最新的 `codex.rate_limits` 日志事件，不访问外网，也不读取 `auth.json`。

菜单栏会显示：

```text
Codex 67 / 95%
```

数字顺序是：`5小时额度剩余 / 7天额度剩余`。

## 定位

CodexVisual 是一个更轻量、更单一用途的菜单栏工具。相比 [steipete/CodexBar](https://github.com/steipete/CodexBar)，它只针对 Codex 的本地额度状态展示，不做额外的工作流管理。

## 构建

```bash
./scripts/build_app.sh
```

构建后应用位于：

```text
build/CodexVisual.app
```

## 运行

```bash
open build/CodexVisual.app
```

菜单栏标题格式为：

```text
Codex 70 / 95%
```

第一个数字是 5 小时额度剩余，第二个数字是 7 天额度剩余。点击菜单栏项目可以查看刷新时间和最后读取时间。

## 安装和卸载

生成 macOS DMG 安装包：

```bash
./scripts/create_dmg.sh
```

DMG 位于：

```text
build/CodexVisual.dmg
```

生成双击安装器：

```bash
./scripts/create_installer_app.sh
```

安装器位于：

```text
build/CodexVisual Installer.app
```

也可以直接用脚本安装或卸载：

```bash
./scripts/install.sh
./scripts/uninstall.sh
```

安装位置是 `~/Applications/CodexVisual.app`。卸载会停止菜单栏进程，并删除 app 与 `~/Library/Application Support/CodexVisual` 下的缓存。
