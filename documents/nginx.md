
# Nginx :

```bash
dpkg-query --show --showformat='${Status}' nginx
apt purge nginx
apt autoremove --purge
apt install --no-install-recommends gpg
curl -o /root/downloads/nginx-archive-keyring.asc https://nginx.org/keys/nginx_signing.key
file /root/downloads/nginx-archive-keyring.asc
gpg --dearmor --output /root/downloads/nginx-archive-keyring.pgp /root/downloads/nginx-archive-keyring.asc
rm /root/downloads/nginx-archive-keyring.asc
mv /root/downloads/nginx-archive-keyring.pgp /etc/apt/keyrings/nginx-archive-keyring.pgp
```

---

### Ubuntu 26 :

Create `/etc/apt/sources.list.d/nginx.sources` :

```text
Types: deb
URIs: https://nginx.org/packages/ubuntu
Suites: resolute
Components: nginx
Signed-By: /etc/apt/keyrings/nginx-archive-keyring.pgp
```

---

### Debian 13 :

Create `/etc/apt/sources.list.d/nginx.sources` :

```text
Types: deb
URIs: https://nginx.org/packages/ubuntu
Suites: trixie
Components: nginx
Signed-By: /etc/apt/keyrings/nginx-archive-keyring.pgp
```

---

Create `/etc/apt/preferences.d/nginx.pref` :

```text
Package: *
Pin: release o=nginx
Pin-Priority: 900
```

```bash
apt update
apt install nginx
nginx -V
rm -f /etc/nginx/conf.d/default.conf
```



/etc/nginx/website_name/tls/

```bash
mkdir -p /etc/nginx/xyz.internal/tls/
cp /root/tls/xyz.internal/xyz.internal.enc.key /etc/nginx/xyz.internal/tls/xyz.internal.enc.key
cp /root/tls/xyz.internal/xyz.internal.cred /etc/nginx/xyz.internal/tls/xyz.internal.cred
cp /root/tls/xyz.internal/xyz.internal-fullchain.crt /etc/nginx/xyz.internal/tls/xyz.internal-fullchain.crt
mkdir -p /etc/systemd/system/nginx.service.d/
mkdir -p /etc/nginx/xyz.internal/conf.d/
```

Create `/etc/nftables/conf.d/11-nginx.nft` :

```text
add rule inet filter input tcp dport 80 accept
add rule inet filter input tcp dport 443 accept
```

```bash
nft --check --file /etc/nftables.conf 
nft --file /etc/nftables.conf
nft list ruleset
```


