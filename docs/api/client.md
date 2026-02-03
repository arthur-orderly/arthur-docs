# Arthur Client API Reference

The `Arthur` class is the main interface for trading on Arthur DEX.

---

## Quick Reference

```python
from arthur_sdk import Arthur

client = Arthur.from_credentials_file("credentials.json")
```

| Category | Methods |
|----------|---------|
| **Trading** | `buy()`, `sell()`, `close()`, `close_all()` |
| **Limit Orders** | `limit_buy()`, `limit_sell()`, `quote()` |
| **Positions** | `positions()`, `position()`, `pnl()` |
| **Orders** | `orders()`, `get_order()`, `cancel()`, `cancel_all()` |
| **Account** | `balance()`, `equity()`, `summary()` |
| **Market Data** | `price()`, `prices()`, `orderbook()`, `spread()` |
| **Risk** | `set_leverage()`, `set_stop_loss()` |

---

## Initialization

### Constructor

```python
Arthur(
    api_key: str = None,
    secret_key: str = None,
    account_id: str = None,
    testnet: bool = False
)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `api_key` | `str` | Orderly API key (ed25519:xxx format) |
| `secret_key` | `str` | Orderly secret key (ed25519:xxx format) |
| `account_id` | `str` | Orderly account ID (0x... format) |
| `testnet` | `bool` | Use testnet instead of mainnet |

**Example:**

```python
client = Arthur(
    api_key="ed25519:xxx",
    secret_key="ed25519:yyy",
    account_id="0x..."
)
```

### from_credentials_file

```python
Arthur.from_credentials_file(path: str, testnet: bool = False) -> Arthur
```

Load credentials from a JSON file.

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | `str` | Path to credentials JSON file |
| `testnet` | `bool` | Use testnet |

**Example:**

```python
client = Arthur.from_credentials_file("credentials.json")

# Or with testnet
client = Arthur.from_credentials_file("creds.json", testnet=True)
```

---

## Trading

### buy

```python
buy(
    symbol: str,
    size: float = None,
    usd: float = None,
    price: float = None,
    reduce_only: bool = False
) -> Order
```

Open or add to a long position.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol (e.g., "ETH" or "PERP_ETH_USDC") |
| `size` | `float` | Position size in base asset |
| `usd` | `float` | Position size in USD (alternative to size) |
| `price` | `float` | Limit price (None for market order) |
| `reduce_only` | `bool` | Only reduce existing position |

**Returns:** `Order` object

**Example:**

```python
# Buy $100 worth of ETH (market order)
order = client.buy("ETH", usd=100)

# Buy 0.5 ETH (market order)
order = client.buy("ETH", size=0.5)

# Buy ETH at limit price
order = client.buy("ETH", usd=100, price=2000)
```

### sell

```python
sell(
    symbol: str,
    size: float = None,
    usd: float = None,
    price: float = None,
    reduce_only: bool = False
) -> Order
```

Open or add to a short position.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `size` | `float` | Position size in base asset |
| `usd` | `float` | Position size in USD |
| `price` | `float` | Limit price (None for market order) |
| `reduce_only` | `bool` | Only reduce existing position |

**Returns:** `Order` object

**Example:**

```python
# Short $100 of BTC
order = client.sell("BTC", usd=100)

# Short 0.01 BTC at specific price
order = client.sell("BTC", size=0.01, price=50000)
```

### close

```python
close(symbol: str, size: float = None) -> Optional[Order]
```

Close a position (partially or fully).

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `size` | `float` | Size to close (None = close entire position) |

**Returns:** `Order` object, or `None` if no position to close

**Example:**

```python
# Close entire ETH position
client.close("ETH")

# Partial close - close 0.1 ETH
client.close("ETH", size=0.1)
```

### close_all

```python
close_all() -> List[Order]
```

Close all open positions.

**Returns:** List of `Order` objects for each closed position

**Example:**

```python
orders = client.close_all()
print(f"Closed {len(orders)} positions")
```

---

## Limit Orders

### limit_buy

```python
limit_buy(
    symbol: str,
    price: float,
    size: float = None,
    usd: float = None,
    post_only: bool = False
) -> Order
```

Place a limit buy order.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `price` | `float` | Limit price |
| `size` | `float` | Order size in base asset |
| `usd` | `float` | Order size in USD |
| `post_only` | `bool` | Cancel if would take liquidity |

**Example:**

```python
# Buy ETH at $2,000 or better
order = client.limit_buy("ETH", price=2000, usd=100)

