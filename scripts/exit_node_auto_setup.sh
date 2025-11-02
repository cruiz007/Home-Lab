#!/usr/bin/env bash
#enter networkID to activate script
set -e
NETWORK_ID="<NETWORK_ID>"
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join "$NETWORK_ID"
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
IFACE=$(ip route get 1.1.1.1 | awk '/dev/ {print $5; exit}')
sudo iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
sudo iptables -A FORWARD -i zt+ -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i "$IFACE" -o zt+ -j ACCEPT
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```
