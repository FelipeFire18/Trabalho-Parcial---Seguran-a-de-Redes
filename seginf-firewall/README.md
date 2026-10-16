# Firewall Linux com Netfilter/iptables — Portal Acadêmico segmentado

Trabalho parcial de Segurança da Informação — IF Goiano, Campus Ceres.
Ambiente simulado com Docker Compose: **LAN (cliente) → Firewall → DMZ (web) → Firewall → rede do banco**.

Relatório técnico completo: [`docs/relatorio.md`](docs/relatorio.md)

## Topologia

| Container   | Rede(s)                     | IP                                   | Função                          |
|-------------|-----------------------------|--------------------------------------|---------------------------------|
| `lan-client`| `lan` 10.99.1.0/24         | 10.99.1.10                          | Estação interna (curl, nmap, psql) |
| `firewall`  | `lan`, `dmz`, `db`          | .254 em cada rede                    | Gateway/roteador, iptables      |
| `dmz-web`   | `dmz` 10.99.2.0/24         | 10.99.2.10                          | Nginx (portal)                  |
| `dmz-db`    | `db` 10.99.3.0/24          | 10.99.3.10                          | PostgreSQL isolado              |

## Requisitos
Docker e Docker Compose v2 (Linux, ou Docker Desktop com WSL2).

## Como executar
```bash
git clone <URL_DO_REPOSITORIO> && cd seginf-firewall
docker compose up -d --build
docker compose logs firewall        # mostra as regras carregadas
./test.sh                           # validação automatizada
```
Para encerrar: `docker compose down -v`.

## Testes manuais
```bash
# Positivos
docker compose exec client curl -i http://dmz-web
docker compose exec web nc -zv dmz-db 5432

# Negativos
docker compose exec client nc -zv -w 3 dmz-db 5432
docker compose exec client nmap -Pn -p 22,80,443,5432 dmz-web dmz-db
docker compose exec web ping -c 1 -W 2 10.99.1.10
```
Logs de pacotes descartados (prefixo `FW-DROP`): `dmesg | grep FW-DROP` no **host** Linux.

## Solução de problemas
- `iptables` com erro de backend: em `firewall/Dockerfile`, troque `iptables` por `iptables-legacy` e use os binários `iptables-legacy`.
- Senha do banco: copie `.env.example` para `.env`.
