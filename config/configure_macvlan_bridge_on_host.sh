#!/usr/bin/env sh

PARENT_INTERFACE=bridge0
BRIDGE_INTERFACE=mac0
BRIDGE_IP=192.168.0.249/24
TARGET_RANGE=192.168.0.160/32

echo "Creating bridge interface..."
ip link show ${BRIDGE_INTERFACE} 2>/dev/null ||
  ip link add ${BRIDGE_INTERFACE} link ${PARENT_INTERFACE} type macvlan mode bridge

sleep 1
echo "Adding IP to bridge interface..."
ip addr show ${BRIDGE_INTERFACE} | grep ${BRIDGE_IP} ||
  ip addr add ${BRIDGE_IP} dev ${BRIDGE_INTERFACE}

sleep 1
echo "Bringing interface up..."
ip link show ${BRIDGE_INTERFACE} | grep "state UP" ||
  ip link set ${BRIDGE_INTERFACE} up

sleep 1
echo "Add route entry for target using interface..."
route | grep ${TARGET_RANGE} ||
  ip route add ${TARGET_RANGE} dev ${BRIDGE_INTERFACE}
