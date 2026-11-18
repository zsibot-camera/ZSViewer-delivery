# Changelog

本文件遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式，
版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [2.1.3] - 2026-11-18

### Added
- 板端模式自动切换：连接 Orin 时通过 SSH 调用 SDK deb 的
  `sudo -n zscamera-mode tool`，把板子从 ROS `source:=local` 切到 UVDP 工具流；
  关闭窗口后调用 `auto-ros` 恢复 ROS，板端 idle timer（30 s 无客户端）兜底。
  链路断开时每 15 s 重试切 tool；板子重启/不可达（ssh rc=255/124）不计入
  失败，恢复后自动重连；只有板端缺脚本/无权限等确定性失败连续 3 次才停用。
- `--no-board-mode-switch`：关闭上述隐式切换；`--auto-start`/`--auto-stop`
  保留为显式开关，语义改为 `tool`/`auto-ros`。

### Changed
- `--auto-start`/`--auto-stop` 不再调用旧版 `orin_stream_start.sh`/
  `orin_stream_stop.sh`（UVDP v1 bridge，与 v2 客户端不兼容），改为
  `zscamera-mode`；无界面模式同样更新。

## [2.1.2] - 2026-11-17

### Fixed
- 重新构建发布包：2.1.1 的发布资产未包含 UVDP v2 直连代码，连接 ZSCamera SDK
  1.0.1 时会在 5 秒 HELLO 超时后被服务端断开；2.1.2 从 2.1.1 源码重新构建，
  连接日志应出现 `(UVDP v2)`。源码功能无变更。

## [2.1.1] - 2026-11-17

### Changed
- 点云相机坐标系改为 **X 左、Y 下、Z 前**（与 OpenCV/ROS 光学系一致，也是用户
  约定的相机系）：反投影、轨道投影、轴标、HUD、`camera_to_world` 换算以及
  PCD/PLY 导出全部统一到同一约定，界面点云与导出文件同系、左右不再镜像。
- 点云默认与“前视/重置”不再使用与 RGB 逐像素重合的平面点阵视角：打开后即
  正对场景的 **3D 透视前视**（近大远小、能看出纵深），前视/重置同样回到该
  视角。平面相机视角仅保留为内部投影实现（`CloudView.camera`），界面不再
  暴露；点云颜色仍取自校正 RGB。
- 点云画布左键**双击 = 重置**：回到 3D 前视并切回相机坐标系（轴标 X 朝左、
  Y 朝下、Z 指向屏幕内），同时清除已选中的点，避免 reset 后残留 HUD；与视图
  菜单“重置”行为一致。原双击适配视图改为该行为（`F` 键仍做适配）。
- 点云坐标面板改为只在点击选中点时显示：未选中（包括仅悬停）不再弹出 HUD，
  点云窗格保持干净；`Ctrl+C` 也只复制已选中点的坐标。
- Orin 数据源改走 UVDP v2：连接后立即发 `HELLO`（proto 2，带 CRC32C），按 64 字节
  头解析 `msg_type`/`stream_id`/`pixel_format`，深度支持 `u16_mm_zlib`（板端默认，
  768x512 从 768 KB 压到约 325 KB），META 改用 v2 的 `streams` + `calibration.data`，
  `left_K`/`right_K`/`depth_K` 在客户端按板端同款 P1/P2 缩放公式推导。v1 兼容解析
  路径移除。实测单客户端 left 30.4 / right 30.4 / depth 6.5 fps、6.2 MB/s。
- 修复拖动后点云“不是点云”的问题：此前旋转绕相机原点进行，点云转到侧面
  会被近平面裁掉、画面撕裂成斜切照片。现在一拖动就切到 CloudCompare 式
  轨道相机（围绕场景中心），`fit` 预先算好轨道参数，旋转后点云完整留在
  视野内（实测 768×512 深度旋转 0°→69°，可见点保持 100%）。
- 点云默认 3D 前视取景：按深度图尺寸与 12 万点显示预算（768×512 即
  stride=2）降采样，`fit` 按点云包围盒取景；RGBA 合并后走展平索引写入，
  768×512 深度单帧渲染约 15 ms。
- 修复光栅化颜色未随深度排序同步重排的问题：此前每个像素可能拿到另一个点
  的颜色，RGB 点云表现为彩色噪点。
- 点云视图重做（参考 CloudCompare）：实时画布改为透视轨道相机，支持左键旋转、
  右键/Shift 平移、滚轮缩放、双击重置，以及前视/顶视/右视/左视/等轴预设；
  新增深色渐变背景、地面网格、XYZ 轴标、可选 EDL 深度增强。
- 点云悬停/单击默认显示**世界系 XYZ（Z 上）**（米）与像素坐标：X 右、Y 前、
  Z 上，地面 Z=0；可在视图菜单切回相机系（X 左、Y 下、Z 前）。单击固定选中点、
  换帧后按采样像素续定位，`Ctrl+C` 复制当前 HUD 坐标，`Esc` 取消选中。
  PCD 导出仍保持相机系，避免破坏下游。
- 点云新增 RGB/深度伪彩配色切换（`C` 键或视图菜单），状态栏显示当前配色；
  校正彩色与深度尺寸不同时按深度像素直接映射取色，不再整帧 resize。
- 点云渲染拆分为共享核心 `pointcloud.py`（反投影/投影/光栅化）；实时画布用
  透视取景，`--snapshot` 拼图保留原正交缩放取景与点数，公式只维护一份。
- 光栅化越界像素不再裁剪到画布边界，消除边缘拖尾。
- 彩色画面显示板端原始分辨率（工具展示优先）；板端发布原始彩色
  （`color.rectified=false`）且 META 带 `calibration` 时，点云取色先按标定
  在客户端 remap 到深度校正网格（如 Thor 1920×1280 → 768×512），
  与板端 VPI 校正几何一致；板端已校正流仍直接取色。
- Orin 右目改为按已匹配左目时间戳配对（深度时间戳偏移时不再误取相邻
  立体对的右目）；预览左右目改用独立解码线程，深度三元组复用预览已解码
  的左目帧，消除 1920×1280 JPEG 串行/重复解码造成的帧率损失。
- Orin 深度预览与三元组解耦：链路丢弃左目帧时，深度窗格仍按裸深度包刷新；
  点云与录制继续使用严格配对的三元组。断开连接时等待预览/维护线程退出，
  避免 1920×1280 JPEG 解码过程中关闭程序触发 abort。
- 标定入口兼容新 SDK 的 `calibration.data` 包装布局（`P1/P2/K/D/R1/R2`
  在 `data` 内），旧 bridge 的平铺布局保持不变。


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
