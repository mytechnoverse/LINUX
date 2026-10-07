
# DNSCrypt :

```bash
apt install dnscrypt-proxy bind9-dnsutils
```

Edit `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` :

```toml
server_names = ['cloudflare']
listen_addresses = ['127.0.0.1:2053']
ipv4_servers = true
doh_servers = true
require_dnssec = true
require_nofilter = true
ignore_system_dns = true
ipv6_servers = false
dnscrypt_servers = false
odoh_servers = false
block_ipv6 = true
cache = true
cache_size = 4096
```

- `[query_log]`
- `[nx_log]`
- `[sources]`

```bash
dnscrypt-proxy -check -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
mkdir -p /etc/systemd/system/dnscrypt-proxy.service.d/
```

Create `/etc/systemd/system/dnscrypt-proxy.service.d/override.conf` :

```ini
[Service]
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
```

```bash
systemctl daemon-reload
systemctl status dnscrypt-proxy
systemctl start dnscrypt-proxy
systemctl status dnscrypt-proxy
systemctl restart dnscrypt-proxy
systemctl status dnscrypt-proxy
systemctl enable dnscrypt-proxy
ss -lntup
dig @127.0.0.1 -p 2053 whoami.cloudflare ch txt +short
```