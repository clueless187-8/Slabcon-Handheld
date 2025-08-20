#!/usr/bin/env bash
set -euo pipefail

# ===== CONFIG =====
USER="YOUR_GITHUB_USERNAME"
REPO="slabcon"
YEAR="$(date +%Y)"

# ===== CREATE TREE =====
mkdir -p "$REPO"/{apps/handheld,services/powerd,hardware/cad,docs,tools}
cd "$REPO"

# ----- .gitignore -----
cat > .gitignore << 'EOF'
# OS/editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Python
__pycache__/
*.pyc
.venv/

# Node
node_modules/
dist/
.parcel-cache/
.sass-cache/
*.map

# CAD exports
hardware/cad/exports/
EOF

# ----- .nojekyll -----
: > .nojekyll

# ----- LICENSE (MIT) -----
cat > LICENSE <<EOF
MIT License

Copyright (c) ${YEAR} ${USER}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# ----- README.md -----
cat > README.md << 'EOF'
# Slabcon — Chapter 01: Dawn Board

A prestige‑edition Raspberry Pi handheld project. This repo contains:
- Handheld runtime (Python)
- Power daemon (graceful low‑voltage shutdown + long‑press)
- GitHub Pages site (interactive shelf)
- Parametric OpenSCAD suite with exploded views
- Release and export tools (BOM, STEP)

## Quick start
- Handheld runtime: see apps/handheld/ (pip install pygame gpiozero smbus2 pyyaml)
- Power daemon: services/powerd/
- Site: docs/ (GitHub Pages serves from /docs)
- CAD: hardware/cad/ (OpenSCAD), export scripts in tools/

## CAD Render Style Guide
- Background #0F0F0F, edges white, accent gold #C9A85C
- Camera 35° iso, Z‑up; subtle shadows
- Exploded: show_exploded = true, explode_factor ≈ 1.5

Each release is a chapter; each chapter gets a spine on the shelf.
EOF

# ===== DOCS (GitHub Pages: interactive shelf) =====

# ----- docs/index.html -----
cat > docs/index.html << 'EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>Slabcon — Vault Shelf</title>
  <link rel="stylesheet" href="styles.css"/>
</head>
<body>
  <header>
    <h1>Slabcon — Vault Shelf</h1>
    <input id="q" type="search" placeholder="Search chapters, tags..."/>
  </header>
  <main id="shelf" class="shelf"></main>
  <div id="modal" class="modal hidden">
    <div class="card">
      <button id="close">×</button>
      <h2 id="m_title"></h2>
      <p id="m_desc"></p>
      <div id="m_meta"></div>
      <nav id="m_links"></nav>
    </div>
  </div>
  <footer>Each spine a heartbeat in the series.</footer>
  <script src="app.js"></script>
</body>
</html>
EOF

# ----- docs/styles.css -----
cat > docs/styles.css << 'EOF'
:root {
  --bg: #0f0f0f;
  --fg: #e6e6e6;
  --muted: #9aa0a6;
  --accent: #c9a85c;
  --card
