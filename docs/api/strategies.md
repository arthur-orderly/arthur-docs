# Strategy Runner API Reference

The strategy module lets you run automated trading strategies from JSON configs.

---

## Quick Example

```python
from arthur_sdk import Arthur, StrategyRunner

client = Arthur.from_credentials_file("credentials.json")
runner = StrategyRunner(client)

result = runner.run("strategy.json")
print(f"Signals: {len(result['signals'])}")
print(f"Trades: {len(result['trades'])}")
```

---

## StrategyRunner

The main class for executing trading strategies.

### Constructor

```python
StrategyRunner(
    client: Arthur,
    dry_run: bool = False,
    on_signal: Callable[[Signal], None] = None,
    on_trade: Callable[[Dict], None] = None
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `client` | `Arthur` | Authenticated trading client |
| `dry_run` | `bool` | If True, don't execute trades |
| `on_signal` | `Callable` | Callback when signal is generated |
| `on_trade` | `Callable` | Callback when trade is executed |

**Example:**

```python
def on_signal(signal):
    print(f"Signal: {signal.action} {signal.symbol}")
    print(f"  Reason: {signal.reason}")

def on_trade(trade):
    print(f"Trade executed: {trade['action']} {trade['symbol']}")

runner = StrategyRunner(
    client,
    dry_run=False,
    on_signal=on_signal,
    on_trade=on_trade
)
```

### run

```python
run(
    strategy: Union[str, StrategyConfig, Dict],
    force: bool = False
) -> Dict[str, Any]
```

Run a strategy once.

| Parameter | Type | Description |
|-----------|------|-------------|
| `strategy` | `str/Config/Dict` | Path to JSON, StrategyConfig, or dict |
| `force` | `bool` | Run even if not time for next check |

**Returns:**

```python
{
    "strategy": str,           # Strategy name
    "version": str,            # Strategy version
    "timestamp": int,          # Run timestamp (ms)
    "signals": List[Dict],     # Generated signals
    "trades": List[Dict],      # Executed trades
    "errors": List[str],       # Any errors
    "dry_run": bool,           # Whether in dry run mode
    "skipped": bool,           # True if skipped (not time yet)
    "reason": str,             # Skip reason if skipped
}
```

**Example:**

```python
# From file
result = runner.run("strategies/momentum.json")

# From dict
result = runner.run({
    "name": "Quick Test",
    "symbol": "ETH",
    "signals": {"long_entry": 30, "short_entry": 70}
})

# Force run (ignore timeframe check)
result = runner.run("strategy.json", force=True)
```

---

## StrategyConfig

Configuration for a trading strategy.

### from_file

```python
StrategyConfig.from_file(path: str) -> StrategyConfig
```

Load strategy from JSON file.

### from_dict

```python
StrategyConfig.from_dict(data: Dict) -> StrategyConfig
```

Create strategy from dict.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `str` | Strategy name |
| `version` | `str` | Version string |
| `description` | `str` | Description |
| `symbol` | `str` | Single symbol (for simple strategies) |
| `long_assets` | `List[str]` | Assets to go long |
| `short_assets` | `List[str]` | Assets to go short |
| `timeframe` | `str` | Check interval (e.g., "4h") |
| `signals` | `Dict` | Signal configuration |
| `risk` | `Dict` | Risk management settings |
| `position` | `Dict` | Position sizing settings |
| `execution` | `Dict` | Execution settings |
| `flags` | `Dict` | Feature flags |

### Computed Properties

| Property | Type | Description |
|----------|------|-------------|
| `all_symbols` | `List[str]` | All tradeable symbols |
| `is_multi_asset` | `bool` | True if multi-asset strategy |
| `leverage` | `int` | Leverage from position config |
| `position_size_pct` | `float` | Position size as % of balance |
| `stop_loss_pct` | `float` | Stop loss percentage |
| `take_profit_pct` | `float` | Take profit percentage |
| `max_positions` | `int` | Maximum open positions |
| `dry_run` | `bool` | Dry run mode flag |
| `allow_shorts` | `bool` | Allow short positions |

---

## Signal

A trading signal from strategy evaluation.

```python
@dataclass
class Signal:
    action: str       # "long", "short", "close", "hold"
    symbol: str       # Full symbol (PERP_ETH_USDC)
    size: float       # Optional size
    usd: float        # Optional USD value
    reason: str       # Why this signal was generated
    confidence: float # 0.0 to 1.0
