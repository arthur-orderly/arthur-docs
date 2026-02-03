# Quickstart

Get from zero to live trading in 5 minutes.

---

## 1. Install the SDK

```bash
pip install arthur-sdk
```

!!! note "Python Version"
    Arthur SDK requires Python 3.9 or higher.

---

## 2. Get Your API Keys

You'll need three things from Arthur DEX:

- **API Key** (ed25519 format)
- **Secret Key** (ed25519 format)
- **Account ID** (0x... format)

=== "From Arthur DEX"

    1. Go to [arthurdex.com](https://arthurdex.com)
    2. Connect your wallet
    3. Navigate to **Settings → API Keys**
    4. Create a new API key
    5. Copy the credentials

=== "From Orderly Network"

    1. Go to [orderly.network](https://orderly.network)
    2. Connect your wallet
    3. Create API keys with trading permissions
    4. Note: Use `broker_id: arthur_dex` for fee sharing

See [Credentials Guide](credentials.md) for detailed instructions.

---

## 3. Create Credentials File

Save your credentials to a JSON file:

```json title="credentials.json"
{
    "api_key": "ed25519:your_api_key_here",
    "secret_key": "ed25519:your_secret_key_here",
    "account_id": "0x1234567890abcdef..."
}
```

!!! warning "Keep it Secret!"
    Never commit your credentials file to git. Add `credentials.json` to your `.gitignore`.

---

## 4. Your First Trade

```python title="trade.py"
from arthur_sdk import Arthur

# Load credentials
client = Arthur.from_credentials_file("credentials.json")

# Check balance
print(f"Balance: ${client.balance():.2f}")

# Buy $10 of ETH (market order)
order = client.buy("ETH", usd=10)
print(f"Order placed: {order.order_id}")

# Check position
pos = client.position("ETH")
if pos:
    print(f"Position: {pos.side} {pos.size} ETH")
    print(f"Entry: ${pos.entry_price:.2f}")
    print(f"PnL: ${pos.unrealized_pnl:.2f}")
```

Run it:

```bash
python trade.py
```

---

## 5. Close Your Position

```python
# Close the ETH position
client.close("ETH")

# Or close everything
client.close_all()
```

---

## What's Next?

<div class="grid cards" markdown>

-   :material-api: **[API Reference](api/client.md)**
    
    Full documentation of all client methods

-   :material-strategy: **[Strategy Guide](examples/strategies.md)**
    
    Build automated trading strategies

-   :material-scale-balance: **[Market Making](examples/market-making.md)**
    
    Provide liquidity and earn rebates

-   :material-console: **[CLI Reference](cli.md)**
    
    Use Arthur from the command line

</div>

---

## Common First Steps

### Check Market Prices

```python
# Single price
eth_price = client.price("ETH")
print(f"ETH: ${eth_price:.2f}")

# All prices
prices = client.prices()
for symbol, price in prices.items():
    if not symbol.startswith("PERP_"):  # Short names only
        print(f"{symbol}: ${price:.2f}")
```

### View Your Account

```python
# Summary view
summary = client.summary()
print(f"Balance: ${summary['balance']:.2f}")
print(f"Equity: ${summary['equity']:.2f}")
print(f"Positions: {summary['positions']}")
print(f"Unrealized PnL: ${summary['unrealized_pnl']:.2f}")
```

### Use Testnet First

```python
# Use testnet for testing (no real money)
client = Arthur.from_credentials_file(
    "credentials.json",
    testnet=True  # ← Enable testnet
)
```

!!! tip "Testnet Faucet"
    Get testnet USDC at [testnet.orderly.network](https://testnet.orderly.network)

---

## Example: Simple DCA Bot

Here's a complete example of a Dollar Cost Averaging bot:

```python title="dca_bot.py"
from arthur_sdk import Arthur
import time

def dca_bot(symbol: str, amount_usd: float, interval_hours: float):
    """Simple DCA bot - buys fixed amount at regular intervals."""
    
    client = Arthur.from_credentials_file("credentials.json")
    
    print(f"Starting DCA bot: ${amount_usd} of {symbol} every {interval_hours}h")
    
    while True:
        try:
            # Get current price
            price = client.price(symbol)
            print(f"\n{symbol} price: ${price:.2f}")
            
            # Place buy order
            order = client.buy(symbol, usd=amount_usd)
            print(f"✓ Bought ${amount_usd} of {symbol}")
            
            # Show position
            pos = client.position(symbol)
            if pos:
                print(f"  Position: {pos.size:.4f} {symbol}")
                print(f"  Avg entry: ${pos.entry_price:.2f}")
                print(f"  PnL: ${pos.unrealized_pnl:.2f}")
            
        except Exception as e:
            print(f"✗ Error: {e}")
        
        # Wait for next interval
        print(f"Next buy in {interval_hours} hours...")
        time.sleep(interval_hours * 3600)


if __name__ == "__main__":
    # Buy $10 of BTC every hour
    dca_bot("BTC", amount_usd=10, interval_hours=1)
```

---

## Need Help?

- **Discord**: [Join our community](https://discord.gg/orderly)
- **Twitter**: [@arthurdex](https://twitter.com/arthurdex)
- **GitHub Issues**: [Report bugs](https://github.com/arthur-orderly/arthur-sdk/issues)
