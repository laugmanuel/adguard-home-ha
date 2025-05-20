# adguard-home-ha

This image contains three parts to support a HA AdGuard setup:

- **AdGuard Home** for DNS resolving
- **Keepalived** to support a floating VIP address
- **Caddy** to serve the current AdGuard configuration to other instances

## Prerequisites

For this container to work, we need a few specific configurations:

- `net.ipv4.ip_nonlocal_bind=1` needs to be set on the container host
- `--cap-add NET_ADMIN` and `--net=host` needs to be set on the container itself

## Config options

| environment variable              | description                                                                                                        | default      | required                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------ | ----------------------------------------------- |
| `TZ`                              | timezone used by the container and AdGuard. Must match the sync origin (if sync is enabled)                        | UTC          | no                                              |
| `ADGUARD_CONFIG_SYNC_ENABLED`     | enables the AdGuard Config Sync using HTTP from a remote instance                                                  | false        | no                                              |
| `ADGUARD_CONFIG_SYNC_INTERVAL`    | number of seconds between sync runs                                                                                | 60           | no                                              |
| `ADGUARD_CONFIG_SYNC_PRIMARY_URL` | URL where to get the AdGuard config; e.g. `http://192.168.0.3:2015/AdGuardHome.yaml`                               | ""           | only if `ADGUARD_CONFIG_SYNC_ENABLED` is `true` |
| `ADGUARD_CONFIG_SYNC_ROLE`        | Determines if this instance provides the config via HTTP (`PRIMARY`) or syncs it from a differnt host (`FOLLOWER`) | PRIMARY      | no                                              |
| `KEEPALIVED_ENABLED`              | enables the integrated keepalived instance                                                                         | false        | no                                              |
| `KEEPALIVED_AUTH_PASS`            | VRRP password used for communcation between keepalived instances                                                   | password     | no                                              |
| `KEEPALIVED_DEFAULT_INTERFACE`    | default interface used for keepalived                                                                              | (autodetect) | no                                              |
| `KEEPALIVED_PRIORITY`             | priority used for keepalived. This is relevant to determine the state/role                                         | 100          | no                                              |
| `KEEPALIVED_ROUTER_ID`            | common VRRP router ID to group remote instances                                                                    | 53           | no                                              |
| `KEEPALIVED_STATE`                | desired state for this keepalived instance. Valid values are `MASTER` or `BACKUP`                                  | BACKUP       | no                                              |
| `KEEPALIVED_VIP`                  | VIP to bind if keepalived determines this instance as MASTER                                                       | ""           | only if `KEEPALIVED_ENABLED` is `true`          |
