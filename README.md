# Access

Add my SSH key to any server with one command. Run it on the server:

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- <name>
```

| Name | Command |
|------|---------|
| **all** (new VM) | `curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh \| bash -s -- all` |
| home | `curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh \| bash -s -- home` |
| office | `curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh \| bash -s -- office` |
| ios | `curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh \| bash -s -- ios` |
| hermes | `curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh \| bash -s -- hermes` |

Safe to re-run: the key is only added once.

## Adding a new key

Add one `name|public key` line to `KEYS` in `access.sh`, then add a row to the table above.
