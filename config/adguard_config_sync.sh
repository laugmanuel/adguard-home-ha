#!/usr/bin/env sh

ADGUARD_HOME_CONFIG_DIR="/opt/adguardhome/conf"

while [ true ]; do
  echo "[$(date)] AdGuardConfigSync: Syncing config from PRIMARY: ${ADGUARD_CONFIG_SYNC_PRIMARY_URL}"

  [ "${DEBUG}" == "true" ] && CURL_PARAMS="-vv" || CURL_PARAMS=""
  SYNC_RESULT=$(curl $CURL_PARAMS --fail-with-body -o "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.temp" ${ADGUARD_CONFIG_SYNC_PRIMARY_URL} 2>&1)

  if [ "$?" -ne 0 ]; then
    echo "$SYNC_RESULT"
  fi

  CURRENT_CONFIG_HASH=$(sha256sum "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml" 2>/dev/null | awk '{print $1}')
  SYNCED_CONFIG_HASH=$(sha256sum "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.temp" 2>/dev/null | awk '{print $1}')

  if [ "${CURRENT_CONFIG_HASH}" != "${SYNCED_CONFIG_HASH}" ]; then
    echo "[$(date)] AdGuardConfigSync: New config detected, updating..."

    mv "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.temp" "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.sync"
  fi

  sleep ${ADGUARD_CONFIG_SYNC_INTERVAL}
done
