#!/usr/bin/env bash
set -e

echo "============================================================"
echo " Starting SURA"
echo "============================================================"
echo " Robot name        : ${SURA_ROBOT_NAME}"
echo " Robot namespace   : ${SURA_ROBOT_NAMESPACE}"
echo " ROS_DOMAIN_ID     : ${ROS_DOMAIN_ID}"
echo " DDS middleware    : ${SURA_DDS}"
echo " RMW implementation: ${RMW_IMPLEMENTATION}"
echo " Workspace         : /sura_ws_meta"
echo "============================================================"
echo

source /opt/ros/humble/setup.bash

if [ -f /sura_ws_meta/install/setup.bash ]; then
  source /sura_ws_meta/install/setup.bash
fi

# Change this command to the real launch file of your architecture.
exec ros2 launch sura_bringup blueboat.launch.py \
  robot_name:="${SURA_ROBOT_NAME}" \
  namespace:="${SURA_ROBOT_NAMESPACE}"
