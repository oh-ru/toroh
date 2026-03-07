#!/bin/sh
set -e

TORRC=/tmp/torrc

cat > "$TORRC" <<EOF
DataDirectory /var/lib/tor
SocksPort 0.0.0.0:9050
SocksPolicy accept 127.0.0.1
SocksPolicy accept 10.0.0.0/8
SocksPolicy accept 172.16.0.0/12
SocksPolicy accept 192.168.0.0/16
SocksPolicy reject *
Log notice stderr
EOF

if [ -z "$TOR_BRIDGES" ] && [ -f /etc/tor/bridges.txt ]; then
    TOR_BRIDGES="$(paste -sd ',' /etc/tor/bridges.txt)"
fi

if [ -n "$TOR_BRIDGES" ]; then
    echo "UseBridges 1" >> "$TORRC"
    echo "ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy" >> "$TORRC"
    echo "$TOR_BRIDGES" | tr ',' '\n' | while read -r bridge; do
        bridge="$(echo "$bridge" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -n "$bridge" ] && echo "Bridge $bridge" >> "$TORRC"
    done
fi

exec tor -f "$TORRC"