# Post-only (maker only)
order = client.limit_buy("ETH", price=2000, size=0.05, post_only=True)
```

### limit_sell

```python
limit_sell(
    symbol: str,
    price: float,
    size: float = None,
    usd: float = None,
    post_only: bool = False
) -> Order
```

Place a limit sell order.

**Example:**

```python
# Sell ETH at $2,500 or better
order = client.limit_sell("ETH", price=2500, usd=100)
```

### quote

```python
quote(
    symbol: str,
    bid_price: float,
    ask_price: float,
    size: float,
    cancel_existing: bool = True
) -> Dict[str, Order]
```

Place a two-sided quote (bid + ask). Useful for market making.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `bid_price` | `float` | Bid (buy) price |
| `ask_price` | `float` | Ask (sell) price |
| `size` | `float` | Size for each side |
| `cancel_existing` | `bool` | Cancel existing orders first |

**Returns:** Dict with `bid` and `ask` Order objects

**Example:**

```python
# Quote around mid price
mid = client.price("ORDER")
quotes = client.quote(
    symbol="ORDER",
    bid_price=mid * 0.999,  # -0.1%
    ask_price=mid * 1.001,  # +0.1%
    size=100
)

print(f"Bid: {quotes['bid'].order_id}")
print(f"Ask: {quotes['ask'].order_id}")
```

---

## Positions

### positions

```python
positions() -> List[Position]
```

Get all open positions.

**Returns:** List of `Position` objects

**Example:**

```python
for pos in client.positions():
    print(f"{pos.symbol}: {pos.side} {pos.size}")
    print(f"  Entry: ${pos.entry_price:.2f}")
    print(f"  Mark: ${pos.mark_price:.2f}")
    print(f"  PnL: ${pos.unrealized_pnl:.2f} ({pos.pnl_percent:.1f}%)")
```

### position

```python
position(symbol: str) -> Optional[Position]
```

Get position for a specific symbol.

**Returns:** `Position` object or `None`

**Example:**

```python
eth_pos = client.position("ETH")
if eth_pos:
    print(f"ETH position: {eth_pos.side} {eth_pos.size}")
```

### pnl

```python
pnl() -> float
```

Get total unrealized PnL across all positions.

**Returns:** Total unrealized PnL in USDC

**Example:**

```python
total_pnl = client.pnl()
print(f"Total PnL: ${total_pnl:.2f}")
```

---

## Position Class

```python
@dataclass
class Position:
    symbol: str          # e.g., "PERP_ETH_USDC"
    side: str            # "LONG" or "SHORT"
    size: float          # Position size
    entry_price: float   # Average entry price
    mark_price: float    # Current mark price
    unrealized_pnl: float
    leverage: float
    
    @property
    def pnl_percent(self) -> float  # PnL as percentage
```

---

## Orders

### orders

```python
orders(symbol: str = None) -> List[Order]
```

Get open orders.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Filter by symbol (optional) |

**Example:**

```python
# All open orders
all_orders = client.orders()

# Orders for specific symbol
eth_orders = client.orders("ETH")
```

### get_order

```python
get_order(order_id: str) -> Optional[Order]
```

Get order by ID.

**Example:**

```python
order = client.get_order("123456")
if order:
    print(f"Status: {order.status}")
```

### cancel

```python
cancel(order_id: str, symbol: str) -> bool
```

Cancel an order.

**Returns:** `True` if cancelled successfully

**Example:**

```python
success = client.cancel("123456", "ETH")
```

### cancel_all

```python
cancel_all(symbol: str = None) -> int
```

Cancel all open orders.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Cancel only orders for this symbol (optional) |

**Returns:** Number of orders cancelled

**Example:**

```python
# Cancel all orders
cancelled = client.cancel_all()

# Cancel only ETH orders
cancelled = client.cancel_all("ETH")
```

---

## Order Class

```python
@dataclass
class Order:
    order_id: str
    symbol: str
    side: str          # "BUY" or "SELL"
    order_type: str    # "MARKET", "LIMIT", "POST_ONLY"
    price: float       # None for market orders
    size: float
    status: str        # "NEW", "FILLED", "CANCELLED", etc.
    created_at: int    # Timestamp in milliseconds
