#!/bin/sh
# Rotas de retorno (LAN) e de acesso ao banco passam pelo firewall
ip route replace 10.99.1.0/24 via 10.99.2.254
ip route replace 10.99.3.0/24 via 10.99.2.254
exec nginx -g 'daemon off;'
