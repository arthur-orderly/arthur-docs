# Strategy Examples

Complete examples of automated trading strategies.

---

## Simple RSI Strategy

A basic strategy that buys when RSI is oversold.

### Strategy File

```json title="strategies/simple-rsi.json"
{
    "name": "Simple RSI",
    "version": "1.0.0",
    "description": "Buy ETH when RSI < 30, sell when RSI > 70",
    
    "symbol": "ETH",
    "timeframe": "4h",
    
    "signals": {
        "period": 14,
        "long_entry": 30,
        "short_entry": 70
    },
    
    "position": {
        "leverage": 3,
        "size_pct": 10
    },
    
    "risk": {
        "stop_loss_pct": 5,
        "take_profit_pct": 15
    },
    
    "flags": {
        "dry_run": false,
        "allow_shorts": false
    }
}
```

### Run It

```python title="run_simple_rsi.py"
from arthur_sdk import Arthur, StrategyRunner

client = Arthur.from_credentials_file("credentials.json")
runner = StrategyRunner(client)

# Run once
result = runner.run("strategies/simple-rsi.json", force=True)

print(f"Signals: {len(result['signals'])}")
for signal in result['signals']:
    print(f"  {signal['action']}: {signal['reason']}")

print(f"Trades: {len(result['trades'])}")
```

---

## Multi-Asset Strategy (Unlockoor Style)

Long majors, short memes. Based on the proven Unlockoor strategy.

### Strategy File

```json title="strategies/unlockoor.json"
{
    "name": "Unlockoor",
    "version": "2.0.0",
    "description": "Long majors on oversold, short memes on overbought",
    
    "long_assets": ["BTC", "ETH", "SOL"],
    "short_assets": ["DOGE", "SHIB", "PEPE"],
    
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
        "max_positions": 4
    },
    
    "flags": {
        "dry_run": false,
        "allow_shorts": true
    }
}
```

### Run It

```python title="run_unlockoor.py"
from arthur_sdk import Arthur, StrategyRunner
import time

client = Arthur.from_credentials_file("credentials.json")

def on_signal(signal):
    emoji = "🟢" if signal.action == "long" else "🔴" if signal.action == "short" else "⚪"
    print(f"{emoji} {signal.symbol}: {signal.action}")
    print(f"   {signal.reason}")

def on_trade(trade):
    status = "✅" if trade.get("status") == "executed" else "❌"
    print(f"{status} Executed: {trade['action']} {trade['symbol']}")

runner = StrategyRunner(
    client,
    on_signal=on_signal,
    on_trade=on_trade
)

# Run continuously
print("Starting Unlockoor strategy...")
while True:
    result = runner.run("strategies/unlockoor.json")
    
    if result.get("skipped"):
        print(f"[{time.strftime('%H:%M')}] Waiting for next candle...")
    else:
        print(f"[{time.strftime('%H:%M')}] "
              f"Signals: {len(result['signals'])} | "
              f"Trades: {len(result['trades'])}")
    
    time.sleep(60)  # Check every minute
```

---

## DCA Bot

Dollar-cost averaging at regular intervals.

```python title="bots/dca_bot.py"
from arthur_sdk import Arthur
import time
from datetime import datetime

def dca_bot(
    symbol: str,
    amount_usd: float,
    interval_hours: float,
    max_position_usd: float = 10000
):
    """
    Dollar-cost averaging bot.
    
    Args:
        symbol: Token to accumulate
        amount_usd: Amount per buy
        interval_hours: Hours between buys
        max_position_usd: Stop when position reaches this size
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"DCA Bot Starting")
    print(f"  Symbol: {symbol}")
    print(f"  Amount: ${amount_usd}/buy")
    print(f"  Interval: {interval_hours}h")
    print(f"  Max position: ${max_position_usd}")
    print("-" * 40)
    
    buys = 0
    total_spent = 0
    
    while True:
        try:
            # Check current position
            pos = client.position(symbol)
            pos_value = (pos.size * pos.mark_price) if pos else 0
            
            if pos_value >= max_position_usd:
                print(f"Max position reached (${pos_value:.0f})")
                break
            
            # Get price
            price = client.price(symbol)
            
            # Buy
            order = client.buy(symbol, usd=amount_usd)
            buys += 1
            total_spent += amount_usd
            
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M')}] "
                  f"Bought ${amount_usd} of {symbol} @ ${price:.2f}")
            
            # Show position
            pos = client.position(symbol)
            if pos:
                print(f"  Position: {pos.size:.4f} {symbol}")
                print(f"  Avg entry: ${pos.entry_price:.2f}")
                print(f"  Value: ${pos.size * pos.mark_price:.2f}")
                print(f"  PnL: ${pos.unrealized_pnl:.2f} ({pos.pnl_percent:.1f}%)")
            
            print(f"  Total buys: {buys} (${total_spent:.0f} spent)")
            
        except Exception as e:
            print(f"Error: {e}")
        
        # Wait for next interval
        time.sleep(interval_hours * 3600)


if __name__ == "__main__":
    # Buy $25 of ETH every 6 hours
    dca_bot("ETH", amount_usd=25, interval_hours=6)
```

