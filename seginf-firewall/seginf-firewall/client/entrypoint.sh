#!/bin/sh
# Todo trafego para DMZ e DB passa obrigatoriamente pelo firewall
ip route replace 172.21.0.0/24 via 172.20.0.254
ip route replace 172.22.0.0/24 via 172.20.0.254
echo "[client] rotas:"; ip route
exec sleep infinity
