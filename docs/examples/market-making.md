# Market Making Examples

Examples of providing liquidity and earning the spread.

---

## Simple Quote Bot

The most basic market maker — place orders on both sides.

```python title="simple_mm.py"
from arthur_sdk import Arthur
import time

def simple_market_maker(
    symbol: str,
    spread_bps: float = 20,  # 0.2% spread
    size_usd: float = 50
):
    """
    Minimal market maker - just place quotes.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"Simple MM: {symbol}")
    print(f"  Spread: {spread_bps} bps")
    print(f"  Size: ${size_usd}/side")
    print("-" * 40)
    
    while True:
        try:
            # Get mid price
            spread_info = client.spread(symbol)
            mid = spread_info['mid']
            
            # Calculate quote prices
            half_spread = (spread_bps / 10000) * mid / 2
            bid_price = mid - half_spread
            ask_price = mid + half_spread
            
            # Place quotes (cancels existing first)
            quotes = client.quote(
                symbol=symbol,
                bid_price=bid_price,
                ask_price=ask_price,
                size=size_usd / mid
            )
            
            print(f"Quoted: {bid_price:.4f} / {ask_price:.4f} "
                  f"(spread: {spread_bps} bps)")
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(30)  # Requote every 30s


if __name__ == "__main__":
    simple_market_maker("ORDER", spread_bps=25, size_usd=100)
```

---

## Using MarketMaker Class

The built-in MarketMaker handles inventory skewing and risk.

### Config File

```json title="strategies/order-mm.json"
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

### Run It

```python title="run_mm.py"
from arthur_sdk import Arthur, MarketMaker, MMConfig

client = Arthur.from_credentials_file("credentials.json")
config = MMConfig.from_file("strategies/order-mm.json")
mm = MarketMaker(client, config)

# Test single quote cycle
print("Testing single quote...")
result = mm.run_once()
print(f"Mid: ${result['mid_price']:.5f}")
print(f"Bid: ${result['quotes']['bid_price']:.5f}")
print(f"Ask: ${result['quotes']['ask_price']:.5f}")
print(f"Spread: {result['quotes']['spread_bps']:.1f} bps")
print(f"Skew: {result['quotes']['skew_bps']:.1f} bps")

# Run continuously (Ctrl+C to stop)
# mm.run_loop()
```

---

## Inventory-Aware MM

Manually implement inventory skewing.

```python title="inventory_mm.py"
from arthur_sdk import Arthur
import time

def inventory_aware_mm(
    symbol: str,
    base_spread_bps: float = 20,
    size_usd: float = 50,
    max_inventory_usd: float = 300,
    skew_per_100: float = 5  # BPS to skew per $100 inventory
):
    """
    Market maker that skews quotes based on inventory.
    
    When long, move quotes down (encourage selling to us).
    When short, move quotes up (encourage buying from us).
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"Inventory-Aware MM: {symbol}")
    print(f"  Base spread: {base_spread_bps} bps")
    print(f"  Max inventory: ${max_inventory_usd}")
    print("-" * 40)
    
    while True:
        try:
            # Get market data
            spread_info = client.spread(symbol)
            mid = spread_info['mid']
            
            # Get current position
            pos = client.position(symbol)
            if pos:
                inventory_usd = pos.size * mid
                if pos.side == "SHORT":
                    inventory_usd = -inventory_usd
            else:
                inventory_usd = 0
            
            # Check inventory limits
            if abs(inventory_usd) >= max_inventory_usd:
                print(f"⚠️ Max inventory reached: ${inventory_usd:.0f}")
                client.cancel_all(symbol)
                time.sleep(60)
                continue
            
            # Calculate skew
            # Positive inventory = long = want to sell = move prices down
            skew_bps = (inventory_usd / 100) * skew_per_100
            
            # Calculate prices
            half_spread = (base_spread_bps / 10000) * mid / 2
            skew_amount = (skew_bps / 10000) * mid
            
            bid_price = mid - half_spread - skew_amount
            ask_price = mid + half_spread - skew_amount
            
            # Place quotes
            quotes = client.quote(
                symbol=symbol,
                bid_price=bid_price,
                ask_price=ask_price,
                size=size_usd / mid
            )
            
            # Log
            actual_spread_bps = ((ask_price - bid_price) / mid) * 10000
            print(f"Mid: ${mid:.4f} | Inv: ${inventory_usd:+.0f} | "
                  f"Skew: {skew_bps:+.1f}bps | "
                  f"Spread: {actual_spread_bps:.1f}bps")
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(30)


if __name__ == "__main__":
    inventory_aware_mm("ORDER")
```

---

## Multi-Level MM

Place multiple levels of quotes.

```python title="multi_level_mm.py"
from arthur_sdk import Arthur
import time

def multi_level_mm(
    symbol: str,
    levels: int = 3,
    base_spread_bps: float = 15,
    level_spacing_bps: float = 10,
    size_per_level_usd: float = 30
):
    """
    Multi-level market maker.
    Places quotes at multiple price levels.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"Multi-Level MM: {symbol}")
    print(f"  Levels: {levels}")
    print(f"  Base spread: {base_spread_bps} bps")
    print(f"  Level spacing: {level_spacing_bps} bps")
    print("-" * 40)
    
    while True:
        try:
            # Cancel existing orders
            client.cancel_all(symbol)
            
            # Get mid
            spread_info = client.spread(symbol)
            mid = spread_info['mid']
            
            print(f"\nMid: ${mid:.4f}")
            
            # Place bids
            for i in range(levels):
                spread = base_spread_bps + (i * level_spacing_bps)
                price = mid * (1 - spread / 10000)
                size = size_per_level_usd / price
                
                order = client.limit_buy(symbol, price=price, size=size, post_only=True)
                print(f"  BID L{i+1}: ${price:.4f} ({size:.2f})")
            
            # Place asks
            for i in range(levels):
                spread = base_spread_bps + (i * level_spacing_bps)
                price = mid * (1 + spread / 10000)
                size = size_per_level_usd / price
                
                order = client.limit_sell(symbol, price=price, size=size, post_only=True)
                print(f"  ASK L{i+1}: ${price:.4f} ({size:.2f})")
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(30)