---

## Grid Trading Bot

Place orders at regular price intervals.

```python title="bots/grid_bot.py"
from arthur_sdk import Arthur
import time

def grid_bot(
    symbol: str,
    lower_price: float,
    upper_price: float,
    grid_levels: int,
    size_per_grid_usd: float
):
    """
    Grid trading bot.
    Places buy orders below current price, sell orders above.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    # Calculate grid prices
    price_range = upper_price - lower_price
    grid_spacing = price_range / (grid_levels - 1)
    grid_prices = [lower_price + i * grid_spacing for i in range(grid_levels)]
    
    print(f"Grid Bot: {symbol}")
    print(f"  Range: ${lower_price:.2f} - ${upper_price:.2f}")
    print(f"  Levels: {grid_levels}")
    print(f"  Spacing: ${grid_spacing:.2f}")
    print(f"  Size: ${size_per_grid_usd}/level")
    print("-" * 40)
    
    while True:
        try:
            # Get current price
            current_price = client.price(symbol)
            print(f"\nCurrent price: ${current_price:.2f}")
            
            # Cancel existing orders
            client.cancel_all(symbol)
            
            # Place grid orders
            for price in grid_prices:
                if price < current_price * 0.999:  # Below current = buy
                    order = client.limit_buy(
                        symbol, 
                        price=price, 
                        usd=size_per_grid_usd,
                        post_only=True
                    )
                    print(f"  BUY @ ${price:.2f}")
                elif price > current_price * 1.001:  # Above current = sell
                    order = client.limit_sell(
                        symbol,
                        price=price,
                        usd=size_per_grid_usd,
                        post_only=True
                    )
                    print(f"  SELL @ ${price:.2f}")
            
            # Show position
            pos = client.position(symbol)
            if pos:
                print(f"\nPosition: {pos.side} {pos.size:.4f}")
                print(f"PnL: ${pos.unrealized_pnl:.2f}")
            
        except Exception as e:
            print(f"Error: {e}")
        
        # Refresh every 5 minutes
        time.sleep(300)


if __name__ == "__main__":
    # Grid trade ETH between $1,800 and $2,200
    grid_bot(
        symbol="ETH",
        lower_price=1800,
        upper_price=2200,
        grid_levels=10,
        size_per_grid_usd=50
    )
```

---

## Momentum Strategy

Trade breakouts based on price momentum.

```python title="bots/momentum_bot.py"
from arthur_sdk import Arthur
import time
from collections import deque

def momentum_bot(
    symbol: str,
    lookback_minutes: int = 60,
    threshold_pct: float = 2.0,
    position_usd: float = 100
):
    """
    Momentum bot - trades breakouts.
    
    Enters long when price is up threshold% in lookback period.
    Enters short when price is down threshold%.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    # Track price history
    prices = deque(maxlen=lookback_minutes)
    
    print(f"Momentum Bot: {symbol}")
    print(f"  Lookback: {lookback_minutes} min")
    print(f"  Threshold: {threshold_pct}%")
    print("-" * 40)
    
    while True:
        try:
            price = client.price(symbol)
            prices.append(price)
            
            if len(prices) < lookback_minutes:
                print(f"Collecting data... ({len(prices)}/{lookback_minutes})")
                time.sleep(60)
                continue
            
            # Calculate momentum
            oldest_price = prices[0]
            momentum_pct = ((price - oldest_price) / oldest_price) * 100
            
            print(f"{symbol}: ${price:.2f} | Momentum: {momentum_pct:+.2f}%")
            
            # Check for existing position
            pos = client.position(symbol)
            
            if pos:
                # Exit logic
                if pos.side == "LONG" and momentum_pct < 0:
                    print(f"Closing long (momentum reversed)")
                    client.close(symbol)
                elif pos.side == "SHORT" and momentum_pct > 0:
                    print(f"Closing short (momentum reversed)")
                    client.close(symbol)
                else:
                    print(f"Holding {pos.side}, PnL: ${pos.unrealized_pnl:.2f}")
            else:
                # Entry logic
                if momentum_pct >= threshold_pct:
                    print(f"🚀 Breakout UP! Going long...")
                    client.buy(symbol, usd=position_usd)
                elif momentum_pct <= -threshold_pct:
                    print(f"📉 Breakdown! Going short...")
                    client.sell(symbol, usd=position_usd)
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(60)


if __name__ == "__main__":
    momentum_bot("ETH", lookback_minutes=30, threshold_pct=1.5)
```

