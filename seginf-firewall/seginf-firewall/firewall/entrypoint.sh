#!/bin/sh
# Carrega as regras do firewall automaticamente na subida do container.
set -e

LAN=172.20.0.0/24
DMZ=172.21.0.0/24
DBN=172.22.0.0/24
WEB=172.21.0.10
DB=172.22.0.10

echo "[firewall] habilitando ip_forward"
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

echo "[firewall] limpando regras antigas"
iptables -F
iptables -X
iptables -t nat -F

echo "[firewall] politica padrao: DROP"
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  ACCEPT

# Chain auxiliar: registra (com limite) e descarta
iptables -N LOGDROP
iptables -A LOGDROP -m limit --limit 5/min --limit-burst 10 \
         -j LOG --log-prefix "FW-DROP: " --log-level 4
iptables -A LOGDROP -j DROP

# ---------------- INPUT (trafego destinado ao proprio firewall) -------------
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 10/s -j ACCEPT
iptables -A INPUT -j LOGDROP

# ---------------- FORWARD (trafego entre as redes) --------------------------
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# R1: LAN -> DMZ web (HTTP/HTTPS)
iptables -A FORWARD -s $LAN -d $WEB -p tcp -m multiport --dports 80,443 \
         -m conntrack --ctstate NEW -j ACCEPT
# R2: LAN -> DMZ web (ping, diagnostico)
iptables -A FORWARD -s $LAN -d $WEB -p icmp --icmp-type echo-request -j ACCEPT
# R3: DMZ web -> banco (PostgreSQL), unico caminho permitido ate o banco
iptables -A FORWARD -s $WEB -d $DB -p tcp --dport 5432 \
         -m conntrack --ctstate NEW -j ACCEPT
# R4: LAN -> banco: bloqueio explicito (com log)
iptables -A FORWARD -s $LAN -d $DBN -j LOGDROP
# R5: DMZ/DB -> LAN: iniciativa de conexao bloqueada (com log)
iptables -A FORWARD -s $DMZ -d $LAN -j LOGDROP
iptables -A FORWARD -s $DBN -d $LAN -j LOGDROP
# Demais: cai na politica DROP (com log)
iptables -A FORWARD -j LOGDROP

# ---------------- NAT -------------------------------------------------------
# O banco nao possui rota de retorno para a DMZ; mascaramos a origem
# (web -> db) para que ele responda ao proprio firewall.
iptables -t nat -A POSTROUTING -d $DBN -j MASQUERADE

echo "[firewall] regras carregadas:"
iptables -L -n -v --line-numbers
iptables -t nat -L -n -v
echo "[firewall] pronto."

exec tail -f /dev/null
