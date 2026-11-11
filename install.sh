#!/usr/bin/env bash
# ZSViewer 一键安装：检测系统 -> 下载对应包 -> 校验 SHA256 -> 安装依赖与工具。
set -euo pipefail

REPO="zsibot-camera/ZSViewer-delivery"
VERSION="${ZSVIEWER_VERSION:-2.1.0}"
MODE="deb"
WITH_DESKTOP=0
CHECK_ONLY=0
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/zsviewer-install.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

usage() {
    cat <<'EOF'
用法: ./install.sh [选项]

  --version <v>    安装指定版本（默认 2.1.0）
  --deb            使用 deb 安装（默认，需要 sudo + apt）
  --appimage       使用 AppImage（免安装，可选 --with-desktop）
  --tar            使用 tar.gz 解压到 ~/.local/opt
  --with-desktop   安装用户级启动器/桌面菜单（AppImage、tar）
  --check          只检查系统与依赖，不下载、不安装
  -h, --help       显示帮助

环境变量:
  ZSVIEWER_VERSION 覆盖默认版本
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="${2:?缺少版本号}"; shift 2 ;;
        --deb) MODE="deb"; shift ;;
        --appimage) MODE="appimage"; shift ;;
        --tar) MODE="tar"; shift ;;
        --with-desktop) WITH_DESKTOP=1; shift ;;
        --check) CHECK_ONLY=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $1" >&2; usage >&2; exit 2 ;;
    esac
done

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

# ---------- 1. 系统检查 ----------
ARCH="$(uname -m)"
[[ "$ARCH" == "x86_64" ]] || die "仅支持 x86_64，当前为 $ARCH"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    info "系统: ${PRETTY_NAME:-unknown}"
else
    warn "未找到 /etc/os-release，按未知发行版继续"
fi

command -v curl >/dev/null || die "缺少 curl，请先安装: sudo apt install -y curl"

APT_DEPS=(
    libgl1 libegl1 libglib2.0-0 libdbus-1-3
    libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1
    libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-xinerama0
)

MISSING=()
if command -v dpkg-query >/dev/null; then
    for p in "${APT_DEPS[@]}"; do
        dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q "install ok installed" \
            || MISSING+=("$p")
    done
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
    warn "缺少运行依赖: ${MISSING[*]}"
else
    info "运行依赖检查通过"
fi

if [[ "$CHECK_ONLY" == "1" ]]; then
    info "仅检查模式，退出"
    exit 0
fi

# ---------- 2. 下载与校验 ----------
BASE="https://github.com/${REPO}/releases/download/v${VERSION}"
case "$MODE" in
    deb) ASSET="ZSViewer-${VERSION}-amd64.deb" ;;
    appimage) ASSET="ZSViewer-${VERSION}-linux-x86_64.AppImage" ;;
    tar) ASSET="ZSViewer-${VERSION}-linux-x86_64.tar.gz" ;;
    *) die "未知安装模式: $MODE" ;;
esac

info "下载 $ASSET ..."
curl -fL --retry 3 -o "$WORKDIR/$ASSET" "$BASE/$ASSET"
curl -fL --retry 3 -o "$WORKDIR/SHA256SUMS" "$BASE/SHA256SUMS"

info "校验 SHA256 ..."
( cd "$WORKDIR" && grep "  ${ASSET}\$" SHA256SUMS | sha256sum -c - ) \
    || die "SHA256 校验失败，停止安装"

# ---------- 3. 安装 ----------
case "$MODE" in
    deb)
        command -v apt >/dev/null || die "缺少 apt；请改用 --appimage 或 --tar"
        info "使用 apt 安装（会自动安装依赖）..."
        sudo apt install -y "$WORKDIR/$ASSET"
        info "验证: $(zsviewer-cli --version)"
        ;;
    appimage)
        DEST="${HOME}/.local/opt/zsviewer"
        mkdir -p "$DEST"
        install -m 0755 "$WORKDIR/$ASSET" "$DEST/ZSViewer.AppImage"
        if [[ ${#MISSING[@]} -gt 0 ]]; then
            warn "AppImage 仍需要系统库，建议执行:"
            warn "  sudo apt update && sudo apt install -y ${MISSING[*]}"
        fi
        if [[ "$WITH_DESKTOP" == "1" ]]; then
            "$DEST/ZSViewer.AppImage" --install-desktop
        fi
        info "安装完成: $DEST/ZSViewer.AppImage"
        ;;
    tar)
        DEST="${HOME}/.local/opt/zsviewer"
        rm -rf "$DEST"
        mkdir -p "$DEST"
        tar -xzf "$WORKDIR/$ASSET" -C "$DEST" --strip-components=1
        if [[ ${#MISSING[@]} -gt 0 ]]; then
            warn "仍缺少系统库，建议执行:"
            warn "  sudo apt update && sudo apt install -y ${MISSING[*]}"
        fi
        if [[ "$WITH_DESKTOP" == "1" ]]; then
            "$DEST/zsviewer-cli" --install-desktop
        fi
        info "安装完成: $DEST/ZSViewer"
        ;;
esac

info "运行: zsviewer --host <板端IP>（或 $DEST/ZSViewer）"
