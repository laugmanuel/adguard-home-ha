#!/usr/bin/env sh

export ADGUARD_HOME_CONFIG_DIR="/opt/adguardhome/conf"

function bail() {
  echo "$@"
  exit 1
}

export TZ=${TZ:-"UTC"}
export KEEPALIVED_ENABLED=${KEEPALIVED_ENABLED:-"false"}
export ADGUARD_CONFIG_SYNC_ENABLED=${ADGUARD_CONFIG_SYNC_ENABLED:-"false"}

# Keepalived
if [ "$KEEPALIVED_ENABLED" == "true" ]; then
  echo "[$(date)] Starting Keepalived..."

  DEFAULT_INTERFACE=$(ip route | grep ^default | awk '{print $5}')

  export KEEPALIVED_STATE=${KEEPALIVED_STATE:-"BACKUP"}
  export KEEPALIVED_DEFAULT_INTERFACE=${KEEPALIVED_DEFAULT_INTERFACE:-$DEFAULT_INTERFACE}
  export KEEPALIVED_ROUTER_ID=${KEEPALIVED_ROUTER_ID:-"53"}
  export KEEPALIVED_PRIORITY=${KEEPALIVED_PRIORITY:-"100"}
  export KEEPALIVED_AUTH_PASS=${KEEPALIVED_AUTH_PASS:-"password"}
  export KEEPALIVED_VIP=${KEEPALIVED_VIP:?"KEEPALIVED_VIP is required"}

  if [ "$KEEPALIVED_STATE" != "MASTER" ] && [ "$KEEPALIVED_STATE" != "BACKUP" ]; then
    bail "[$(date)] KEEPALIVED_STATE must be either MASTER or BACKUP"
  fi

  envsubst </etc/keepalived/keepalived.conf.template >/etc/keepalived/keepalived.conf

  /usr/sbin/keepalived --dont-fork --log-detail --log-console --use-file=/etc/keepalived/keepalived.conf &
fi

# AdGuardHome Config sync
if [ "$ADGUARD_CONFIG_SYNC_ENABLED" == "true" ]; then
  export ADGUARD_CONFIG_SYNC_INTERVAL=${ADGUARD_CONFIG_SYNC_INTERVAL:-"60"}
  export ADGUARD_CONFIG_SYNC_ROLE=${ADGUARD_CONFIG_SYNC_ROLE:-"PRIMARY"}

  if [ "$ADGUARD_CONFIG_SYNC_ROLE" != "PRIMARY" ] && [ "$ADGUARD_CONFIG_SYNC_ROLE" != "FOLLOWER" ]; then
    bail "[$(date)] ADGUARD_CONFIG_SYNC_ROLE must be either PRIMARY or FOLLOWER"
  fi

  if [ "$ADGUARD_CONFIG_SYNC_ROLE" == "PRIMARY" ]; then
    echo "[$(date)] Starting AdGuardHome config sync PRIMARY..."

    # the environment variable is evaluated in Caddyfile
    [ "${DEBUG}" == "true" ] && export CADDY_DEBUG="debug"
    caddy run --config /etc/caddy/Caddyfile $CADDY_PARAMS &
  else
    if [ -z "$ADGUARD_CONFIG_SYNC_PRIMARY_URL" ]; then
      bail "[$(date)] ADGUARD_CONFIG_SYNC_PRIMARY_URL must be configured if running in FOLLOWER mode"
    fi

    echo "[$(date)] Starting AdGuardHome config sync FOLLOWER..."
    /adguard_config_sync.sh &

    # wait for some sort of config to exist (either via SYNC or via mount)
    while [[ ! -f "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml" && ! -f "${ADGUARD_HOME_CONFIG_DIR}/AdGuardHome.yaml.sync" ]]; do
      ls "${ADGUARD_HOME_CONFIG_DIR}"
      echo "[$(date)] Waiting for config to exist..."
      sleep 1
    done
  fi
fi

# AdGuardHome
echo "[$(date)] Starting AdGuardHome..."
/adguard.sh

# this is required because we want to restart adguard on config changes
sleep infinity
