# Access

Install my SSH public keys on any Linux server with one command. Run it on the server; each block has a copy button.

## New VM: install all keys

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- all
```

## Install one key

**home** (Home PC)

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- home
```

**office** (Office desk (Windows))

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- office
```

**ios** (iOS)

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- ios
```

**hermes** (Hermes agent VPS)

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- hermes
```

**mimi** (Code VM (dev@code-vm))

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- mimi
```

## Remove a key

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- remove mimi
```

Replace `mimi` with any key name. `remove all` is blocked so you can't lock yourself out.

## Notes

- Safe to re-run: a key is only added once.
- Output shows each key's status and fingerprint, plus the server, user and an `ssh user@ip` line.
- Don't remove the key you are currently logged in with.

## Adding a new key

1. Add one `name|public key` line to `KEYS` in `access.sh`.
2. Add a block for it under "Install one key" above.
