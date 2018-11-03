#!/bin/bash

# possibly quickest way to share your internet connection over a wired network.
# requires
#   * NetworkManager >= 1.4 up and running
#   * dnsmasq binary in your path
#   * iptables and ip6tables with NAT support (requires at least linux 3.9)

# usage: $0 DEVICENAME

set -eu

die() {
    printf '[FATAL] %s\n' "$*" 1>&2
    exit 1
}

info() {
    printf '[INFO] %s\n' "$*" 1>&2
}

if [ "x${1:-}" = "x" ]; then
    die "No device given. Usage: $0 DEVICENAME"
    # TODO: list available devices
fi

netdev=$1

if [ ! "x$UID" = "x0" ]; then
    die "Must be root"
fi

# TODO: intelligently select subnets

ip4="10.12.42"
ip6="fd22:5066:bddf"
uuid=$(uuidgen)
con="Quick Wired Hotspot"

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding

info Deleting possible leftovers
nmcli con delete "$con" || true
iptables -t nat -D POSTROUTING -s $ip4.0/24 -j MASQUERADE || true
ip6tables -t nat -D POSTROUTING -s $ip6::/64 -j MASQUERADE || true

info Setting static IP configuration for $netdev...

nmcli con add save no connection.id "$con" type ethernet ifname $netdev ip4 "$ip4.1/24" ip6 "$ip6::1/64" connection.zone "trusted"

info Starting connection on $netdev...
nmcli con up "$con"

info Setting up IPv4 NAT
iptables -t nat -A POSTROUTING -s $ip4.0/24 -j MASQUERADE

info Setting up IPv6 NAT
ip6tables -t nat -A POSTROUTING -s $ip6::/64 -j MASQUERADE

info Starting dnsmasq
info Exit with CTRL+C
trap "printf '\n'; info dnsmasq killed by user" SIGINT;
dnsmasq --no-daemon --conf-file=/dev/null --interface=$netdev \
    --dhcp-range=$ip4.2,$ip4.200 \
    --dhcp-range=$ip6::2,ra-only \
    --bind-interfaces \
    || true
trap - SIGINT

info Shutting down NAT
iptables -t nat -D POSTROUTING -s $ip4.0/24 -j MASQUERADE
ip6tables -t nat -D POSTROUTING -s $ip6::/64 -j MASQUERADE

info Shutting down NM connection
nmcli con down "$con" || true
nmcli con delete "$con"

info Done
