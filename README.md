# Masking your egress IP with ZeroTier: a step-by-step guide for running an Exit Node for many servers — no VPN subscription required

**Target User:** Individuals who want to *mask the public IP* of many servers and machines (e.g., lab hosts, cloud VMs, home lab) by routing their outbound internet through one or more trusted VMs running ZeroTier exit nodes. This avoids paying for a commercial VPN and gives you control over where traffic egresses.

---

## Short summary (TL;DR)
1. Create a ZeroTier network and join an exit-node VM and peers.
2. Configure the exit node: enable IP forwarding and NAT (masquerade) on its internet interface.
3. Advertise a managed route `0.0.0.0/0` via the exit node’s ZeroTier IP in ZeroTier Central.
4. Enable `allowDefault=1` on peers so they accept the default route.
5. Verify routing and public IPs (`curl ifconfig.me`), and make configs persistent.

---

## Why do this?
- Mask many servers’ public IPs behind a single trusted exit node (useful for testing, privacy, geo egress).
- Lower cost than a commercial VPN for many devices — you run your own egress.
- Full control: choose geographic location, firewall rules, logging policies.
- Works across platforms and cloud providers (AWS, GCP, Azure, home VMs).

---

## Advantages
- **Cost control** — no monthly VPN subscription for many machines.
- **Centralized egress** — all outbound traffic can come from one IP or a small set of IPs (useful for allowlisting).
- **Flexibility & control** — you control NAT, firewalling, logging, and egress region.
- **Scalable** — any number of peers can join your ZeroTier network and route traffic through exit nodes.
- **Cross-platform** — works on Linux, Windows, macOS, containers.

## Potential cons / cautions
- **Single point of failure & bandwidth limits** — exit node VM/network becomes the bottleneck; egress bandwidth is limited by that machine/connection.
- **Security / trust** — all egress traffic goes through your exit node; you must secure and monitor it (or you can’t trust it).
- **Legal/responsibility** — you are responsible for traffic originating through your exit node. Abuse or illegal activity could cause issues with your ISP or provider.
- **Latency & performance** — extra hop may add latency; heavy traffic can overload the exit node.
- **Persistence & maintenance** — you must manage iptables, persistence, and keep the exit node patched.

---

## Detailed step-by-step configuration

> These instructions assume Linux for the **exit node** (Ubuntu/Debian style) and *Linux peers* for examples. Windows/macOS client steps are noted where relevant.

### 1 — Prepare ZeroTier network
1. Create a free account at ZeroTier Central (https://my.zerotier.com) and create a new network.  
2. Note the **Network ID** (a 16-character ID like `8056c2e21c000001`).

### 2 — Install ZeroTier on the exit node (Linux)
```bash
curl -s https://install.zerotier.com | sudo bash
sudo systemctl enable --now zerotier-one
sudo zerotier-cli join <NETWORK_ID>
```
Authorize the exit node in ZeroTier Central and note its ZeroTier IP.

### 3 — Enable IP forwarding on the exit node
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 4 — Configure NAT (masquerade) on the exit node
```bash
IFACE=$(ip route get 1.1.1.1 | awk '/dev/ {print $5; exit}')
sudo iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE
sudo iptables -A FORWARD -i zt+ -o "$IFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i "$IFACE" -o zt+ -j ACCEPT
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```

### 5 — Advertise default route in ZeroTier Central
Add this under **Managed Routes** in your network:
```
0.0.0.0/0 via <EXIT_NODE_ZEROTIER_IP>
```

### 6 — Allow peers to accept the default route
```bash
sudo zerotier-cli set <NETWORK_ID> allowDefault=1
sudo systemctl restart zerotier-one
```

### 7 — Verify configuration
```bash
ip route
curl ifconfig.me
```

### 8 — Windows & macOS peers
Use the ZeroTier GUI or Central to enable **Allow Default Route**.  
Then verify with `route print` or `netstat -rn` and `curl ifconfig.me`.

---

## Troubleshooting checklist
| Problem | Fix |
|----------|-----|
| Exit node not authorized | Authorize in Central |
| Peer lacks `allowDefault` | `zerotier-cli set <NETWORK_ID> allowDefault=1` |
| Managed route missing | Add `0.0.0.0/0 via <ZT-IP>` |
| IP forwarding off | `sysctl -w net.ipv4.ip_forward=1` |
| Missing NAT | `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` |
| DNS leak | Configure DNS via ZeroTier or custom resolver |

---

## Final checklist
- [ ] Exit node authorized in ZeroTier Central  
- [ ] Route `0.0.0.0/0 via <ZT-IP>` exists  
- [ ] Peers have `allowDefault=1`  
- [ ] IP forwarding = 1  
- [ ] NAT active and persisted  
- [ ] Peer `curl ifconfig.me` matches exit node IP

---

## Security and maintenance
- Restrict exit-node use to trusted members.  
- Keep exit node updated and monitored.  
- Rotate credentials or ZeroTier IDs if sharing access.  
- Monitor bandwidth and connection count if handling many peers.
# Home-Lab
