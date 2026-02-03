# Getting Credentials

This guide explains how to get API credentials for trading on Arthur DEX.

---

## What You Need

To trade via the SDK, you need three credentials:

| Credential | Format | Description |
|------------|--------|-------------|
| **API Key** | `ed25519:xxx...` | Public key for authentication |
| **Secret Key** | `ed25519:xxx...` | Private key for signing requests |
| **Account ID** | `0x...` | Your unique account identifier |

---

## Option 1: Arthur DEX (Recommended)

The easiest way to get credentials.

### Step 1: Connect Wallet

1. Go to [arthurdex.com](https://arthurdex.com)
2. Click **Connect Wallet**
3. Select your wallet (MetaMask, WalletConnect, etc.)
4. Sign the connection message

### Step 2: Deposit Funds

1. Navigate to **Portfolio** or **Deposit**
2. Deposit USDC to your trading account
3. Wait for confirmation (usually < 1 minute)

### Step 3: Create API Keys

1. Go to **Settings → API Keys**
2. Click **Create API Key**
3. Give it a descriptive name (e.g., "My Trading Bot")
4. Select permissions:
    - ✅ **Read** - View positions, orders, balance
    - ✅ **Trade** - Place and cancel orders
    - ❌ **Withdraw** - Not needed for trading
5. Click **Create**
6. **Important**: Copy both the API Key AND Secret Key immediately
7. The secret key is only shown once!

### Step 4: Get Account ID

Your Account ID is shown in:

- **Settings → Account Info**
- Or in the URL: `arthurdex.com/portfolio/0x...`

---

## Option 2: Orderly Network Direct

For advanced users who want direct access.

### Using orderly-evm-connector

```python
# Install the official SDK
pip install orderly-evm-connector

from orderly_evm_connector import Client
from eth_account import Account

# Generate a new wallet or use existing
wallet = Account.create()  # Or Account.from_key("your_private_key")

# Create Orderly client
client = Client(
    private_key=wallet.key.hex(),
    orderly_account_id=None,  # Will be created
)

# Register and get credentials
client.register()
api_key = client.create_api_key()

print(f"API Key: {api_key['api_key']}")
print(f"Secret: {api_key['secret_key']}")
print(f"Account ID: {client.orderly_account_id}")
```

---

## Credentials File Format

Save your credentials to a JSON file:

```json title="credentials.json"
{
    "api_key": "ed25519:6ZBxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "secret_key": "ed25519:yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy",
    "account_id": "0x1234567890abcdef1234567890abcdef12345678901234567890abcdef12345678"
}
```

### Alternative Key Names

The SDK accepts multiple key name formats:

```json
// Option A (standard)
{
    "api_key": "...",
    "secret_key": "...",
    "account_id": "..."
}

// Option B (Orderly style)
{
    "orderly_key": "...",
    "orderly_secret": "...",
    "account_id": "..."
}

// Option C (minimal)
{
    "key": "...",
    "secret_key": "...",
    "account_id": "..."
}
```

---

## Security Best Practices

### DO ✅

- Store credentials in a file outside your git repo
- Use environment variables for production
- Create separate API keys for each bot/purpose
- Regularly rotate API keys
- Use read-only keys when possible

### DON'T ❌

- Never commit credentials to git
- Don't share API keys
- Don't give withdraw permissions to trading bots
- Don't hardcode credentials in source code

### Using Environment Variables

For production, use environment variables:

```python
import os
from arthur_sdk import Arthur

client = Arthur(
    api_key=os.environ["ARTHUR_API_KEY"],
    secret_key=os.environ["ARTHUR_SECRET_KEY"],
    account_id=os.environ["ARTHUR_ACCOUNT_ID"],
)
```

Set them in your shell:

```bash
export ARTHUR_API_KEY="ed25519:xxx"
export ARTHUR_SECRET_KEY="ed25519:yyy"
export ARTHUR_ACCOUNT_ID="0x..."
```

### .gitignore

Add these to your `.gitignore`:

```text
credentials.json
*.credentials.json
.env
.env.*
```

---

## Testnet Credentials

For testing without real money, use testnet:

1. Go to [testnet.orderly.network](https://testnet.orderly.network)
2. Connect wallet
3. Get testnet USDC from the faucet
4. Create API keys (same process as mainnet)

Use testnet in your code:

```python
client = Arthur.from_credentials_file(
    "testnet-credentials.json",
    testnet=True
)
```

---

## Troubleshooting

### "Invalid API Key" Error

- Check that the key starts with `ed25519:`
- Verify you copied the entire key without trailing spaces
- Make sure the key has trading permissions

### "Invalid Signature" Error

- Secret key might be wrong
- Check for copy-paste errors
- Ensure the key hasn't been rotated/revoked

### "Account Not Found" Error

- Account ID format should be `0x` followed by 64 hex characters
- Make sure you've deposited funds to activate the account

### Rate Limiting

Arthur DEX has rate limits:

- **10 requests/second** for order placement
- **20 requests/second** for other endpoints

The SDK handles rate limiting gracefully, but avoid hammering the API.

---

## Managing Multiple Accounts

For multiple accounts, use different credential files:

```python
# Production account
prod_client = Arthur.from_credentials_file("prod-credentials.json")

# Test account
test_client = Arthur.from_credentials_file("test-credentials.json", testnet=True)

# Different strategy accounts
strat_a = Arthur.from_credentials_file("strategy-a-credentials.json")
strat_b = Arthur.from_credentials_file("strategy-b-credentials.json")
```

Or use a credentials manager:

```python
import json
from pathlib import Path

class CredentialsManager:
    def __init__(self, base_path: str = "~/.arthur"):
        self.base = Path(base_path).expanduser()
        self.base.mkdir(exist_ok=True)
    
    def save(self, name: str, creds: dict):
        path = self.base / f"{name}.json"
        path.write_text(json.dumps(creds, indent=2))
    
    def load(self, name: str) -> Arthur:
        path = self.base / f"{name}.json"
        return Arthur.from_credentials_file(str(path))
    
    def list(self) -> list:
        return [p.stem for p in self.base.glob("*.json")]
```

---

## Next Steps

Once you have credentials:

1. [Start trading →](quickstart.md#4-your-first-trade)
2. [Explore the API →](api/client.md)
3. [Build a strategy →](examples/strategies.md)
