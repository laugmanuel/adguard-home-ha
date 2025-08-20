#!/usr/bin/env sh

ADGUARD_HOME_CONFIG_DIR="/opt/adguardhome/conf"

function start_adguard() {
  [ "${DEBUG}" == "true" ] && ADGUARD_PARAMS="-v" || ADGUARD_PARAMS=""

  # call the upstream entrypoint (https://github.com/AdguardTeam/AdGuardHome/blob/master/docker/Dockerfile)
  /opt/adguardhome/AdGuardHome $ADGUARD_PARAMS\
    --no-check-update \
    -c /opt/adguardhome/conf/AdGuardHome.yaml \
    -w /opt/adguardhome/work
}

start_adguard &

while [ true ]; do
  if [ -f "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.sync" ]; then
    echo "[$(date)] AdGuard: new synced config detected, restarting AdGuardHome..."

    diff -s "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml" "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.sync" 2>/dev/null

    pkill AdGuardHome
    mv "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.sync" "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml"
    start_adguard &
  fi

  sleep 5
done
