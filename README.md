# ZSViewer

统一 RGB-D 查看 / 录制 / 点云工具，支持 NVIDIA Jetson（Orin NX / AGX Thor）与
RV1126B 板端。

本仓库是 ZSViewer 的**独立交付仓库**，只存放交付文档与发布包，不包含源码历史。
源码在内部 GitLab（`camera/ZSViewer`）维护，本仓库不接受源码 PR。

## AI 一键安装

客户侧 AI 助手可直接阅读 [`AI-INSTALL.md`](AI-INSTALL.md)，按步骤选择资产、
校验并安装；人类用户按下面的“下载 / 安装”操作即可。

## 下载

从 [Releases](https://github.com/zsibot-camera/ZSViewer-delivery/releases) 下载当前版本：

| 平台 | 资产 |
|---|---|
| Linux | `ZSViewer-<v>-linux-x86_64.AppImage` / `ZSViewer-<v>-amd64.deb` / `ZSViewer-<v>-linux-x86_64.tar.gz` |
| Windows | `ZSViewer-<v>-windows-x64-setup.exe` / `ZSViewer-<v>-windows-x64-portable.zip` |
| 通用 | `zsviewer-<v>-py3-none-any.whl` |

每个 Release 附带 `SHA256SUMS`，下载后请校验：

```bash
sha256sum -c SHA256SUMS --ignore-missing
```

## 安装

- **deb**：`sudo apt install ./ZSViewer-<v>-amd64.deb`，安装后可直接运行 `zsviewer`。
- **AppImage**：`chmod +x ZSViewer-*.AppImage && ./ZSViewer-*.AppImage`。
- **AppImage / tar.gz 安装启动器**：运行一次
  `./ZSViewer-*.AppImage --install-desktop`（tar.gz 用解压目录里的
  `zsviewer-cli --install-desktop`）。只写用户目录 `~/.local/bin` 和
  `~/.local/share/applications`，不需要 root；`--uninstall-desktop` 可移除。
- **Windows 便携版**：解压后运行 `ZSViewer.exe`，数据写入 `data/`。
- **Windows 安装包**：普通用户安装到 `%LOCALAPPDATA%\Programs\ZSViewer`。
- **Python wheel**（Python 3.10+）：
  `python3 -m pip install ./zsviewer-<v>-py3-none-any.whl`，入口为 `zsviewer`
  与 `zsviewer-cli`。

## 运行

```bash
zsviewer                              # GUI：在顶部输入设备 IP 并回车连接
zsviewer --host 192.168.1.100         # GUI：启动后自动连接
zsviewer-cli --no-gui --host 192.168.1.100 --duration 10   # 无界面录制
zsviewer-cli --version
```

界面支持 RGB / 深度 / 点云多视图、画面最大化与缩略图排列、深度距离调节、拍照与数据集录像。
彩色流由板端 VIC/RGA 硬件校正，工具端不做二次去畸变。

## 设备连接

- 设备需运行 ZSCamera SDK 的板端服务，通过 UVDP（TCP，默认 9600）提供
  left / right / depth / meta 流。
- 支持 Orin NX、AGX Thor 与 RV1126B；具体可用流和标定来源以固件实际提供的
  服务为准。
- 标定参数默认从模组 Flash 读取；Flash 为空时界面留空，不影响其他功能。

## 版本与支持

- 当前版本见 `VERSION`，变更见 `CHANGELOG.md`。
- 问题反馈请附：ZSViewer 版本、操作系统、设备型号/固件版本、复现步骤与日志。

## 开源与许可

- 本仓库只发布交付文档与二进制包，不包含源码；源码在内部 GitLab 维护。
- 二进制包含 PyQt5（GPLv3 或 Riverbank 商业许可），按 **GPLv3** 分发。
  Corresponding Source 获取方式见 [`SOURCE-OFFER.md`](SOURCE-OFFER.md)。
- 第三方组件与许可见 `NOTICE` 与包内 `licenses/`。

## 相关仓库

- [ZSCamera_sdk](https://github.com/zsibot-camera/ZSCamera_sdk) — 统一相机与双目深度 SDK
- [nvidia-jetson-camera-drivers](https://github.com/zsibot-camera/nvidia-jetson-camera-drivers) — NVIDIA Jetson 相机驱动与深度 SDK
- [d-robotics-camera-drivers](https://github.com/zsibot-camera/d-robotics-camera-drivers) — D-Robotics RDK 相机驱动与 SDK
