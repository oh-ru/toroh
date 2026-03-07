# toroh

Docker-образ OpenHAB со встроенным Tor и поддержкой obfs4-мостов.

Предназначен для пользователей, у которых провайдер блокирует доступ к `*.openhab.org`, `*.eclipse.org`, `*.osgi.org` и другим доменам, необходимым OpenHAB для загрузки и установки аддонов.

## Как это работает

Образ основан на `openhab/openhab:5.1.2-debian`, в который добавлены `tor` и `obfs4proxy`.

При старте контейнера:

1. Tor запускается в фоне, используя мосты из переменной окружения `TOR_BRIDGES` или из встроенного файла `/etc/tor/bridges.txt`
2. Entrypoint ждёт, пока Tor сообщит `Bootstrapped 100%` (до 5 минут)
3. Только после успешного bootstrap запускается OpenHAB — это гарантирует, что все сетевые запросы идут через Tor с первой же секунды

Трафик JVM OpenHAB автоматически направляется через локальный SOCKS5-прокси (`127.0.0.1:9050`). Параметры прокси добавляются автоматически в `EXTRA_JAVA_OPTS`:

```
-DsocksProxyHost=127.0.0.1
-DsocksProxyPort=9050
-DsocksProxyVersion=5
-Dhttp.nonProxyHosts=localhost|127.0.0.1|10.*|172.*|192.168.*
```

Если вы передаёте свои параметры через `EXTRA_JAVA_OPTS`, они добавляются к этим дефолтным.

## Использование

### Минимальный запуск (с встроенными мостами)

```yaml
services:
  openhab:
    image: ghcr.io/oh-ru/toroh:5.1.2
    container_name: openhab
    restart: unless-stopped
    network_mode: host
    environment:
      - USER_ID=1001
      - GROUP_ID=1001
    volumes:
      - ./conf:/openhab/conf
      - ./userdata:/openhab/userdata
      - ./addons:/openhab/addons
```

Или через `docker run`:

```bash
docker run -d \
  --name openhab \
  --restart unless-stopped \
  --network host \
  -e USER_ID=1001 \
  -e GROUP_ID=1001 \
  -v ./conf:/openhab/conf \
  -v ./userdata:/openhab/userdata \
  -v ./addons:/openhab/addons \
  ghcr.io/oh-ru/toroh:5.1.2
```

### С собственными мостами

Через переменную окружения мосты через запятую:

```yaml
environment:
  - TOR_BRIDGES=obfs4 1.2.3.4:1234 FINGERPRINT cert=... iat-mode=0,obfs4 5.6.7.8:5678 FINGERPRINT cert=... iat-mode=0
```

Или монтируя файл с мостами:

```yaml
volumes:
  - ./bridges.txt:/etc/tor/bridges.txt:ro
```

Формат файла — по одному мосту на строку:

```
obfs4 1.2.3.4:1234 FINGERPRINT cert=... iat-mode=0
obfs4 5.6.7.8:5678 FINGERPRINT cert=... iat-mode=0
```