if __name__ == "__main__":
    multi_level_mm("ORDER", levels=3)
```

---

## Spread Capture with TP/SL

Lock in profits when orders fill.

```python title="spread_capture_mm.py"
from arthur_sdk import Arthur
import time

def spread_capture_mm(
    symbol: str,
    spread_bps: float = 30,
    size_usd: float = 100,
    take_profit_bps: float = 10,
    stop_loss_bps: float = 20
):
    """
    Place quote, set TP/SL when filled.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"Spread Capture MM: {symbol}")
    print("-" * 40)
    
    while True:
        try:
            # Check for existing position
            pos = client.position(symbol)
            
            if pos:
                # Manage existing position
                pnl_bps = pos.pnl_percent * 100  # Convert to bps
                
                if pnl_bps >= take_profit_bps:
                    print(f"✅ Take profit: {pnl_bps:.0f} bps")
                    client.close(symbol)
                elif pnl_bps <= -stop_loss_bps:
                    print(f"❌ Stop loss: {pnl_bps:.0f} bps")
                    client.close(symbol)
                else:
                    print(f"Position: {pos.side} | PnL: {pnl_bps:.0f} bps")
            else:
                # No position - place quotes
                spread_info = client.spread(symbol)
                mid = spread_info['mid']
                
                half_spread = (spread_bps / 10000) * mid / 2
                bid = mid - half_spread
                ask = mid + half_spread
                
                quotes = client.quote(symbol, bid, ask, size=size_usd / mid)
                print(f"Quoted: ${bid:.4f} / ${ask:.4f}")
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(10)


if __name__ == "__main__":
    spread_capture_mm("ORDER")
```

---

## Spread Monitoring Dashboard

Monitor spreads across markets.

```python title="spread_monitor.py"
from arthur_sdk import Arthur
import time

def spread_monitor():
    """Monitor spreads to find market making opportunities."""
    client = Arthur.from_credentials_file("credentials.json")
    
    symbols = ["ORDER", "WOO", "TIA", "SUI", "ARB", "OP"]
    
    print("Spread Monitor")
    print("=" * 60)
    
    while True:
        print(f"\n{time.strftime('%H:%M:%S')}")
        print(f"{'Symbol':<10} {'Bid':<12} {'Ask':<12} {'Spread':<10} {'Vol'}")
        print("-" * 60)
        
        opportunities = []
        
        for symbol in symbols:
            try:
                spread_info = client.spread(symbol)
                spread_bps = spread_info['spread_bps']
                
                # Wide spread = opportunity
                flag = "🟢" if spread_bps > 20 else "  "
                
                print(f"{symbol:<10} "
                      f"${spread_info['best_bid']:<11.4f} "
                      f"${spread_info['best_ask']:<11.4f} "
                      f"{spread_bps:>6.1f} bps "
                      f"{flag}")
                
                if spread_bps > 20:
                    opportunities.append((symbol, spread_bps))
                    
            except Exception as e:
                print(f"{symbol:<10} Error: {e}")
        
        if opportunities:
            print(f"\n🎯 Opportunities:")
            for sym, spread in sorted(opportunities, key=lambda x: -x[1]):
                print(f"  {sym}: {spread:.1f} bps")
        
        time.sleep(60)


if __name__ == "__main__":
    spread_monitor()
```

---

## MM Performance Tracker

Track your market making performance.

```python title="mm_tracker.py"
from arthur_sdk import Arthur
from dataclasses import dataclass
from datetime import datetime
import json

@dataclass
class MMStats:
    symbol: str
    start_time: datetime
    quotes_placed: int = 0
    orders_filled: int = 0
    volume_usd: float = 0
    fees_paid: float = 0
    fees_earned: float = 0  # Maker rebates
    pnl: float = 0


def mm_with_tracking(symbol: str, spread_bps: float = 25, size_usd: float = 50):
    """Market maker with performance tracking."""
    client = Arthur.from_credentials_file("credentials.json")
    
    stats = MMStats(symbol=symbol, start_time=datetime.now())
    
    print(f"MM with Tracking: {symbol}")
    print("-" * 40)
    
    try:
        while True:
            # Get mid
            spread_info = client.spread(symbol)
            mid = spread_info['mid']
            
            # Place quotes
            half_spread = (spread_bps / 10000) * mid / 2
            bid = mid - half_spread
            ask = mid + half_spread
            
            quotes = client.quote(symbol, bid, ask, size=size_usd / mid)
            stats.quotes_placed += 2
            
            print(f"Quotes: {stats.quotes_placed} | "
                  f"Fills: {stats.orders_filled} | "
                  f"Volume: ${stats.volume_usd:.0f} | "
                  f"PnL: ${stats.pnl:.2f}")
            
            time.sleep(30)
            
    except KeyboardInterrupt:
        # Print final stats
        runtime = (datetime.now() - stats.start_time).total_seconds() / 3600
        
        print("\n" + "=" * 40)
        print("SESSION SUMMARY")
        print("=" * 40)
        print(f"Runtime: {runtime:.1f} hours")
        print(f"Quotes placed: {stats.quotes_placed}")
        print(f"Orders filled: {stats.orders_filled}")
        print(f"Volume: ${stats.volume_usd:.2f}")
        print(f"Fees paid: ${stats.fees_paid:.2f}")
        print(f"Rebates earned: ${stats.fees_earned:.2f}")
        print(f"PnL: ${stats.pnl:.2f}")
        
        if stats.volume_usd > 0:
            print(f"PnL/Volume: {(stats.pnl / stats.volume_usd) * 10000:.1f} bps")


if __name__ == "__main__":
    mm_with_tracking("ORDER")
```

---

## Going Live Checklist

Before running live:

- [ ] **Start with dry_run=True** — Test your logic first
- [ ] **Use small sizes** — $25-50 per side initially
- [ ] **Wide spreads** — Start at 30-50 bps, tighten gradually
- [ ] **Set max inventory** — Don't accumulate too much risk
- [ ] **Monitor closely** — Watch first few hours of live trading
- [ ] **Have stop loss** — Cut losses if things go wrong
- [ ] **Test on testnet** — Use testnet.orderly.network first

---

## Fee Economics

On Arthur DEX (via Orderly):

| Role | Fee |
|------|-----|
| Taker | ~0.05% |
| Maker | **-0.02%** (rebate) |

With **post_only=True**, you're always a maker → earn rebates!

**Break-even spread:**
```
Break-even = taker_fee - maker_rebate
           = 0.05% - (-0.02%)
           = 0.07% = 7 bps
```

Any spread > 7 bps is profitable (before inventory risk).

---

## Next Steps

- [API Reference](../api/market-maker.md) — Full MM API docs
- [Strategy Examples](strategies.md) — Directional strategies
- [Basic Examples](basic.md) — Simple trading
