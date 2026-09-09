#!/usr/bin/env bash
set -e
exec bash <(curl -fsSL "https://raw.githubusercontent.com/mijanlab/key/main/access-tui.sh") "$@"
