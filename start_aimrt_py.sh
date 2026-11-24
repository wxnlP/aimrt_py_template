#!/bin/bash

if [ $# -lt 1 ]; then
    echo "⚠️ ：请输入配置文件"
    exit
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE=$1
PYTHON_BIN=$(command -v python)
echo "Python 环境: $PYTHON_BIN"

# 处理ros2环境
source "$SCRIPT_DIR/setup.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️ ：找不到配置文件 $CONFIG_FILE"
    exit
fi

export AIMRT_PLUGIN_DIR="$(${PYTHON_BIN} -c 'import aimrt_py, pathlib; print(pathlib.Path(aimrt_py.__file__).resolve().parent)')"

${PYTHON_BIN} "${SCRIPT_DIR}/main.py" \
    --cfg_file_path="${SCRIPT_DIR}/$1"
