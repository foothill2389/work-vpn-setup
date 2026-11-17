# /etc/work-vpn.conf — local (private) configuration for 90-work-vpn.sh
#
# Copy this file to /etc/work-vpn.conf and fill in your real values.
# DO NOT commit the real file to git — it contains internal domain names.

# Interface name the dispatcher triggers on (the VPN connection's
# interface, as shown by `nmcli device status`).
VPN_IF="vpn0"

# Domains resolved through the VPN's DNS servers (split-DNS).
# Space-separated. These become `resolvectl domain` routing entries,
# so sub-domains match automatically.
VPN_DOMAINS="corp.example.com wiki.example.net dev.example.org"

# Lowered MTU to account for tunnel overhead (prevents fragmentation
# stalls on TCP over the VPN). 1334 is an example — tune to your VPN.
VPN_MTU=1334

# Disable DNSSEC validation on this interface if the VPN's resolvers
# don't support it. "no" disables; "allow-downgrade" is a softer option.
VPN_DNSSEC=no
