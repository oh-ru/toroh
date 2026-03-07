FROM openhab/openhab:5.2.0-debian

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    tor \
    obfs4proxy \
    && rm -rf /var/lib/apt/lists/*

COPY tor-start.sh /tor-start.sh
COPY entrypoint.sh /entrypoint.sh
COPY bridges.txt /etc/tor/bridges.txt
RUN chmod +x /tor-start.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["su-exec", "openhab", "tini", "-s", "./start.sh"]
