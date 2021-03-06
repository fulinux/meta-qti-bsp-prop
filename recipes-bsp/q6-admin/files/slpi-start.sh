#!/bin/sh
###############################################################################
#
# This script is used for administration of the Hexagon DSP
#
# Copyright (c) 2012-2016 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
###############################################################################

KEEP_ALIVE=0
subsys_name=""

# Wait for slpi.mdt to show up
count=0
while [ ! -s /firmware/image/slpi.mdt ]; do
  sleep 0.1
  # wait 10s for /firmare mounted
  count=$(( $count + 1 ))
  if [ $count -ge 100 ]; then
    echo "[ERROR] Can not find the slpi's firmware"
    exit 1
  fi
done

for subsys in `ls /sys/bus/msm_subsys/devices`; do
  name=`cat /sys/bus/msm_subsys/devices/${subsys}/name`
  if [ "`cat /sys/bus/msm_subsys/devices/${subsys}/name`" = "slpi" ]; then
    subsys_name="${subsys}"
    break
  fi
done

if [ "$KEEP_ALIVE" = "1" ]; then
  if [ -n "${subsys_name}" ]; then
    sysctl -w kernel.panic=0
    echo 1 > /sys/bus/msm_subsys/devices/${subsys_name}/keep_alive
  else
    echo "[ERROR] Can not keep slpi alive"
  fi
fi

# FIXME: See ATL-3054
echo 1 > /sys/module/subsystem_restart/parameters/enable_debug
#FIXME: ATL-6032:Enable SSR ramdump by default,ATL-3054,ATL-2820
#TODO:once excelsior goes production builds.check if this is required
echo 1 > /sys/module/subsystem_restart/parameters/enable_ramdump
# Bring slpi out of reset
echo "[INFO] Bringing slpi out of reset"
echo 1 > /sys/kernel/boot_slpi/boot

# wait boot finished
if [ -n "${subsys_name}" ]; then
  count=0
  state=`cat /sys/bus/msm_subsys/devices/${subsys_name}/state`
  while [ "${state}" != "ONLINE" ]; do
    # wait 2s for subsys boot finished
    count=$(( $count + 1 ))
    if [ $count -ge 200 ]; then
      echo "[ERROR] slpi fail to boot"
      exit 1
    fi
    sleep 0.01
  done
fi

# Emit slpi
initctl emit slpi
