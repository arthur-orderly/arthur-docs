# Arthur SDK Documentation Site

Beautiful, comprehensive documentation for the Arthur SDK.

🔗 **Live:** https://arthurdex.com/docs

## Quick Start

```bash
# Install dependencies
pip install mkdocs-material mkdocs-minify-plugin

# Preview locally
mkdocs serve
# → Open http://127.0.0.1:8000

# Build static site
mkdocs build
# → Output in site/
```

## Structure

```
docs-site/
├── mkdocs.yml           # MkDocs configuration
├── docs/
│   ├── index.md         # Homepage
│   ├── quickstart.md    # Getting started
│   ├── credentials.md   # Credentials guide
│   ├── cli.md           # CLI reference
│   ├── api/
│   │   ├── client.md    # Arthur client API
│   │   ├── strategies.md # Strategy runner API
│   │   └── market-maker.md # Market maker API
│   ├── examples/
│   │   ├── basic.md     # Basic trading examples
│   │   ├── strategies.md # Strategy examples
│   │   └── market-making.md # MM examples
│   └── stylesheets/
│       └── extra.css    # Custom Arthur styling
└── site/                # Built site (after build)
```

## Deployment

### Option 1: Static Hosting

Build and upload `site/` to any static host:
- Vercel
- Netlify
- AWS S3 + CloudFront
- nginx/Apache

### Option 2: GitHub Pages

```bash
mkdocs gh-deploy
```

### Option 3: Subdirectory on arthurdex.com

1. Build: `mkdocs build`
2. Copy `site/*` to `/docs/` on your web server
3. Configure nginx/Apache to serve from that path

## Customization

### Colors

Arthur brand orange is configured in `docs/stylesheets/extra.css`:

```css
:root {
  --md-primary-fg-color: #FF6B35;
}
```

### Navigation

Edit `mkdocs.yml` → `nav` section to change menu structure.

### Adding Pages

1. Create `.md` file in `docs/`
2. Add to `nav` in `mkdocs.yml`
3. Rebuild

## Features

- 🌙 Dark mode by default (Material theme)
- 🔍 Built-in search
- 📋 Copy-paste code blocks
- 📱 Mobile responsive
- ⚡ Fast static site

## Why This Helps Volume

Great documentation is a **force multiplier** for developer adoption:

1. **Lower friction** — Developers can integrate faster
2. **Fewer support questions** — Docs answer common questions
3. **Professional credibility** — Shows we're serious
4. **Copy-paste friendly** — Every example works
5. **SEO** — Developers searching for trading SDKs find us

Every developer who successfully integrates = another agent driving volume on Arthur DEX.

## License

MIT — Same as Arthur SDK
