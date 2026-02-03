# Market Maker API Reference

The market maker module provides tools for automated liquidity provision.

---

## Overview

Market making earns the bid-ask spread by placing limit orders on both sides of the orderbook. The `MarketMaker` class handles:

- Two-sided quoting
- Inventory-based skewing
- Risk management
- Continuous requoting

---

## Quick Example

```python
from arthur_sdk import Arthur, MarketMaker, MMConfig

client = Arthur.from_credentials_file("credentials.json")
config = MMConfig.from_file("mm-config.json")
mm = MarketMaker(client, config)

# Single quote cycle
result = mm.run_once()

# Continuous quoting
mm.run_loop()  # Runs until Ctrl+C
```

---

## MarketMaker

The main class for market making.

### Constructor

```python
MarketMaker(client: Arthur, config: MMConfig)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `client` | `Arthur` | Authenticated trading client |
| `config` | `MMConfig` | Market maker configuration |

### run_once

```python
run_once() -> Dict[str, Any]
```

Run one quote cycle.

**Returns:**

```python
{
    "timestamp": int,          # Quote timestamp (ms)
    "symbol": str,             # Market symbol
    "dry_run": bool,
    "mid_price": float,        # Current mid price
    "market_spread_bps": float, # Market spread in bps
    "inventory_usd": float,    # Current inventory value
    "quotes": {
        "bid_price": float,
        "ask_price": float,
        "size": float,
        "spread_bps": float,
        "skew_bps": float,
    },
    "orders": {                # Only if live (not dry run)
        "bid": str,            # Bid order ID
        "ask": str,            # Ask order ID
    },
    "status": str,             # "quoted", "dry_run", "max_inventory", "error"
    "action": str,             # "placed_orders", "would_quote", "cancel_all"
}
```

**Example:**

```python
result = mm.run_once()
print(f"Mid: ${result['mid_price']:.5f}")
print(f"Bid: ${result['quotes']['bid_price']:.5f}")
print(f"Ask: ${result['quotes']['ask_price']:.5f}")
print(f"Spread: {result['quotes']['spread_bps']:.1f} bps")
```

### run_loop

```python
run_loop(duration_sec: float = None)
```

Run continuous quoting loop.

| Parameter | Type | Description |
|-----------|------|-------------|
| `duration_sec` | `float` | Run duration in seconds (None = forever) |

**Example:**

```python
# Run forever (Ctrl+C to stop)
mm.run_loop()

# Run for 1 hour
mm.run_loop(duration_sec=3600)
```

### status

```python
status() -> Dict
```

Get current MM status.

**Returns:**

```python
{
    "symbol": str,
    "mode": str,               # "dry_run" or "live"
    "mid_price": float,
    "market_spread_bps": float,
    "position": {
        "side": str,           # "LONG", "SHORT", or None
        "size": float,
        "pnl": float,
    },
    "open_orders": int,
    "uptime_sec": float,
}
```

---

## MMConfig

Market maker configuration.

### from_file

```python
MMConfig.from_file(path: str) -> MMConfig
```

Load config from JSON file.

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `str` | - | Strategy name |
| `symbol` | `str` | - | Market to quote |
| `base_spread_bps` | `float` | `30` | Base spread in basis points |
| `min_spread_bps` | `float` | `15` | Minimum spread |
| `order_size_usd` | `float` | `50` | Size per side in USD |
| `max_inventory_usd` | `float` | `300` | Max inventory before stopping |
| `levels` | `int` | `1` | Number of price levels |
| `skew_per_100_usd` | `float` | `5` | BPS to skew per $100 inventory |
| `max_position_usd` | `float` | `500` | Max position value |
| `stop_loss_pct` | `float` | `5` | Stop loss percentage |
| `daily_loss_limit_usd` | `float` | `50` | Max daily loss |
| `post_only` | `bool` | `True` | Use post-only orders |
| `requote_interval_sec` | `float` | `30` | Seconds between requotes |
| `min_edge_bps` | `float` | `5` | Minimum edge to quote |
| `dry_run` | `bool` | `True` | Don't execute trades |
| `log_quotes` | `bool` | `True` | Log quote details |

---

## Config JSON Format

```json title="mm-config.json"
{
    "name": "ORDER Market Maker",
    "symbol": "ORDER",
    
    "market_making": {
        "base_spread_bps": 30,
        "min_spread_bps": 15,
        "order_size_usd": 50,
        "max_inventory_usd": 300,
        "levels": 1,
        "skew_per_100_usd": 5,
        "requote_interval_sec": 30
    },
    
    "risk": {
        "max_position_usd": 500,
        "stop_loss_pct": 5,
        "daily_loss_limit_usd": 50
    },
    
    "execution": {
        "post_only": true,
        "min_edge_bps": 5
    },
    
    "flags": {
        "dry_run": true,
        "log_quotes": true
    }
}
```

---

## How It Works

### Quote Calculation

1. **Get mid price** from orderbook
2. **Calculate base spread** (configurable BPS)
3. **Apply inventory skew** (move quotes away from heavy side)
4. **Ensure minimum spread** 
5. **Round to tick sizes**
6. **Place post-only orders**

### Inventory Skewing

When you accumulate inventory, quotes are skewed to reduce position:

- **Long inventory**: Lower bid price, lower ask price (encourage sells)
- **Short inventory**: Higher bid price, higher ask price (encourage buys)

Skew formula:
```
skew_bps = (inventory_usd / 100) × skew_per_100_usd
```

### Risk Management

Quoting stops when:

1. **Max inventory reached**: Position value ≥ `max_inventory_usd`
2. **Stop loss hit**: Position PnL ≤ -`stop_loss_pct`
3. **Daily loss limit**: Total daily loss ≥ `daily_loss_limit_usd`

---

## Example: ORDER Token MM

```python title="order_mm.py"
from arthur_sdk import Arthur, MarketMaker, MMConfig

