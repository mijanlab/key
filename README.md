# key

Minimal SSH access setup for Linux & macOS servers.

## Quickstart

Run directly on any server:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mijanlab/key/main/access-tui.sh)
```

## Features

- Fast navigation (`UP`/`DOWN`, `k`/`j`, or number keys `1-6`)
- Instant `Esc` or `q` cancellation on every screen
- Install preconfigured or custom keys
- Clean numeric selection for viewing & deleting authorized keys
- Toggle password authentication (keys only vs. passwords enabled)
- Safe lockout protection (prevents disabling passwords if no SSH keys are installed)
- Automatically sets secure permissions (`chmod 755 ~`, `chmod 700 ~/.ssh`, `chmod 600 authorized_keys`, user ownership) on every operation
- Zero dependencies
