#!/bin/bash
# Script: find-ip-address-linux.sh
# Purpose: A firewall rule or a backup destination built on the wrong IP locks
#          you out or ships data to the wrong host — this prints every address
#          that matters on one screen so you copy from a report, not a guess.
# Usage: ./find-ip-address-linux.sh [interface]   (default: the one holding the default route)
# Tested: Kali 2026.3 (bash 5.3)
set -euo pipefail

CHECK="✓"
CROSS="✗"

# ── CONFIGURATION ──────────────────────────────────────────────
PUBLIC_IP_SERVICE="https://ifconfig.me"   # any plain-text "what is my IP" endpoint
CURL_TIMEOUT=5                            # seconds — a hung lookup must not hang the report

# ── DEFAULT ROUTE ──────────────────────────────────────────────
# The interface carrying the default route is the one the outside world
# reaches you through. Every other address on the box is local or virtual.
DEFAULT_ROUTE=$(ip -4 route show default | head -n 1)
if [ -z "$DEFAULT_ROUTE" ]; then
  echo "$CROSS no IPv4 default route — this box is not on a routed network" >&2
  exit 1
fi
GATEWAY=$(awk '{print $3}' <<< "$DEFAULT_ROUTE")
ROUTE_IFACE=$(awk '{for (i = 1; i <= NF; i++) if ($i == "dev") print $(i + 1)}' <<< "$DEFAULT_ROUTE")
IFACE="${1:-$ROUTE_IFACE}"

if [ ! -d "/sys/class/net/$IFACE" ]; then
  echo "$CROSS interface '$IFACE' does not exist — see: ip -brief link" >&2
  exit 1
fi

# ── ADDRESSES ──────────────────────────────────────────────────
# -brief prints one line per interface: name, state, then the addresses.
# Dropping the first two fields leaves only the addresses, however many.
addrs_of() {
  ip "$1" -brief addr show dev "$IFACE" "${@:2}" \
    | awk '{ $1 = ""; $2 = ""; sub(/^ +/, ""); print }'
}
LOCAL_IPV4=$(addrs_of -4)
LOCAL_IPV6=$(addrs_of -6 scope global)   # scope global skips the fe80:: link-local noise
MAC=$(cat "/sys/class/net/$IFACE/address")

# ── DNS ────────────────────────────────────────────────────────
# On systemd-resolved boxes /etc/resolv.conf says 127.0.0.53 — that is the
# local stub, not the upstream server. resolvectl knows the real ones.
DNS_SERVERS=""
DNS_SOURCE="resolvectl"
if command -v resolvectl >/dev/null 2>&1; then
  DNS_SERVERS=$(resolvectl dns "$IFACE" 2>/dev/null | sed 's/^[^:]*: *//' || true)
fi
if [ -z "$DNS_SERVERS" ]; then
  DNS_SERVERS=$(awk '/^nameserver/ {printf "%s ", $2}' /etc/resolv.conf)
  DNS_SOURCE="/etc/resolv.conf"
fi

# ── PUBLIC IP ──────────────────────────────────────────────────
# Nothing on the box knows its public address — it is whatever NAT rewrote
# the source to. Ask an outside service and treat "no answer" as data.
PUBLIC_IPV4=$(curl -4 -s --max-time "$CURL_TIMEOUT" "$PUBLIC_IP_SERVICE" || true)
PUBLIC_IPV6=$(curl -6 -s --max-time "$CURL_TIMEOUT" "$PUBLIC_IP_SERVICE" || true)

# ── REPORT ─────────────────────────────────────────────────────
echo "Network report for $(hostname) — $(date '+%Y-%m-%d %H:%M')"
echo "────────────────────────────────────────────────────"
printf '%-13s %s\n' "interface"   "$IFACE"
printf '%-13s %s\n' "local IPv4"  "${LOCAL_IPV4:-none}"
printf '%-13s %s\n' "local IPv6"  "${LOCAL_IPV6:-none}"
printf '%-13s %s\n' "MAC"         "$MAC"
printf '%-13s %s\n' "gateway"     "$GATEWAY"
printf '%-13s %s (%s)\n' "DNS"    "${DNS_SERVERS:-none}" "$DNS_SOURCE"
if [ -n "$PUBLIC_IPV4" ]; then
  printf '%-13s %s %s\n' "public IPv4" "$PUBLIC_IPV4" "$CHECK"
else
  printf '%-13s %s %s\n' "public IPv4" "lookup failed — offline or $PUBLIC_IP_SERVICE unreachable" "$CROSS"
fi
printf '%-13s %s\n' "public IPv6" "${PUBLIC_IPV6:-none}"
echo
echo "Every interface that is up (Docker veth pairs hidden):"
ip -brief addr show up | grep -v '^veth' || true
