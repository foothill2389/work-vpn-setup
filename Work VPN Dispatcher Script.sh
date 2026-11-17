#!/bin/bash
#
# 90-work-vpn.sh - NetworkManager dispatcher hook for corporate VPN
#
# Installed at: /etc/NetworkManager/dispatcher.d/90-work-vpn.sh
#
# When the VPN interface comes up, this script:
#   1. Routes DNS lookups for the work domains through the VPN's
#      DNS servers (split-DNS via systemd-resolved).
#   2. Disables DNSSEC validation on that interface (work resolvers
#      typically don't support it).
#   3. Lowers the interface MTU (fixes fragmentation/tunnel-overhead
#      issues with the corporate VPN).
#
# Domains are NOT hardcoded: they are read from a config file so this
# script can be shared publicly. Create the config before installing:
#
#   /etc/work-vpn.conf
#       VPN_IF="vpn0"
#       VPN_DOMAINS="corp.example.com wiki.example.net dev.example.org"
#       VPN_MTU=1334
#       VPN_DNSSEC=no
#
# To test by hand without the dispatcher:
#   sudo ./90-work-vpn.sh vpn0 vpn-up
#
set -u

CONF=/etc/work-vpn.conf

# Sensible defaults; the config file overrides all of these.
VPN_IF="vpn0"
VPN_DOMAINS=""
VPN_MTU=1334
VPN_DNSSEC=no

# shellcheck source=/dev/null
[ -r "$CONF" ] && . "$CONF"

iface="${1:-}"
action="${2:-}"

usage() {
    echo "Usage (dispatcher): $0 <interface> <action>" >&2
    echo "Config file:        $CONF (sets VPN_IF, VPN_DOMAINS, VPN_MTU, VPN_DNSSEC)" >&2
    exit 1
}

# Sanity checks -----------------------------------------------------
if [ -z "$iface" ] || [ -z "$action" ]; then
    usage
fi
if [ -z "$VPN_DOMAINS" ]; then
    echo "ERROR: $CONF missing or VPN_DOMAINS empty - no domains configured." >&2
    exit 1
fi
if ! command -v resolvectl >/dev/null 2>&1; then
    echo "ERROR: resolvectl not found (systemd-resolved required)." >&2
    exit 1
fi

# Only act when OUR vpn interface comes up --------------------------
case "$iface:$action" in
    "$VPN_IF:vpn-up"|"$VPN_IF:up")
        echo "Applying work-VPN DNS settings on $iface"
        # shellcheck disable=SC2086  # word splitting intended: one arg per domain
        resolvectl domain "$iface" $VPN_DOMAINS
        resolvectl dnssec "$iface" "$VPN_DNSSEC"
        ip link set dev "$iface" mtu "$VPN_MTU"
        ;;
    *)
        # Interface or action not relevant - exit quietly so the
        # dispatcher log stays clean.
        exit 0
        ;;
esac
