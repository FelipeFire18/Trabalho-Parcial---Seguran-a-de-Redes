#!/bin/sh
# Testes automatizados de validacao. Uso: ./test.sh  (com o ambiente no ar)
PASS=0; FAIL=0
check() { # descricao esperado(0=sucesso,1=falha) comando...
  desc="$1"; exp="$2"; shift 2
  "$@" >/dev/null 2>&1; rc=$?
  if { [ "$exp" = 0 ] && [ $rc -eq 0 ]; } || { [ "$exp" = 1 ] && [ $rc -ne 0 ]; }; then
    echo "[OK]   $desc"; PASS=$((PASS+1))
  else
    echo "[FAIL] $desc"; FAIL=$((FAIL+1))
  fi
}
C="docker compose exec -T client"
W="docker compose exec -T web"

echo "== Testes positivos (devem funcionar) =="
check "LAN -> DMZ web HTTP (curl)"            0 $C curl -s -f -m 5 http://dmz-web
check "LAN -> DMZ web ping"                   0 $C ping -c 2 -W 2 dmz-web
check "DMZ web -> banco TCP 5432"             0 $W nc -z -w 3 dmz-db 5432

echo "== Testes negativos (devem ser bloqueados) =="
check "LAN -> banco TCP 5432 (direto)"        1 $C nc -z -w 3 dmz-db 5432
check "LAN -> banco via psql"                 1 $C env PGCONNECT_TIMEOUT=3 psql -h dmz-db -U portal -c 'select 1'
check "LAN -> web porta 22 (nao liberada)"    1 $C nc -z -w 3 dmz-web 22
check "LAN -> banco ping"                     1 $C ping -c 1 -W 2 dmz-db
check "DMZ web -> LAN ping (nova conexao)"    1 $W ping -c 1 -W 2 172.20.0.10

echo; echo "Resultado: $PASS ok, $FAIL falha(s)"
[ $FAIL -eq 0 ]
