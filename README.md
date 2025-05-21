# adguard-home-ha

This image contains three parts to support a HA AdGuard setup:

- **AdGuard Home** for DNS resolving
- **Keepalived** to support a floating VIP address
- **Caddy** to serve the current AdGuard configuration to other instances

## Config options

| Environment variable              | Description                                                                                                         | Default      | Required                                        |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------ | ----------------------------------------------- |
| `TZ`                              | timezone used by the container and AdGuard. Must match the sync origin (if sync is enabled)                         | UTC          | no                                              |
| `DEBUG`                           | start services in DEBUG mode                                                                                        | false        | no                                              |
| `ADGUARD_CONFIG_SYNC_ENABLED`     | enables the AdGuard Config Sync using HTTP from a remote instance                                                   | false        | no                                              |
| `ADGUARD_CONFIG_SYNC_INTERVAL`    | number of seconds between sync runs                                                                                 | 60           | no                                              |
| `ADGUARD_CONFIG_SYNC_PRIMARY_URL` | URL where to get the AdGuard config; e.g. `http://192.168.0.3:2015/AdGuardHome.yaml`                                | ""           | only if `ADGUARD_CONFIG_SYNC_ENABLED` is `true` |
| `ADGUARD_CONFIG_SYNC_ROLE`        | Determines if this instance provides the config via HTTP (`PRIMARY`) or syncs it from a different host (`FOLLOWER`) | PRIMARY      | no                                              |
| `KEEPALIVED_ENABLED`              | enables the integrated keepalived instance                                                                          | false        | no                                              |
| `KEEPALIVED_AUTH_PASS`            | VRRP password used for communication between keepalived instances                                                   | password     | no                                              |
| `KEEPALIVED_DEFAULT_INTERFACE`    | default interface used for keepalived                                                                               | (autodetect) | no                                              |
| `KEEPALIVED_PRIORITY`             | priority used for keepalived. This is relevant to determine the state/role                                          | 100          | no                                              |
| `KEEPALIVED_ROUTER_ID`            | common VRRP router ID to group remote instances                                                                     | 53           | no                                              |
| `KEEPALIVED_STATE`                | desired state for this keepalived instance. Valid values are `MASTER` or `BACKUP`                                   | BACKUP       | no                                              |
| `KEEPALIVED_VIP`                  | VIP to bind if keepalived determines this instance as MASTER                                                        | ""           | only if `KEEPALIVED_ENABLED` is `true`          |

## Networking modes

### Host networking (easy)

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

### MacVlan mode (advanced)

This mode uses `macvlan` on the given host interface to support native communication to the container. Therefore the container gets its separate IPv4/IPv6 out of the given range.

**NOTE: In this mode, the communication between the host and container is not possible by default!** You can use <https://github.com/laugmanuel/macvlan-router> as a workaround. This tool creates a virtual network interface on the host, enabling communication between the host and the container through the MacVlan network.

The config below requires an existing docker network called `macvlan` (see [macvlan-router](https://github.com/laugmanuel/macvlan-router) repo for examples)

```yaml
# docker compose
services:
  adguard:
    [...]
    cap_add:
      - NET_ADMIN
    networks:
      macvlan:
        ipv4_address: 192.168.0.3
    [...]

networks:
  macvlan:
    external: true
```

or when using plain docker:

```sh
docker run -dt [...] --cap-add NET_ADMIN --network=macvlan --ip 192.168.0.3 ghcr.io/laugmanuel/adguard-home-ha:main
```

## Failover & Autohealing

There is a DNS resultion check script which is invoked by keepalived and also the container runtime itself.

If the script fails, keepalived will release the VIP for a follower to pick it up. Also, the container will become unhealthy after the defined amount of failed requests, as configured in the container's health check settings.

If you want to enable autohealing (e.g. restarting the container if it becomes unhealthy), you can use <https://hub.docker.com/r/willfarrell/autoheal/> like so:

```yaml
services:
  adguard:
    [...]
    labels:
      autoheal: true

  autoheal:
    restart: unless-stopped
    image: willfarrell/autoheal:latest
    environment:
      AUTOHEAL_CONTAINER_LABEL: autoheal
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```