Полная документация базового образа: [hub.docker.com/r/openhab/openhab](https://hub.docker.com/r/openhab/openhab)

## Переменные окружения

| Переменная | Обязательная | Описание |
|---|---|---|
| `TOR_BRIDGES` | Нет | Список obfs4-мостов через запятую. Если не задана, используются встроенные мосты из `/etc/tor/bridges.txt`. |
| `EXTRA_JAVA_OPTS` | Нет | Дополнительные JVM-параметры для OpenHAB. Добавляются к автоматическим SOCKS-параметрам. Например: `-Duser.timezone=Europe/Moscow`. |
| `USER_ID` | Нет | UID процесса openhab (по умолчанию: 9001) |
| `GROUP_ID` | Нет | GID процесса openhab (по умолчанию: USER_ID) |

Все остальные переменные окружения базового образа `openhab/openhab` поддерживаются без изменений.

## Получение obfs4-мостов

Образ содержит встроенные мосты, которые обновляются при каждой сборке. Если они не работают, получите свежие мосты:

- На [bridges.torproject.org](https://bridges.torproject.org/bridges?transport=obfs4) — выбрать тип **obfs4**
- В телеграм-боте [@GetBridgesBot](https://t.me/GetBridgesBot)

Несколько мостов разделяются запятой в `TOR_BRIDGES`:

```
TOR_BRIDGES=obfs4 1.2.3.4:1234 FP1 cert=AAA iat-mode=0,obfs4 5.6.7.8:5678 FP2 cert=BBB iat-mode=0
```

## Теги образа

| Тег | Описание |
|---|---|
| `5.1.2` | Актуальная сборка ветки `v5.1.2` |
| `sha-<hash>` | Сборка конкретного коммита |

Образы публикуются в `ghcr.io/oh-ru/toroh` через GitHub Actions при каждом пуше в ветку `v5.1.2`, а также ежедневно по расписанию.

---

# toroh

OpenHAB Docker image with built-in Tor and obfs4 bridge support.

Designed for users whose ISP blocks access to `*.openhab.org`, `*.eclipse.org`, `*.osgi.org` and other domains required for OpenHAB to download and install add-ons.

## How it works

The image is based on `openhab/openhab:5.1.2-debian` with `tor` and `obfs4proxy` added on top.

On container start:

1. Tor starts in the background using bridges from the `TOR_BRIDGES` environment variable or from the built-in `/etc/tor/bridges.txt`
2. The entrypoint waits until Tor reports `Bootstrapped 100%` (up to 5 minutes)
3. Only after successful bootstrap does OpenHAB start — guaranteeing that all network requests go through Tor from the very first second

OpenHAB JVM traffic is automatically routed through the local SOCKS5 proxy (`127.0.0.1:9050`). The proxy parameters are added automatically to `EXTRA_JAVA_OPTS`:

```
-DsocksProxyHost=127.0.0.1
-DsocksProxyPort=9050
-DsocksProxyVersion=5
-Dhttp.nonProxyHosts=localhost|127.0.0.1|10.*|172.*|192.168.*
```

If you pass your own parameters via `EXTRA_JAVA_OPTS`, they are appended to these defaults.

## Usage

### Minimal setup (with built-in bridges)

```yaml
services:
  openhab:
    image: ghcr.io/oh-ru/toroh:5.1.2
    container_name: openhab
    restart: unless-stopped
    network_mode: host
    environment:
      - USER_ID=1001
      - GROUP_ID=1001
    volumes:
      - ./conf:/openhab/conf
      - ./userdata:/openhab/userdata
      - ./addons:/openhab/addons
```

Or with `docker run`:

```bash
docker run -d \
  --name openhab \
  --restart unless-stopped \
  --network host \
  -e USER_ID=1001 \
  -e GROUP_ID=1001 \
  -v ./conf:/openhab/conf \
  -v ./userdata:/openhab/userdata \
  -v ./addons:/openhab/addons \
  ghcr.io/oh-ru/toroh:5.1.2
```

### With custom bridges

Via environment variable (comma-separated):

```yaml
environment:
  - TOR_BRIDGES=obfs4 1.2.3.4:1234 FINGERPRINT cert=... iat-mode=0,obfs4 5.6.7.8:5678 FINGERPRINT cert=... iat-mode=0
```

Or by mounting a bridges file:

```yaml
volumes:
  - ./bridges.txt:/etc/tor/bridges.txt:ro
```

File format — one bridge per line:

```
obfs4 1.2.3.4:1234 FINGERPRINT cert=... iat-mode=0
obfs4 5.6.7.8:5678 FINGERPRINT cert=... iat-mode=0
```

Full base image documentation: [hub.docker.com/r/openhab/openhab](https://hub.docker.com/r/openhab/openhab)

## Environment variables

| Variable | Required | Description |
|---|---|---|
| `TOR_BRIDGES` | No | Comma-separated list of obfs4 bridges. If not set, built-in bridges from `/etc/tor/bridges.txt` are used. |
| `EXTRA_JAVA_OPTS` | No | Additional JVM options for OpenHAB. Appended to the automatic SOCKS parameters. Example: `-Duser.timezone=Europe/London`. |
| `USER_ID` | No | UID for the openhab process (default: 9001) |
| `GROUP_ID` | No | GID for the openhab process (default: USER_ID) |

All other environment variables from the base `openhab/openhab` image are supported as-is.

## Getting obfs4 bridges

The image includes built-in bridges that are updated on every build. If they don't work, get fresh bridges:

- From [bridges.torproject.org](https://bridges.torproject.org/bridges?transport=obfs4) — select **obfs4** type
- Via Telegram bot [@GetBridgesBot](https://t.me/GetBridgesBot)

Multiple bridges are separated by a comma in `TOR_BRIDGES`:

```
TOR_BRIDGES=obfs4 1.2.3.4:1234 FP1 cert=AAA iat-mode=0,obfs4 5.6.7.8:5678 FP2 cert=BBB iat-mode=0
```

## Image tags

| Tag | Description |
|---|---|
| `5.1.2` | Latest build from `v5.1.2` branch |
| `sha-<hash>` | Specific commit build |

Images are published to `ghcr.io/oh-ru/toroh` via GitHub Actions on every push to the `v5.1.2` branch and daily on schedule.
