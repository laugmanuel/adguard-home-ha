# adguard-home-ha

This image contains three parts to support a HA AdGuard setup:

- **AdGuard Home** for DNS resolving
- **Keepalived** to support a floating VIP address
- **Caddy** to serve the current AdGuard configuration to other instances

## Prerequisites


## Config options

| environment variable              | description                                                                                                        | default      | required                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------ | ----------------------------------------------- |
| `TZ`                              | timezone used by the container and AdGuard. Must match the sync origin (if sync is enabled)                        | UTC          | no                                              |
| `DEBUG`                           | start services in DEBUG mode                                                                                       | false        | no                                              |
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

## Networking modes

### Host networking

You can just use host networking and let the container bind the VIP to the hosts interface. For that to work, you need to enable `net.ipv4.ip_nonlocal_bind=1` on the host.

**Warning**: You might run into port collisions if the host itself also listens on some ports AdGuard wants to use..

For this mode you configure the docker container like this:

```yaml
# docker compose
services:
  adguard:
    [...]
    cap_add:
      - NET_ADMIN
    network_mode: host
    [...]
```

or when using plain docker:

```sh
# docker run
docker run -dt [...] --network=host --cap-add NET_ADMIN ghcr.io/laugmanuel/adguard-home-ha:main
```

### IPVlan mode

This mode creates a Layer2 bridge on the given host interface and attaches it to the container. Therefore the container gets it's sperate IPv4/IPv6 on the given VLAN.

```yaml
# docker compose
services:
  adguard:
    [...]
    networks:
      - adguard
    [...]

networks:
  adguard:
    driver: ipvlan
    driver_opts:
      parent: eth0 # host interface
      ipvlan_mode: l2 # layer2 mode
    ipam:
      config:
        - subnet: 192.168.0.0/24 # your local subnet present on the interface
          gateway: 192.168.0.1 # the gateway of the network
          ip_range: 192.168.0.160/32 # IP of this container (can also be a range). Make sure it does not collide with any DHCP range!
```

or when using plain docker:

```sh
# docker
docker network create --driver ipvlan -o parent=eth0 -o ipvlan_mode=l2 --subnet 192.168.0.0/24 --gateway 192.168.0.1 --ip-range 192.168.0.160/32 adguard
docker run -dt [...] --network=adguard ghcr.io/laugmanuel/adguard-home-ha:main
```
