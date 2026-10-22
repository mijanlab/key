#!/bin/bash
# Usage: curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- <name|all>
#        curl ... | bash -s -- remove <name>
# To add a new key: add one "name|public key" line below, then add its command to README.md.

KEYS='
home|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOhFnsZEj3hobSCHPKM5nBe5pe5JpMBZLkclhs/4tbsq contact.mijanur80@gmail.com
office|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1vLQK3RO6iR06SMJvWHtKFIyAUoGGWk2ZO8NtnTg8D office-desk-windows
ios|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIuCvdGaodeKgn9cRLndpx8s4uuJ9qV11bsHF4aJ1XF root@localhost
hermes|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJOYaOXwIYWDTMPgAiPZwfTLDnnLa+Te02AXUACvP5C5 hermes-agent-vps
mimi|ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPizIlnZKIa4zminbUC3mEn3u0/kDixPVAz9sAVMMDVX dev@code-vm
'

if [ -t 1 ]; then
  G=$'\e[32m'; Y=$'\e[33m'; R=$'\e[31m'; B=$'\e[1m'; D=$'\e[2m'; C=$'\e[36m'; N=$'\e[0m'
else
  G=; Y=; R=; B=; D=; C=; N=
fi

NAMES=$(echo "$KEYS" | grep '|' | cut -d'|' -f1)
MODE=add
if [ "$1" = "remove" ]; then MODE=remove; shift; fi
NAME="$1"

echo
echo "  ${B}${C}Pro Cloudify${N} ${D}· SSH Access${N}"
echo "  ${D}──────────────────────────────${N}"

if [ "$MODE" = "remove" ] && [ "$NAME" = "all" ]; then
  echo "  ${R}✗${N} Refusing 'remove all' (could lock you out). Remove keys one by one."
  echo
  exit 1
elif [ "$NAME" = "all" ]; then
  SELECTED="$NAMES"
elif echo "$NAMES" | grep -qx "$NAME"; then
  SELECTED="$NAME"
else
  echo "  ${R}✗${N} Unknown key '${NAME}'"
  echo "  ${D}Available:${N} all $(echo $NAMES)"
  echo
  exit 1
fi

mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

for K in $SELECTED; do
  KEY=$(echo "$KEYS" | grep "^$K|" | cut -d'|' -f2-)
  if [ "$MODE" = "remove" ]; then
    if grep -qF "$KEY" ~/.ssh/authorized_keys; then
      grep -vF "$KEY" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.tmp
      cat ~/.ssh/authorized_keys.tmp > ~/.ssh/authorized_keys && rm -f ~/.ssh/authorized_keys.tmp
      printf "  ${R}✗${N} Removed            ${B}%-8s${N}
" "$K"
    else
      printf "  ${Y}●${N} Not installed      ${B}%-8s${N}
" "$K"
    fi
    continue
  fi
  if grep -qF "$KEY" ~/.ssh/authorized_keys; then
    STATUS="${Y}●${N} Already installed"
  else
    echo "$KEY" >> ~/.ssh/authorized_keys
    STATUS="${G}✓${N} Access granted  "
  fi
  FP=$(echo "$KEY" | ssh-keygen -lf - 2>/dev/null | awk '{print $2}')
  printf "  %s  ${B}%-8s${N} ${D}%s${N}\n" "$STATUS" "$K" "$FP"
done

echo
echo "  ${D}Server  ${N} $(hostname)"
echo "  ${D}User    ${N} $(whoami)"
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -n "$IP" ] && echo "  ${D}Connect ${N} ${B}ssh $(whoami)@$IP${N}"
echo
