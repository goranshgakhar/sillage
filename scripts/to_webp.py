#!/usr/bin/env python3
"""Stills -> webp posters for the site (PIL; no cwebp needed)."""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
NAMES = ["harvest", "atelier", "boutique", "finale"]

for name in NAMES:
    src = next(
        (ROOT / "work" / f"still_{name}.{ext}" for ext in ("png", "jpg", "jpeg", "webp")
         if (ROOT / "work" / f"still_{name}.{ext}").exists()),
        None,
    )
    if src is None:
        print(f"skip  still_{name} (missing)")
        continue
    im = Image.open(src).convert("RGB")
    if im.width > 1800:
        im = im.resize((1800, round(im.height * 1800 / im.width)), Image.LANCZOS)
    out = ROOT / "assets" / f"{name}.webp"
    im.save(out, "WEBP", quality=84)
    print(f"webp  {out}  {im.width}x{im.height}  {out.stat().st_size // 1024} KB")
