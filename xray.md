
# Configuration :

| Component          | Configuration |
|--------------------|---------------|
| **Linux Distro**   | Ubuntu        |
| **Distro Version** | 26 LTS        |
| **Memory**         | 2 GB          |
| **Processor**      | 2 Core        |
| **Storage**        | 16 GB         | 
| **User Name**      | Root          |
| **IP Protocol**    | IPv4          |
| **Firewall**       | Nftables      |
| **Proxy**          | Xray          |

sudo su root --login





# Xray Server :

### PPTP Setup :

```bash
dpkg-query --show --showformat='${Status}' ppp
curl -o /root/downloads/ppp.deb https://archive.ubuntu.com/ubuntu/pool/main/p/ppp/ppp_2.5.2-1+1.2_amd64.deb
dpkg --install /root/downloads/ppp.deb
dpkg-query --show --showformat='${Status}' pptp-linux
curl -o /root/downloads/pptp-linux.deb https://archive.ubuntu.com/ubuntu/pool/main/p/pptp-linux/pptp-linux_1.10.0-2build1_amd64.deb
dpkg --install /root/downloads/pptp-linux.deb
```

Create `/etc/ppp/peers/pptp-vpn` :

```text
pty "pptp pptp_server_ip --nolaunchpppd"
name pptp_username
password pptp_password
require-mschap-v2
refuse-mschap
refuse-chap
refuse-pap
refuse-eap
defaultroute
replacedefaultroute
usepeerdns
noauth
nodetach
```

Replace :

- `pptp_server_ip`
- `pptp_username`
- `pptp_password`

Create `/etc/systemd/system/pptp-vpn.service` :

```ini
[Unit]
Description=PPTP VPN
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/pppd call pptp-vpn
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
```

```bash
systemctl daemon-reload
systemctl status pptp-vpn
systemctl start pptp-vpn
systemctl status pptp-vpn
systemctl enable pptp-vpn
```

### Dnscrypt Setup :

```bash
apt install dnscrypt-proxy bind9-dnsutils
```

Overwrite `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` :

