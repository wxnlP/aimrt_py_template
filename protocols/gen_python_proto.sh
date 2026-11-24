#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pb"
GEN_DIR="$ROOT/_gen"
includes=()
protos=()
for dir in "$ROOT"/*/; do
  [[ "$dir" != "$GEN_DIR/" ]] || continue
  files=("$dir"*.proto)
  ((${#files[@]})) || continue
  includes+=(-I "${dir%/}")
  protos+=("${files[@]}")
done
((${#protos[@]})) || fail "未在 $ROOT 的一级包目录中找到 .proto 文件。"
command -v protoc >/dev/null || fail "未找到 protoc，请先安装 protobuf 编译器。"

rpc_args=()
if plugin=$(command -v protoc_plugin_py_gen_aimrt_py_rpc); then
  rpc_args=(--aimrt_rpc_out="$GEN_DIR" --plugin=protoc-gen-aimrt_rpc="$plugin")
else
  printf '%s\n' "未找到 protoc_plugin_py_gen_aimrt_py_rpc，跳过 AimRT RPC 桩生成。" >&2
fi

mkdir -p "$GEN_DIR"
protoc "${includes[@]}" --python_out="$GEN_DIR" --pyi_out="$GEN_DIR" \
  "${rpc_args[@]}" "${protos[@]}" || fail "Protobuf Python 代码生成失败。"

modules=("$GEN_DIR"/*_pb2.py "$GEN_DIR"/*_pb2.pyi)
if ((${#modules[@]})); then
  sed -i -E 's/^import ([A-Za-z0-9_]+_pb2)( as [A-Za-z0-9_]+)?$/from . import \1\2/' "${modules[@]}"
fi

touch "$GEN_DIR/__init__.py"
printf '已生成：%s\n' "$GEN_DIR"
