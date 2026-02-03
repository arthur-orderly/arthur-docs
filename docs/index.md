# Arthur SDK

<div class="hero" markdown>

## Trade in 3 Lines of Code

The simplest way to trade perpetual futures with AI agents.

```python
from arthur_sdk import Arthur

client = Arthur.from_credentials_file("credentials.json")
client.buy("ETH", usd=100)  # That's it!
```

[Get Started](quickstart.md){ .md-button .md-button--primary }
[View on PyPI](https://pypi.org/project/arthur-sdk/){ .md-button }

</div>

---

## Why Arthur SDK?

### 🤖 Built for Agents

Designed specifically for AI trading agents. No complex signatures, no confusing structs. Just simple methods that do what they say.

### ⚡ Zero Friction

Install with pip, load credentials from a file, start trading. Go from zero to live trades in under 5 minutes.

### 🛡️ Battle-Tested

Built on [Orderly Network](https://orderly.network) — the same infrastructure powering billions in trading volume across DeFi.

### 📊 Full Featured

Market orders, limit orders, positions, strategies, market making — everything you need in one package.

---

## Quick Install

```bash
pip install arthur-sdk
```

---

## Features at a Glance

=== "Trading"

    ```python
    # Market orders
    client.buy("ETH", usd=100)      # Long $100 of ETH
    client.sell("BTC", size=0.01)   # Short 0.01 BTC
    
    # Limit orders
    client.limit_buy("ETH", price=2000, usd=100)
    client.limit_sell("ETH", price=2500, usd=100)
    
    # Close positions
    client.close("ETH")             # Close single
    client.close_all()              # Close all
    ```

=== "Positions"

    ```python
    # Check positions
    for pos in client.positions():
        print(f"{pos.symbol}: {pos.side}")
        print(f"  Size: {pos.size}")
        print(f"  PnL: ${pos.unrealized_pnl:.2f}")
    
    # Quick PnL check
    print(f"Total PnL: ${client.pnl():.2f}")
    
    # Account summary
    summary = client.summary()
    ```

=== "Strategies"

    ```python
    from arthur_sdk import StrategyRunner
    
    runner = StrategyRunner(client)
    result = runner.run("strategy.json")
    
    # Multi-asset strategies supported:
    # - RSI-based entries
    # - Stop loss / take profit
    # - Position limits
    ```

=== "Market Making"

    ```python
    from arthur_sdk import MarketMaker, MMConfig
    
    config = MMConfig.from_file("mm-config.json")
    mm = MarketMaker(client, config)
    
    # Single quote cycle
    mm.run_once()
    
    # Continuous quoting
    mm.run_loop()
    ```

---

## Supported Markets

Trade any perpetual market on Orderly Network:

| Symbol | Market |
|--------|--------|
| `BTC` | Bitcoin |
| `ETH` | Ethereum |
| `SOL` | Solana |
| `ARB` | Arbitrum |
| `OP` | Optimism |
| `AVAX` | Avalanche |
| `LINK` | Chainlink |
| `DOGE` | Dogecoin |
| `SUI` | Sui |
| `TIA` | Celestia |
| `WOO` | WOO Network |
| `ORDER` | Orderly Network |

Use short symbols (`ETH`) or full symbols (`PERP_ETH_USDC`) — the SDK handles both.

---

## Links

- **Arthur DEX**: [https://arthurdex.com](https://arthurdex.com)
- **Orderly Network**: [https://orderly.network](https://orderly.network)
- **GitHub**: [https://github.com/arthur-orderly](https://github.com/arthur-orderly)
- **PyPI**: [https://pypi.org/project/arthur-sdk/](https://pypi.org/project/arthur-sdk/)

---

<div class="footer-cta" markdown>

Ready to build? [Get started in 5 minutes →](quickstart.md)

</div>
