#!/bin/sh
# Todo trafego para DMZ e DB passa obrigatoriamente pelo firewall
ip route replace 10.99.2.0/24 via 10.99.1.254
ip route replace 10.99.3.0/24 via 10.99.1.254
echo "[client] rotas:"; ip route
exec sleep infinity
