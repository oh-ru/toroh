#!/bin/bash
set -e

USER_ID=${USER_ID:-9001}
GROUP_ID=${GROUP_ID:-$USER_ID}

TOR_JAVA_OPTS="-DsocksProxyHost=127.0.0.1 -DsocksProxyPort=9050 -DsocksProxyVersion=5 -Dhttp.nonProxyHosts=localhost|127.0.0.1|10.*|172.*|192.168.*"
export EXTRA_JAVA_OPTS="${TOR_JAVA_OPTS}${EXTRA_JAVA_OPTS:+ $EXTRA_JAVA_OPTS}"

mkdir -p /var/lib/tor
chown -R "$USER_ID:$GROUP_ID" /var/lib/tor

echo "[toroh] Starting tor..."
su-exec "$USER_ID:$GROUP_ID" /tor-start.sh > >(tee /tmp/tor.log) 2>&1 &
TOR_PID=$!

echo "[toroh] Waiting for Tor bootstrap..."
timeout=600
elapsed=0
while true; do
    if grep -q "Bootstrapped 100%" /tmp/tor.log 2>/dev/null; then
        echo "[toroh] Tor bootstrapped successfully."
        break
    fi
    if ! kill -0 "$TOR_PID" 2>/dev/null; then
        echo "[toroh] Tor process died unexpectedly." >&2
        exit 1
    fi
    if [ "$elapsed" -ge "$timeout" ]; then
        echo "[toroh] Tor did not bootstrap within ${timeout}s." >&2
        exit 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
done

echo "[toroh] Starting OpenHAB..."
exec /entrypoint "$@"