---

## Mean Reversion Strategy

Trade reversions to the mean.

```python title="bots/mean_reversion.py"
from arthur_sdk import Arthur
import time
from collections import deque
import statistics

def mean_reversion_bot(
    symbol: str,
    lookback: int = 20,
    std_devs: float = 2.0,
    position_usd: float = 100
):
    """
    Mean reversion - buys at lower band, sells at upper band.
    Uses Bollinger Bands logic.
    """
    client = Arthur.from_credentials_file("credentials.json")
    
    prices = deque(maxlen=lookback)
    
    print(f"Mean Reversion: {symbol}")
    print(f"  Lookback: {lookback}")
    print(f"  Std devs: {std_devs}")
    print("-" * 40)
    
    while True:
        try:
            price = client.price(symbol)
            prices.append(price)
            
            if len(prices) < lookback:
                print(f"Collecting... ({len(prices)}/{lookback})")
                time.sleep(60)
                continue
            
            # Calculate bands
            mean = statistics.mean(prices)
            std = statistics.stdev(prices)
            upper_band = mean + (std_devs * std)
            lower_band = mean - (std_devs * std)
            
            print(f"{symbol}: ${price:.2f}")
            print(f"  Mean: ${mean:.2f}")
            print(f"  Bands: ${lower_band:.2f} - ${upper_band:.2f}")
            
            pos = client.position(symbol)
            
            if pos:
                # Exit at mean
                if pos.side == "LONG" and price >= mean:
                    print("Price at mean, closing long")
                    client.close(symbol)
                elif pos.side == "SHORT" and price <= mean:
                    print("Price at mean, closing short")
                    client.close(symbol)
            else:
                # Entry at bands
                if price <= lower_band:
                    print(f"🟢 Price at lower band, going long")
                    client.buy(symbol, usd=position_usd)
                elif price >= upper_band:
                    print(f"🔴 Price at upper band, going short")
                    client.sell(symbol, usd=position_usd)
            
        except Exception as e:
            print(f"Error: {e}")
        
        time.sleep(60)


if __name__ == "__main__":
    mean_reversion_bot("ETH")
```

---

## Running Strategies 24/7

### Using systemd (Linux)

```ini title="/etc/systemd/system/arthur-bot.service"
[Unit]
Description=Arthur Trading Bot
After=network.target

[Service]
Type=simple
User=youruser
WorkingDirectory=/home/youruser/trading
ExecStart=/usr/bin/python3 bot.py
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable arthur-bot
sudo systemctl start arthur-bot
sudo journalctl -u arthur-bot -f  # View logs
```

### Using pm2 (Node.js process manager)

```bash
npm install -g pm2
pm2 start bot.py --interpreter python3 --name arthur-bot
pm2 save
pm2 startup  # Auto-start on reboot
pm2 logs arthur-bot
```

### Using Docker

```dockerfile title="Dockerfile"
FROM python:3.11-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

CMD ["python", "bot.py"]
```

```bash
docker build -t arthur-bot .
docker run -d --name arthur-bot --restart always arthur-bot
```

---

## Next Steps

- [Market Making Examples](market-making.md) — Provide liquidity
- [API Reference](../api/strategies.md) — Strategy API docs
- [Basic Examples](basic.md) — Simple trading patterns