# Load credentials
client = Arthur.from_credentials_file("credentials.json")

# Configure MM
config = MMConfig(
    name="ORDER MM",
    symbol="ORDER",
    base_spread_bps=25,        # 0.25% spread
    min_spread_bps=10,
    order_size_usd=100,        # $100 per side
    max_inventory_usd=500,     # Stop at $500 position
    skew_per_100_usd=3,        # 3 bps skew per $100
    requote_interval_sec=15,   # Requote every 15s
    dry_run=True,              # Start with dry run!
)

# Create market maker
mm = MarketMaker(client, config)

# Check initial status
print("Starting MM...")
print(f"Symbol: {config.symbol}")
print(f"Spread: {config.base_spread_bps} bps")
print(f"Size: ${config.order_size_usd}/side")
print(f"Mode: {'DRY RUN' if config.dry_run else 'LIVE'}")
print("-" * 40)

# Run single cycle
result = mm.run_once()
print(f"Mid: ${result['mid_price']:.5f}")
print(f"Quotes: {result['quotes']['bid_price']:.5f} / {result['quotes']['ask_price']:.5f}")
print(f"Spread: {result['quotes']['spread_bps']:.1f} bps")

# Run continuously
# mm.run_loop()
```

---

## Multi-Symbol MM

To make markets on multiple symbols:

```python title="multi_mm.py"
from arthur_sdk import Arthur, MarketMaker, MMConfig
import threading

client = Arthur.from_credentials_file("credentials.json")

# Define symbols to market make
symbols = ["ORDER", "WOO", "TIA"]

# Create MM instances
makers = []
for sym in symbols:
    config = MMConfig(
        name=f"{sym} MM",
        symbol=sym,
        base_spread_bps=30,
        order_size_usd=50,
        max_inventory_usd=200,
        requote_interval_sec=30,
        dry_run=True,
    )
    makers.append(MarketMaker(client, config))

# Run each in a thread
threads = []
for mm in makers:
    t = threading.Thread(target=mm.run_loop)
    t.daemon = True
    threads.append(t)
    t.start()
    print(f"Started {mm.config.symbol} MM")

# Keep main thread alive
try:
    while True:
        for mm in makers:
            status = mm.status()
            print(f"{mm.config.symbol}: "
                  f"inv=${status['position']['pnl'] if status['position'] else 0:.0f} "
                  f"orders={status['open_orders']}")
        time.sleep(60)
except KeyboardInterrupt:
    print("Stopping all MMs...")
```

---

## Convenience Function

```python
from arthur_sdk.market_maker import run_mm

run_mm(
    config_path="mm-config.json",
    credentials_path="credentials.json",
    duration=3600  # Run for 1 hour
)
```

---

## Best Practices

### Start Conservatively

```python
config = MMConfig(
    symbol="ORDER",
    base_spread_bps=50,        # Wide spread initially
    order_size_usd=25,         # Small sizes
    max_inventory_usd=100,     # Low limits
    dry_run=True,              # Always start dry!
)
```

### Monitor Inventory

```python
while True:
    result = mm.run_once()
    
    inv = result['inventory_usd']
    max_inv = config.max_inventory_usd
    
    if abs(inv) > max_inv * 0.8:
        print(f"⚠️ High inventory: ${inv:.0f} / ${max_inv}")
    
    time.sleep(config.requote_interval_sec)
```

### Handle Errors

```python
import traceback

while True:
    try:
        result = mm.run_once()
        if result.get('status') == 'error':
            print(f"Error: {result.get('error')}")
    except Exception as e:
        print(f"Exception: {e}")
        traceback.print_exc()
        time.sleep(5)  # Back off on errors
    
    time.sleep(config.requote_interval_sec)
```

---

## Fees & Economics

Market makers on Arthur DEX (via Orderly Network) enjoy:

- **Negative maker fees**: Get rebates for providing liquidity
- **Earn the spread**: Capture bid-ask when orders fill
- **Volume mining**: Additional rewards for volume

Check [Arthur DEX](https://arthurdex.com) for current fee structure.

---

## Next Steps

- [Market Making Examples](../examples/market-making.md) — Complete MM examples
- [Strategy Runner](strategies.md) — Directional trading strategies
- [Arthur Client](client.md) — Full trading API
