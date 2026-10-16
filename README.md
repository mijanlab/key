# Access

Add my SSH key to any server. Run on the server (click the copy button on each block):

## New VM (all keys)

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- all
```
## home

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- home
```
## office

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- office
```
## ios

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- ios
```
## hermes

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- hermes
```
## mimi

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- mimi
```

## Remove a key

```bash
curl -sSL https://raw.githubusercontent.com/mijanlab/key/main/access.sh | bash -s -- remove mimi
```

Replace `mimi` with any name. `remove all` is blocked so you can't lock yourself out.

Safe to re-run: a key is only added once.

## Adding a new key

Add one `name|public key` line to `KEYS` in `access.sh`, then add a block above.