```toml
server_names = ['cloudflare']
listen_addresses = ['127.0.0.1:53']
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

Keep :

- `[query_log]`
- `[nx_log]`
- `[sources]`

```bash
dnscrypt-proxy -check -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml -resolve google.com
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
dig @127.0.0.1 whoami.cloudflare ch txt +short
```

### TLS Setup :

```bash
apt install openssl
mkdir -p /root/tls/
```

Create `/root/tls/create-ca.sh` :

```bash
#!/usr/bin/bash
set -Eeuo pipefail
ca_name=$1
ca_tld=$2
ca_tls_path="/root/tls/${ca_name}/"
mkdir $ca_tls_path
ca_key_path="${ca_tls_path}${ca_name}.key"
ca_crt_path="${ca_tls_path}${ca_name}.crt"
crt_cn="/CN=${ca_name}"
crt_serial="0x$(openssl rand -hex 16)"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out $ca_key_path
openssl req -new -sha256 -x509 -days 365 -key $ca_key_path -out $ca_crt_path -subj $crt_cn -set_serial $crt_serial -addext 'keyUsage=critical,keyCertSign,cRLSign' \
-addext 'basicConstraints=critical,CA:TRUE,pathlen:0' -addext "nameConstraints=critical,permitted;DNS:${ca_tld}" -addext 'subjectKeyIdentifier=hash'
```

Create `/root/tls/create-server.sh` :

```bash
#!/usr/bin/bash
set -Eeuo pipefail
ca_name=$1
server_name=$2
ca_tls_path="/root/tls/${ca_name}/"
ca_key_path="${ca_tls_path}${ca_name}.key"
ca_crt_path="${ca_tls_path}${ca_name}.crt"
server_tls_path="/root/tls/${server_name}/"
mkdir $server_tls_path
server_key_path="${server_tls_path}${server_name}.key"
server_key_pass_path="${server_tls_path}${server_name}.pass"
server_key_enc_path="${server_tls_path}${server_name}.enc.key"
server_key_cred_path="${server_tls_path}${server_name}.cred"
server_csr_path="${server_tls_path}${server_name}.csr"
server_crt_path="${server_tls_path}${server_name}.crt"
server_crt_chain_path="${server_tls_path}${server_name}-fullchain.crt"
crt_cn="/CN=${server_name}"
crt_serial="0x$(openssl rand -hex 16)"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-256 -out $server_key_path
openssl rand -hex 32 > $server_key_pass_path
openssl pkcs8 -topk8 -v2 aes-256-cbc -v2prf hmacWithSHA256 -saltlen 16 -iter 600000 -in $server_key_path -out $server_key_enc_path -passout file:$server_key_pass_path
systemd-creds encrypt --name=$server_name $server_key_pass_path $server_key_cred_path
shred -u $server_key_pass_path
openssl req -new -sha256 -key $server_key_path -out $server_csr_path -subj $crt_cn
shred -u $server_key_path
crt_exts=$(cat <<EOF
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
extendedKeyUsage=serverAuth
subjectAltName=DNS:$server_name
EOF
)
openssl x509 -req -sha256 -days 365 -CA $ca_crt_path -CAkey $ca_key_path -in $server_csr_path -out $server_crt_path -set_serial $crt_serial -extfile <(printf '%s' "$crt_exts")
rm $server_csr_path
cat $server_crt_path $ca_crt_path > $server_crt_chain_path
```

```bash
bash /root/tls/create-ca.sh internal-ca internal
bash /root/tls/create-server.sh internal-ca xyz.internal
openssl verify -CAfile /root/tls/internal-ca/internal-ca.crt -purpose sslserver /root/tls/xyz.internal/xyz.internal.crt
```

### Nginx Setup :

Create `/etc/nftables/conf.d/11-nginx.nft` :

```text
add rule inet filter input tcp dport 80 accept
add rule inet filter input tcp dport 443 accept
```

```bash
nft --check --file /etc/nftables.conf 
nft --file /etc/nftables.conf
nft list ruleset
apt install --no-install-recommends gpg
curl -o /root/downloads/nginx-archive-keyring.asc https://nginx.org/keys/nginx_signing.key
file /root/downloads/nginx-archive-keyring.asc
gpg --dearmor --output /root/downloads/nginx-archive-keyring.pgp /root/downloads/nginx-archive-keyring.asc
rm /root/downloads/nginx-archive-keyring.asc
mv /root/downloads/nginx-archive-keyring.pgp /etc/apt/keyrings/nginx-archive-keyring.pgp
```

Create `/etc/apt/sources.list.d/nginx.sources` :

```text
Types: deb
URIs: https://nginx.org/packages/ubuntu
Suites: resolute
Components: nginx
Signed-By: /etc/apt/keyrings/nginx-archive-keyring.pgp
```

Create `/etc/apt/preferences.d/nginx.pref` :

```text
Package: *
Pin: release o=nginx
Pin-Priority: 900
```

```bash
dpkg-query --show --showformat='${Status}' nginx
apt purge nginx
apt autoremove --purge
apt update
apt install nginx
nginx -V
rm -f /etc/nginx/conf.d/default.conf
mkdir -p /etc/nginx/xyz.internal/tls/
cp /root/tls/xyz.internal/xyz.internal.enc.key /etc/nginx/xyz.internal/tls/xyz.internal.enc.key
cp /root/tls/xyz.internal/xyz.internal.cred /etc/nginx/xyz.internal/tls/xyz.internal.cred
cp /root/tls/xyz.internal/xyz.internal-fullchain.crt /etc/nginx/xyz.internal/tls/xyz.internal-fullchain.crt
mkdir -p /etc/systemd/system/nginx.service.d/
mkdir -p /etc/nginx/xyz.internal/conf.d/
```

Create `/etc/systemd/system/nginx.service.d/xyz.internal.conf` :

```ini
[Service]
LoadCredentialEncrypted=xyz.internal:/etc/nginx/xyz.internal/tls/xyz.internal.cred
```

Create `/etc/nginx/conf.d/xyz.internal.conf` :

```nginx
server {
    listen 80;
    server_name xyz.internal;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    http2 on;
    server_name xyz.internal;
    ssl_certificate /etc/nginx/xyz.internal/tls/xyz.internal-fullchain.crt;
    ssl_certificate_key /etc/nginx/xyz.internal/tls/xyz.internal.enc.key;
    ssl_password_file /run/credentials/nginx.service/xyz.internal;
    ssl_protocols TLSv1.2 TLSv1.3;
    location / {
        root /usr/share/nginx/html;
        index index.html;
    }
    include /etc/nginx/xyz.internal/conf.d/*.conf;
}
```

```bash
systemctl daemon-reload
systemctl status nginx
systemctl start nginx
systemctl status nginx
systemctl restart nginx
systemctl status nginx
systemctl enable nginx
systemctl status nginx
ss -lntup
```




