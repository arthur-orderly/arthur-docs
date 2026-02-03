# CLI Reference

Use Arthur SDK from the command line.

---

## Installation

The CLI is included when you install the SDK:

```bash
pip install arthur-sdk
```

Verify installation:

```bash
arthur --help
```

---

## Commands Overview

| Command | Description |
|---------|-------------|
| `arthur price` | Get current prices |
| `arthur status` | Check account status |
| `arthur trade` | Execute trades |
| `arthur positions` | View open positions |
| `arthur orders` | View open orders |
| `arthur run` | Run a strategy |

---

## arthur price

Get current market prices.

```bash
# Single symbol
arthur price ETH

# Multiple symbols
arthur price BTC ETH SOL ARB

# All supported symbols
arthur price --all
```

**Example output:**

```
BTC:   $43,250.00
ETH:   $2,285.50
SOL:   $98.75
ARB:   $1.45
```

---

## arthur status

Check account balance and positions.

```bash
arthur status -c credentials.json
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --credentials` | Path to credentials file |
| `--testnet` | Use testnet |
| `-j, --json` | Output as JSON |

**Example output:**

```
Account Status
==============
Balance:      $1,234.56
Equity:       $1,456.78
Positions:    2
Unrealized:   $222.22

Positions:
  ETH  LONG   0.5000 @ $2,100.00  PnL: $92.75 (+8.8%)
  BTC  SHORT  0.0100 @ $44,000.00 PnL: $129.47 (+5.9%)
```

---

## arthur trade

Execute trades from the command line.

### Buy

```bash
# Buy $100 of ETH
arthur trade buy ETH --usd 100 -c credentials.json

# Buy 0.5 ETH
arthur trade buy ETH --size 0.5 -c credentials.json

# Limit buy
arthur trade buy ETH --usd 100 --price 2000 -c credentials.json
```

### Sell (Short)

```bash
# Short $100 of BTC
arthur trade sell BTC --usd 100 -c credentials.json

# Short 0.01 BTC
arthur trade sell BTC --size 0.01 -c credentials.json
```

### Close

```bash
# Close ETH position
arthur trade close ETH -c credentials.json

# Close all positions
arthur trade close-all -c credentials.json
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --credentials` | Path to credentials file |
| `--usd` | Trade size in USD |
| `--size` | Trade size in base asset |
| `--price` | Limit price (omit for market) |
| `--testnet` | Use testnet |
| `-y, --yes` | Skip confirmation |

---

## arthur positions

View open positions.

```bash
arthur positions -c credentials.json
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --credentials` | Path to credentials file |
| `--testnet` | Use testnet |
| `-j, --json` | Output as JSON |

**Example output:**

```
Open Positions
==============
Symbol  Side   Size     Entry      Mark       PnL
------  ----   ----     -----      ----       ---
ETH     LONG   0.5000   $2,100.00  $2,285.50  $92.75 (+8.8%)
BTC     SHORT  0.0100   $44,000.00 $43,250.00 $7.50 (+1.7%)

Total PnL: $100.25
```

---

## arthur orders

View open orders.

```bash
arthur orders -c credentials.json

# Filter by symbol
arthur orders --symbol ETH -c credentials.json

# Cancel all
arthur orders cancel-all -c credentials.json

# Cancel specific
arthur orders cancel 12345 ETH -c credentials.json
```

**Example output:**

```
Open Orders
===========
ID       Symbol  Side  Type   Price      Size    Status
-------- ------  ----  ----   -----      ----    ------
1234567  ETH     BUY   LIMIT  $2,000.00  0.05    NEW
1234568  ETH     SELL  LIMIT  $2,500.00  0.05    NEW
```

---

## arthur run

Run a trading strategy.

```bash
# Run strategy once
arthur run strategy.json -c credentials.json

# Run continuously
arthur run strategy.json -c credentials.json --loop

# Dry run (no actual trades)
arthur run strategy.json -c credentials.json --dry-run

# Force run (ignore timeframe)
arthur run strategy.json -c credentials.json --force
```

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --credentials` | Path to credentials file |
| `--testnet` | Use testnet |
| `--dry-run` | Don't execute trades |
| `--loop` | Run continuously |
| `--force` | Ignore timeframe check |
| `-v, --verbose` | Verbose output |

**Example output:**

```
Running: Simple RSI v1.0.0
Checking ETH...
  RSI: 28.5
  Signal: LONG (RSI 28.5 <= 30)
  
Executed: BUY 0.0437 ETH @ $2,285.50
  Order ID: 1234567
  Status: FILLED
```

---

## Environment Variables

You can use environment variables instead of credentials file:

```bash
export ARTHUR_API_KEY="ed25519:xxx"
export ARTHUR_SECRET_KEY="ed25519:yyy"
export ARTHUR_ACCOUNT_ID="0x..."

# Now commands work without -c flag
arthur status
arthur price BTC ETH
```

---

## Shell Completion

Enable tab completion:

### Bash

```bash
# Add to ~/.bashrc
eval "$(_ARTHUR_COMPLETE=bash_source arthur)"
```

### Zsh

```bash
# Add to ~/.zshrc
eval "$(_ARTHUR_COMPLETE=zsh_source arthur)"
```

### Fish

```bash
# Add to ~/.config/fish/completions/arthur.fish
_ARTHUR_COMPLETE=fish_source arthur | source
```

---

## Examples

### Quick Trading Session

```bash
# Check balance
arthur status -c creds.json

# Check prices
arthur price BTC ETH SOL

# Open position
arthur trade buy ETH --usd 100 -c creds.json

# Check position
arthur positions -c creds.json

# Close when done
arthur trade close ETH -c creds.json
```

### Monitor and Trade

```bash
# Watch prices (in a loop)
watch -n 5 'arthur price BTC ETH SOL'

# In another terminal, trade when ready
arthur trade buy ETH --usd 50 -c creds.json -y
```

### Quick Scripts

```bash
#!/bin/bash
# morning_check.sh - Quick morning status

echo "=== Morning Status Check ==="
arthur status -c ~/creds.json
echo ""
arthur price BTC ETH SOL
```

---

## JSON Output

Use `-j` or `--json` for machine-readable output:

```bash
arthur status -c creds.json --json | jq '.balance'
arthur price BTC ETH --json | jq '.ETH'
arthur positions -c creds.json --json | jq '.[0].pnl'
```

---

## Testnet

All commands support `--testnet`:

```bash
arthur status -c testnet-creds.json --testnet
arthur trade buy ETH --usd 100 -c testnet-creds.json --testnet
```

!!! tip "Testnet Credentials"
    Get testnet credentials from [testnet.orderly.network](https://testnet.orderly.network)

---

## Common Issues

### "Command not found"

```bash
# If arthur command not found, try:
python -m arthur_sdk.cli price BTC

# Or ensure pip install location is in PATH
export PATH="$PATH:$(python -m site --user-base)/bin"
```

### "Invalid credentials"

```bash
# Check credentials file format
cat credentials.json

# Should look like:
# {
#   "api_key": "ed25519:...",
#   "secret_key": "ed25519:...",
#   "account_id": "0x..."
# }
```

### Rate limiting

The CLI has built-in rate limiting, but if you're scripting heavily:

```bash
# Add delays between commands
arthur price BTC && sleep 1 && arthur price ETH
```

---

## Next Steps

- [Basic Examples](examples/basic.md) — Python examples
- [API Reference](api/client.md) — Full API docs
- [Quickstart](quickstart.md) — Getting started guide
