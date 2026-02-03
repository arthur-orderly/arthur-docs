# Basic Trading Examples

Copy-paste examples to get started quickly.

---

## Setup

All examples assume you have credentials set up:

```python
from arthur_sdk import Arthur

client = Arthur.from_credentials_file("credentials.json")
```

---

## Market Orders

### Buy by USD Value

```python
# Buy $100 worth of ETH
order = client.buy("ETH", usd=100)
print(f"Bought {order.size:.4f} ETH")
```

### Buy by Size

```python
# Buy exactly 0.5 ETH
order = client.buy("ETH", size=0.5)
print(f"Order: {order.order_id}")
```

### Short Sell

```python
# Short $200 of BTC
order = client.sell("BTC", usd=200)
print(f"Shorted {order.size:.6f} BTC")
```

### Close Position

```python
# Close entire ETH position
order = client.close("ETH")
if order:
    print(f"Closed position")
else:
    print("No position to close")
```

### Close All Positions

```python
# Emergency close everything
orders = client.close_all()
print(f"Closed {len(orders)} positions")
```

---

## Limit Orders

### Limit Buy

```python
# Buy ETH if price drops to $2,000
order = client.limit_buy("ETH", price=2000, usd=100)
print(f"Limit order placed: {order.order_id}")
```

### Limit Sell

```python
# Take profit at $2,500
order = client.limit_sell("ETH", price=2500, usd=100)
```

### Post-Only (Maker Only)

```python
# Ensure we're a maker (no taker fees)
order = client.limit_buy("ETH", price=2000, size=0.1, post_only=True)
```

---

## Position Management

### View All Positions

```python
positions = client.positions()

if not positions:
    print("No open positions")
else:
    for pos in positions:
        print(f"\n{pos.symbol}")
        print(f"  Side: {pos.side}")
        print(f"  Size: {pos.size}")
        print(f"  Entry: ${pos.entry_price:.2f}")
        print(f"  Mark: ${pos.mark_price:.2f}")
        print(f"  PnL: ${pos.unrealized_pnl:.2f} ({pos.pnl_percent:.1f}%)")
```

### Check Specific Position

```python
eth = client.position("ETH")
if eth:
    print(f"ETH {eth.side}: {eth.size} @ ${eth.entry_price:.2f}")
    print(f"PnL: ${eth.unrealized_pnl:.2f}")
```

### Total PnL

```python
total_pnl = client.pnl()
print(f"Total unrealized PnL: ${total_pnl:.2f}")
```

---

## Account Info

### Balance and Equity

```python
balance = client.balance()
equity = client.equity()
print(f"Available: ${balance:.2f}")
print(f"Total equity: ${equity:.2f}")
```

### Full Summary

```python
summary = client.summary()
print(f"Balance: ${summary['balance']:.2f}")
print(f"Equity: ${summary['equity']:.2f}")
print(f"Positions: {summary['positions']}")
print(f"Unrealized PnL: ${summary['unrealized_pnl']:.2f}")

for p in summary['position_details']:
    print(f"  {p['symbol']}: {p['side']} {p['size']:.4f} (${p['pnl']:.2f})")
```

---

## Market Data

### Current Price

```python
eth_price = client.price("ETH")
print(f"ETH: ${eth_price:.2f}")
```

### Multiple Prices

```python
prices = client.prices()
for symbol in ["BTC", "ETH", "SOL"]:
    print(f"{symbol}: ${prices[symbol]:,.2f}")
```

### Orderbook

```python
ob = client.orderbook("ETH", depth=5)

print("Bids:")
for price, size in ob['bids']:
    print(f"  ${price:.2f}: {size:.4f} ETH")

print("Asks:")
for price, size in ob['asks']:
    print(f"  ${price:.2f}: {size:.4f} ETH")
```

### Spread Info

```python
spread = client.spread("ETH")
print(f"Best bid: ${spread['best_bid']:.2f}")
print(f"Best ask: ${spread['best_ask']:.2f}")
print(f"Mid: ${spread['mid']:.2f}")
print(f"Spread: {spread['spread_bps']:.1f} bps")
```

---