```

---

## Account

### balance

```python
balance() -> float
```

Get available USDC balance.

**Example:**

```python
available = client.balance()
print(f"Available: ${available:.2f}")
```

### equity

```python
equity() -> float
```

Get total account equity (balance + unrealized PnL).

**Example:**

```python
total = client.equity()
print(f"Total equity: ${total:.2f}")
```

### summary

```python
summary() -> Dict[str, Any]
```

Get account summary including balance, positions, and PnL.

**Returns:**

```python
{
    "balance": float,
    "equity": float,
    "positions": int,          # Number of open positions
    "unrealized_pnl": float,
    "position_details": [
        {
            "symbol": str,     # Short name (ETH, BTC)
            "side": str,
            "size": float,
            "entry": float,
            "mark": float,
            "pnl": float,
            "pnl_pct": float,
        },
        ...
    ]
}
```

**Example:**

```python
summary = client.summary()
print(f"Balance: ${summary['balance']:.2f}")
print(f"Equity: ${summary['equity']:.2f}")
print(f"Open positions: {summary['positions']}")
print(f"Unrealized PnL: ${summary['unrealized_pnl']:.2f}")
```

---

## Market Data

### price

```python
price(symbol: str) -> float
```

Get current mark price for a symbol.

**Example:**

```python
eth_price = client.price("ETH")
print(f"ETH: ${eth_price:.2f}")
```

### prices

```python
prices() -> Dict[str, float]
```

Get prices for all supported symbols.

**Returns:** Dict mapping symbol to price (includes both short and full names)

**Example:**

```python
all_prices = client.prices()
print(f"ETH: ${all_prices['ETH']:.2f}")
print(f"BTC: ${all_prices['BTC']:.2f}")
```

### orderbook

```python
orderbook(symbol: str, depth: int = 10) -> Dict[str, List]
```

Get orderbook for a symbol.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `depth` | `int` | Number of levels (default 10) |

**Returns:**

```python
{
    "bids": [[price, size], ...],  # Sorted best to worst
    "asks": [[price, size], ...],
    "timestamp": int
}
```

**Example:**

```python
ob = client.orderbook("ETH", depth=5)
best_bid = ob["bids"][0]  # [price, size]
best_ask = ob["asks"][0]
print(f"Best bid: ${best_bid[0]:.2f} ({best_bid[1]} ETH)")
print(f"Best ask: ${best_ask[0]:.2f} ({best_ask[1]} ETH)")
```

### spread

```python
spread(symbol: str) -> Dict[str, float]
```

Get current spread info for a symbol.

**Returns:**

```python
{
    "best_bid": float,
    "best_ask": float,
    "mid": float,
    "spread": float,      # Absolute spread
    "spread_pct": float,  # Spread as percentage
    "spread_bps": float,  # Spread in basis points
}
```

**Example:**

```python
s = client.spread("ETH")
print(f"Mid: ${s['mid']:.2f}")
print(f"Spread: {s['spread_bps']:.1f} bps")
```

---

## Risk Management

### set_leverage

```python
set_leverage(symbol: str, leverage: int) -> bool
```

Set leverage for a symbol.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `leverage` | `int` | Leverage multiplier (1-50) |

**Returns:** `True` if successful

**Example:**

```python
client.set_leverage("ETH", 5)  # 5x leverage
```

### set_stop_loss

```python
set_stop_loss(
    symbol: str,
    price: float = None,
    pct: float = None
) -> Order
```

Set stop loss for a position.

| Parameter | Type | Description |
|-----------|------|-------------|
| `symbol` | `str` | Token symbol |
| `price` | `float` | Stop price |
| `pct` | `float` | Stop loss percentage from entry |

**Example:**

```python
# Stop at specific price
client.set_stop_loss("ETH", price=1800)

# Stop at 5% loss from entry
client.set_stop_loss("ETH", pct=5)
```

---

## Symbol Mapping

Short symbols are automatically converted to full Orderly symbols:

| Short | Full |
|-------|------|
| `BTC` | `PERP_BTC_USDC` |
| `ETH` | `PERP_ETH_USDC` |
| `SOL` | `PERP_SOL_USDC` |
| `ARB` | `PERP_ARB_USDC` |
| `OP` | `PERP_OP_USDC` |
| `AVAX` | `PERP_AVAX_USDC` |
| `LINK` | `PERP_LINK_USDC` |
| `DOGE` | `PERP_DOGE_USDC` |
| `SUI` | `PERP_SUI_USDC` |
| `TIA` | `PERP_TIA_USDC` |
| `WOO` | `PERP_WOO_USDC` |
| `ORDER` | `PERP_ORDER_USDC` |

You can use either format:

```python
client.buy("ETH", usd=100)          # Short form
client.buy("PERP_ETH_USDC", usd=100)  # Full form
```

---

## Exceptions

```python
from arthur_sdk import (
    ArthurError,           # Base exception
    AuthError,             # Authentication failed
    OrderError,            # Order placement failed
    InsufficientFundsError # Not enough balance
)

try:
    client.buy("ETH", usd=10000)
except InsufficientFundsError:
    print("Not enough balance!")
except OrderError as e:
    print(f"Order failed: {e}")
except ArthurError as e:
    print(f"General error: {e}")
```
