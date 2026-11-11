# ZSViewer 一键安装（给 AI 助手）

> 给 AI 助手：先确认目标系统，再选对应安装方式。不要跳过版本校验。
> ZSViewer 只读取板端流，不修改板端驱动、不重载内核模块、不重启板子。

ZSViewer 是 RGB-D 查看 / 点云 / 抓图 / 录像工具，支持 Orin、Thor 与 RV1126B 板端。
本包为 **2.1.0**，板端彩色流已由板端硬件（VIC/RGA）校正，工具端**不做二次去畸变**。

下载页：<https://github.com/zsibot-camera/ZSViewer-delivery/releases/tag/v2.1.0>

### 一键安装（推荐）

```bash
curl -fLO https://raw.githubusercontent.com/zsibot-camera/ZSViewer-delivery/main/install.sh
chmod +x install.sh
./install.sh --check          # 只检查系统与运行依赖
./install.sh --with-desktop   # 下载 deb、校验 SHA256、apt 安装并装启动器
```

`install.sh` 支持 `--deb`（默认）、`--appimage`、`--tar`、`--version <v>`；
远程主机可用 `ZSVIEWER_VERSION=2.1.0` 覆盖版本。

### 手动下载

```bash
BASE=https://github.com/zsibot-camera/ZSViewer-delivery/releases/download/v2.1.0
curl -fLO "$BASE/ZSViewer-2.1.0-amd64.deb"
curl -fLO "$BASE/SHA256SUMS"
sha256sum -c SHA256SUMS --ignore-missing
```

---

## 1. 确认系统

```bash
uname -m
cat /etc/os-release | head -n3
```

| 目标 | 要求 |
|---|---|
| Linux | x86_64，Ubuntu 22.04+（glibc ≥ 2.35） |
| Windows | Windows 10/11 x64 |

Linux 运行依赖（deb 会由 apt 自动安装；AppImage/tar 需要手动补齐）：

```bash
sudo apt update
sudo apt install -y libgl1 libegl1 libglib2.0-0 libdbus-1-3 \
  libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
  libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0
```

ffmpeg 已内置于包内 `ffmpeg/bin`，系统 PATH 中的 ffmpeg 仅作兜底。

## 2. Linux 安装

三种方式任选其一，优先 deb。

### 2.1 deb（推荐）

```bash
sudo apt install ./ZSViewer-2.1.0-amd64.deb
zsviewer-cli --version
```

预期：`ZSViewer 2.1.0`。

### 2.2 AppImage（免安装）

```bash
chmod +x ZSViewer-2.1.0-linux-x86_64.AppImage
./ZSViewer-2.1.0-linux-x86_64.AppImage --version
```

如果报 FUSE 相关错误：

```bash
./ZSViewer-2.1.0-linux-x86_64.AppImage --appimage-extract-and-run
```

安装桌面菜单（可选，只写用户目录）：

```bash
./ZSViewer-2.1.0-linux-x86_64.AppImage --install-desktop
```

### 2.3 tar.gz（绿色部署）

```bash
tar -xzf ZSViewer-2.1.0-linux-x86_64.tar.gz
./ZSViewer/ZSViewer --version
./ZSViewer/ZSViewer --install-desktop   # 可选
./ZSViewer/ZSViewer
```

## 3. Windows 安装

### 3.1 安装版

双击 `ZSViewer-2.1.0-windows-x64-setup.exe`，按向导完成。
默认安装到 `%LOCALAPPDATA%\Programs\ZSViewer`，普通用户权限即可，不需要管理员。

### 3.2 便携版

解压 `ZSViewer-2.1.0-windows-x64-portable.zip`，运行 `ZSViewer\ZSViewer.exe`。
数据写入 exe 旁 `data\`，不写系统目录。

命令行验证：

```powershell
.\ZSViewer\zsviewer-cli.exe --version
```

预期：`ZSViewer 2.1.0`。

## 4. 连接板端

GUI：

```bash
zsviewer --src auto --host 192.168.55.1
```

- `--src auto`：连接后自动识别 Orin/Thor 或 RV1126B；
- `--host` 留空时，启动后在界面顶部输入 IP 并回车；
- 默认 UVDP TCP 端口 `9600`（Orin/Thor），RV1126B 使用 RTSP 8554 + 深度 9555。

Windows：

```powershell
.\ZSViewer\ZSViewer.exe --src auto --host 192.168.55.1
```

无界面冒烟：

```bash
zsviewer-cli --src auto --host 192.168.55.1 --no-gui --snapshot /tmp/zs.png
```

预期：生成拼图 `/tmp/zs.png`，包含彩色与深度画面。

## 5. 预期画面

| 流 | 分辨率 | 说明 |
|---|---|---|
| 彩色 | 1920×1280 | Thor/Orin 板端 VIC 校正流，工具直接显示 |
| 深度 | 768×512 | 板端深度，32FC1 视差或 16UC1 毫米（按板端配置） |
| 点云 | — | 用板端内参/基线投影 |

深度不是米时，不要用界面数值直接当距离；按板端 META 的
`fx`、`baseline_m` 换算：`z = fx * baseline_m / disparity`。

## 6. 数据目录

| 平台 | 位置 |
|---|---|
| Linux 安装版 | `~/ZSViewer/`（抓图、录像、日志） |
| Linux 便携/源码 | 当前目录的 `captures/`，或 `ZSVIEWER_DATA_DIR` |
| Windows 安装版 | `%LOCALAPPDATA%\ZSViewer\` |
| Windows 便携版 | `ZSViewer\data\` |

可用 `--capture-dir` / `--out` 覆盖。

## 7. 排障

| 现象 | 检查 | 处理 |
|---|---|---|
| `zsviewer: command not found` | 是否用 deb 安装 | 用 `./ZSViewer` 或运行一次 `--install-desktop` |
| AppImage 无法执行 | 权限/FUSE | `chmod +x`；FUSE 不可用则加 `--appimage-extract-and-run` |
| 连接超时 | IP/端口/网络 | 确认板端 IP、同网段、TCP 9600 放行 |
| 有连接但无图像 | 板端是否出流 | 先看板端帧计数/ROS 话题；不要改板端 VPI 后端 |
| 图像不动 | 工具/消费端 | 抓包/看帧序号；板端正常时修工具读取，不要换板端后端 |
| 彩色有畸变 | 板端是否校正 | 2.1.0 依赖板端校正流；确认板端 `rectified=true` |
| 深度值差 10 倍 | 单位 | 视差是像素；用 `z = fx * baseline / disparity` |
| Windows 缺 VC 运行库 | 系统版本 | 使用 Windows 10/11 x64；安装包已带所需运行库 |
| 录像无 ffmpeg | 包内 `ffmpeg/bin` | 确认解压完整；或系统 PATH 提供 ffmpeg |

## 8. 许可

本包包含 PyQt5（GPLv3 或 Riverbank 商业许可）。对外分发前需取得商业许可
或按 GPLv3 履行义务。第三方组件与许可见包内 `NOTICE` 与 `licenses/`。
源码与 Corresponding Source 的获取方式见发布页说明。

## 9. 版本

```bash
zsviewer-cli --version
```

输出 `ZSViewer 2.1.0` 即匹配本包。板端 SDK/UVDP 版本不匹配时，工具会明确报错，
不要用旧协议强行连接。