## Risk Management

### Set Leverage

```python
# Set 5x leverage for ETH
client.set_leverage("ETH", 5)
```

### Stop Loss by Price

```python
# Stop loss at $1,800
client.set_stop_loss("ETH", price=1800)
```

### Stop Loss by Percentage

```python
# Stop loss at 5% from entry
client.set_stop_loss("ETH", pct=5)
```

---

## Order Management

### View Open Orders

```python
orders = client.orders()
for order in orders:
    print(f"{order.order_id}: {order.side} {order.size} {order.symbol} @ ${order.price}")
```

### Cancel Order

```python
client.cancel("12345", "ETH")
```

### Cancel All Orders

```python
# Cancel all orders
cancelled = client.cancel_all()
print(f"Cancelled {cancelled} orders")

# Cancel only ETH orders
cancelled = client.cancel_all("ETH")
```

---

## Complete Examples

### Simple Long Trade

```python
from arthur_sdk import Arthur

client = Arthur.from_credentials_file("credentials.json")

# Check balance
balance = client.balance()
print(f"Balance: ${balance:.2f}")

# Buy ETH
print("Opening long position...")
client.buy("ETH", usd=50)

# Check position
pos = client.position("ETH")
print(f"Position: {pos.size:.4f} ETH @ ${pos.entry_price:.2f}")

# Wait for price to move... (in real code, add logic here)

# Close position
input("Press Enter to close...")
client.close("ETH")
print("Position closed")
```

### Quick Scalp

```python
from arthur_sdk import Arthur
import time

client = Arthur.from_credentials_file("credentials.json")

symbol = "ETH"
take_profit_pct = 0.5  # 0.5% profit target
stop_loss_pct = 0.3    # 0.3% stop loss

# Enter position
print(f"Entering long on {symbol}...")
client.buy(symbol, usd=100)
entry = client.position(symbol).entry_price
print(f"Entry: ${entry:.2f}")

# Monitor
while True:
    pos = client.position(symbol)
    if not pos:
        print("Position closed externally")
        break
    
    pnl_pct = pos.pnl_percent
    
    if pnl_pct >= take_profit_pct:
        print(f"✓ Take profit hit: {pnl_pct:.2f}%")
        client.close(symbol)
        break
    elif pnl_pct <= -stop_loss_pct:
        print(f"✗ Stop loss hit: {pnl_pct:.2f}%")
        client.close(symbol)
        break
    else:
        print(f"PnL: {pnl_pct:.2f}%", end="\r")
    
    time.sleep(1)
```

### Price Alert Bot

```python
from arthur_sdk import Arthur
import time

client = Arthur.from_credentials_file("credentials.json")

symbol = "BTC"
alert_above = 50000
alert_below = 45000

print(f"Watching {symbol}...")
print(f"Alert above ${alert_above:,}")
print(f"Alert below ${alert_below:,}")

while True:
    price = client.price(symbol)
    
    if price >= alert_above:
        print(f"\n🚀 {symbol} above ${alert_above:,}! Current: ${price:,.2f}")
        # Could trigger a buy here
        break
    elif price <= alert_below:
        print(f"\n📉 {symbol} below ${alert_below:,}! Current: ${price:,.2f}")
        # Could trigger a sell here
        break
    else:
        print(f"{symbol}: ${price:,.2f}", end="\r")
    
    time.sleep(5)
```

---

## Error Handling

```python
from arthur_sdk import (
    Arthur, 
    ArthurError, 
    AuthError, 
    OrderError, 
    InsufficientFundsError
)

client = Arthur.from_credentials_file("credentials.json")

try:
    # Try to buy more than we can afford
    client.buy("ETH", usd=1000000)
except InsufficientFundsError:
    print("Not enough balance!")
except AuthError:
    print("Authentication failed - check credentials")
except OrderError as e:
    print(f"Order failed: {e}")
except ArthurError as e:
    print(f"General error: {e}")
```

---

## Next Steps

- [Strategy Examples](strategies.md) — Automated trading strategies
- [Market Making](market-making.md) — Provide liquidity
- [API Reference](../api/client.md) — Full method documentation
