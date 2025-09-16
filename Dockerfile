# renovate: datasource=docker depName=adguard/adguardhome versioning=docker
ARG ADGUARD_HOME_VERSION=v0.107.66
FROM adguard/adguardhome:${ADGUARD_HOME_VERSION}

RUN apk add keepalived envsubst caddy curl

COPY --chmod=0755 config/entrypoint.sh /
COPY --chmod=0755 config/adguard_config_sync.sh /
COPY --chmod=0755 config/adguard.sh /
COPY config/keepalived.conf /etc/keepalived/keepalived.conf.template
COPY config/Caddyfile /etc/caddy/Caddyfile
# AdguardHome Config Sync
EXPOSE 2015

ENTRYPOINT ["/entrypoint.sh"]
CMD [""]
