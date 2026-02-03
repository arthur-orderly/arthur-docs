#!/bin/bash
# Build Arthur SDK Documentation

set -e

echo "🦊 Building Arthur SDK Docs..."

# Check for required packages
if ! pip show mkdocs-material > /dev/null 2>&1; then
    echo "Installing mkdocs-material..."
    pip install mkdocs-material mkdocs-minify-plugin
fi

# Build the site
mkdocs build

echo ""
echo "✅ Build complete!"
echo "   Static site generated in: site/"
echo ""
echo "To preview locally:"
echo "   mkdocs serve"
echo "   → Open http://127.0.0.1:8000"
echo ""
echo "To deploy to arthurdex.com/docs:"
echo "   1. Copy site/ contents to your web server"
echo "   2. Or use: mkdocs gh-deploy (for GitHub Pages)"
