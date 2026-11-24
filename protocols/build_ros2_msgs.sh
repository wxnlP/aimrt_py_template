#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/ros2"
STUB_DIR="$ROOT/rpc_stubs"
ROS_PREFIX="${ROS2_PREFIX:-/opt/ros/${ROS_DISTRO:-humble}}"
BUILD_PYTHON="${BUILD_PYTHON:-/usr/bin/python3}"
packages=()
services=()
for dir in "$ROOT"/*/; do
  case "${dir%/}" in
    "$ROOT/build"|"$ROOT/install"|"$ROOT/log"|"$STUB_DIR") continue ;;
  esac
  [[ -f "${dir}package.xml" ]] || continue
  packages+=("${dir%/}")
  services+=("${dir}srv/"*.srv)
done
((${#packages[@]})) || fail "未在 $ROOT 的一级包目录中找到 package.xml。"
[[ -x "$BUILD_PYTHON" ]] || fail "未找到构建用 Python：$BUILD_PYTHON"
[[ -f "$ROS_PREFIX/setup.bash" ]] || fail "未找到 ROS2：$ROS_PREFIX/setup.bash，请检查 ROS2_PREFIX 或 ROS_DISTRO。"

set +u
source "$ROS_PREFIX/setup.bash"
set -u
command -v colcon >/dev/null || fail "未找到 colcon。"
if ((${#services[@]})); then
  rpc_gen="${AIMRT_ROS2_RPC_GEN:-aimrt_py-gen-ros2-rpc}"
  rpc_gen=$(command -v "$rpc_gen") && [[ -x "$rpc_gen" ]] || fail "未找到 ROS2 RPC 生成器，请安装 aimrt_py 或设置 AIMRT_ROS2_RPC_GEN。"
  [[ "$rpc_gen" = /* ]] || rpc_gen="$PWD/$rpc_gen"
fi

cd "$ROOT"
colcon build --paths "${packages[@]}" --merge-install --install-base install --build-base build \
  --cmake-clean-cache --cmake-args -DPython3_EXECUTABLE="$BUILD_PYTHON" \
  -DPYTHON_EXECUTABLE="$BUILD_PYTHON" || fail "ROS2 协议包构建失败。"

mkdir -p "$STUB_DIR"
[[ "$(realpath -- "$STUB_DIR")" == "$(pwd -P)/rpc_stubs" ]] || fail "RPC 桩目录指向工作区外或不是预期目录：$STUB_DIR"
rm -f -- "$STUB_DIR"/*_aimrt_rpc_ros2.py
last_dir=
for srv in "${services[@]}"; do
  dir=${srv%/srv/*}
  if [[ "$dir" != "$last_dir" ]]; then
    pkg=$("$BUILD_PYTHON" -c 'import sys, xml.etree.ElementTree as ET; print(ET.parse(sys.argv[1]).getroot().findtext("name", "").strip())' "$dir/package.xml")
    [[ -n "$pkg" ]] || fail "package.xml 缺少包名：$dir/package.xml"
    last_dir=$dir
  fi
  name=${srv##*/}
  [[ ! -e "$STUB_DIR/${name%.srv}_aimrt_rpc_ros2.py" ]] || fail "RPC 桩文件名冲突：$srv"
  "$rpc_gen" --pkg_name="$pkg" --srv_file="$srv" --output_path="$STUB_DIR" || fail "RPC 桩生成失败：$srv"
done

touch "$STUB_DIR/__init__.py"
printf '已构建：%s\n已生成 RPC 桩（%s 个）：%s\nsource %q\n' \
  "$ROOT/install" "${#services[@]}" "$STUB_DIR" "$ROOT/install/local_setup.bash"
