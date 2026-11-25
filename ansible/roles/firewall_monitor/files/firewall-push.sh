#!/usr/bin/env bash
# Envia ao Uptime Kuma (monitor Push) o que o firewall bloqueou.
#   - gráfico (ping): bloqueios registrados pelo UFW na última hora
#   - alerta (vermelho): pacotes descartados no último minuto acima de LIMITE
# Roda a cada minuto pelo firewall-push.timer. Configuração em /etc/firewall-push.env.
set -uo pipefail

# shellcheck source=/dev/null
. /etc/firewall-push.env   # KUMA_PUSH_URL e LIMITE

ESTADO=/var/lib/firewall-push/ultimo
mkdir -p "$(dirname "$ESTADO")"

# Contador exato de pacotes descartados pela política DROP do UFW (IPv4 + IPv6).
v4=$(iptables -L INPUT -n -v -x | awk 'NR==1 {print $5}')
v6=$(ip6tables -L INPUT -n -v -x 2>/dev/null | awk 'NR==1 {print $5}')
atual=$(( ${v4:-0} + ${v6:-0} ))
anterior=$(cat "$ESTADO" 2>/dev/null || echo "$atual")
echo "$atual" > "$ESTADO"

minuto=$(( atual - anterior ))
if [ "$minuto" -lt 0 ]; then   # contador zerou (reboot ou ufw reload)
  minuto=0
fi

# Bloqueios registrados pelo UFW na última hora e as portas mais atacadas.
# O log do UFW tem limite de taxa: em ataque forte ele mostra menos que o real
# (por isso o alerta usa o contador exato acima).
dpts=$(journalctl -k --since "-60min" --no-pager -o cat 2>/dev/null \
  | grep 'UFW BLOCK' | grep -o 'DPT=[0-9]*' | cut -d= -f2 || true)
if [ -n "$dpts" ]; then
  hora=$(printf '%s\n' "$dpts" | wc -l)
  portas=$(printf '%s\n' "$dpts" | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s:%s ", $2, $1}')
else
  hora=0
  portas=""
fi

banidos=$(fail2ban-client status sshd 2>/dev/null | awk -F'\t' '/Currently banned/ {print $2}' || true)

status=up
if [ "$minuto" -gt "$LIMITE" ]; then
  status=down
fi

msg="${hora} bloqueados na última hora | ${minuto} no último minuto | portas (1 h): ${portas:-nenhuma} | fail2ban: ${banidos:-?} banido(s)"

curl -fsS -m 10 -o /dev/null -G "$KUMA_PUSH_URL" \
  --data-urlencode "status=${status}" \
  --data-urlencode "msg=${msg}" \
  --data-urlencode "ping=${hora}"