```

---

## Strategy JSON Format

### Simple Strategy (Single Symbol)

```json title="simple-strategy.json"
{
    "name": "ETH Momentum",
    "version": "1.0.0",
    "description": "RSI-based ETH trading",
    "symbol": "ETH",
    "timeframe": "4h",
    
    "signals": {
        "period": 14,
        "long_entry": 30,
        "short_entry": 70
    },
    
    "position": {
        "leverage": 5,
        "size_pct": 10
    },
    
    "risk": {
        "stop_loss_pct": 5,
        "take_profit_pct": 15,
        "max_positions": 1
    },
    
    "flags": {
        "dry_run": false,
        "allow_shorts": true
    }
}
```

### Multi-Asset Strategy (Unlockoor Style)

```json title="multi-asset-strategy.json"
{
    "name": "Unlockoor",
    "version": "2.0.0",
    "description": "Multi-asset RSI strategy",
    
    "long_assets": ["BTC", "ETH", "SOL"],
    "short_assets": ["DOGE", "SHIB"],
    
    "timeframe": "4h",
    
    "signals": {
        "period": 14,
        "long_entry": 30,
        "short_entry": 70
    },
    
    "position": {
        "leverage": 3,
        "size_pct": 5
    },
    
    "risk": {
        "stop_loss_pct": 8,
        "take_profit_pct": 20,
        "max_positions": 5
    },
    
    "flags": {
        "dry_run": false,
        "allow_shorts": true
    }
}
```

---

## Configuration Reference

### signals

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `period` | `int` | `14` | RSI period |
| `long_entry` | `int` | `30` | RSI threshold for long entry |
| `short_entry` | `int` | `70` | RSI threshold for short entry |
| `timeframe` | `str` | `"4h"` | Candle timeframe |

### position

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `leverage` | `int` | `5` | Position leverage |
| `size_pct` | `float` | `10` | Position size as % of balance |

### risk

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `stop_loss_pct` | `float` | `None` | Stop loss % from entry |
| `take_profit_pct` | `float` | `None` | Take profit % from entry |
| `max_positions` | `int` | `5` | Maximum concurrent positions |

### flags

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `dry_run` | `bool` | `false` | Don't execute trades |
| `allow_shorts` | `bool` | `true` | Allow short positions |

---

## Signal Logic

### Entry Signals

For **long assets**:

- Entry when RSI ≤ `long_entry` (default 30)
- Exit when RSI ≥ 70

For **short assets**:

- Entry when RSI ≥ `short_entry` (default 70)
- Exit when RSI ≤ 30

### Exit Signals

Positions are closed when:

1. **Stop loss hit**: PnL % ≤ -`stop_loss_pct`
2. **Take profit hit**: PnL % ≥ `take_profit_pct`
3. **RSI exit**: RSI reverses to opposite extreme
4. **Manual close**: Via `client.close()`

### Position Limits

New positions won't be opened if:

- Current positions ≥ `max_positions`
- Already have a position in that symbol

---

## Convenience Function

```python
from arthur_sdk import run_strategy

result = run_strategy(
    strategy_path="strategy.json",
    credentials_path="credentials.json",
    dry_run=False
)
```

Quick one-liner to run a strategy.

---

## Complete Example

```python title="run_strategy.py"
from arthur_sdk import Arthur, StrategyRunner, StrategyConfig

# Setup
client = Arthur.from_credentials_file("credentials.json")

# Track signals and trades
signals_log = []
trades_log = []

def on_signal(signal):
    signals_log.append(signal)
    emoji = "🟢" if signal.action == "long" else "🔴" if signal.action == "short" else "⚪"
    print(f"{emoji} {signal.action.upper()} {signal.symbol}")
    print(f"   {signal.reason}")

def on_trade(trade):
    trades_log.append(trade)
    status = "✅" if trade.get("status") == "executed" else "❌"
    print(f"{status} Trade: {trade['action']} {trade['symbol']}")

# Create runner
runner = StrategyRunner(
    client,
    dry_run=False,
    on_signal=on_signal,
    on_trade=on_trade
)

# Run strategy
result = runner.run("strategy.json", force=True)

# Print summary
print(f"\n{'='*40}")
print(f"Strategy: {result['strategy']}")
print(f"Signals: {len(result['signals'])}")
print(f"Trades: {len(result['trades'])}")
print(f"Errors: {len(result['errors'])}")

if result['errors']:
    for err in result['errors']:
        print(f"  ⚠️ {err}")
```

---

## Continuous Running

To run a strategy continuously:

```python title="bot.py"
import time
from arthur_sdk import Arthur, StrategyRunner

client = Arthur.from_credentials_file("credentials.json")
runner = StrategyRunner(client)

strategy_path = "strategy.json"

print("Starting strategy bot...")

while True:
    try:
        result = runner.run(strategy_path)
        
        if result.get("skipped"):
            print(f"Skipped: {result.get('reason')}")
        else:
            print(f"Ran: {len(result['signals'])} signals, {len(result['trades'])} trades")
        
    except Exception as e:
        print(f"Error: {e}")
    
    # Check every minute (strategy timeframe handles actual signal timing)
    time.sleep(60)
```

!!! tip "Use a Process Manager"
    For production, use `systemd`, `supervisord`, or `pm2` to keep your bot running and auto-restart on failures.

---

## Next Steps

- [Strategy Examples](../examples/strategies.md) — Complete strategy examples
- [Market Making](market-maker.md) — Run a market making strategy
- [Arthur Client](client.md) — Full trading API
