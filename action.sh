#!/system/bin/sh

MODDIR=${0%/*}
. "$MODDIR/common.sh"

REPO_RAW=https://raw.githubusercontent.com/ATIK455/tailscale-native-module/prebuilt
CUSTOM_URL_FILE="$BASE/upstream_url"
if [ -r "$CUSTOM_URL_FILE" ]; then
    CUSTOM_URL="$(tr -d '\r\n ' < "$CUSTOM_URL_FILE")"
    [ -n "$CUSTOM_URL" ] && REPO_RAW="$CUSTOM_URL"
fi

TMP="$BASE/update.$$"
REMOTE_COMMIT_FILE="$TMP/commit"
POST_COMMIT_FILE="$TMP/commit-after"
INSTALLED_COMMIT_FILE="$MODDIR/upstream_commit"

cleanup() {
    rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

mkdir -p "$TMP"

valid_commit_marker() {
    MARKER="$1"
    [ "${#MARKER}" -eq 40 ] || return 1
    case "$MARKER" in
        *[!0-9a-f]*)
            return 1
            ;;
    esac
}

echo "=== Native Tailscale Module Updater ==="
echo

CURRENT_VERSION="$("$MODDIR/bin/tailscaled" --version 2>/dev/null | head -n 1)"
[ -n "$CURRENT_VERSION" ] || CURRENT_VERSION="unknown"
echo "Installed version: $CURRENT_VERSION"

if ! download_file "$REPO_RAW/commit" "$REMOTE_COMMIT_FILE"; then
    echo "ERROR: Could not download the upstream commit marker."
    exit 1
fi

REMOTE_COMMIT="$(tr -d '\r\n ' < "$REMOTE_COMMIT_FILE")"
if ! valid_commit_marker "$REMOTE_COMMIT"; then
    echo "ERROR: Invalid upstream commit marker."
    exit 1
fi

INSTALLED_COMMIT="$(cat "$INSTALLED_COMMIT_FILE" 2>/dev/null | tr -d '\r\n ')"
echo "Installed commit: ${INSTALLED_COMMIT:-unknown}"
echo "Remote commit:    $REMOTE_COMMIT"

if [ "$REMOTE_COMMIT" = "$INSTALLED_COMMIT" ]; then
    echo
    echo "Already up-to-date."
    "$MODDIR/bin/tailscale" --socket="$SOCKET" status 2>/dev/null || true
    exit 0
fi

echo
echo "Downloading updated ARM64 binaries..."

if ! download_file "$REPO_RAW/arm64/tailscale?commit=$REMOTE_COMMIT" "$TMP/tailscale"; then
    echo "ERROR: tailscale download failed."
    exit 1
fi

if ! download_file "$REPO_RAW/arm64/tailscaled?commit=$REMOTE_COMMIT" "$TMP/tailscaled"; then
    echo "ERROR: tailscaled download failed."
    exit 1
fi

if ! download_file "$REPO_RAW/commit" "$POST_COMMIT_FILE"; then
    echo "ERROR: Could not recheck upstream commit marker."
    exit 1
fi

POST_COMMIT="$(tr -d '\r\n ' < "$POST_COMMIT_FILE")"
if ! valid_commit_marker "$POST_COMMIT" || [ "$POST_COMMIT" != "$REMOTE_COMMIT" ]; then
    echo "ERROR: Upstream changed during download. Please run Action again."
    exit 1
fi

chmod 0755 "$TMP/tailscale" "$TMP/tailscaled"

if ! is_elf "$TMP/tailscale" || ! is_elf "$TMP/tailscaled"; then
    echo "ERROR: Downloaded file is not a valid ELF executable."
    exit 1
fi

NEW_VERSION="$("$TMP/tailscaled" --version 2>/dev/null | head -n 1)"
if [ -z "$NEW_VERSION" ]; then
    echo "ERROR: Downloaded daemon did not execute properly."
    exit 1
fi

echo "Downloaded Tailscale: $NEW_VERSION"
sha256sum "$TMP/tailscale" "$TMP/tailscaled" | tee "$BASE/last-update.sha256"

WAS_RUNNING=0
pid_is_ours && WAS_RUNNING=1

cp -fp "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscale.bak" 2>/dev/null || true
cp -fp "$MODDIR/bin/tailscaled" "$MODDIR/bin/tailscaled.bak" 2>/dev/null || true

stop_daemon

cp -f "$TMP/tailscale" "$MODDIR/bin/tailscale"
cp -f "$TMP/tailscaled" "$MODDIR/bin/tailscaled"
chmod 0755 "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscaled"

if official_tailscale_vpn_active; then
    printf '%s\n' "$REMOTE_COMMIT" > "$INSTALLED_COMMIT_FILE"
    echo
    echo "Updated successfully."
    echo "Daemon was not started because official Android VPN is active."
    exit 0
fi

if start_daemon; then
    printf '%s\n' "$REMOTE_COMMIT" > "$INSTALLED_COMMIT_FILE"
    echo
    echo "Update succeeded and tailscaled restarted!"
    "$MODDIR/bin/tailscale" --socket="$SOCKET" status 2>/dev/null || true
    exit 0
fi

echo
echo "New daemon failed to start; rolling back..."
stop_daemon
[ -f "$MODDIR/bin/tailscale.bak" ] && cp -f "$MODDIR/bin/tailscale.bak" "$MODDIR/bin/tailscale"
[ -f "$MODDIR/bin/tailscaled.bak" ] && cp -f "$MODDIR/bin/tailscaled.bak" "$MODDIR/bin/tailscaled"
chmod 0755 "$MODDIR/bin/tailscale" "$MODDIR/bin/tailscaled"

if [ "$WAS_RUNNING" -eq 1 ]; then
    start_daemon || true
fi

echo "Rollback complete. Check $LOGFILE"
exit 1
