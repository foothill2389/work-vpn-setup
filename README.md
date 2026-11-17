# work-vpn-setup

A [NetworkManager dispatcher](https://networkmanager.dev/) hook that automatically configures DNS split-routing and MTU when a corporate VPN connection comes up.

## What it does

When the configured VPN interface transitions to the up state (either the `up` or `vpn-up` dispatcher action), the script:

1. **Routes DNS for your work domains through the VPN's resolvers** using `resolvectl domain` — so only traffic for those domains uses the VPN's DNS, and everything else keeps using your normal resolvers (split-DNS via `systemd-resolved`).
2. **Disables DNSSEC validation on that interface** — many corporate resolvers don't support DNSSEC, causing lookup failures if validation stays on.
3. **Sets a lowered MTU on the interface** — accounts for tunnel overhead and prevents fragmented/stalled TCP connections over the VPN.

Any other interface or action causes the script to exit silently.

## Why domains aren't hardcoded

This repository is safe to publish because **no internal hostnames live in the script**. Per-machine settings (domain list, interface name, MTU, DNSSEC policy) are read from a private config file that stays on each workstation and is never committed:

```
/etc/work-vpn.conf
```

## Installation

1. Install the dispatcher script:

   ```bash
   sudo cp 90-work-vpn.sh /etc/NetworkManager/dispatcher.d/90-work-vpn.sh
   sudo chown root:root /etc/NetworkManager/dispatcher.d/90-work-vpn.sh
   sudo chmod 750 /etc/NetworkManager/dispatcher.d/90-work-vpn.sh
   ```

   > Permissions matter: NetworkManager **ignores** dispatcher scripts that are world-writable or not owned by root.

2. Create the private config:

   ```bash
   sudo cp work-vpn.conf.example /etc/work-vpn.conf
   sudoedit /etc/work-vpn.conf   # fill in your real domains and interface
   ```

3. Activate — either reconnect the VPN or run the dispatcher hook by hand:

   ```bash
   sudo /etc/NetworkManager/dispatcher.d/90-work-vpn.sh vpn0 vpn-up
   ```

4. Verify:

   ```bash
   resolvectl status vpn0       # should list your domains; DNSSEC: no
   ip link show vpn0            # should show the configured MTU
   ```

## Configuration reference

| Variable       | Purpose                                        | Example                          |
|----------------|------------------------------------------------|----------------------------------|
| `VPN_IF`       | Interface the dispatcher triggers on           | `vpn0`                           |
| `VPN_DOMAINS`  | Space-separated domains routed via VPN DNS     | `corp.example.com wiki.example.net` |
| `VPN_MTU`      | MTU applied to the interface                   | `1334`                           |
| `VPN_DNSSEC`   | DNSSEC mode passed to `resolvectl dnssec`      | `no`                             |

Sub-domains match automatically: configuring `corp.example.com` also routes `git.corp.example.com`.

## Requirements

- Linux with NetworkManager (dispatcher hooks enabled) and `systemd-resolved`
- `resolvectl` (systemd) and `ip` (iproute2)
- Root privileges to install

## Troubleshooting

- **Script seems ignored** — check permissions (`750`, root-owned) and that the `NetworkManager-dispatcher` unit is enabled: `systemctl status NetworkManager-dispatcher`.
- **Dispatcher logs** — dispatcher script output lands in the journal: `journalctl -u NetworkManager-dispatcher`.
- **No effect at all** — confirm the config exists and `VPN_DOMAINS` is non-empty; the script refuses to run with an empty domain list by design.

## License

MIT
