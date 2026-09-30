#!/usr/bin/env bash
# Prints each problem found and exits 1 if findatalk.com is down, parked, or
# being served inconsistently by DNS; prints "All checks passed" otherwise.
set -uo pipefail

DOMAIN="${DOMAIN:-findatalk.com}"
# GitHub Pages' apex IPs. Records must stay "DNS only" (not proxied) at the
# DNS host, so these stay the answer everywhere.
EXPECTED_IPS="185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153"

problems=()
expected=$(echo $EXPECTED_IPS | tr ' ' '\n' | sort | tr '\n' ' ')

check_dns() {
  local label=$1 answer=$2 got
  got=$(echo "$answer" | grep -E '^[0-9.]+$' | sort | tr '\n' ' ')
  [ "$got" = "$expected" ] || problems+=("DNS: $label answered '${got:-nothing}' instead of the GitHub Pages IPs")
}

# Ask every nameserver the .com registry currently delegates to, directly.
# One of two GoDaddy nameservers once served a month-stale zone while the
# other was correct — only a per-nameserver check catches that.
nameservers=$(dig @a.gtld-servers.net +norecurse +noall +authority +time=5 +tries=2 "$DOMAIN" NS | awk '$4=="NS"{print $5}')
[ -n "$nameservers" ] || problems+=("DNS: could not read $DOMAIN's nameserver delegation from the .com registry")
for ns in $nameservers; do
  check_dns "authoritative nameserver $ns" "$(dig @"$ns" +short +norecurse +time=5 +tries=2 "$DOMAIN" A)"
done

for resolver in 1.1.1.1 8.8.8.8 9.9.9.9; do
  check_dns "public resolver $resolver" "$(dig @"$resolver" +short +time=5 +tries=2 "$DOMAIN" A)"
done

# $1 path, $2 text the first 4 KB must contain
check_page() {
  local out code
  out=$(mktemp)
  code=$(curl -sS --max-time 20 -r 0-4095 -o "$out" -w '%{http_code}' "https://$DOMAIN$1" 2>&1) || true
  if [ "$code" != 200 ] && [ "$code" != 206 ]; then
    problems+=("HTTP: $1 returned $code")
  elif grep -q '/lander' "$out"; then
    problems+=("HTTP: $1 is serving GoDaddy's parked-domain page")
  elif ! grep -q "$2" "$out"; then
    problems+=("HTTP: $1 loaded but doesn't contain \"$2\"")
  fi
  rm -f "$out"
}

# $1 path, $2 required content-type prefix (empty = anything except text/html)
check_file() {
  local result code type
  result=$(curl -sS --max-time 20 -I -o /dev/null -w '%{http_code} %{content_type}' "https://$DOMAIN$1" 2>&1) || true
  code=${result%% *}
  type=${result#* }
  if [ "$code" != 200 ]; then
    problems+=("HTTP: $1 returned $result")
  elif [ -n "$2" ] && [[ "$type" != "$2"* ]]; then
    problems+=("HTTP: $1 has content-type '$type', expected $2")
  elif [ -z "$2" ] && [[ "$type" == text/html* ]]; then
    problems+=("HTTP: $1 is returning an HTML page instead of the file")
  fi
}

check_page / 'FindATalk'
check_page /ledger.html 'Project Ledger'
check_file /data.json application/json
check_file /.well-known/assetlinks.json application/json
check_file /.well-known/apple-app-site-association ''

if [ ${#problems[@]} -eq 0 ]; then
  echo "All checks passed for $DOMAIN."
  exit 0
fi
printf '%s\n' "${problems[@]}"
exit 1
