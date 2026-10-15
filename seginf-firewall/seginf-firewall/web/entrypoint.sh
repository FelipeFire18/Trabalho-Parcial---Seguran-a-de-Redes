#!/bin/sh
# Rotas de retorno (LAN) e de acesso ao banco passam pelo firewall
ip route replace 172.20.0.0/24 via 172.21.0.254
ip route replace 172.22.0.0/24 via 172.21.0.254
exec nginx -g 'daemon off;'
