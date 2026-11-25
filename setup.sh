#!/bin/bash

INSTALL_DIR="protocols/ros2/install"
if [[ -f "$INSTALL_DIR/local_setup.sh" ]]; then
  source "$INSTALL_DIR/local_setup.sh"
else
  echo "⚠️ ：未找到 $INSTALL_DIR/local_setup.sh，已跳过 ROS2 环境加载"
fi

# 使用ros2 plugin时需要打开
# source "${AIMRT_PLUGIN_DIR}/share/ros2_plugin_proto/local_setup.sh"
