# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [2.1.0] - 2026-11-11

### Added
- `--install-desktop` / `--uninstall-desktop`：AppImage 与 tar.gz 可在用户目录
  （`~/.local/bin`、`~/.local/share/applications`）安装启动器和桌面菜单项，
  不需要 root；deb 仍使用 `/usr/bin/zsviewer` 软链。

### Changed
- 移除「畸变矫正」开关：Orin/Thor 板端改为发布 VIC 硬件校正后的
  1920×1280 彩色流（深度仍为 768×512），工具与 ROS 直接使用板端校正帧，
  不再做客户端二次去畸变，显示/点云/录像几何保持一致。
- 预览缩放改用平滑（bilinear）滤波，消除 1920×1280 画面缩到窗格时的
  摩尔纹和锯齿；「存图」仍保存原始分辨率。
- 画面最大化时，主画面放大并保留边距，其余已开启画面缩为右侧竖排缩略图，
  点击缩略图的「□」可切换主画面。
- 不再默认连接固定 IP：`--host` 默认为空，启动后在界面输入 IP 并回车即可连接；
  无界面/旧界面模式仍要求显式 `--host`。
- 深度距离设置取消 10 m 上限，可直接输入更大的毫米值。
- 实时点云与快照共用同一投影/光栅化实现，保证与 RGB、深度图像方向一致。
- 标定参数默认从模组 Flash 自动读取；Flash 为空或读取异常时界面保持空白，
  不弹出错误、不影响其他功能。

## [2.0.0] - 2026-11-09

### Added
- 独立仓库与 `src/zsviewer/` 包结构（按常量、采集、录制、快照、GUI 分层）。
- 内置 ffmpeg/ffprobe（BtbN LGPL，锁定 dated tag + SHA256）。
- Linux AppImage / deb / tar.gz 与 Windows Inno Setup / 便携 zip。
- venv 安装器改为消费 Release wheel，快捷方式名 `ZSViewer (Venv)`。
- `--version` 参数；冻结版用户数据目录（Linux `~/ZSViewer`、
  Windows `%LOCALAPPDATA%\ZSViewer`、便携 `exe_dir/data`）。
- CI（Linux 3.10/3.11 + Windows）与 tag 触发的 draft Release 流水线。

### Changed
- 单文件 `ZSViewer.tool` 重构为模块化 Python 包，不再提供旧单文件入口。
- PyQt5 改为惰性导入，`--help/--version/--no-gui` 不再依赖图形栈。
- 日志兼容无控制台窗口，并写入轮转文件。

## [1.0.0] - 2026-11-05

### Added
- RV1126B 双目 RGB-D 预览、深度、点云、拍照、数据集录像与网络 OTA。
- Orin 双目 RGB-D 采集（UVDP/TCP 9600）、自动启停流与 Flash 标定读写。
- 单文件版本与 Linux/Windows 安装脚本。
