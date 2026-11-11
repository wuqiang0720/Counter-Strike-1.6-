> 适用环境：Steam 版 Counter-Strike 1.6（Windows）
>
> 游戏目录示例：`D:\SteamLibrary\steamapps\common\Half-Life`
>
> 本指南使用 AMX Mod X + Metamod 加载 `amx_ammo.amxx` 插件。

## 1. 功能说明

插件可以为指定玩家持续补充手雷。当前已验证的使用方式：

- 对指定玩家开启无限手雷。
- 对指定玩家关闭无限手雷。
- 插件状态可通过 AMX Mod X 控制台命令检查。

原插件的默认手雷类型由 `ammo_nade_flags` 控制。常见标记如下：

| 标记 | 手雷类型 |
|---|---|
| `a` | 高爆手雷（HE） |
| `b` | 烟雾弹（Smoke） |
| `c` | 闪光弹（Flash） |

默认值为 `ac`，即高爆手雷和闪光弹，不包含烟雾弹。若要启用三种手雷，需要在源码中将默认值调整为 `abc`，重新编译后再安装。

## 2. 安装前准备

需要准备：

1. Steam 版 CS 1.6。
2. [Metamod（Windows 版本）。 ](https://sourceforge.net/projects/metamod/files/Metamod%20Binaries/?utm_source)
3. [AMX Mod X Base Package（Windows 版本）。](https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-base-windows.zip?utm_source)
4. [AMX Mod X Counter-Strike Addon（Windows 版本）。](https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-cstrike-windows.zip?utm_source)
5. [已编译好的 `amx_ammo.amxx` 插件。](https://forums.alliedmods.net/attachment.php?attachmentid=18361&d=1215056141)

请确认所有组件版本相互兼容。修改前建议备份原始配置文件。

## 3. 目录结构

以下以游戏目录为例：

```text
D:\SteamLibrary\steamapps\common\Half-Life\
└── cstrike\
    ├── liblist.gam
    └── addons\
        ├── metamod\
        │   ├── dlls\
        │   │   └── metamod.dll
        │   └── plugins.ini
        └── amxmodx\
            ├── dlls\
            │   └── amxmodx_mm.dll
            ├── configs\
            │   └── plugins.ini
            └── plugins\
                └── amx_ammo.amxx
```

如果 AMX Mod X 安装包解压后已经包含其他目录和文件，请保留原有结构，不要只复制上面列出的几个文件。

## 4. 安装 Metamod

### 4.1 放置 Metamod 文件

将 Windows 版 Metamod 解压到：

```text
cstrike\addons\metamod\
```

确认文件存在：

```text
cstrike\addons\metamod\dlls\metamod.dll
```

### 4.2 创建 Metamod 插件配置

创建或编辑：

```text
cstrike\addons\metamod\plugins.ini
```

写入：

```ini
win32 addons/amxmodx/dlls/amxmodx_mm.dll
```

### 4.3 修改 liblist.gam

文件位置：

```text
cstrike\liblist.gam
```

先备份：

```cmd
copy "D:\SteamLibrary\steamapps\common\Half-Life\cstrike\liblist.gam" "D:\SteamLibrary\steamapps\common\Half-Life\cstrike\liblist.gam.bak"
```

找到原来的游戏 DLL 配置：

```ini
gamedll "dlls\mp.dll"
```

将其修改为：

```ini
gamedll "addons\metamod\dlls\metamod.dll"
```

注意：只修改对应的 `gamedll` 行，不要删除文件中的其他配置。

## 5. 安装 AMX Mod X

### 5.1 复制文件
[amxmodx-latest-base-windows](https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-base-windows.zip?utm_source)

[amxmodx-latest-cstrike-windows](https://www.amxmodx.org/amxxdrop/1.10/amxmodx-latest-cstrike-windows.zip?utm_source)

将 AMX Mod X Base Package 和 Counter-Strike Addon 按安装包原有目录结构合并到：

```text
D:\SteamLibrary\steamapps\common\Half-Life\cstrike\
```

如果系统询问是否合并目录或覆盖文件，请确认目标是正确的 `cstrike` 目录。

### 5.2 放置无限手雷插件

将编译生成的：

```text
amx_ammo.amxx
```

复制到：

```text
cstrike\addons\amxmodx\plugins\
```

### 5.3 启用插件

编辑：

```text
cstrike\addons\amxmodx\configs\plugins.ini
```

在文件末尾增加一行：

```ini
amx_ammo.amxx
```

保存文件。不要把这行添加到 Metamod 的 `plugins.ini`；它属于 AMX Mod X 的插件列表。

## 6. 启动并检查插件

启动 CS 1.6，创建本地游戏或进入服务器。

打开游戏控制台，执行：

```text
meta list
```

确认 Metamod 已加载。

再执行：

```text
amxx plugins
```

在插件列表中找到 `amx_ammo.amxx`，状态应为：

```text
running
```

如果插件显示 `bad load`、`error` 或没有出现在列表中，请检查文件路径、插件文件名和配置文件。

## 7. 使用无限手雷

### 7.1 查询玩家昵称

在游戏控制台执行：

```text
status
```

查看玩家列表，确认目标玩家的昵称。昵称中如果有空格，执行命令时需要加双引号。

### 7.2 开启无限手雷

命令格式：

```text
amx_ammo "<玩家昵称>" 1
```

例如：

```text
amx_ammo "Player" 1
```

### 7.3 关闭无限手雷

命令格式：

```text
amx_ammo "<玩家昵称>" 0
```

例如：

```text
amx_ammo "Player" 0
```

参数含义：

| 参数 | 含义 |
|---|---|
| `1` | 开启无限手雷 |
| `0` | 关闭无限手雷 |

该命令需要相应的 AMX Mod X 管理员权限。若提示没有权限，需要检查 `addons\amxmodx\configs\users.ini` 中的管理员配置。

## 8. 验证效果

1. 进入游戏并确保插件状态为 `running`。
2. 给目标玩家开启无限手雷。
3. 购买或拿到插件支持的手雷。
4. 投出一颗手雷。
5. 等待插件的补充检查执行。
6. 确认手雷数量是否自动恢复。

当前已实际验证过无限手雷命令能够生效。具体支持哪些手雷类型，以源码中的 `ammo_nade_flags` 设置为准。

## 9. 常见问题排查

### 9.1 `amxx plugins` 中找不到插件

检查：

- 文件是否存在于 `cstrike\addons\amxmodx\plugins\amx_ammo.amxx`。
- `cstrike\addons\amxmodx\configs\plugins.ini` 是否包含 `amx_ammo.amxx`。
- 文件名是否拼写正确。
- Metamod 是否成功加载 AMX Mod X。

### 9.2 插件显示 `bad load`

常见原因：

- `.amxx` 文件没有放在正确目录。
- 插件依赖的模块没有加载。
- 插件与当前 AMX Mod X 版本不兼容。
- 编译时使用的 include 或编译器版本不匹配。

查看 AMX Mod X 日志：

```text
cstrike\addons\amxmodx\logs\
```

根据日志中的错误信息进一步排查。

### 9.3 提示 `You have no access to that command`

这是管理员权限问题。检查：

```text
cstrike\addons\amxmodx\configs\users.ini
```

确认当前玩家拥有插件命令要求的权限。修改权限配置后，重新加载配置或重启地图。

### 9.4 命令执行了，但没有补充手雷

依次确认：

1. `amxx plugins` 中插件状态是 `running`。
2. 命令中的昵称与 `status` 显示的昵称完全一致。
3. 使用 `1` 开启，而不是 `0`。
4. 当前手雷类型包含在插件配置中。
5. 查看 AMX Mod X 日志是否有运行错误。

### 9.5 Metamod 或 AMX Mod X 没有加载

检查：

- `liblist.gam` 的 `gamedll` 是否指向 Metamod。
- `metamod.dll` 是否位于 `addons\metamod\dlls\`。
- `addons\metamod\plugins.ini` 是否正确指向 `amxmodx_mm.dll`。
- 文件路径和文件名是否完全一致。

## 10. 常用命令速查

| 用途 | 命令 |
|---|---|
| 查看玩家昵称 | `status` |
| 查看 Metamod 插件 | `meta list` |
| 查看 AMX Mod X 插件 | `amxx plugins` |
| 开启指定玩家无限手雷 | `amx_ammo "Player" 1` |
| 关闭指定玩家无限手雷 | `amx_ammo "Player" 0` |

## 11. 卸载或恢复原状

1. 从 `cstrike\addons\amxmodx\configs\plugins.ini` 删除：
   ```ini
   amx_ammo.amxx
   ```
2. 如需完全移除 AMX Mod X 和 Metamod，再按安装前备份恢复 `liblist.gam`：
   ```cmd
   copy /Y "D:\SteamLibrary\steamapps\common\Half-Life\cstrike\liblist.gam.bak" "D:\SteamLibrary\steamapps\common\Half-Life\cstrike\liblist.gam"
   ```
3. 确认游戏可以正常启动后，再清理不需要的插件文件。

> 建议先只删除 `amx_ammo.amxx` 的启用配置来停用插件。不要在未备份的情况下直接删除整个 `addons` 目录。

## 12. 当前配置状态

- 游戏：Steam 版 CS 1.6（Windows）。
- 插件：`amx_ammo.amxx`。
- 插件加载：已验证为 `running`。
- 无限手雷命令：已验证可用。
- 已测试命令：`amx_ammo "Player" 1`。
- 默认手雷标记：`ac`（HE + Flash）。
- 自动购买防弹衣：不属于当前已验证版本，尚未集成。
"""
## 13. 编译方法
<img width="1595" height="628" alt="image" src="https://github.com/user-attachments/assets/0d87ebd7-a1d1-4062-ad29-c8c67ce24177" />

