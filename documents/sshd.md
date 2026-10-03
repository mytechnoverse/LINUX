
/etc/ssh/sshd_config.d/00-bruteforce.conf :

AllowUsers admin_username
PermitRootLogin no
PermitEmptyPasswords no
PasswordAuthentication yes
KbdInteractiveAuthentication no
UsePAM yes
MaxAuthTries 3
LoginGraceTime 1m
MaxStartups 10
PerSourceMaxStartups 2
ClientAliveInterval 20
ClientAliveCountMax 3

- `admin_username`

sshd -t
systemctl restart ssh

/etc/nftables/conf.d/10-chain-ssh-bruteforce.nft :

table inet firewall {
    set ssh_conn_rate { type ipv4_addr; flags dynamic,timeout; timeout 2m; size 65536; }
    set ssh_blocklist { type ipv4_addr; flags dynamic,timeout; timeout 5m; size 65536; }
    set ssh_offenders { type ipv4_addr; flags dynamic,timeout; timeout 1d; size 65536; }
    set ssh_repeaters { type ipv4_addr; flags dynamic,timeout; timeout 1w; size 65536; }

    chain ssh_strike {
        ip saddr @ssh_repeaters update @ssh_repeaters { ip saddr } add @ssh_blocklist { ip saddr timeout 24h } counter drop
        ip saddr @ssh_offenders update @ssh_repeaters { ip saddr } add @ssh_blocklist { ip saddr timeout 1h } counter drop
        update @ssh_offenders { ip saddr } add @ssh_blocklist { ip saddr timeout 5m } counter drop
    }

    chain ssh_guard {
        type filter hook input priority -10; policy accept;
        ip saddr @ssh_blocklist tcp dport 22 counter drop
        meta nfproto ipv4 tcp dport 22 ct state new add @ssh_conn_rate { ip saddr limit rate over 3/minute burst 3 packets } jump ssh_strike
    }
}

/etc/fail2ban/fail2ban.local :

[Definition]
dbpurgeage = 2w

/etc/fail2ban/jail.d/10-sshd.local :

[DEFAULT]
backend = systemd
banaction = nftables

[sshd]
enabled = true
mode = aggressive
maxretry = 5
findtime = 1h
bantime = 5m
bantime.increment = true
bantime.multipliers = 1 12 288 2016
bantime.maxtime = 1w

sudo nft -c -f /etc/nftables.conf && sudo systemctl reload nftables
sudo systemctl restart fail2ban


sudo nft list set inet firewall ssh_blocklist
sudo fail2ban-client status sshd
nft list table inet f2b-table

fail2ban-client set sshd unbanip 203.0.113.5
nft delete element inet firewall ssh_black_list { 203.0.113.5 }

